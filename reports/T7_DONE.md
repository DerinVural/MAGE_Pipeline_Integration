# T7 — Debug Agent Live Smoke Test

## 1. Run summary

Runner: `tests/test_top_agent_ollama_debug.py` (4 kmap problems, n=1,
qwen2.5-coder:7b, temperature=0.85, top_p=0.95, max_token=4096,
use_golden_tb_in_mage=True). Wall time: **16m 08s**.

| Problem | Pass | RTL Editor rounds | First mismatches | Final mismatches | Score before / after | Notes |
|---|---|---:|---:|---:|---|---|
| Prob050_kmap1 | ✅ | 0 | 0 / 219 | 0 / 219 | 1.00 / 1.00 | Initial RTL passed golden TB immediately — Debug Agent path not reachable by design |
| Prob057_kmap2 | ❌ | 0 | — | 127 / 232 | — / 0.453 | TB revised 4× (`sim_max_retry=4`); `properly_finished.tag` not written — assertion caught and swallowed |
| Prob093_ece241_2014_q3 | ❌ | 0 | — | 60 / 60 | — / 0.000 | Same pattern; total mismatch, not a single output bit correct |
| Prob122_kmap4 | ❌ | 0 | — | 181 / 232 | — / 0.220 | Same pattern |

Score = `1 − mismatches / total_samples` (MAGE paper Eq. 2). "First" column is
blank for failed runs because the initial simulation never made it to
completion — see section 5.

Pass rate: **1/4 (25%)**.

## 2. Evidence — was Debug Agent triggered?

Direct greps on the per-problem `mage_rtl_total.log` and `mage.rtl_editor.log`:

```
$ for p in Prob050_kmap1 Prob057_kmap2 Prob093_ece241_2014_q3 Prob122_kmap4; do
    d=log_t7_debug_smoke_0/VERILOG_EVAL_V2_$p
    edit_bytes=$(wc -c < $d/mage.rtl_editor.log)
    edit_rounds=$(grep -c "RTL Editing: round" $d/mage_rtl_total.log)
    cand_rounds=$(grep -c "Candidate generation: round" $d/mage_rtl_total.log)
    sel_rounds=$(grep -c "Selected candidate: round" $d/mage_rtl_total.log)
    echo "$p: editor_log=${edit_bytes}B edit=$edit_rounds cand=$cand_rounds sel=$sel_rounds"
  done
```
```
Prob050_kmap1:           editor_log=0B edit=0 cand=0 sel=0
Prob057_kmap2:           editor_log=0B edit=0 cand=0 sel=0
Prob093_ece241_2014_q3:  editor_log=0B edit=0 cand=0 sel=0
Prob122_kmap4:           editor_log=0B edit=0 cand=0 sel=0
```

Additional invariant check — `properly_finished.tag` is written on the
happy-path exit of `Top.run()` (agent.py:251); absence = exception caught by
the outer `except Exception:` at agent.py:253.

```
Prob050_kmap1:           properly_finished.tag NOT PRESENT
Prob057_kmap2:           properly_finished.tag NOT PRESENT
Prob093_ece241_2014_q3:  properly_finished.tag NOT PRESENT
Prob122_kmap4:           properly_finished.tag NOT PRESENT
```

Per-problem verdict: Debug Agent **did not trigger** in any of the four
problems. `RTLEditor.chat(...)` was never invoked — the Editor log file is
literally empty, and not a single "RTL Editing: round N" message was emitted.
Critically, Candidate Generation (the stage *before* the Editor at
agent.py:157) also never ran — `Candidate generation: round` is also zero.
So the control flow didn't even make it to the candidate loop, let alone to
the Editor that follows it.

## 3. Quoted log excerpts

### Prob057_kmap2 — TB Generator produces `topmodule` (malformed)

`log_t7_debug_smoke_0/VERILOG_EVAL_V2_Prob057_kmap2/mage.agent.log` (edited
for width):

```
11:10:18  INFO  Initial tb:
11:10:18  INFO  (tb content — 127 lines, starts with: `timescale 1 ps/1 ps` …)
11:10:18  INFO  Initial if:
11:10:18  INFO  module TopModule (input logic a, input logic b, input logic c,
                                  input logic d, output logic out); endmodule
11:10:30  INFO  Initial rtl:
11:10:30  INFO  module TopModule (…); assign out = (a & ~b & c & d) | …; endmodule
11:10:34  INFO  Fallback from display queue to display moment
11:11:12  INFO  Revised tb:
11:11:54  INFO  Revised tb:
11:12:37  INFO  Revised tb:
11:13:21  INFO  Revised tb:
```

Four `Revised tb:` events — the inner TB-fix loop (`for i in
range(self.sim_max_retry)`, agent.py:106 with `sim_max_retry = 4`) ran to
exhaustion. The stimulus the Sim Judge rejected, from
`mage.sim_judge.log` excerpt:

```
<failed_sim_log>
./output_t7_debug_smoke_0/VERILOG_EVAL_V2_Prob057_kmap2/tb.sv:5: syntax error
I give up.
./output_t7_debug_smoke_0/…/sim_output.vvp: Unable to open input file.
</failed_sim_log>

<failed_testbench>
1: `timescale 1 ps/1 ps
2: `define OK 12
3: `define INCORRECT 13
4:
5: topmodule stimulus_gen (           ← LLM wrote "topmodule" instead of "module"
6:   input clk,
7:   output reg a, b, c, d,
8: );
...
27: topmodule tb();                   ← same typo on the second module
```

The LLM kept JSON-mode schema but hallucinated the keyword `topmodule`.
Testbench never compiled, so `is_sim_pass` stayed False, so the loop kept
regenerating the TB. After the 4-retry budget ran out, the downstream
`assert not tb_need_fix` at agent.py:130 was hit; the outer `except` (agent.py:253)
swallowed it and `run()` returned `(False, "Exception: ...")`. Debug Agent
never came into play because candidate generation (agent.py:133) is gated on
that assert having passed first.

### Prob122_kmap4 — same pattern, different symptom

Same structure: Initial RTL produced, 4× TB revised, final
`sim_review_output.json` shows 181 / 232 mismatches (score 0.22), Editor log
empty, `properly_finished.tag` absent. The TB generator never produced a
compilable-and-judged-good testbench; control never advanced past line 130.

## 4. Score progression

Not applicable. Debug Agent did not execute any rounds in any problem, so
there is no "round 0 → round 1 → round 2" trajectory to report. For Prob050
the trajectory is a single value `[1.00]`; for the three failures the
trajectory is `[<pre-candidate-phase>, …, 0.45 / 0.00 / 0.22]` where only the
final-state mismatch is observable — intermediate candidate scores were never
produced because the candidate loop never ran.

## 5. Verdict

**(γ) Debug Agent still never triggered.**

Root cause is one step upstream of what T7 was designed to probe. The paper's
Debug Agent gate requires, in sequence:

1. Initial RTL passes syntax (✓ in 4/4).
2. Initial simulation produces `is_sim_pass=False` *with* `sim_mismatch_cnt > 0`
   (needed for the assert at agent.py:136) — and the TB has to compile for
   this count to exist. In our 3 failing problems the TB never compiled, so
   `sim_mismatch_cnt` was never established, and the `for i in
   range(sim_max_retry)` loop exited with `tb_need_fix=True`. That trips the
   assert at line 130 before candidate generation.
3. `rtl_max_candidates=20` candidates all produce mismatches — not reached.
4. `rtl_edit.chat(...)` called — not reached.

So Prob050 fell out on condition 2 (TB passed and RTL passed → no debug
needed — the "easy" outcome that keeps the Editor silent), while Prob057 /
Prob093 / Prob122 all fell out on condition 2 (TB never compiled → assert
trips → caught by outer `except` → `(False, "Exception: …")` returned). The
outer exception handler (agent.py:253) silently converts the assertion into a
`False` verdict, which is why record.json looks clean.

### Implications

- **A control-flow gap, not a Debug-Agent capability failure.** The paper's
  `RTLEditor` class is correctly wired (`self.rtl_edit = RTLEditor(…)` at
  agent.py:242 is asserted at line 75), but with `qwen2.5-coder:7b` the TB
  Generator on 4-input kmap problems produces SystemVerilog that doesn't
  even compile, so the pipeline bails before reaching the Editor branch.
- **The silent `except Exception:` at agent.py:253** is itself a concern: it
  makes assertion failures indistinguishable from legitimate functional
  failures in `record.json`. Any future pass-rate number becomes ambiguous
  unless we separate "pipeline asserted" from "RTL was wrong".
- **T5 ablation is not interpretable** with the current model on kmap
  problems — we cannot claim Phase 2 results reflect MAGE's methodology when
  its centerpiece never executed.

### Recommendations (for PM decision, not acted on in T7)

- **T8 (control-flow investigation):** decide whether the `assert not
  tb_need_fix` at agent.py:130 should become a graceful `rtl_need_fix =
  False; break-with-best-effort-TB` path, or whether `sim_max_retry` should
  scale for weaker models. Either way, surface the assertion (write
  `pipeline_exception.tag` or equivalent) so record.json isn't silently
  mixed.
- **Model upgrade consideration:** Prob057 failed at the `module` vs
  `topmodule` keyword — this is a token-level hallucination inside
  JSON-mode output. Larger (`qwen2.5-coder:32b` is already present on the
  box) or a reasoning-specific model may clear the TB bar without code
  changes. Worth a one-problem retry before bigger investigations.
- **Alternate target selection:** kmap problems may not actually be the
  sweet spot for this model — it stumbles on the testbench stage, not the
  RTL stage. A better probe would be problems where Initial RTL compiles
  but is subtly wrong and the *golden* TB (which always compiles) is used.
  `use_golden_tb_in_mage=True` is already set; the gap is that the run
  still lets the LLM edit/regenerate the TB first.

Phase 2 authorization: **hold**. Recommend T8 to either fix the TB retry
contract or bypass the TB-gen stage (use-golden-TB-only mode) before running
the full VerilogEval sweep.
