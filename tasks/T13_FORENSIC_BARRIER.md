# Task T13: Forensic Investigation of Pre-Step-4 Barriers

**Status:** PENDING
**Priority:** HIGH — last task of Faz 0; gates Faz 1 entry
**Depends on:** T10, T11, T12 merged to `feat/mage-open-v2`
**Reference:** Plan v3 §3 T13, T12_DONE.md "Out-of-scope follow-ups"

---

## Context

T12 added `bypass_tb_gen=True` to remove the TBGenerator loop as a
suspect. Empirical result over 20 problem-runs (10 problems × 2 models):

- ✅ TBGen LLM call count: 0/20 (bypass works as specified)
- ❌ Candidate generation rounds: **0/20** (Step 4 still never reached)
- ❌ RTLEditor rounds: **0/20** (Step 5 still never reached)

This means TBGen was *one* barrier, not *the* barrier. Something
else in `agent.py` `_run()` blocks the path to Step 4. T12's report
flagged this explicitly:

> "Even with bypass, the pipeline exits before `rtl_edit.chat` runs.
> Suggests the assertion checked above fires before edit-loop entry."

**T13 is purely forensic.** No code changes. No fixes. Just localize
the barrier(s), document them, and produce a clean diagnostic report
the PM can use to scope T14 (the eventual fix task).

This is also the final Faz 0 deliverable. Faz 1 (Abstraction Layer)
cannot begin until we understand what's blocking Step 4 — otherwise
multi-model testing in Faz 2 will produce 8 model × N "stuck at the
same place" results that teach us nothing about the models.

---

## Hypothesis to verify

A grep of `agent.py` reveals two assertion sites between Step 3 (TB
loop) and Step 4 (candidate generation):

```python
# Line 160 — exit guard from TB loop
assert not tb_need_fix, f"tb_need_fix should be False. sim_log: {sim_log}"

# Line 165-167 — entry guard to candidate generation
if rtl_need_fix:
    assert (
        sim_mismatch_cnt > 0
    ), f"rtl_need_fix should be True only when sim_mismatch_cnt > 0. sim_log: {sim_log}"
```

**Working hypothesis:** Under `bypass_tb_gen=True`, the SimJudge can
still return `tb_need_fix=True` on a golden testbench. The bypass
loop's `continue` statement skips the TB regeneration but does not
reset `tb_need_fix` to `False`. When the loop exits (either by
`break` on sim pass, or by exhausting `sim_max_retry`), line 160
asserts and the pipeline crashes — never reaching the `if rtl_need_fix:`
block at line 163.

This hypothesis is consistent with T12's finding that 12/20 cells
ended in `pipeline_assert` despite some having `is_pass=True`. T13's
job is to **prove or refute this with logs**, not to fix it.

---

## Scope

T13 is observational. Do NOT modify any source file. The deliverable
is a report.

### T13.1 — Re-run T12 smokes with verbose tracing

Re-execute T12's exact 10-problem set on both 32B and 7B with
`bypass_tb_gen=True`. Same configs as T12 — only the logging is
expanded.

**Logging additions** (these go in a separate diagnostic logger, not
a source-file modification — see "How to add tracing" below):

For each problem, capture:

1. **Per-iteration state of `tb_need_fix` and `rtl_need_fix`** —
   trace their value at the top of each loop iteration and at exit.
2. **`sim_mismatch_cnt` at exit** — what was it when the assertion
   fired (or didn't)?
3. **Which line raised**, exactly. Use `traceback.extract_tb()` on
   the exception caught by T10's sidecar; quote the file:line.
4. **Whether each problem reached the `if rtl_need_fix:` block** at
   line 163.

### How to add tracing without modifying agent.py

T13 must remain non-invasive. Use Python's `sys.settrace` or a
`logging.DEBUG`-level shim activated at runtime, OR write a small
`debug_trace.py` harness module that:

```python
# debug_trace.py — sketch only, T13 implementer expands
import logging
import os

def install_trace_hooks():
    """Install temporary log hooks for T13. No source-file edits."""
    logger = logging.getLogger("mage")
    logger.setLevel(logging.DEBUG)
    # Add a handler that writes to a per-problem trace file
    ...
```

If the cleanest implementation requires a one-liner addition to
`agent.py` (e.g., `logger.debug("tb_need_fix=%s", tb_need_fix)`),
that is acceptable provided:

- The change is `logger.debug(...)` only (no behavior change)
- It is committed as a separate commit with `[T13-trace]` prefix
- It can be cleanly reverted

Default expectation: **no source-file edits**. Use Python tracing,
existing log levels, or a wrapper script.

### T13.2 — Locate the assertion(s) that fired

For each of the 20 cells from T13.1, classify which exit path was
taken:

| Exit path | Where | Trigger condition |
|---|---|---|
| A | `return False, rtl_code` (line 122) | `not is_syntax_pass` from initial RTL gen |
| B | `assert not tb_need_fix` (line 160) | TB loop exited with `tb_need_fix=True` |
| C | `assert sim_mismatch_cnt > 0` (line 165-167) | `rtl_need_fix=True` but no mismatch counted |
| D | `for i in range(self.rtl_max_candidates):` (line 187) | Reached candidate gen |
| E | `if rtl_need_fix:` (line 216) | Reached RTLEditor branch |
| F | Normal exit (line 246+) | Pipeline completed |
| G | Other / unknown | (catch-all; investigate) |

The output is a per-problem tag (A/B/C/D/E/F/G) plus a 1-2 line
explanation citing log evidence.

### T13.3 — Quantitative summary

Build a 20-row table:

| Problem | Model | bypass_tb_gen | Exit path | tb_need_fix at exit | rtl_need_fix at exit | sim_mismatch_cnt at exit | Pre-Step-4 barrier? |
|---|---|---|---|---|---|---|---|
| Prob001_zero | 32B | True | ? | ? | ? | ? | ? |
| ... | (10 × 2 = 20 rows) |

The "Pre-Step-4 barrier?" column is binary (yes/no). If yes, name it
(e.g., "L160 tb_need_fix assert"). This table is the central
deliverable.

### T13.4 — Hypothesis verdict

State explicitly which is true:

- **(I) Hypothesis confirmed.** Line 160 (`assert not tb_need_fix`)
  is the dominant pre-Step-4 barrier. >50% of cells fail there.
- **(II) Hypothesis partially confirmed.** Line 160 is one barrier
  but other exit paths are also common. List them with frequencies.
- **(III) Hypothesis refuted.** Line 160 fires <20% of the time;
  the dominant barrier is elsewhere. Identify it.
- **(IV) Mixed; barrier varies by model or problem family.**
  Provide breakdown.

### T13.5 — Recommendations for T14 (the future fix)

Without implementing the fix, propose 2-3 candidate fixes ranked by
estimated invasiveness and compatibility with "faithful reproduction".

**Format for each proposal:**
- One-paragraph description
- Estimated invasiveness (lines changed, files touched)
- Faithful-reproduction compatibility: does this break upstream MAGE
  semantics? Yes/No/Partially
- Expected effect on Step 4/5 reachability

Do NOT pick a winner. PM picks during T14 scoping. T13 just lists.

---

## Acceptance criteria

- [ ] No source files modified, OR if `logger.debug` lines were added
      to `agent.py`, they are in a clearly tagged `[T13-trace]` commit
      that is reversible.
- [ ] Both smoke runs completed, 20 cells captured.
- [ ] Per-cell classification (A/B/C/D/E/F/G) for all 20.
- [ ] Quantitative table populated.
- [ ] Verdict (I/II/III/IV) stated explicitly.
- [ ] 2-3 fix proposals listed (no implementation).
- [ ] Commit on `feat/mage-open-v2`, message:
      `[T13] Forensic localization of pre-Step-4 pipeline barriers`
- [ ] Report filed: `reports/v2/T13_DONE.md`

---

## Stop conditions

File `reports/v2/T13_BLOCKED.md` if:

- Smoke run takes >2x the T12 wall-clock time without producing
  log artifacts (logging system itself is broken)
- Tracing instrumentation crashes the pipeline that previously
  worked (you've broken something — back out and report)
- Cells produce inconsistent results between back-to-back runs
  with same seed (suggests stochasticity that complicates
  classification — describe it)

---

## Do NOT

- Modify any source file beyond a single optional `[T13-trace]` debug
  logging commit
- Implement any fix for the barrier(s) you find
- Add new flags or modes
- Run more than the 20 specified cells
- Pick a "winning" fix proposal in the report — that's T14's job
- Change `bypass_tb_gen`, `temperature`, `top_p`, or any other config
  from T12 baseline
- Conclude that "the pipeline is broken" — be specific about *which*
  control-flow point is reached and not reached

## Why purely forensic

Faz 0 was originally three patches (T10, T11, T12) plus a baseline
re-run (T13). T11 and T12 each surprised us — T11's hypothesis was
wrong (oscillation isn't temperature-driven), T12's bypass exposed
the next layer. T13 should not assume what's beneath; it should
just look. A clean forensic report enables a small, targeted fix
in T14, rather than a sprawling refactor born from guesses.

---

## Report template

```markdown
# Task T13: Forensic Localization of Pre-Step-4 Barriers

**Status:** DONE
**Branch:** feat/mage-open-v2
**Commits:** <hash> (+ optional [T13-trace] commit)
**Date:** <date>

## Summary
<2-3 sentences: which exit path dominates, verdict (I/II/III/IV)>

## Methodology
- Logging mechanism used: <python tracing / logger.debug / wrapper>
- Smoke runs: 32B (10 problems) + 7B (10 problems), bypass_tb_gen=True
- Wall time: <total>

## Per-cell classification

| Problem | Model | Exit path | tb_need_fix | rtl_need_fix | sim_mismatch_cnt | Barrier? |
|---|---|---|---|---|---|---|
| ... 20 rows ... |

## Exit-path frequency

| Path | Description | Count (32B) | Count (7B) | Total |
|---|---|---|---|---|
| A | initial RTL syntax fail | ... |
| B | L160 tb_need_fix assert | ... |
| C | L165 sim_mismatch assert | ... |
| D | reached candidate gen | ... |
| E | reached RTLEditor | ... |
| F | normal completion | ... |
| G | other | ... |

## Verdict

**Verdict <I/II/III/IV>:** <explanation>

## Evidence excerpts

For at least 3 representative cells (one per dominant exit path),
quote 10-20 lines of log showing the state transition.

## Fix proposals (for T14 PM scoping)

### Proposal 1: <short name>
- Description: ...
- Invasiveness: <X lines, Y files>
- Faithful-reproduction: <yes/no/partial>
- Expected effect: ...

### Proposal 2: <short name>
- ...

### Proposal 3 (if applicable): <short name>
- ...

## Notes
<Anything PM should know>

## Follow-ups spotted
<Out-of-scope observations>
```

---

## After T13

**Do not start T14 or Faz 1 work.** T13 closes Faz 0. PM reviews the
forensic report and decides:

- Open T14 with a chosen fix proposal (small, targeted patch), then
  re-run T13 verification before declaring Faz 0 truly complete.
- OR accept the barriers as documented limitations, declare Faz 0
  complete with an asterisk, and move to Faz 1 (Abstraction Layer)
  with the understanding that Step 4/5 reachability remains unsolved.

This is a real fork in the project's path. T13's report is what
makes that decision tractable.
