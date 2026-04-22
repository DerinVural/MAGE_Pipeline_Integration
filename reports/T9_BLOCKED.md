# T9 — BLOCKED: Prob127_lemmings1 Exceeded 25-Minute Hard Stop

## Stop condition triggered

Per T9 spec: *"Per-problem max: 25 minutes (kill and file BLOCKED if exceeded)"* and
the Stop condition *"A single problem runs >25 minutes."*

Prob127_lemmings1 started at **15:55:24** and was still iterating in the
TB-revision loop at **16:22:42** when the runner was killed — 27 minutes
elapsed with no convergence. Prob128_fsm_ps2 never started.

Runner PID 534351 killed at 16:22:42.

Despite the block, the partial run yielded strong mechanism evidence that
answers T9's core question. This report files the block AND preserves the
T9.4 forensic findings for the 4 problems that produced logs.

---

## 1. Runner diff

New file `tests/test_top_agent_ollama_hard.py` — clone of the T8 runner
(`test_top_agent_ollama_32b.py`) with exactly two field changes:

```diff
-    "filter_instance": "^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|Prob005_notgate)$",
+    "filter_instance": "^(Prob121_2014_q3bfsm|Prob124_rule110|Prob127_lemmings1|Prob128_fsm_ps2|Prob119_fsm3)$",
 ...
-    "run_identifier": "ollama_32b_5probs",
+    "run_identifier": "ollama_32b_hard",
```

All other fields identical: `provider=ollama`, `model=qwen2.5-coder:32b`,
`n=1`, `temperature=0.85`, `top_p=0.95`, `max_token=4096`,
`use_golden_tb_in_mage=True`, `type_benchmark=verilog_eval_v2`,
`path_benchmark=./verilog-eval`.

## 2. Problem existence check

All 5 FSM-class problems exist in the benchmark:

```
$ for p in Prob121_2014_q3bfsm Prob124_rule110 Prob127_lemmings1 Prob128_fsm_ps2 Prob119_fsm3; do
    ls verilog-eval/dataset_spec-to-rtl/${p}_prompt.txt
  done
verilog-eval/dataset_spec-to-rtl/Prob121_2014_q3bfsm_prompt.txt
verilog-eval/dataset_spec-to-rtl/Prob124_rule110_prompt.txt
verilog-eval/dataset_spec-to-rtl/Prob127_lemmings1_prompt.txt
verilog-eval/dataset_spec-to-rtl/Prob128_fsm_ps2_prompt.txt
verilog-eval/dataset_spec-to-rtl/Prob119_fsm3_prompt.txt
```

No BLOCKED condition from missing specs.

## 3. Mechanism activation table — partial (4/5)

`record.json` not written (runner killed before completion). Forensic pulled
directly from per-problem log dirs.

| Problem | Started | Finished | Wall | `properly_finished.tag` | TB retries | **Cand. rounds** | **Editor rounds** | `rtl_editor.log` | Initial syntax pass | First valid mismatch_cnt |
|---|---|---|---:|---|---:|---:|---:|---:|---|---:|
| Prob119_fsm3          | 15:15 | 15:25 | 10m  | **YES** | 1 | **0** | **0** | 0 B | No (1st try), Yes (2nd) | 0 (pass) |
| Prob121_2014_q3bfsm   | 15:25 | 15:46 | 21m  | **NO**  | 1 | **0** | **0** | 0 B | Yes | **315** |
| Prob124_rule110       | 15:46 | 15:55 | 9m   | **YES** | 1 | **0** | **0** | 0 B | Yes | 0 (pass) |
| Prob127_lemmings1     | 15:55 | KILLED 16:22 | 27m+ | — | 2 (in flight) | **0** | **0** | 0 B | No (1st), Yes (2nd) | **83** |
| Prob128_fsm_ps2       | never started | — | — | — | — | — | — | — | — | — |

Notes:
- "TB retries" = count of `Revised tb:` entries in `mage.agent.log`.
- "First valid mismatch_cnt" = first simulation where iverilog compiled
  and vvp ran to completion; earlier 0-mismatch entries were
  `tb.sv: syntax error` / `Unable to open input file` i.e. TB Gen's initial
  output didn't compile.
- `log_ollama_32b_hard_0/VERILOG_EVAL_V2_Prob128_fsm_ps2/` does not exist
  because the runner was killed before Prob127 released.

**Headline:** across 4 observed problems — including two (Prob121, Prob127)
where simulation produced 315 and 83 mismatches respectively on
syntactically valid RTL — **Candidate generation rounds = 0 and RTL
Editing rounds = 0 everywhere**. Same pattern as T5/T7/T8.

## 4. Quoted evidence — why the debug machinery didn't trigger on mismatch-heavy runs

### 4.1 Prob127 had functionally wrong RTL with 83 mismatches — Debug Agent should have fired

`log_ollama_32b_hard_0/VERILOG_EVAL_V2_Prob127_lemmings1/mage.sim_reviewer.log`,
16:06:58 entry (after initial TB retry, once TB compiled cleanly):

```
[2026-04-22 16:06:58,279 - mage.sim_reviewer - INFO]
Simulation is_pass: False, mismatch_cnt: 83
output: {
    "stdout": "... SIMULATION FAILED - 83 MISMATCHES DETECTED, FIRST AT TIME 120 ...",
    "stderr": ""
}
```

DUT vs. reference — 83 out of 229 samples mismatched on both `walk_left` and
`walk_right`. Syntactically valid, functionally wrong — this is the exact
condition T9 was designed to surface.

### 4.2 But sim_judge kept voting `tb_needs_fix` — preventing the Candidate/Editor branch

`mage.sim_judge.log` verdicts for Prob127 (in order):

```
"tb_needs_fix": false
"tb_needs_fix": true
"tb_needs_fix": false
"tb_needs_fix": true
"tb_needs_fix": false
"tb_needs_fix": false
```

Six verdicts across the observed window. The `true` verdicts triggered the
two `Revised tb:` entries in `mage.agent.log` (16:06:58 and 16:12:09). The
`false` verdicts — which per `agent.py:127-151` should EXIT the TB loop and
drop into the RTL-candidate/Editor branch — are interleaved with new `true`
verdicts, so the loop never cleanly exits. With `sim_max_retry=4`, the
pipeline keeps flipping between "TB is broken, re-gen it" and "TB is OK"
verdicts on essentially the same simulation data, producing a new TB each
cycle while never reaching the RTL-side debug branch.

### 4.3 Prob121_2014_q3bfsm — same pattern, 315 mismatches and no Editor

`mage.sim_judge.log` verdicts for Prob121:

```
"tb_needs_fix": false
"tb_needs_fix": true
"tb_needs_fix": false
"tb_needs_fix": false
```

Prob121 completed (21m, `properly_finished.tag` absent). Same story: 315
mismatches on the valid-TB simulation, judge alternates verdicts, pipeline
never reaches `RTLEditor` because the TB loop is still technically active.

### 4.4 Prob127 initial RTL — syntactically valid, functionally subtle

`output_ollama_32b_hard_0/VERILOG_EVAL_V2_Prob127_lemmings1/rtl.sv` (the RTL
that produced 83 mismatches):

```systemverilog
module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    output logic walk_left,
    output logic walk_right
);
    localparam STATE_LEFT = 1'b0;
    localparam STATE_RIGHT = 1'b1;
    logic state, state_next;

    initial begin state = STATE_LEFT; end

    always @(posedge clk or posedge areset) begin
        if (areset) state <= STATE_LEFT;
        else        state <= state_next;
    end

    always @(*) begin
        case (state)
            STATE_LEFT:
                if (bump_left)       state_next = STATE_RIGHT;
                else if (bump_right) state_next = STATE_RIGHT;  // bug: bump_right from LEFT should stay LEFT
                else                 state_next = STATE_LEFT;
            STATE_RIGHT:
                if (bump_right)      state_next = STATE_LEFT;
                else if (bump_left)  state_next = STATE_LEFT;   // bug: bump_left from RIGHT should stay RIGHT
                else                 state_next = STATE_RIGHT;
        endcase
    end

    assign walk_left  = (state == STATE_LEFT);
    assign walk_right = (state == STATE_RIGHT);
endmodule
```

Exactly the "syntactically valid, functionally subtle" case T9 targeted.
Spec says a Lemming bumped *on its left* walks *right*, and *on its right*
walks *left* — but this DUT transitions on *either* bump from either
state, flipping direction indiscriminately. A Debug Agent iteration pointed
at this diff with the spec would very likely catch it. It never ran.

## 5. Verdict (partial-run resolution)

Under the rubric from T9.5, the evidence best matches:

**(η) Neither triggered on hard problems either.** Same pattern as
T5/T7/T8 — 0 Candidate rounds and 0 Editor rounds across all observed
problems. The hypothesis that FSM-class problems would naturally activate
the debug machinery is **not supported** by this run.

Refinement: for the 4 problems observed here, the reason is not (as in T8)
that 32B succeeds in one shot — Prob121 and Prob127 produced 315 and 83
simulation mismatches respectively. The reason is an **upstream control
issue**: `SimJudge` keeps oscillating between `tb_needs_fix: true` and
`false` on ambiguous failures, keeping the pipeline inside the TB-revision
loop until it either (a) gets a clean simulation by chance (not observed
here on Prob127), (b) asserts on TB-retry exhaustion (Prob121's path), or
(c) times out (Prob127's path). In none of those outcomes does control
reach the `RTLEditor` branch — *even when* the RTL is observably wrong.

This is a **pipeline-design finding**, consistent with (and strengthening)
T7 verdict γ's observation that the TB loop is a control-flow gate the
debug machinery sits behind.

## Acceptance-criteria status

- [x] Runner file committed (`tests/test_top_agent_ollama_hard.py`)
- [ ] Run completes without Python exceptions — **killed manually at 27min on Prob127**
- [ ] All 5 problems produce a `record.json` entry — **4/5 produce log dirs; record.json never written; Prob128 never started**
- [x] Forensic table filed (partial, 4/5)
- [x] Explicit verdict stated with evidence (η)

## Why this is filed as BLOCKED not DONE

Per T9 spec Stop conditions, a single problem running >25 minutes is a hard
block. Prob127 ran 27m and Prob128 never started — both conditions that the
spec explicitly mandates BLOCKED for. The partial-run findings are
preserved above, but the formal acceptance criteria aren't met.

Recommended to PM: treat verdict **η** as the answer to T9's headline
question (debug machinery does not activate naturally, even on functionally
subtle FSM problems), with the additional mechanism observation that the
blocker is sim_judge oscillation rather than "32B gets it right in one
shot". T7 and T8 both attributed the non-activation to different causes
(model failure at TB; model success before Editor). T9 adds a third
distinct cause: judge oscillation on mismatch-heavy simulations.

Project closure per PM's T9.5 mapping would be: **"η → Methodology
non-triggerable with open 32B model, report as negative finding"**, with
the refinement that the bound isn't purely model-capacity — it's
`SimJudge`'s inability to commit to a verdict when faced with a large
mismatch count.
