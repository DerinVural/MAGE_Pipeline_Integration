# T8 — 32B Pipeline Test on 5 Problems

## 1. Runner diff

New file `tests/test_top_agent_ollama_32b.py` — clone of the T5 runner with
two field changes:

```diff
-    "model": "qwen2.5-coder:7b",
+    "model": "qwen2.5-coder:32b",
 ...
-    "run_identifier": "ollama_5probs",
+    "run_identifier": "ollama_32b_5probs",
```

All other fields identical: `provider=ollama`, same 5-problem filter
`^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|Prob005_notgate)$`,
`n=1`, `temperature=0.85`, `top_p=0.95`, `max_token=4096`,
`use_golden_tb_in_mage=True`, `type_benchmark=verilog_eval_v2`. T5's runner
`test_top_agent_ollama.py` is left untouched for comparability.

## 2. Model availability

`qwen2.5-coder:32b` was already present on the box — no pull needed.

```
$ curl -s http://localhost:11434/api/tags | jq -r '.models[] | select(.name | contains("32b")) | "\(.name)\t\(.size)"'
qwen2.5-coder:32b       19851349898
```

19.85 GB. Disk: 3.0 TB available on /. Memory: 104 GB free at launch (of 120
GB total). OOM not a concern.

## 3. Side-by-side results

| Problem | T5 (7B json_mode) | T8 (32B) | Wall Δ |
|---|---|---|---|
| Prob001_zero          | ❌ FAIL (3m 31s)  | ✅ PASS (2m 48s)  | −43s |
| Prob002_m2014_q4i     | ✅ PASS (2m 59s)  | ✅ PASS (2m 07s)  | −52s |
| Prob003_step_one      | ✅ PASS (2m 19s)  | ✅ PASS (14m 28s) | +12m (TB retry path) |
| Prob004_vector2       | ❌ FAIL (1m 20s)  | ✅ PASS (3m 11s)  | +1m 51s (but now passes) |
| Prob005_notgate       | ✅ PASS (3m 23s)  | ✅ PASS (2m 53s)  | −30s |
| **Total pass_cnt**    | **3 / 5**         | **5 / 5**         | — |
| **Total wall**        | 13m 34s           | 25m 28s           | +11m 54s |

7B: 3/5. 32B: **5/5**. Prob001 and Prob004 — the two 7B failures — both flip
to PASS on 32B. Prob003's wall time ballooned (see forensic section below)
but the outcome is still a pass.

## 4. Forensic evidence

### T8 32B (this run)

| Problem | `properly_finished.tag` | `Revised tb:` count | Json Decode Err | Candidate rounds | Debug Agent rounds | `rtl_editor.log` size |
|---|---|---:|---:|---:|---:|---:|
| Prob001_zero          | YES | 0 | 0 | 0 | 0 | 0 B |
| Prob002_m2014_q4i     | YES | 0 | 0 | 0 | 0 | 0 B |
| Prob003_step_one      | **NO** | **4** | 0 | 0 | 0 | 0 B |
| Prob004_vector2       | YES | 0 | 0 | 0 | 0 | 0 B |
| Prob005_notgate       | YES | 0 | 0 | 0 | 0 | 0 B |

### T5 7B json_mode (baseline, for diff)

| Problem | `properly_finished.tag` | `Revised tb:` count | Candidate rounds | Debug Agent rounds |
|---|---|---:|---:|---:|
| Prob001_zero          | NO   | 4 | 0 | 0 |
| Prob002_m2014_q4i     | NO   | 4 | 0 | 0 |
| Prob003_step_one      | YES  | 2 | 0 | 0 |
| Prob004_vector2       | YES  | 0 | 0 | 0 |
| Prob005_notgate       | NO   | 4 | 0 | 0 |

### Observations

- **Zero JSON decode errors on 32B.** `json_mode=True` holds — no regression
  from T5's grammar-constrained sampling.
- **Zero candidate-generation rounds, zero Debug Agent rounds.** Same
  finding as T7: across all 5 problems, the pipeline either (a) initial-RTL
  + initial-TB combination passes outright, so no debug branch is reached
  (Prob001/002/004/005), or (b) TB retry loop exhausts and `agent.py:130`
  asserts, which is caught by the outer `except Exception:` —
  `properly_finished.tag` is absent in that case (Prob003). The
  runner-level `sim_review_golden_benchmark` at test_top_agent.py:95 then
  evaluates the last-written `rtl.sv` against the real golden TB
  independently, which is what yields `is_pass=True` even when the agent
  itself asserted.
- **Prob003 pattern has flipped.** On 7B json_mode, Prob003 passed cleanly
  (`properly_finished.tag=YES`, 2 TB retries). On 32B, Prob003 hits 4 TB
  retries and asserts — but still passes via the runner-level golden TB
  fallback (initial RTL was already correct). Net cost: +12 minutes of
  wall time for the same outcome. This is a pipeline-design symptom, not a
  model regression: the stronger model isn't triggering the bug *less*;
  it's just getting pass credit from a code path that sidesteps the bug.
- **Prob001 and Prob004 now pass.** These were the 7B JSON-mode failures.
  On 32B both flow through the happy path end-to-end
  (`properly_finished.tag=YES`, 0 TB retries, 0 candidates, 0 edits) —
  initial TB + initial RTL both clean on the first try.

## 5. Raw response excerpt — Prob004_vector2 on 32B

`log_ollama_32b_5probs_0/VERILOG_EVAL_V2_Prob004_vector2/mage.rtl_generator.log`,
lines 3–6 (the JSON object the model returned for the RTL-Gen prompt):

```
{
    "reasoning": "To implement the module TopModule that reverses the byte order
     of a 32-bit vector, we need to rearrange the bytes of the input vector such
     that the most significant byte becomes the least significant and vice versa.
     The input in is 32 bits wide, meaning it has four 8-bit bytes. We will
     extract each 8-bit byte from its position in the input vector and reassign
     them to their new positions in the output vector. For instance, the first 8
     bits of the input (in[7:0]) should be placed at the end of the output
     (out[31:24]), and so on. This process ensures that the byte order is
     reversed without altering the internal values of the bytes themselves.",
    "module": "module TopModule (\n\tinput logic [31:0] in,\n\toutput logic [31:0] out\n);\n\n\talways @(*) begin\n\t\tout[7:0] = in[31:24];\n\t\tout[15:8] = in[23:16];\n\t\tout[23:16] = in[15:8];\n\t\tout[31:24] = in[7:0];\n\tend\n\nendmodule"
}
```

Rendered `rtl.sv` written to disk:

```systemverilog
module TopModule (
	input logic [31:0] in,
	output logic [31:0] out
);

	always @(*) begin
		out[7:0] = in[31:24];
		out[15:8] = in[23:16];
		out[23:16] = in[15:8];
		out[31:24] = in[7:0];
	end

endmodule
```

This is the exact byte-reverse (`{in[7:0], in[15:8], in[23:16], in[31:24]}`
decomposed into four per-byte assigns) that 7B failed to produce on the same
prompt on the same seed range. No candidate generation or Editor rounds were
needed — 32B got it right on the initial pass.

## 6. Verdict

**(A) 32B materially outperforms 7B.**

- Pass rate 5/5 vs. 3/5 for 7B json_mode — both 7B failures (Prob001, Prob004)
  cleanly flip to PASS, and the two already-passing problems are ~30-50s
  faster on 32B despite the 4.5× parameter count (TB generator converges in
  one shot, no retry budget consumed).
- Pipeline reaches the happy-path terminus (`properly_finished.tag`
  written) in 4/5 problems, vs. 2/5 on 7B.
- JSON-mode remains stable (0 decode errors). The T5 fix is not regressed
  by the larger model.

But note the **qualifier for Phase 2 interpretability** (consistent with T7
verdict γ):

- **Debug Agent still never triggers** (0 Editor rounds across all 5
  problems, 4/5 via initial-RTL-pass, 1/5 via assert-then-golden-TB-bypass).
- **Candidate generation also never runs** (0 rounds across all 5
  problems).
- The `agent.py:130` assertion trip path still masks as a pass via
  runner-level `sim_review_golden_benchmark`. This is a pipeline-design
  concern, not a model concern.

So the narrative for project close-out:
- **Correctness** (does RTL match spec): 32B delivers a clean 5/5 on the T5
  suite.
- **Mechanism attribution** (did MAGE's debug/candidate machinery
  contribute): still no — the model is strong enough on these 5 problems
  that neither branch is exercised. Any claim that "MAGE's multi-agent
  methodology" produced these results is unsupported by this run; on these
  problems it reduces to "one shot through TB-Gen + RTL-Gen".

Recommendation for PM on project closure:
- Report this test as a model-upgrade verification, not as a MAGE methodology
  validation.
- For a real MAGE-methodology claim, the suite would need problems that
  stress the Editor branch *and* the `sim_max_retry` loop doesn't assert
  out — that would require either pipeline changes (T7 recommendations) or
  a benchmark subset tuned to the current control-flow gates.

**Project stops here per T8 task spec.**
