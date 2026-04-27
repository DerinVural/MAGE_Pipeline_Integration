# Task T13: Forensic Localization of Pre-Step-4 Barriers

**Status:** DONE
**Branch:** `feat/mage-open-v2`
**Commits:** `27933e8` `[T13-trace]` (revertible debug logging) + final report commit
**Date:** 2026-04-27

## Summary

Hypothesis **REFUTED**. The dominant pre-Step-4 barrier is **not** the
`assert not tb_need_fix` on line 179 (only 1/20 cells); it is the
`assert sim_mismatch_cnt > 0` on **line 186** (17/20 cells). The root
cause is one level deeper: `sim_reviewer.review()` returns
`is_sim_pass=False, sim_mismatch_cnt=0` for the golden-loaded
testbench because `sim_reviewer.py:69` requires the literal string
`"SIMULATION PASSED"` in stdout, which **VerilogEval-v2 testbenches
do not emit**. They emit `"Mismatches: 0 in N samples"` instead.
Verdict: **III** (hypothesis refuted; the dominant barrier is
elsewhere — at the reviewer's pass-check string).

Step 4 (candidate gen) and Step 5 (RTLEditor) are reached by
**0/20 cells**.

## Methodology

- **Logging mechanism:** added 7 `logger.info("[T13-trace] ...")` lines
  to `agent.run_instance()` (commit `27933e8`). These capture
  per-iteration `tb_need_fix / rtl_need_fix / sim_mismatch_cnt /
  is_sim_pass`, plus markers at the entry to Step 4 and Step 5 and at
  normal exit. Two single-value initializations were also added
  (`sim_mismatch_cnt = 0`, `is_sim_pass = False`) so the post-loop
  trace can read them safely if `sim_max_retry == 0`. Behaviour
  unchanged for the runs studied (`sim_max_retry == 4`). Commit is
  revertible.
- **No other source files modified.**
- **Smoke runs:** `tests/test_t13_32b_trace.py` and
  `tests/test_t13_7b_trace.py` — same 10-problem set as T12, same
  configs (`bypass_tb_gen=True`, `temperature=0.85`, `top_p=0.95`).
- **Wall time:** 32B run 13:50; 7B run 4:20. Total ~18 min.
- **Artefacts:** `output_t13_32b_trace_0/`, `log_t13_32b_trace_0/`
  and 7B counterparts.

## Per-cell classification (20 rows)

| Problem | Model | Pass | Exit path | Assert line | tb_need_fix at exit | rtl_need_fix at exit | sim_mismatch_cnt at exit | TB-loop iters | Pre-Step-4 barrier? | Run time |
|---|---|---|---|---|---|---|---|---|---|---|
| Prob001_zero | 32B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:30 |
| Prob002_m2014_q4i | 32B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:28 |
| Prob003_step_one | 32B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:44 |
| Prob004_vector2 | 32B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:48 |
| Prob005_notgate | 32B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:36 |
| Prob119_fsm3 | 32B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 2:29 |
| Prob121_2014_q3bfsm | 32B | ✗ | C | 186 | False | True | 0 | 2 | yes — L186 | 1:52 |
| Prob124_rule110 | 32B | ✗ | C | 186 | False | True | 0 | 1 | yes — L186 | 1:58 |
| Prob127_lemmings1 | 32B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 1:20 |
| Prob128_fsm_ps2 | 32B | ✗ | **B** | **179** | **True** | True | 0 | 4 | yes — L179 | 3:02 |
| Prob001_zero | 7B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:08 |
| Prob002_m2014_q4i | 7B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:08 |
| Prob003_step_one | 7B | ✗ | C | 186 | False | True | 0 | 4 | yes — L186 | 0:24 |
| Prob004_vector2 | 7B | ✗ | **A** | (return) | – | – | – | 0 | yes — L122 | 0:59 |
| Prob005_notgate | 7B | ✓ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:07 |
| Prob119_fsm3 | 7B | ✗ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:19 |
| Prob121_2014_q3bfsm | 7B | ✗ | C | 186 | False | True | 0 | 2 | yes — L186 | 0:24 |
| Prob124_rule110 | 7B | ✗ | C | 186 | False | True | 0 | 1 | yes — L186 | 0:22 |
| Prob127_lemmings1 | 7B | ✗ | C | 186 | False | True | 0 | 2 | yes — L186 | 0:20 |
| Prob128_fsm_ps2 | 7B | ✗ | **A** | (return) | – | – | – | 0 | yes — L122 | 1:13 |

`is_pass=True` cells under `pipeline_assert` are T10's known
sidecar false-negative: the assert fired at L186, but the final RTL
written to `rtl.sv` did pass the golden TB on the *previous*
iteration's review. T10 logs the failure-type even when `is_pass=True`.

Line numbers refer to `src/mage/agent.py` **after** the `[T13-trace]`
commit (insertion shifted everything down). Pre-trace mapping:
L179 → original L160; L186 → original L165–167.

## Exit-path frequency

| Path | Description | 32B | 7B | Total |
|---|---|---|---|---|
| A | initial RTL syntax fail (L122 `return False, rtl_code`) | 0 | 2 | 2 |
| B | L179 `assert not tb_need_fix` (TB-loop exhausted with judge stuck on `tb_need_fix=True`) | 1 | 0 | 1 |
| C | **L186 `assert sim_mismatch_cnt > 0`** (TB-loop exited cleanly but `is_sim_pass=False` and `sim_mismatch_cnt=0`) | 9 | 8 | **17** |
| D | reached candidate gen (Step 4) | 0 | 0 | **0** |
| E | reached RTLEditor (Step 5) | 0 | 0 | **0** |
| F | normal completion (return at L240+) | 0 | 0 | 0 |
| G | other | 0 | 0 | 0 |

## Verdict

**Verdict III — Hypothesis refuted.** Spec working hypothesis was
that L160 (`assert not tb_need_fix`) is the dominant pre-Step-4
barrier. Empirically it fires in 1/20 cells (32B Prob128). The
dominant barrier is **L186** (`assert sim_mismatch_cnt > 0`) at
17/20 cells. Path A (initial RTL syntax failure) accounts for the
remaining 2/20.

The deeper finding: in all 17 Path-C cells, `tb_loop` completed
cleanly with `tb_need_fix=False` (judge accepts the golden TB) but
**`is_sim_pass=False sim_mismatch_cnt=0`** at the same time.
That state is logically reachable only if the simulation reviewer
disagrees with itself — counts zero mismatches but reports the run
as a failure.

## Evidence excerpts

### Path C (dominant) — 32B Prob001_zero

`log_t13_32b_trace_0/VERILOG_EVAL_V2_Prob001_zero/mage.agent.log`:

```
[T13-trace] tb_loop iter=0 entry: tb_need_fix=True rtl_need_fix=True
[T13-trace] tb_loop iter=0 after review: is_sim_pass=False sim_mismatch_cnt=0
[T13-trace] tb_loop iter=0 after judge: tb_need_fix=False
[T13-trace] tb_loop exit: tb_need_fix=False rtl_need_fix=True is_sim_pass=False sim_mismatch_cnt=0
[T13-trace] entering candidate gen (Step 4)
```

Then `agent.py:186` raises:
```
AssertionError: rtl_need_fix should be True only when sim_mismatch_cnt > 0.
sim_log: { "stdout": "...Mismatches: 0 out of 20 samples..." }
```

`sim_reviewer.log` for the same cell:
```
Simulation is_pass: False, mismatch_cnt: 0
output: { "stdout": "...Hint: Output 'zero' has no mismatches.
Hint: Total mismatched samples is 0 out of 20 samples
Mismatches: 0 in 20 samples" }
```

Reviewer counted the mismatch as zero correctly, but flagged the run
as `is_pass=False`. The cause is at `sim_reviewer.py:67-74`:

```python
is_pass = (
    is_pass
    and "SIMULATION PASSED" in sim_output_obj.stdout
    and (sim_output_obj.stderr == "" or stderr_all_lines_benign(sim_output_obj.stderr))
)
```

The literal `"SIMULATION PASSED"` is **never present** in
VerilogEval-v2 golden testbench output — those TBs print
`"Mismatches: N in M samples"`. Under `bypass_tb_gen=True` we load
that golden TB verbatim (no LLM-rewriting), so the keyword is
permanently absent.

### Path B (rare) — 32B Prob128_fsm_ps2

```
[T13-trace] tb_loop iter=0 entry: tb_need_fix=True rtl_need_fix=True
[T13-trace] tb_loop iter=0 after review: is_sim_pass=False sim_mismatch_cnt=0
[T13-trace] tb_loop iter=0 after judge: tb_need_fix=True
[T13-trace] tb_loop iter=1 entry: tb_need_fix=True rtl_need_fix=True
[T13-trace] tb_loop iter=1 after review: is_sim_pass=False sim_mismatch_cnt=0
[T13-trace] tb_loop iter=1 after judge: tb_need_fix=True
... (4 iters, all tb_need_fix=True)
[T13-trace] tb_loop exit: tb_need_fix=True rtl_need_fix=True is_sim_pass=False sim_mismatch_cnt=0
```

`agent.py:179` raises (`assert not tb_need_fix`). The bypass loop's
`continue` honours `tb_need_fix=True` from the judge but never
modifies the golden TB; loop runs `sim_max_retry=4` times and exits
with `tb_need_fix=True` still set, tripping L179. Sim reviewer is
again returning `is_sim_pass=False sim_mismatch_cnt=0` — same root
cause; just here SimJudge keeps voting "fix the TB" because the RTL
has a real elaboration error (`port 'in' is not a port of
top_module1`).

### Path A — 7B Prob128_fsm_ps2

No `T13-trace` entries; `failure_info.trace` is empty. The pipeline
returned at L122 (`if not is_syntax_pass: return False, rtl_code`)
during the *initial* `rtl_gen.chat()` call (before the TB-loop is
ever entered). Stored RTL in `failure_info.error_msg` is
syntactically broken SystemVerilog.

## Fix proposals (for T14 PM scoping — no implementation here)

### Proposal 1: Replace the literal pass-string at `sim_reviewer.py:69`

- **Description:** Change the `is_pass` calculation in
  `sim_reviewer.py:67-74` to either (a) accept multiple pass-strings
  (`"SIMULATION PASSED"` OR `"Mismatches: 0 "`) or (b) base the
  decision purely on the parsed `mismatch_cnt` (already computed at
  L75). Option (b) is simpler and TB-format-independent. This is the
  smallest possible patch that unblocks Path C.
- **Invasiveness:** ~3-5 lines, 1 file (`sim_reviewer.py`).
- **Faithful-reproduction:** Partial. Upstream MAGE was tuned for its
  own TBGenerator output, which presumably does emit
  `"SIMULATION PASSED"`. Loosening the pass-string changes how
  *any* TB is judged — including LLM-generated ones in non-bypass
  runs. May increase false-positives if `mismatch_cnt` parsing fails
  on a malformed TB output.
- **Expected effect:** All 17 Path-C cells should reach Step 4
  immediately. Step 5 (RTLEditor) reachability will then depend on
  candidate-generation outcomes, which T13 has not measured.

### Proposal 2: Add a `golden_tb_format` flag and route reviewer logic

- **Description:** Introduce a runner-level flag indicating that the
  testbench is a VerilogEval-v2 golden TB. When set, `sim_reviewer`
  uses `mismatch_cnt == 0` as the pass criterion; when unset, retains
  the original `"SIMULATION PASSED"` check. Plumb the flag from
  `test_top_agent.py` through `TopAgent` to `SimReviewer`.
- **Invasiveness:** ~15-25 lines across 3 files (`agent.py`,
  `sim_reviewer.py`, `test_top_agent.py`). Mirrors the `bypass_tb_gen`
  setter pattern.
- **Faithful-reproduction:** Yes. Default behaviour is byte-identical
  to upstream MAGE. Only opt-in cells under the new flag take the
  alternative path.
- **Expected effect:** Same Step 4/5 reachability win as Proposal 1
  for golden-TB cells, with no risk to LLM-generated TB cells.

### Proposal 3: Wrap golden TB to emit `"SIMULATION PASSED"` at run-time

- **Description:** When `bypass_tb_gen=True`, post-process the loaded
  golden TB to inject a final `if (mismatches == 0) $display("SIMULATION PASSED");`
  line, or wrap the TB in a synthetic Verilog harness that prints the
  expected keyword based on the golden TB's exit code. Keeps
  `sim_reviewer.py` untouched.
- **Invasiveness:** ~10-30 lines in `agent.py` (or a helper file).
  Risky: requires mechanical Verilog rewriting; failure modes
  include malformed inserts, parse errors, or missing the right
  point of insertion in `endmodule`-terminated files.
- **Faithful-reproduction:** Yes for the upstream paths. But adds a
  new failure surface specific to bypass mode.
- **Expected effect:** Same Step 4/5 reachability as 1 and 2 for the
  cells where injection succeeds; some cells may regress to a new
  parse-error class.

## Notes

- **Path A (initial RTL syntax fail)** is **not** a barrier between
  Step 3 and Step 4 in the spec's strict sense — it returns earlier,
  at L122. Whether to treat it as a barrier is a definitional choice.
  Listed in the table as "yes — L122" for completeness; T14 may scope
  it as a separate sub-task ("improve initial RTLGen syntax check").
- The 32B Prob128 Path-B cell is interesting: SimJudge votes
  `tb_need_fix=True` four times in a row. With bypass enabled the loop
  cannot satisfy the judge (golden TB is read-only), so the assert is
  the inevitable terminus. After Proposal 1 or 2 lands, this cell
  would still fail (just at a different site) unless SimJudge's logic
  is also revisited under bypass.
- Reviewer behaviour is **deterministic** within a cell; back-to-back
  T13 runs reproduced identical exit paths and identical assert lines.
  No stochasticity-related blockers were observed.

## Follow-ups spotted

- T10 sidecar's `failure_type=pipeline_assert when is_pass=True`
  classifier is misleading. The cell *did* pass the golden TB —
  it just hit the assert before normal exit. Worth a 5-line tweak
  in T10.
- `sim_reviewer.py:69` pattern check isn't the only fragile string
  match in the repo; a quick grep suggests other modules also key on
  literal stdout substrings. Audit candidate for a follow-up T-task.
- The 7B's two functional_mismatch cells (Prob004, Prob128) bypassed
  the TB-loop entirely via Path A. After Proposal 1/2 lands, the rest
  of the 7B cells would join them in reaching Step 4, opening the
  door to first-time RTLEditor data.

## After T13

Per spec: **T13 closes Faz 0.** Do not start T14 or Faz 1. Awaiting
PM decision: (a) open T14 with one of Proposals 1/2/3 + verify by
re-running T13's classification, or (b) accept these as documented
limitations and proceed to Faz 1 with Step 4/5 reachability still at
0/20.
