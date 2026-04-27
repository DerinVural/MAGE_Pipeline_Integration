# codev-qwen-7B Baseline vs vanilla qwen2.5-coder:7B

**Date**: 2026-04-27
**Branch**: feat/mage-open-v2
**Pipeline build**: post-T14 (`bypass_tb_gen=True`, `golden_tb_format=True`)
**Run identifier**: `codev_qwen_7b_verify_0`
**Total wall time**: 14:57

## Question

After T14 closed Faz 0 with vanilla `qwen2.5-coder:7b` reaching ≥5/6 PASS on the same 10-problem set, we asked: **does `codev-qwen2.5-7b:latest` (a community fine-tune already pulled into Ollama, 7.6B F16, 15.2 GB) do better, worse, or same on the same pipeline + same problems?**

This is a model-substitution baseline, not a pipeline change. Pipeline code is byte-identical to commit `beebc2f` (T14 head).

## Configuration

| Field | Value |
|---|---|
| provider | ollama |
| model | `codev-qwen2.5-7b:latest` |
| temperature / top_p | 0.85 / 0.95 |
| max_token | 4096 |
| context_window | 32768 (Ollama default in `gen_config`) |
| `bypass_tb_gen` | True |
| `golden_tb_format` | True |
| `use_golden_tb_in_mage` | True |

10 problems: 5 easy (Prob001-005) + 5 hard (Prob119, 121, 124, 127, 128). Same hard set as T14 32B verify.

## Headline

**1/10 PASS**, vs vanilla `qwen2.5-coder:7b` ≥5/6 on the overlapping subset.

Three cells (Prob005, Prob127, Prob128) failed with `failure_type=unexpected` — a pydantic schema validation error on the LLM's JSON output, **not** a functional mismatch. That fault class did not appear once in the T14 vanilla 7B run. It is specific to this fine-tune's response format.

## Per-cell results

| Cell | Result | failure_type | Time | Notes |
|---|---|---|---|---|
| Prob001_zero | FAIL | functional_mismatch | 0:17 | T14 vanilla: PASS |
| Prob002_m2014_q4i | FAIL | functional_mismatch | 0:17 | T14 vanilla: PASS |
| Prob003_step_one | **PASS** | none | 0:04 | T14 vanilla: PASS |
| Prob004_vector2 | FAIL | functional_mismatch | 1:41 | T14 vanilla: PASS |
| Prob005_notgate | FAIL | **unexpected** | 0:31 | RTLOutputFormat schema error |
| Prob119_fsm3 | FAIL | functional_mismatch | 0:49 | T14 vanilla: PASS (with full Step 5 RTLEditor cycle) |
| Prob121_2014_q3bfsm | FAIL | functional_mismatch | 1:09 | T14 vanilla: 25-min stop (mid-Step-4) |
| Prob124_rule110 | FAIL | functional_mismatch | 1:41 | not in T14 7B verify scope |
| Prob127_lemmings1 | FAIL | **unexpected** | 0:04 | KeyError 'module' — schema |
| Prob128_fsm_ps2 | FAIL | **unexpected** | 5:51 | KeyError 'module' — schema |

`tag` column: 7/10 reached `properly_finished.tag`; the 3 schema-error cells exited via the `unexpected` exception path before the tag was written, exactly as T14's failure-type plumbing intends.

## Failure-mode breakdown

### `functional_mismatch` (6 cells)

The model produced syntactically valid SystemVerilog matching the JSON schema, simulation ran, but mismatch_cnt > 0. RTLEditor rounds executed but did not converge. This is the same failure mode dominant in T13 → resolved in T14 for vanilla 7B; codev-7B simply produces lower-quality candidates. Example, Prob001_zero (spec asks for `assign zero=0;`):

```
"<module>TopModule\ninput logic a,b;\noutput logic out;\nlogic [2:0] state, ...
... assign out = a&~b;\nendmodule"
```

The model hallucinated a 3-state FSM for a literal-zero output. Vanilla 7B does not exhibit this on Prob001.

### `unexpected` schema errors (3 cells)

`src/mage/rtl_generator.py:233` parses LLM output through a pydantic `RTLOutputFormat` model. codev-qwen-7B occasionally returns shapes that fail validation:

- **Prob005**: `2 validation errors for RTLOutputFormat — reasoning: Input should be a valid string ... input_value=['The order of the four c...he kmap in input_spec.']` — model returned `reasoning` as a list-of-strings instead of a single string.
- **Prob127, Prob128**: `KeyError: 'module'` raised inside `rtl_generator.parse_*`. The model's JSON omitted or renamed the `module` key.

This means the fine-tune's instruction-following on JSON schemas is weaker than the base `qwen2.5-coder:7b`. T14's failure-type plumbing correctly classifies these as `unexpected` (not `functional_mismatch`), so they are visible at the dashboard layer without manual log forensics.

### `none` (1 cell)

Prob003_step_one — LLM produced correct `assign step=1'b1;` and tb mismatch_cnt=0 on the first generated candidate. RTLEditor never invoked. 4 seconds total.

## Comparison to T14 baseline

| Metric | codev-qwen-7B (this run) | vanilla qwen2.5-coder:7b (T14 verify) |
|---|---|---|
| PASS / attempted | 1 / 10 | ≥5 / 6 (run cut at 25-min stop on Prob121) |
| `unexpected` failures | 3 | 0 |
| Wall time / cell (avg) | ~1:30 | ~variable; harder cells reached Step 5 |
| Pipeline-asserts | 0 | 0 |
| Schema-conformance issues | 3/10 | 0 |

codev-qwen-7B is **strictly worse** than the base model on this pipeline for both metrics that matter: end-to-end pass rate and JSON-schema obedience.

## Why this matters for Faz 1 planning

1. **Model selection is not an "any-7B works"**: even within the qwen2.5-coder family, an instruction-tuned fine-tune broke the response-format contract that the pipeline relies on. Future LLM swaps need a smoke check that exercises `rtl_generator`'s pydantic parse path before a full verify.
2. **T14's failure-type sidecar paid off immediately**: without it, the 3 schema errors would have been counted as "FAIL" indistinguishably from the 6 functional mismatches, and the actionable signal (this fine-tune emits invalid JSON shapes) would have been buried in the logs. The dashboard now separates them.
3. **No code change is suggested**. The pipeline is doing exactly what it should — surface the bad LLM as a bad LLM, with the right failure category. The decision is at the model-selection layer, not the pipeline layer.

## Artifacts

- Output dir: `output_codev_qwen_7b_verify_0/` (per-cell `rtl.sv`, `tb.sv`, `failure_info.json`, `sim_review_output.json`, `properly_finished.tag` for 7/10 cells)
- Log dir: `log_codev_qwen_7b_verify_0/` (per-cell agent logs incl. `mage.rtl_generator.log` for the schema-error cells)
- Stdout: `/tmp/codev_qwen_verify.log` (truncated to most recent run)

## Reproducibility

The two scratch runners that produced this report (`tests/test_codev_qwen_smoke.py`, `tests/test_codev_qwen_verify.py`) are removed in the same commit per the T11/T12/T13/T14 precedent. To re-run, copy `tests/test_top_agent_ollama.py` and override `model`, `filter_instance`, `run_identifier`, and add `bypass_tb_gen=True, golden_tb_format=True` to `args_dict`.

## Recommendation

Do **not** adopt `codev-qwen2.5-7b:latest` as the open-LLM default. Stay on `qwen2.5-coder:7b` (vanilla) for the 7B tier and `qwen2.5-coder:32b` for the 32B tier as established by T14.
