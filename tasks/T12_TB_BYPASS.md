# Task T12: Golden TB True Bypass Mode

**Status:** PENDING
**Priority:** HIGH — third Faz 0 task, sets up T13 baseline
**Depends on:** T11 merged to `feat/mage-open-v2`
**Reference:** Plan v3 §3 T12, T11_DONE.md follow-ups, T9_BLOCKED.md

---

## Context

T11 (per-agent temperature override for SimJudge) was implemented and
verified, but its core hypothesis — that `temperature=0` would
eliminate `tb_needs_fix` oscillation and unblock the Debug Agent
branch — was **not confirmed by evidence**:

- Under `qwen2.5-coder:32b`: SimJudge was already true-locked at
  baseline; T11 had null behavioral effect.
- Under `qwen2.5-coder:7b`: T11 enabled pipeline progression
  (4 iterations vs. 1-then-crash), but SimJudge still oscillated
  (3 true / 1 false) — verdicts vary because **prompt context
  changes between iterations**, not because of sampling temperature.

The corollary: pipeline still doesn't reach `RTLEditor`. Across 20
problem-runs over the project's history (T5 5 + T7 4 + T8 5 + T9 4 +
T11 2), Debug Agent has triggered **zero times**. The pipeline keeps
getting stuck in the TB-revision loop.

T12 attacks this from a different angle: provide an **opt-in escape
hatch** that bypasses the LLM-based TB Generator entirely when a
golden testbench is available. With TB Gen out of the picture, the
pipeline progresses directly to RTL Generator and (on functional
mismatch) to candidate generation and RTLEditor.

---

## Architectural starting point — read carefully

The `use_golden_tb_in_mage` flag already exists, but its current
semantics are NOT what one might expect:

**Current behavior (`use_golden_tb_in_mage=True`):**
- `TBGenerator` still calls the LLM (one round per iteration).
- The golden TB is loaded and inserted into the prompt as a
  *reference* (`GOLDEN_TB_PROMPT` in `prompts.py`). The LLM then
  generates its own "optimized" testbench using the golden as a guide.
- The TB-revision loop runs as normal: SimJudge can ask for revisions,
  TB Generator regenerates, etc.
- **The LLM is not bypassed; it is given a hint.**

**Current behavior (`use_golden_tb_in_mage=False`):**
- `TBGenerator` calls the LLM with `NON_GOLDEN_TB_PROMPT` and
  `TB_4_SHOT_EXAMPLES`. No golden TB is referenced.

T12 introduces a third semantic: **true bypass**.

### T12's new semantic

A **new flag**, kept separate from `use_golden_tb_in_mage`, controls
the bypass:

```python
# In agent.py constructor / config
self.bypass_tb_gen: bool = False   # default: faithful MAGE methodology
```

When `bypass_tb_gen=True`:
- `TBGenerator.chat()` is **not called**.
- The golden TB file is read directly into `testbench`.
- `interface` is extracted from the golden TB (or from the spec — see
  T12.2 design choice below).
- The pipeline proceeds as if TB generation already produced a perfect
  result on the first try.
- SimJudge may still flag the TB as needing fixes; in that case the TB
  loop iterates but **the testbench is never modified** (it's golden).
  This is the desired behavior because the goal is to force the
  pipeline to give up on TB revisions and progress to RTL fixes.

When `bypass_tb_gen=False` (default):
- Existing behavior preserved bit-for-bit. `use_golden_tb_in_mage`
  retains its current meaning. **No change to default pipeline.**

### Why the new flag is separate from `use_golden_tb_in_mage`

Three reasons:

1. **Backward compatibility.** Every existing runner script
   (`test_top_agent_ollama.py`, `test_top_agent_ollama_32b.py`, etc.)
   sets `use_golden_tb_in_mage=True`. Repurposing this flag would
   silently change the behavior of all 5 existing runners. That is
   not faithful reproduction; that is breaking the experimental
   record.

2. **Faithful reproduction principle (Plan v3 §1).** The default
   pipeline must remain bit-identical to upstream MAGE. New behavior
   is only available via an explicitly opt-in flag.

3. **Combinability.** A user might want
   `bypass_tb_gen=True` AND `use_golden_tb_in_mage=True` (the latter
   is irrelevant when bypassed but should not error). Or they might
   want `bypass_tb_gen=True` with no golden TB available (this should
   fail loudly with a clear message — see T12.2).

---

## Scope

### T12.1 — Add `bypass_tb_gen` flag

**File:** `src/mage/agent.py`

Add a new instance attribute and constructor parameter:

```python
class TopAgent:
    def __init__(self, ...):
        # existing fields...
        self.bypass_tb_gen: bool = False  # new

    def set_run_config(self, ..., bypass_tb_gen: bool = False, ...):
        # extend existing setter to accept and store bypass_tb_gen
        self.bypass_tb_gen = bypass_tb_gen
```

If the existing constructor signature is large and changing it is
invasive, prefer adding a setter method or extending an existing
config dict. Do not introduce a new singleton or config class.

### T12.2 — Wire the bypass into `_run`

In the `_run()` method (currently around line 78-90 of `agent.py`),
the TB generation step is:

```python
self.tb_gen.reset()
self.tb_gen.set_golden_tb_path(self.golden_tb_path)
if not self.golden_tb_path:
    logger.info("No golden testbench provided")
testbench, interface = self.tb_gen.chat(spec)
```

Replace with:

```python
self.tb_gen.reset()
self.tb_gen.set_golden_tb_path(self.golden_tb_path)

if self.bypass_tb_gen:
    if not self.golden_tb_path:
        raise ValueError(
            "bypass_tb_gen=True requires a golden_tb_path; received None. "
            "Either provide a golden testbench or set bypass_tb_gen=False."
        )
    testbench, interface = self._load_golden_tb_directly()
    logger.info(
        "TB Gen BYPASSED — loaded golden testbench from %s",
        self.golden_tb_path,
    )
else:
    if not self.golden_tb_path:
        logger.info("No golden testbench provided")
    testbench, interface = self.tb_gen.chat(spec)
```

### T12.3 — Implement `_load_golden_tb_directly`

Add a new private method on `TopAgent`:

```python
def _load_golden_tb_directly(self) -> Tuple[str, str]:
    """Load golden testbench and synthesize an interface block.

    Returns (testbench_text, interface_text).

    The interface is extracted from the spec or testbench. For T12 we
    use the simplest workable approach: read the golden TB, then
    re-use the existing prompt-extraction helper from TBGenerator if
    available, OR fall back to an empty interface stub if extraction
    is non-trivial (the downstream pipeline tolerates a None or empty
    interface — verify before assuming).
    """
    assert self.golden_tb_path is not None
    with open(self.golden_tb_path, "r") as f:
        testbench = f.read()

    # For interface: T12 minimal scope — empty string fallback is OK.
    # If TBGenerator has a static interface-extraction helper, use it.
    # Otherwise return "" and let downstream agents deal.
    interface = ""

    return testbench, interface
```

**Investigation step before implementing:** grep `interface` usage
across `rtl_generator.py` and `agent.py`. If the interface is required
to be non-empty (e.g., used in the RTL Generator's prompt), then
T12.3 must extract it. If the empty fallback works, keep it minimal.
Document the finding in the report.

### T12.4 — Runner support

**File:** `tests/test_top_agent.py`

Add an argparse flag and pass it through to `TopAgent.set_run_config`:

```python
parser.add_argument(
    "--bypass-tb-gen",
    action="store_true",
    help="Skip TB Generator entirely, load golden testbench directly. "
         "Requires --use-golden-tb-in-mage to also be set.",
)
```

In `args_dict` setup (around line 39):
```python
"bypass_tb_gen": False,  # default off
```

Pass it through to `agent.set_run_config(...)` at the call site.

### T12.5 — Smoke runs (sequential, 32B then 7B)

Both runs use the same problem set: T5's 5 easy + T9's 5 hard
(10 total). Use `n=1`. Per the user's PM directive on Faz 0
testing methodology, **run 32B first, then 7B**, in sequence —
not in parallel.

#### T12.5a — 32B smoke

```bash
# Create a runner variant or use args:
python tests/test_top_agent_ollama_32b.py \
    --bypass-tb-gen \
    --filter-instance '^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|Prob005_notgate|Prob119_fsm3|Prob121_2014_q3bfsm|Prob124_rule110|Prob127_lemmings1|Prob128_fsm_ps2)$' \
    --run-identifier t12_32b_bypass
```

Forensic data to collect for each problem:
- `is_pass`, `failure_type` (from T10's structured logging)
- TB Gen LLM call count: `grep -c '\[agent=TBGenerator\]' mage.token_counter.log`
  (should be **0** under bypass)
- SimJudge LLM call count
- RTLGenerator LLM call count
- **Candidate generation rounds**: `grep -c 'Candidate generation: round'`
- **RTLEditor rounds**: `grep -c 'RTL Editing: round'`
- Wall time

#### T12.5b — 7B smoke

Same 10 problems, identical flag, with `qwen2.5-coder:7b`. Use a
distinct `run_identifier` such as `t12_7b_bypass` so artifacts don't
overwrite.

```bash
python tests/test_top_agent_ollama.py \
    --bypass-tb-gen \
    --filter-instance '^(...same 10 problems...)$' \
    --run-identifier t12_7b_bypass
```

Collect the same forensic data.

### T12.6 — Side-by-side comparison

Compose a single table per problem:

| Problem | 32B baseline (T9/T8) | 32B + T12 bypass | 7B baseline (T9/T5) | 7B + T12 bypass |
|---|---|---|---|---|
| Prob001 | pass=true, ed=0 | ? | pass=?, ed=? | ? |
| ... | | | | |

`ed` = RTLEditor rounds. Whatever baseline data is missing (because
some problems were never run on a given model) is left as "—".

The headline metric for T12 is:
- **How many problem×model cells produce ed≥1?** This is the first
  empirical measurement of Debug Agent activation in the project.
- **How many produce candidate generation rounds≥1?** Even more basic
  pipeline progression metric.

---

## Acceptance criteria

- [ ] `src/mage/agent.py` modified only in `_run` (TB step) and
      `__init__`/setter (new flag); no other methods touched.
- [ ] `_load_golden_tb_directly` added as private method.
- [ ] `tests/test_top_agent.py` exposes `--bypass-tb-gen` flag.
- [ ] Default behavior unchanged: with `bypass_tb_gen=False` (default),
      a smoke run produces logs identical to pre-T12 behavior on at
      least one problem (Prob001 is the simplest sanity check).
- [ ] No agent file modified (`tb_generator.py`, `rtl_generator.py`,
      `sim_judge.py`, `rtl_editor.py`, `prompts.py`,
      `benchmark_read_helper.py`).
- [ ] Unit test in new file `tests/test_bypass_tb_gen.py`:
  1. With `bypass_tb_gen=True` and a valid `golden_tb_path`,
     `_load_golden_tb_directly` returns the file contents.
  2. With `bypass_tb_gen=True` and `golden_tb_path=None`, `_run`
     raises `ValueError` with the expected message.
  3. With `bypass_tb_gen=False`, behavior is unchanged (verify
     `tb_gen.chat` is called).
- [ ] Full-suite regression passes (excluding pre-existing
      `test_single_agent.py` import failure):
      `pytest tests/ --ignore=tests/test_single_agent.py`
- [ ] Both 32B and 7B smoke runs completed with `--bypass-tb-gen`.
      Each produces a `record.json` for all 10 problems.
- [ ] Side-by-side table assembled in the report.
- [ ] Commit message: `[T12] Add bypass_tb_gen flag for direct golden testbench injection`
- [ ] Report filed: `reports/v2/T12_DONE.md`

---

## Stop conditions

File `reports/v2/T12_BLOCKED.md` if:

- Empty `interface` string causes `RTLGenerator` to fail (i.e., the
  fallback in T12.3 doesn't work). In that case, document what
  `RTLGenerator` requires from the interface and propose the smallest
  viable extraction strategy as a follow-up — do NOT solve it in T12.
- A 32B problem run takes >25 minutes (Ollama hang or unusual
  pipeline behavior).
- The default-behavior sanity check (T12 acceptance #4) fails — i.e.,
  setting `bypass_tb_gen=False` produces different logs than pre-T12.
  This means the patch leaked into the default path.
- Existing unit tests regress.

---

## Do NOT

- Modify any of: `tb_generator.py`, `rtl_generator.py`,
  `sim_judge.py`, `rtl_editor.py`, `prompts.py`,
  `benchmark_read_helper.py`.
- Repurpose `use_golden_tb_in_mage`. Add a new flag.
- Add a third bypass mode (e.g., `bypass_judge`, `bypass_rtl_gen`).
  T12 scope is testbench-only. Plan v3 §3 T12 explicitly says minimal.
- Auto-detect bypass conditions (e.g., "if golden_tb available, just
  bypass"). The flag must be explicit.
- Run more than 10 problems. The 5 easy + 5 hard set is the
  measurement instrument; don't change it for T12.
- Run 32B and 7B in parallel. Sequential, 32B first, then 7B.
- Try to extract the interface from the golden TB via regex parsing
  if the empty-string fallback works. Save invasive parsing for a
  follow-up if needed.

---

## Report template

```markdown
# Task T12: Golden TB True Bypass Mode

**Status:** DONE
**Branch:** feat/mage-open-v2
**Commits:** <hash>

## Changes
- src/mage/agent.py: added `bypass_tb_gen` flag + `_load_golden_tb_directly`
- tests/test_top_agent.py: added `--bypass-tb-gen` argparse flag
- tests/test_bypass_tb_gen.py: 3 unit tests, all passing

## Investigation finding
<Did the empty interface fallback work? If not, what was the minimum
fix? Document here for the PM.>

## Verification
- pytest tests/test_bypass_tb_gen.py -v: 3 passed
- pytest tests/ --ignore=tests/test_single_agent.py: <N> passed
- Default behavior sanity check on Prob001: pre-T12 logs match post-T12
  logs (with bypass_tb_gen=False).

## 32B smoke run
- 10 problems, run_identifier=t12_32b_bypass, wall time: <total>
- record.json: <pass/fail summary>
- Forensic table: <below>

## 7B smoke run
- 10 problems, run_identifier=t12_7b_bypass, wall time: <total>
- record.json: <pass/fail summary>
- Forensic table: <below>

## Side-by-side mechanism table

| Problem | 32B baseline | 32B+T12 | 7B baseline | 7B+T12 |
|---|---|---|---|---|
| Prob001_zero | ... | ... | ... | ... |
| ... |
| Prob128_fsm_ps2 | ... | ... | ... | ... |

## Headline metrics
- Cells with RTLEditor rounds ≥ 1: <count> / <total cells>
- Cells with candidate generation ≥ 1: <count> / <total cells>
- TB Gen LLM call count under bypass: <should be 0 across all 20 runs>

## Notes
<Anything PM should know. E.g.:
- "Debug Agent triggered for the first time on Prob004_vector2 under 7B+T12,
   2 rounds, score went from 0.45 to 0.78."
- OR "Debug Agent still 0 across all 20 cells; pipeline now stops at
   RTL Gen syntax check rather than TB loop."
>

## Follow-ups spotted
<Out-of-scope observations.>
```

---

## After T12

**Do not start T13.** File the report and wait. T13 is the Faz 0
baseline re-run that consolidates T10+T11+T12 effects across the
full 10-problem set. The PM will compose T13 spec based on what T12
revealed.

If T12's smoke runs already cover the full 10-problem set adequately
(which they should), T13 may end up being a thinner integration task
or a metrics-aggregation task rather than another full smoke run.
PM decision based on T12 report.
