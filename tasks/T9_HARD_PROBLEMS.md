# Task T9: Hard-Problem Test for Debug Agent & Candidate Generation

**Status:** PENDING
**Priority:** MEDIUM — final mechanism-validation test before project close
**Depends on:** T8 merged
**Objective:** Select 5 functionally complex problems and run
`qwen2.5-coder:32b` on them, observing whether MAGE's candidate
generation and Debug Agent branches activate *naturally* (no pipeline
modifications, no synthetic triggers).

---

## Context

Across 9 problem-runs so far (T5 x5, T7 x4, T8 x5 with overlap):
- Debug Agent (`RTLEditor`) rounds: **always 0**
- Candidate generation rounds: **always 0**

Two explanations so far:
- T7 (7B): model fails at TB Generator, pipeline asserts before
  candidate loop is reached
- T8 (32B): model succeeds so thoroughly on initial RTL that no
  candidate loop is needed (4/5 cases); one case (Prob003) still
  asserted at TB retry exhaustion

Neither path exercised the debug machinery that is the paper's
headline contribution. T9 tests the **natural hypothesis**: give the
model problems that are complex enough to produce syntactically valid
but functionally subtle RTL, forcing the pipeline into the candidate
loop and (ideally) onward to Debug Agent.

No code changes. No synthetic triggers. No TB bypass. Just 5
deliberately chosen problems.

---

## Problem selection rationale

Five problems picked from VerilogEval-v2 based on:
1. FSM or stateful logic (subtle transition errors are classic)
2. Concise specification (TB Gen less likely to hallucinate)
3. Multiple outputs (increases mismatch surface area)
4. Not already tested in T5/T7/T8

Selected:

| Problem | Type | Why it's a good Debug Agent probe |
|---|---|---|
| `Prob121_2014_q3bfsm` | FSM, counter-based | State encoding + output gating — easy to get wrong edge cases |
| `Prob124_rule110` | Cellular automaton | 8-case truth table; one wrong row → ~12% mismatch |
| `Prob127_lemmings1` | 2-state Moore FSM | Transition logic with 2 inputs; async reset subtlety |
| `Prob128_fsm_ps2` | PS/2 protocol FSM | Multi-state, serial bit counting |
| `Prob119_fsm3` | 4-state FSM | Reset + transition table |

If any of these has already been run in T5/T7/T8, swap with another
fsm-family problem. None should overlap per current logs.

## Scope

### T9.1 — Create the hard-problem runner

**File:** `tests/test_top_agent_ollama_hard.py` (new)

Clone `tests/test_top_agent_ollama_32b.py` (the T8 runner) and change
only these two fields:

```python
"filter_instance": "^(Prob121_2014_q3bfsm|Prob124_rule110|Prob127_lemmings1|Prob128_fsm_ps2|Prob119_fsm3)$",
"run_identifier": "ollama_32b_hard",
```

Keep every other field identical to T8 (model=qwen2.5-coder:32b,
provider=ollama, n=1, temperature=0.85, top_p=0.95, max_token=4096,
use_golden_tb_in_mage=True, type_benchmark=verilog_eval_v2).

### T9.2 — Verify problems exist

Before the run:

```bash
for p in Prob121_2014_q3bfsm Prob124_rule110 Prob127_lemmings1 Prob128_fsm_ps2 Prob119_fsm3; do
    ls verilog-eval/dataset_spec-to-rtl/${p}_prompt.txt || echo "MISSING: $p"
done
```

If any is missing, file BLOCKED with details.

### T9.3 — Run

```bash
python tests/test_top_agent_ollama_hard.py
```

Expected wall time: 30–90 minutes. 32B is slow; FSM problems with
sampling iteration may add up. Monitor:
- First 5 minutes: at least Prob121 should start generating output
- Per-problem max: 25 minutes (kill and file BLOCKED if exceeded)

### T9.4 — Mechanism-focused forensic analysis

Standard pass/fail is secondary here. The report must answer:

For each of the 5 problems:

| Evidence | How to get it |
|---|---|
| `is_pass` | `record.json` |
| `properly_finished.tag` present | file existence |
| TB Gen retries | `grep -c "Revised tb:"` |
| **Candidate generation rounds** | `grep -c "Candidate generation: round"` |
| **Debug Agent (RTLEditor) rounds** | `grep -c "RTL Editing: round"` |
| `mage.rtl_editor.log` size in bytes | `wc -c` |
| Initial RTL syntax-valid? | First `Syntax check is_pass` in log |
| Initial simulation mismatch count | First `mismatch` number from log |

**The headline metric is "candidate rounds" and "Debug Agent rounds".**
If any problem produces nonzero on either, quote 30–60 lines of raw
log showing that activity.

### T9.5 — Report

Write `reports/T9_DONE.md` with:

**1. Runner diff** — changes vs. T8 runner.

**2. Problem existence check** — paste the `ls` output from T9.2.

**3. Mechanism activation table** — the 8-column forensic table from T9.4.

**4. Quoted evidence** — if candidate or Debug Agent rounds fired in
any problem, quote raw log. If they didn't fire anywhere, quote the
RTL Generator's initial output for one problem that passed and one
that failed, showing what the model produced in single-shot.

**5. Verdict** — choose exactly one:

- **(ε) Debug Agent triggered** at least once, ≥1 round completed.
  Quote the state-checkpoint comparison if visible. First real
  observation of the mechanism in action.
- **(ζ) Candidate generation triggered but Debug Agent didn't.**
  Candidate loop saw mismatches but at least one candidate passed
  before the loop fell through to Editor. Partial mechanism
  observation.
- **(η) Neither triggered on hard problems either.** Same pattern
  as T5/T7/T8 — 32B either gets it right in one shot, or TB Gen
  asserts. No debug machinery exercised.
- **(θ) TB Gen asserts on majority of problems.** Regression back to
  T7 pattern, 32B can't sustain TB Gen on FSM class problems.

---

## Acceptance criteria

- [ ] Runner file committed with `[T9] Add hard-problem runner for Debug Agent probe`
- [ ] Run completes without Python exceptions
- [ ] All 5 problems produce a `record.json` entry
- [ ] `reports/T9_DONE.md` filed with all 5 sections
- [ ] Explicit verdict (ε/ζ/η/θ) stated with evidence

## Stop conditions

File `reports/T9_BLOCKED.md` if:
- Any selected problem doesn't exist in benchmark
- A single problem runs >25 minutes
- Ollama OOM or hang
- JSON decode errors reappear (json_mode regression)

## Do not

- Modify any source file
- Add problems beyond the 5 specified
- Run with n>1
- Skip the forensic table — pass/fail alone is not useful for T9
- Draw conclusions beyond what logs support

## Project closure

After T9_DONE.md is filed, **the project stops**. The PM will compose
the final closure document based on combined T5–T9 findings regardless
of verdict. Each verdict tells a different closure story:

- ε → "MAGE methodology observed in action, partial reproduction"
- ζ → "Candidate sampling validated, Debug Agent unreached"
- η → "Methodology non-triggerable with open 32B model, report as negative finding"
- θ → "Model regression on complex problems, document the bound"
