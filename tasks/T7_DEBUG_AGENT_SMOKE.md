# Task T7: Debug Agent Live Smoke Test

**Status:** PENDING
**Priority:** HIGH — blocks Phase 2 authorization
**Depends on:** T6 merged
**Reference:** T5_DONE.md section 5 "Ek bulgu" (Debug Agent never triggered)

---

## Context

A critical finding in T5: across all 10 problem-runs (5 problems ×
2 configurations), MAGE's **Debug Agent (`RTLEditor`) was never
triggered**. `grep "RTL Editing: round"` returned zero matches in every
log file, and `mage.rtl_editor.log` was empty throughout.

This matters because Debug Agent + Verilog-State Checkpoint is one of
MAGE paper's two headline contributions (Section III-C). If we run the
full VerilogEval benchmark and get a pass rate while this mechanism
never activates, we cannot meaningfully attribute results to the MAGE
methodology, and our S1–S3b ablation comparisons become
uninterpretable.

### Why Debug Agent didn't trigger in T5

The control flow in `src/mage/agent.py` only reaches `rtl_edit.chat(...)`
when all of the following hold:

1. `rtl_gen.chat(...)` returns `is_syntax_pass=True` (initial RTL compiles)
2. Initial simulation reports `sim_mismatch_cnt > 0` (functional bug)
3. Candidate generation (`rtl_max_candidates=20`) all produce syntactically
   valid but functionally wrong RTL — no candidate passes the testbench
4. `rtl_need_fix` is still `True` after candidate loop

In T5's 5 problems, either (a) the model never achieved syntax-PASS in
5 trials (Prob004), or (b) initial RTL passed the golden testbench
outright (Prob001, Prob002, Prob003, Prob005 after T5). Neither path
reaches the Debug Agent.

### What T7 does

Deliberately select problems that are **known to be hard enough to
induce functional mismatches but simple enough to produce
syntactically valid RTL** — the sweet spot that forces MAGE into its
Debug Agent branch. The MAGE paper itself uses
`Prob093_ece241_2014_q3` as its worked example (Figure 3); this
problem and other kmap/FSM problems are our natural targets.

The goal is **not** high pass rate. The goal is to **prove Debug Agent
can execute at least one round successfully**, which means:

- `RTLEditor` instance gets created
- `rtl_edit.chat(...)` is called
- At least one `"RTL Editing: round N / 15"` appears in the log
- The agent produces a well-formed edit action (even if wrong)
- State checkpoint simulation runs on the edited RTL

If Debug Agent runs but always fails, that's a real finding we report.
If Debug Agent never runs despite these problem selections, we have a
pipeline control-flow bug to investigate in a follow-up task.

---

## Scope

### T7.1 — Create a Debug-Agent-targeted runner

**File:** `tests/test_top_agent_ollama_debug.py` (new)

Model this on `tests/test_top_agent_ollama.py`. Change only:

```python
"filter_instance": "^(Prob050_kmap1|Prob057_kmap2|Prob093_ece241_2014_q3|Prob122_kmap4)$",
"run_identifier": "t7_debug_smoke",
```

Rationale:
- `Prob093_ece241_2014_q3` — paper's own Figure 3 case study (5-to-1
  mux with kmap). Primary target.
- `Prob050_kmap1`, `Prob057_kmap2`, `Prob122_kmap4` — other kmap
  problems of increasing difficulty. Kmaps are a classic source of
  "syntactically easy, functionally subtle" bugs: one wrong minterm
  compiles fine but gives a mismatch for half the input space.

Leave `n=1`, `temperature=0.85`, `top_p=0.95`, `max_token=4096`,
`use_golden_tb_in_mage=True`, `model=qwen2.5-coder:7b`,
`provider=ollama` — all unchanged from T5.

### T7.2 — Execute

```bash
python tests/test_top_agent_ollama_debug.py
```

Expected wall time: 15–30 minutes (4 problems, each potentially
running through 20 candidates + up to 15 debug rounds).

### T7.3 — Forensic evidence collection

For each of the 4 problems, inspect:

- `log_t7_debug_smoke_0/VERILOG_EVAL_V2_<prob>/mage_rtl_total.log`
- `log_t7_debug_smoke_0/VERILOG_EVAL_V2_<prob>/mage.rtl_editor.log`

and record:

| Evidence | How to get it |
|---|---|
| Debug Agent triggered? | `grep -c "RTL Editing: round" <total.log>` |
| Rounds executed | First and last round numbers seen |
| State-checkpoint comparison actually happened? | Presence of `ODUT` / `Oexp` mention, or waveform-window log entries (see paper Sec III-C equations 5-6) |
| Edit action produced? | Non-empty `mage.rtl_editor.log`, look for `Replace`/`With` patterns |
| Did editing improve the score? | Mismatch count before vs. after at least one round |
| Final outcome | PASS / FAIL, and final mismatch count |

For **at least two problems** quote 30–60 lines of raw log verbatim
showing the Debug Agent in action (input prompt → model response →
state checkpoint → next round). The quoted sections are the evidence
the PM needs to verify Debug Agent is genuinely functional vs. just
producing empty-ish responses that get dropped.

### T7.4 — Report

Write `reports/T7_DONE.md` with these sections:

**1. Run summary table**

| Problem | Pass | RTL Editor rounds | First score | Final score | Notes |
|---|---|---|---|---|---|
| Prob050_kmap1 | ? | ? | ? | ? | ? |
| Prob057_kmap2 | ? | ? | ? | ? | ? |
| Prob093_ece241_2014_q3 | ? | ? | ? | ? | ? |
| Prob122_kmap4 | ? | ? | ? | ? | ? |

Where "score" is `1 - mismatch_count/total_checks` from MAGE paper Eq. 2.

**2. Evidence — Debug Agent triggered?**

Direct `grep` output with line counts for each problem. Yes/no verdict per problem.

**3. Quoted log excerpts**

Two problems, 30–60 lines each of raw Debug Agent activity. Include
enough context to show: input state, model output, edit action,
post-edit simulation result.

**4. Score progression**

For any problem where Debug Agent ran ≥2 rounds, show the score
trajectory: `[round 0: 0.67, round 1: 0.72, round 2: 0.89, ...]`
This is the MAGE paper Figure 4(b) analogue.

**5. Verdict**

Choose exactly one:

- **(α) Debug Agent functional** — triggered in ≥2 problems, executed
  ≥1 complete round with measurable score improvement. Phase 2 is
  authorized to proceed.
- **(β) Debug Agent triggered but non-productive** — ran, but scores
  never improved across rounds, or rounds always terminated on JSON
  decode error. Phase 2 runs but results flagged with caveat.
- **(γ) Debug Agent still never triggered** — control flow never
  reached `rtl_edit.chat(...)` despite selected problems. Opens T8:
  investigate `agent.py` control flow.
- **(δ) Mixed** — some problems reached Debug Agent, others didn't.
  Describe the pattern and let PM decide.

---

## Acceptance criteria

- [ ] `tests/test_top_agent_ollama_debug.py` created with the 4-problem filter
- [ ] Runner executed successfully (all 4 problems completed without pipeline exceptions)
- [ ] Commit message: `[T7] Add Debug Agent live smoke test and report`
- [ ] Log evidence collected for all 4 problems
- [ ] Report contains all 5 sections, with quoted log excerpts for ≥2 problems
- [ ] Explicit verdict (α/β/γ/δ) stated
- [ ] No source file modifications — this task is observational only

## Stop conditions

File `reports/T7_BLOCKED.md` if:

- Any of the 4 selected problems doesn't exist in the VerilogEval
  dataset (unlikely — all 4 confirmed present in `dataset_spec-to-rtl/`)
- Runner produces pipeline Python exceptions (not agent failures —
  actual crashes). Include stack trace.
- A run takes >2 hours (hung Ollama, likely) — kill and report
- Disk space issues writing logs (large state-checkpoint dumps)

---

## Do not

- Modify any source file — this is a read-only / observational task
- Change `rtl_max_candidates` or `sim_max_retry` parameters (we want
  to observe actual behavior, not artificially force Debug Agent)
- Add new problems beyond the 4 specified
- Re-run T5 or T6 artifacts
- Draw conclusions beyond what the log evidence supports

## Do not proceed after T7

File `reports/T7_DONE.md` and stop. The verdict determines the next
step — PM will decide between Phase 2 full run, T8 control-flow
investigation, or model upgrade consideration. The decision tree is
intentionally gated here because these three branches have very
different costs.
