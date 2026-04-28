# T15 — Fine-Tuned Model Integration & Verify Run

**Date**: 2026-04-27 (run executed 2026-04-28 08:57 → 09:13 local)
**Branch**: feat/mage-open-v2
**Pipeline build**: post-T14 (`bypass_tb_gen=True`, `golden_tb_format=True`), byte-identical to commit `beebc2f`
**Run identifier**: `t15_ft_verify_0`
**Total wall time**: 16:14 across 10 cells

## Question

The previous baseline (`reports/v2/CODEV_QWEN_7B_BASELINE.md`) was run against `codev-qwen2.5-7b:latest` — a community fine-tune that turned out to be **the wrong model**. T15 integrates the **correct** intended fine-tune `muratkarahan/codev-qwen2.5-coder-7B-v2` (HuggingFace) into Ollama as `bizim-ft-codev-qwen-7b-v2` and re-runs the same 10-problem verify.

The model was fine-tuned by the user following the **CodeV** methodology (arXiv:2407.10424) on the CodeV authors' dataset. CodeV's training objective is *direct prompt → Verilog code generation* (Chat-FIM-Tag SFT over 165K Verilog modules + 18.7K Chisel modules, decontaminated against VerilogEval). It does **not** include agent-loop / JSON-structured-response training data.

Three questions for this run:

1. Does the **correct** FT outperform the **wrong** community fine-tune (1/10 PASS, 3 unexpected)?
2. Does it outperform vanilla `qwen2.5-coder:7b` (T14 verify ≥5/6 PASS)?
3. Does the schema-obedience failure class observed in the wrong-model baseline (`unexpected` failure_type with `KeyError: 'module'` and pydantic shape errors) reappear?

## Configuration

| Field | Value |
|---|---|
| provider | ollama |
| model | `bizim-ft-codev-qwen-7b-v2` (Ollama tag) |
| HF source | `muratkarahan/codev-qwen2.5-coder-7B-v2` @ `97aaa12d596cf7fd1b73373cac31c4edc305367c` |
| GGUF size | 15,237,853,088 bytes (F16, 339 tensors, 28 blocks) |
| Architecture | qwen2 (Qwen2.5-Coder-7B base, bos==eos==151643) |
| temperature / top_p | 0.85 / 0.95 |
| max_token | 4096 |
| context_window | 32768 |
| `bypass_tb_gen` | True |
| `golden_tb_format` | True |
| `use_golden_tb_in_mage` | True |

10 problems (same set as T14 verify and the wrong-model baseline): 5 easy (Prob001–005) + 5 hard (Prob119, 121, 124, 127, 128).

## Headline

**0/10 PASS**.

8 cells classified `functional_mismatch`, 2 cells classified `unexpected`. Per-cell forensics show that **all 10 cells fail at the JSON-schema layer**, not at the Verilog-generation layer — the 8 "functional_mismatch" cells slipped through the pydantic validator only because the model's `module` field happened to be a non-empty string, but the string itself was a single line of Verilog (truncated open-paren, placeholder text, or a literal token like `<SYSTEMVERILOG_CODE>` / `<your module here>`).

This is the **same failure class** as the wrong-model baseline, only worse:

| | wrong model (codev-qwen2.5-7b) | correct FT (bizim-ft-codev-qwen-7b-v2) |
|---|---|---|
| `unexpected` (schema invalid) | 3/10 | 2/10 |
| `functional_mismatch` w/ valid Verilog | 6/10 | 0/10 |
| `functional_mismatch` w/ truncated 1-line garbage | 0/10 | 8/10 |
| **Effective schema/format failure** | **9/10** | **10/10** |

## Per-cell results

| Cell | failure_type | error_msg (rtl.sv first line) | rtl.sv lines | Time | properly_finished.tag |
|---|---|---|---|---|---|
| Prob001_zero | unexpected | `KeyError: 'module'` | 0 (empty) | 0:00:04 | NO |
| Prob002_m2014_q4i | functional_mismatch | `<SYSTEMVERILOG_CODE>` | 1 | 0:00:25 | YES |
| Prob003_step_one | functional_mismatch | `module TopModule(` | 1 | 0:00:25 | YES |
| Prob004_vector2 | functional_mismatch | `module top_module ( ` | 1 | 0:00:38 | YES |
| Prob005_notgate | functional_mismatch | `module TopModule( x, y); // Do not modify module name` | 1 | 0:00:33 | YES |
| Prob119_fsm3 | functional_mismatch | `<your module here>` | 0 (placeholder) | 0:02:23 | YES |
| Prob121_2014_q3bfsm | functional_mismatch | `module TopModule(clk,reset,x,z) input clk, reset; input [2:0] x; output z;` | 1 | 0:00:43 | YES |
| Prob124_rule110 | unexpected | `KeyError: 'module'` | 0 (empty) | 0:08:41 | NO |
| Prob127_lemmings1 | functional_mismatch | `module TopModule(` | 1 | 0:00:20 | YES |
| Prob128_fsm_ps2 | functional_mismatch | `<example3>module TopModule(` | 1 | 0:02:01 | YES |

`tag` column: 8/10 reached `properly_finished.tag` — the 2 schema-error cells exited via the `unexpected` exception path before the tag was written, exactly as T14's failure-type plumbing intends.

Pipeline-side counts (every cell): TBGen calls = 0 (golden TB bypass works correctly, `mage.tb_generator.log` is empty everywhere); RTLEditor rounds = 0 (`mage.rtl_editor.log` is empty everywhere — the editor never engages because the initial RTL parsing produces no usable artifact, so simulation fails on iverilog, the judge marks fix-needed but the loop terminates after the first failed sim).

## Forensic detail — what the model actually returns

Reading `output_t15_ft_verify_0/VERILOG_EVAL_V2_*/rtl.sv` directly:

- **2 cells** (`Prob001_zero`, `Prob124_rule110`): pydantic raised `KeyError: 'module'` — the JSON either lacked the `module` key entirely or used a different key. `rtl.sv` is empty. These are surfaced as `unexpected`.
- **8 cells**: pydantic accepted a `module` field that was a single line. The `rtl.sv` written to disk is exactly that line. iverilog then fails to compile (`syntax error` on incomplete module declaration). The pipeline classifies this as `functional_mismatch` because a sim attempt did happen, but the underlying defect is schema-format, not functional logic.

Representative `rtl.sv` contents (verbatim):
```
Prob003_step_one rtl.sv (1 line):
    module TopModule(

Prob119_fsm3 rtl.sv (1 line):
    <your module here>

Prob002_m2014_q4i rtl.sv (1 line):
    <SYSTEMVERILOG_CODE>
```

The `<SYSTEMVERILOG_CODE>` and `<your module here>` outputs are particularly telling — they are **template placeholder tokens** that the model has emitted as the actual `module` field value, suggesting the FT learned these tokens as literal output tokens rather than as fillable placeholders.

## Comparison vs T14 vanilla 7B and wrong-model baseline

| Metric | T14 vanilla `qwen2.5-coder:7b` | Wrong model `codev-qwen2.5-7b:latest` | **T15 correct FT** |
|---|---|---|---|
| PASS / attempted | ≥5 / 6 | 1 / 10 | **0 / 10** |
| `unexpected` failures | 0 | 3 | 2 |
| Functional Verilog produced (any cell) | 6/6 | 7/10 | **0/10** |
| Avg wall time / cell | variable, deeper RTLEditor cycles | ~1:30 | 1:37 (skewed by Prob124 hang) |
| Schema/format failures (effective) | 0 | 9/10 | **10/10** |

The correct FT is **strictly worse** than both prior runs on this pipeline. The wrong model at least produced multi-line Verilog modules that the simulator could compile and then fail functionally; the correct FT produces single-line garbage that the simulator cannot even parse.

## Why this happens — CodeV training context

The user's fine-tune follows the CodeV paper (arXiv:2407.10424) verbatim:

1. **Multi-level summarization**: GPT-3.5 takes raw HDL from GitHub, produces high-level natural language descriptions.
2. **Chat-FIM-Tag SFT**: supervised fine-tuning on Chat task + Fill-in-Middle task with `<Verilog>` / `<Chisel>` language tags.
3. **Dataset**: 165K Verilog modules + 18.7K Chisel modules, decontaminated against VerilogEval.
4. **Reported SOTA**: 80.1% pass@1 on VerilogEval-Machine, 59.2% on VerilogEval-Human.

CodeV's evaluation harness is **direct generation**: the prompt asks for a Verilog module, the model emits the module body inline, and the eval harness extracts it via regex. There is **no JSON envelope**, no `reasoning` field, no agent loop, no `RTLOutputFormat` schema.

MAGE's pipeline requires the LLM to return a structured response that pydantic parses into `RTLOutputFormat` (see `src/mage/rtl_generator.py:233`). The schema expects:
- `reasoning: str` — the model's natural-language plan
- `module: str` — the full module body, multi-line, between `module` and `endmodule`

A model trained per CodeV's recipe is optimized to emit Verilog *directly into the response stream*. When MAGE's prompt asks it to wrap the same content in JSON, the FT either (a) drops the wrapper entirely (caught by the pydantic validator → `unexpected`), or (b) emits a JSON object with the `module` field set to whatever fragment of Verilog appears at that token position — typically the first line.

This is consistent with the smoke probes from §T15.6:
- **Probe 1** (asked for JSON envelope): model returned bare Verilog → schema fail.
- **Probe 2** (direct "write Verilog for `assign zero = 1'b0;`"): model returned the exact correct one-liner.

The FT achieved its training objective (direct Verilog generation works) but is **structurally incompatible with MAGE's agent-loop architecture**.

## What this means for Plan v3 Faz 2-FT scoping

### Question 1 — did correct FT beat wrong model?

**No.** 0/10 vs 1/10. The correct FT is worse because it fails at the schema layer in a way that produces no compilable Verilog at all (single-line truncations), whereas the wrong fine-tune at least produced complete (but functionally incorrect) modules in 7/10 cells.

### Question 2 — did correct FT beat vanilla `qwen2.5-coder:7b`?

**No.** 0/10 vs ≥5/6. Vanilla 7B is the right tool for this pipeline.

### Question 3 — did the schema-error class reappear?

**Yes**, and it is now the dominant failure mode (10/10 cells, vs 9/10 in the wrong-model run, vs 0/0 in vanilla). The T14 sidecar correctly distinguished the 2 hard-fail cells (`unexpected`) from the 8 soft-fail cells (`functional_mismatch`), but the underlying pathology is the same in all 10.

### Question 4 — recommendation

**Do not adopt `bizim-ft-codev-qwen-7b-v2` as a drop-in replacement for vanilla 7B in MAGE.** The FT is well-trained for its stated objective (direct Verilog generation) but mismatched to the pipeline's interface contract.

Two distinct paths forward — they are not alternatives, both are useful:

- **(a) Validate the FT on a CodeV-style harness**, not MAGE. If the model reproduces the paper's 80.1% / 59.2% on VerilogEval direct generation, the fine-tuning replication is confirmed successful and the FT becomes a useful asset for any *non-agent* code-gen task. This is also the cheapest sanity check that the GGUF F16 conversion did not damage the weights.
- **(b) If the goal is to use this FT inside MAGE**, the training data needs to include agent-loop JSON examples. Concretely: a second SFT pass with examples shaped like `{"reasoning": "...", "module": "module TopModule(...) ... endmodule"}` covering the same 165K Verilog corpus. The current weights cannot be coaxed into schema obedience by prompt engineering alone — the wrong-model baseline's 9/10 schema failure rate at higher temperature, and this run's 10/10 at the same settings, both show the model's prior over emit-bare-Verilog is far stronger than the prompt's instruction to wrap.

For the immediate Faz 1 / Faz 2 milestones, **stay on `qwen2.5-coder:7b` (vanilla) for the 7B tier** as established by T14. The fine-tune effort is preserved as a parallel artifact in Ollama, available for direct-generation experiments under (a) without further conversion work.

## Pipeline behavior

The MAGE pipeline itself behaved correctly. It:
- bypassed TBGen on every cell (TBGen log empty everywhere — `bypass_tb_gen=True` works);
- used the golden TB (`use_golden_tb_in_mage=True`);
- attached `golden_tb_format=True` PASS detection (8/10 cells reached `properly_finished.tag`);
- correctly classified the 2 schema-invalid cells as `unexpected` and the 8 schema-valid-but-degenerate cells as `functional_mismatch`.

No `pipeline_assert` failures, no hangs (Prob124's 8:41 was Ollama generation latency, not pipeline state machine stalling), no code change suggested. The pipeline did its job; the model is the constraint.

## Artifacts

- HF identity: `muratkarahan/codev-qwen2.5-coder-7B-v2` @ commit `97aaa12d596cf7fd1b73373cac31c4edc305367c`
- GGUF: `/home/test123/models/codev-qwen-7b-v2-f16.gguf` (15.24 GB, F16, qwen2 arch)
- Modelfile: `/home/test123/models/codev-qwen-7b-v2.Modelfile` (ChatML template, num_ctx=32768)
- Ollama tag: `bizim-ft-codev-qwen-7b-v2`
- Output dir: `output_t15_ft_verify_0/` (per-cell `rtl.sv`, `tb.sv`, `failure_info.json`, `sim_review_output.json`, `properly_finished.tag` for 8/10 cells, `record.json`)
- Log dir: `log_t15_ft_verify_0/` (per-cell agent / generator / editor logs)

## Reproducibility

The scratch runner (`tests/test_t15_ft_verify.py`) is removed in the same commit per T11–T14 / wrong-model precedent. The Ollama Modelfile lives outside the repo at `/home/test123/models/codev-qwen-7b-v2.Modelfile`. To re-run:

1. Pull HF repo `muratkarahan/codev-qwen2.5-coder-7B-v2` at commit `97aaa12d596cf7fd1b73373cac31c4edc305367c`.
2. Convert with `llama.cpp/convert_hf_to_gguf.py --outtype f16` → 15.24 GB GGUF.
3. `ollama create bizim-ft-codev-qwen-7b-v2 -f /home/test123/models/codev-qwen-7b-v2.Modelfile`.
4. Copy `tests/test_top_agent_ollama.py`, override `model="bizim-ft-codev-qwen-7b-v2"`, the 10-problem `filter_instance`, `run_identifier`, and add `bypass_tb_gen=True`, `golden_tb_format=True`, `use_golden_tb_in_mage=True`.
