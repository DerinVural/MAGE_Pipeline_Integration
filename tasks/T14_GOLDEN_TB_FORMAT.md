# Task T14: Golden-TB Format Flag for SimReviewer

**Status:** PENDING
**Priority:** HIGH — closes Faz 0 properly, unblocks Step 4/5 reachability
**Depends on:** T13 merged to `feat/mage-open-v2`
**Reference:** T13_DONE.md "Fix proposals" Proposal 2

---

## Context

T13 located the dominant pre-Step-4 barrier with high precision:

1. `sim_reviewer.py:69` requires the literal substring `"SIMULATION PASSED"`
   in stdout to declare a simulation passed.
2. VerilogEval-v2 golden testbenches do not emit this substring; they
   emit `"Mismatches: N in M samples"` instead.
3. Under `bypass_tb_gen=True`, the golden TB is loaded verbatim, so
   the literal is permanently absent.
4. Result: `is_sim_pass=False sim_mismatch_cnt=0` simultaneously, which
   trips `agent.py:186 assert sim_mismatch_cnt > 0` in 17/20 cells.
5. Step 4 (candidate generation) and Step 5 (RTLEditor) remain
   unreached.

T13 proposed three fixes; PM selected **Proposal 2: a runner-level
opt-in flag** that switches `sim_reviewer` to a mismatch-count-based
pass criterion when set.

This is a faithful-reproduction-friendly fix. The default behaviour
of `sim_reviewer` for non-bypass, LLM-generated TBs remains
bit-identical to upstream MAGE.

---

## Goal

Add `golden_tb_format: bool` flag (default `False`) plumbed from
runner → `TopAgent` → `SimReviewer` → `sim_review` function. When
`True`, the pass criterion in `sim_review` is:

```python
is_pass = (subprocess succeeded)
          and (mismatch_cnt == 0)
          and (stderr is empty or all-benign)
```

When `False` (default), the existing pass criterion is preserved
verbatim.

After implementation, **re-run T13's smoke set with both `bypass_tb_gen=True`
AND `golden_tb_format=True`**. Expectation: at least some cells now
reach Step 4 (`Candidate generation: round 1` log line) and
plausibly Step 5 (`RTL Editing: round 1`).

---

## Architectural starting point

T13 identified the relevant code:

```python
# sim_reviewer.py:67-74 (existing)
is_pass = (
    is_pass
    and "SIMULATION PASSED" in sim_output_obj.stdout
    and (
        sim_output_obj.stderr == ""
        or stderr_all_lines_benign(sim_output_obj.stderr)
    )
)
mismatch_cnt = sim_review_mismatch_cnt(sim_output_obj.stdout)
```

`mismatch_cnt` is already computed at line 75 — we just need to make
the pass check route through it under the new flag.

The `SimReviewer` class wraps `sim_review`. The flag needs to be
threaded through:

1. `sim_review()` function — accept new kwarg
2. `SimReviewer.__init__` and `review()` — accept and pass through
3. `TopAgent.__init__` or setter — accept and pass to `SimReviewer`
4. Runner argparse — expose `--golden-tb-format` flag

---

## Scope

### T14.1 — Modify `sim_review()` function

**File:** `src/mage/sim_reviewer.py`

Add a new keyword argument `golden_tb_format: bool = False` to the
`sim_review()` function signature. Inside the function, branch on
this flag:

```python
def sim_review(
    output_path_per_run: str,
    golden_rtl_path: str | None = None,
    golden_tb_format: bool = False,  # new
) -> Tuple[bool, int, str]:
    # ... existing code up to line 65 ...

    is_pass, sim_output = run_bash_command(cmd, timeout=60)
    sim_output_obj = CommandResult.model_validate_json(sim_output)
    mismatch_cnt = sim_review_mismatch_cnt(sim_output_obj.stdout)

    stderr_clean = (
        sim_output_obj.stderr == ""
        or stderr_all_lines_benign(sim_output_obj.stderr)
    )

    if golden_tb_format:
        is_pass = is_pass and (mismatch_cnt == 0) and stderr_clean
    else:
        is_pass = (
            is_pass
            and "SIMULATION PASSED" in sim_output_obj.stdout
            and stderr_clean
        )

    logger.info(
        f"Simulation is_pass: {is_pass}, mismatch_cnt: {mismatch_cnt}, "
        f"golden_tb_format: {golden_tb_format}\noutput: {sim_output}"
    )
    assert isinstance(sim_output, str) and isinstance(is_pass, bool)
    return is_pass, mismatch_cnt, sim_output
```

**Note:** The mismatch_cnt computation moves earlier (before is_pass
calculation) so the new branch can use it. This is a pure reordering;
the value is identical.

The other call sites of `sim_review`-style logic (lines 124+ in
`sim_review_golden`) are **out of scope for T14**. Only `sim_review`
(the one called by `SimReviewer.review()`) gets the new flag. If
parallel changes to `sim_review_golden` are needed later, that's
T14.5 or follow-up.

### T14.2 — Modify `SimReviewer` class

Same file. Constructor and `review()`:

```python
class SimReviewer:
    def __init__(
        self,
        output_path_per_run: str,
        golden_rtl_path: str | None = None,
        golden_tb_format: bool = False,  # new
    ):
        self.output_path_per_run = output_path_per_run
        self.golden_rtl_path = golden_rtl_path
        self.golden_tb_format = golden_tb_format

    def review(self) -> Tuple[bool, int, str]:
        return sim_review(
            self.output_path_per_run,
            self.golden_rtl_path,
            golden_tb_format=self.golden_tb_format,
        )
```

### T14.3 — Plumb through `TopAgent`

**File:** `src/mage/agent.py`

Add `golden_tb_format: bool = False` attribute and constructor /
setter parameter (mirror the `bypass_tb_gen` pattern from T12). When
constructing `SimReviewer` in `_run()`, pass the flag through:

```python
# In TopAgent.__init__:
self.golden_tb_format: bool = False

# In set_run_config (or wherever bypass_tb_gen was added in T12):
self.golden_tb_format = golden_tb_format

# In _run() where SimReviewer is constructed:
self.sim_reviewer = SimReviewer(
    output_path_per_run=self.output_dir_per_run,
    golden_rtl_path=self.golden_rtl_path,
    golden_tb_format=self.golden_tb_format,
)
```

Find the existing SimReviewer construction site by grepping for
`SimReviewer(`. Add the new kwarg.

### T14.4 — Runner support

**File:** `tests/test_top_agent.py`

Add `--golden-tb-format` argparse flag (mirror `--bypass-tb-gen`):

```python
parser.add_argument(
    "--golden-tb-format",
    action="store_true",
    help="Treat the testbench as a VerilogEval-v2 golden TB; "
         "use mismatch_cnt==0 instead of 'SIMULATION PASSED' literal "
         "for pass detection.",
)
```

In the runner's `args_dict`:
```python
"golden_tb_format": False,
```

Pass to `agent.set_run_config(...)` (or whichever method T12 used).

### T14.5 — Unit tests

Create `tests/test_golden_tb_format.py` with these cases:

1. **`test_golden_tb_format_pass`** — Mock `run_bash_command` to return
   stdout containing `"Mismatches: 0 in 100 samples"` (no
   `"SIMULATION PASSED"`). Call `sim_review(..., golden_tb_format=True)`.
   Expect `is_pass=True, mismatch_cnt=0`.

2. **`test_golden_tb_format_fail_with_mismatches`** — Mock stdout
   `"Mismatches: 5 in 100 samples"`. Call with
   `golden_tb_format=True`. Expect `is_pass=False, mismatch_cnt=5`.

3. **`test_default_format_unchanged_pass`** — Mock stdout containing
   `"SIMULATION PASSED"` (and `"Mismatches: 0..."` for parser).
   Call with `golden_tb_format=False` (default). Expect `is_pass=True,
   mismatch_cnt=0`. This guards backward compatibility.

4. **`test_default_format_unchanged_fail`** — Mock stdout WITHOUT
   `"SIMULATION PASSED"` but mismatch_cnt=0. Call with
   `golden_tb_format=False`. Expect `is_pass=False`. (This is the
   exact pre-T14 behaviour that broke bypass-mode runs — it must
   stay broken in default mode for backward compat.)

5. **`test_stderr_blocks_pass`** — Mock stderr with non-benign
   content, stdout fine. Both flag values should produce
   `is_pass=False`.

6. **`test_simreviewer_passes_flag_through`** — Construct
   `SimReviewer(golden_tb_format=True)`. Mock `sim_review` and verify
   it was called with `golden_tb_format=True`.

Use `unittest.mock.patch` on `run_bash_command` for the IO-bound
parts. Stub `CommandResult.model_validate_json` with a fake CommandResult
or patch the class directly.

### T14.6 — Verification: T13 rerun

After T14.1-T14.5 are committed and tests pass, re-run the same
20 cells from T13 with the new flag enabled. Use the existing T13
trace runners (or a thin variant):

```bash
# Sequential, 32B first then 7B (per PM directive)
python tests/test_t14_32b_verify.py  # bypass_tb_gen=True, golden_tb_format=True
python tests/test_t14_7b_verify.py   # same
```

Create new `run_identifier`s such as `t14_32b_verify` and
`t14_7b_verify` so the artefact directories are distinct from T13.

For each cell, capture the same forensic columns as T13:
- Exit path (A/B/C/D/E/F/G)
- TB-loop iters
- `tb_need_fix` / `rtl_need_fix` / `sim_mismatch_cnt` at exit
- **NEW: `Candidate generation: round` count** (Step 4 reach indicator)
- **NEW: `RTL Editing: round` count** (Step 5 reach indicator)
- `is_pass`, `failure_type`

The T14 report's headline metric: **how many of the 20 cells now
reach Step 4 and Step 5?**

---

## Acceptance criteria

- [ ] `src/mage/sim_reviewer.py` modified only in `sim_review()` and
      `SimReviewer.__init__`/`review()`. The `sim_review_golden`
      function (if present) is NOT modified.
- [ ] `src/mage/agent.py` modified to plumb `golden_tb_format` through
      to `SimReviewer`. No changes to agent control flow logic.
- [ ] `tests/test_top_agent.py` exposes `--golden-tb-format` flag.
- [ ] Default behaviour bit-identical: with both `bypass_tb_gen=False`
      and `golden_tb_format=False`, sample log output on Prob001
      pre-T14 and post-T14 is identical (modulo timestamps).
- [ ] No agent file modified (`tb_generator.py`, `rtl_generator.py`,
      `sim_judge.py`, `rtl_editor.py`).
- [ ] `tests/test_golden_tb_format.py` created with 6 test cases,
      all passing: `pytest tests/test_golden_tb_format.py -v`.
- [ ] Full-suite regression passes:
      `pytest tests/ --ignore=tests/test_single_agent.py`
- [ ] T14 verify rerun completed for both 32B and 7B (20 cells total).
- [ ] T14_DONE report includes side-by-side T13 vs T14 forensic table
      and the headline "Step 4 reach count" / "Step 5 reach count".
- [ ] Commit message: `[T14] Add golden_tb_format flag for VerilogEval pass detection`
- [ ] Report filed: `reports/v2/T14_DONE.md`

---

## Stop conditions

File `reports/v2/T14_BLOCKED.md` if:

- Default-behaviour test (bypass=False, golden_tb_format=False)
  produces different logs than pre-T14 baseline. Indicates the flag
  leaked into the default path.
- T14 verify rerun produces NO Step 4 reach (count remains 0/20).
  This would mean Proposal 2's hypothesis was incomplete — there
  is yet another barrier between L186 and Step 4. Stop, do not
  speculate, write a BLOCKED report with the per-cell exit paths.
- Existing tests regress.
- An unexpected cell reaches Step 5 (Debug Agent) but produces a
  pipeline crash inside `RTLEditor`. This means we've reached new
  territory — file a partial report describing what happened, do
  NOT attempt to fix RTLEditor in T14 (out of scope).

---

## Do NOT

- Modify any agent file (`tb_generator.py`, `rtl_generator.py`,
  `sim_judge.py`, `rtl_editor.py`, `prompts.py`,
  `benchmark_read_helper.py`).
- Modify `sim_review_golden` (a separate function in `sim_reviewer.py`).
  It's used for final golden verification at the end of the run, not
  the per-iteration review. T14 scope is per-iteration only.
- Auto-detect `golden_tb_format` based on `bypass_tb_gen` value. The
  flags are independent. A user might want one without the other in
  the future. Plan v3 §1 "explicit opt-in" principle holds.
- Run more than the 20 verification cells. The T13 problem set is the
  measurement instrument.
- Try to fix Path B (32B Prob128) cells where SimJudge stays stuck on
  `tb_need_fix=True`. T13 explicitly noted this won't be solved by
  Proposal 2; it's a separate concern.
- Touch the Path A cells (initial RTL syntax fail). Out of scope.
- Run 32B and 7B in parallel. Sequential, 32B first.
- Pre-emptively add similar fixes to other modules (e.g., other
  literal-string match sites mentioned in T13's follow-ups). Stay in
  scope.

---

## Report template

```markdown
# Task T14: Golden-TB Format Flag for SimReviewer

**Status:** DONE
**Branch:** feat/mage-open-v2
**Commits:** <hash>

## Changes
- src/mage/sim_reviewer.py: added golden_tb_format kwarg to
  sim_review() and SimReviewer; mismatch_cnt-based pass branch
- src/mage/agent.py: plumbed golden_tb_format through TopAgent
- tests/test_top_agent.py: added --golden-tb-format flag
- tests/test_golden_tb_format.py: 6 unit tests, all passing

## Verification
- pytest tests/test_golden_tb_format.py -v: 6 passed
- pytest tests/ --ignore=tests/test_single_agent.py: <N> passed
- Default-behaviour sanity check on Prob001: pre-T14 logs match post-T14

## T14 verify rerun summary
- 32B run wall time: <time>
- 7B run wall time: <time>
- Total cells: 20

## Side-by-side T13 vs T14 forensic table

| Problem | Model | T13 exit | T14 exit | Step 4 reach? | Step 5 reach? | T14 is_pass |
|---|---|---|---|---|---|---|
| ... 20 rows ... |

## Headline metrics

- **Cells reaching Step 4 (candidate generation)**: <count>/20
  (T13 baseline: 0/20)
- **Cells reaching Step 5 (RTLEditor)**: <count>/20
  (T13 baseline: 0/20)
- **Cells with first-ever functional improvement via candidate gen**:
  <count> (problems where initial RTL failed but a candidate passed)

## Evidence excerpt (≥2 cells reaching Step 4)

Quote 30-50 lines of log per cell showing:
- TB loop exit
- "Candidate generation: round 1 / N"
- Per-candidate sim review outcomes
- (If reached) "RTL Editing: round 1 / N" and editor input/output

## Notes
<Anything PM should know. Especially:
- If Step 5 was reached for the first time in this project, quote the
  full RTLEditor invocation log.
- If candidate generation reached but no candidate ever passes,
  describe the failure pattern.
- T13's Path B cell (32B Prob128) is expected to still fail; confirm
  it failed at the same site or a different one.>

## Follow-ups spotted
<Out-of-scope observations.>
```

---

## After T14

**Faz 0 closes here, properly.** PM reviews and decides:

- If T14 verify rerun shows ≥1 cell reaching Step 4 and Step 5: Faz 0
  successful, transition to Faz 1 (Abstraction Layer) with the
  pipeline now genuinely operational on open models for the first
  time in project history.
- If T14 reaches Step 4 but Step 5 stays at 0: candidate generation
  is unblocked, but RTLEditor still has its own barrier. Document and
  accept; transition to Faz 1.
- If T14 still doesn't reach Step 4: there's another barrier we
  haven't located. PM decides between additional forensic work
  (T15) or accepting the limitation and moving to Faz 1 with an
  asterisk.

This is the last Faz 0 task. The full Plan v3 then continues to Faz 1
regardless of T14 outcome — we don't want to spend more than the
Faz 0 budget on barrier-hunting.
