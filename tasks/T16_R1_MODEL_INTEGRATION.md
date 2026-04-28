# Task T16: R1-RL Fine-Tuned Model Integration & Verify Run

**Status:** PENDING
**Priority:** HIGH — second FT-vs-base experiment, this time on an R1-style RL-trained model
**Depends on:** T15 merged to `feat/mage-open-v2` (post-T14 pipeline + T15 precedent)
**Reference:** Plan v3 §5 model registry; T15_FT_VERIFY.md (CodeV-methodology FT, 0/10 PASS)

---

## Context

T15 integrated `muratkarahan/codev-qwen2.5-coder-7B-v2` (a CodeV-methodology
SFT fine-tune over the **base** Qwen2.5-Coder-7B) and produced 0/10 PASS on
the 10-problem verify. Root cause: CodeV's training objective is direct
prompt → Verilog generation; MAGE's pipeline requires JSON-structured agent
responses parsed by pydantic `RTLOutputFormat`.

T16 repeats the same flow on a **structurally different** Verilog FT to
test whether a different training methodology (RL + Instruct base) does
better with the agent-loop interface contract. The candidate is:

> **HuggingFace repo: [`zhuyaoyu/CodeV-R1-RL-Qwen-7B`](https://huggingface.co/zhuyaoyu/CodeV-R1-RL-Qwen-7B)**
>
> - 4-shard safetensors (BF16)
> - Architecture: `Qwen2ForCausalLM`
> - `eos_token_id = 151645`, `pad_token_id = 151643` → fine-tuned over the
>   **Instruct** variant `Qwen2.5-Coder-7B-Instruct`, not the base (contrast
>   with T15's base FT)
> - Training method: distillation + DAPO RL with verification reward (RLVR)
> - Native chat template uses `<think>...</think><answer>` reasoning
>   structure with ```` ```verilog ``` ```` code fences inside the answer
> - Reported benchmarks: VerilogEval v2 spec-to-RTL **68.8%** pass@1,
>   code-completion 69.9%; RTLLM v1.1 72.9%
> - Main commit at task time: `286cf433f596f1b8525529c1163eb81c19425c22`

T16 has two halves:
1. **Bring the R1-RL model into Ollama** (download → convert → import).
2. **Re-run the post-T14 verify on this model**, producing a 4-way
   side-by-side: T14 vanilla 7B / T15 SFT FT / T16 RL FT / wrong-model
   baseline.

Pipeline code is **frozen** at T14 head. No source-file edits in T16.

---

## Hard constraints

1. **Use the exact HuggingFace repo above** at commit
   `286cf433f596f1b8525529c1163eb81c19425c22`. If main has advanced past
   this commit by the time T16 runs, pin to this hash explicitly via
   `--revision` and note the divergence in the report.
2. **No code changes to `src/mage/`.** Same precedent as T15.
3. **Output Ollama name MUST be `bizim-codev-r1-rl-qwen-7b`.** No `:latest`
   suffix in the Modelfile. The runner's `args_dict["model"]` reads
   literally `bizim-codev-r1-rl-qwen-7b`.
4. **Modelfile uses ChatML template, NOT the native `<think>/<answer>`
   template.** Rationale: T15 used ChatML for the SFT FT; for a clean
   T15-vs-T16 comparison the Modelfile-side prompt envelope must be
   identical. The model's RL training will still bias toward emitting
   `<think>` tokens — that bias is the **point** of the experiment.
5. **Same 10 problems as T14/T15.** No filter changes:
   `^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|Prob005_notgate|Prob119_fsm3|Prob121_2014_q3bfsm|Prob124_rule110|Prob127_lemmings1|Prob128_fsm_ps2)$`
6. **Same generation parameters as T15:** `temperature=0.85`, `top_p=0.95`,
   `max_token=4096`, `num_ctx=32768`. Sampling owned by the runner; the
   Modelfile only carries stop tokens + context.
7. **Scratch runner deleted in same commit.** `tests/test_t16_r1_verify.py`
   does not survive the commit, per T11–T15 precedent.

---

## Sub-tasks

### §T16.1 — HF identity check

- Resolve `main` to a commit SHA on `huggingface.co/api/models/zhuyaoyu/CodeV-R1-RL-Qwen-7B/revision/main`.
- Verify SHA matches `286cf433f596f1b8525529c1163eb81c19425c22`. If
  different, record both and pin `--revision` to the spec hash.
- Pull `config.json`, `tokenizer_config.json`, `tokenizer.json`,
  `special_tokens_map.json`, `generation_config.json` first (light-weight)
  and confirm:
  - `architectures = ["Qwen2ForCausalLM"]`
  - `eos_token_id == 151645` (Instruct, not base)
  - `pad_token_id == 151643`
  - `vocab_size == 152064`
  - `hidden_size == 3584`, `num_hidden_layers == 28`
  - sha256 of `config.json` recorded for reproducibility

### §T16.2 — Full safetensors download

- `huggingface-cli download` with `--revision <commit>` and
  `HF_HUB_ENABLE_HF_TRANSFER=1` for parallel download.
- Target dir: `/home/test123/models/codev-r1-rl-qwen-7b-source/`.
- Acceptance: 4 shard files + index + tokenizer files present, total
  ~15 GB BF16.

### §T16.3 — GGUF F16 conversion

- `python3 /home/test123/llama.cpp/convert_hf_to_gguf.py
  /home/test123/models/codev-r1-rl-qwen-7b-source/
  --outtype f16 --outfile /home/test123/models/codev-r1-rl-qwen-7b-f16.gguf`
- Acceptance: 14–16 GB GGUF, `general.architecture = qwen2`, ~7.6B params,
  339 tensors, 28 blocks, embedding 3584, ff 18944, context 32768.

### §T16.4 — Ollama Modelfile + import

- File: `/home/test123/models/codev-r1-rl-qwen-7b.Modelfile`
- Contents (mirror T15's Modelfile structure):
  ```
  FROM ./codev-r1-rl-qwen-7b-f16.gguf
  TEMPLATE """{{- if .Tools }}<|im_start|>system
  ... [ChatML template, identical to T15's] ...
  <|im_start|>assistant
  """
  PARAMETER stop "<|endoftext|>"
  PARAMETER stop "<|im_end|>"
  PARAMETER num_ctx 32768
  ```
- No sampling parameters (owned by runner).
- `ollama create bizim-codev-r1-rl-qwen-7b -f /home/test123/models/codev-r1-rl-qwen-7b.Modelfile`
- Acceptance: `ollama list` shows `bizim-codev-r1-rl-qwen-7b:latest` at ~15 GB.

### §T16.5 — Smoke probes (2 probes, mirror T15.6)

Strip ANSI escapes from `ollama run` output before recording. Both probes
use `temperature=0.85, top_p=0.95`.

- **Probe 1** (JSON envelope): same prompt as T15 — request a JSON
  response with `reasoning` and `module` fields for a trivial spec.
  Record verbatim output. Pass = valid JSON parseable by pydantic
  `RTLOutputFormat`.
- **Probe 2** (direct Verilog): same as T15 — "Write a Verilog module
  named TopModule with output `zero` that always outputs LOW." Pass = any
  syntactically correct module that simulates to `out=0`.

Probes are diagnostic, not gating. Failures inform §T16.10 analysis.

### §T16.6 — Scratch runner

- Path: `/home/test123/MAGE/tests/test_t16_r1_verify.py`
- Contents (literal `args_dict`):
  ```python
  args_dict = {
      "provider": "ollama",
      "model": "bizim-codev-r1-rl-qwen-7b",
      "filter_instance": (
          "^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|"
          "Prob005_notgate|Prob119_fsm3|Prob121_2014_q3bfsm|Prob124_rule110|"
          "Prob127_lemmings1|Prob128_fsm_ps2)$"
      ),
      "type_benchmark": "verilog_eval_v2",
      "path_benchmark": "./verilog-eval",
      "run_identifier": "t16_r1_verify",
      "n": 1,
      "temperature": 0.85, "top_p": 0.95, "max_token": 4096,
      "use_golden_tb_in_mage": True,
      "bypass_tb_gen": True,
      "golden_tb_format": True,
      "key_cfg_path": None,
  }
  ```
- Identical structure to `tests/test_t15_ft_verify.py`.

### §T16.7 — Verify run

- `cd /home/test123/MAGE && python3 tests/test_t16_r1_verify.py`
- Expected wall time: 15–60 minutes (R1 reasoning may produce longer
  responses than T15; if the run exceeds 90 minutes, kill and document
  hang per T13/T14 precedent).
- Outputs: `output_t16_r1_verify_0/`, `log_t16_r1_verify_0/`.

### §T16.8 — Forensic data collection

Per-cell table with columns:
- failure_type (`functional_mismatch` / `unexpected` / `none`)
- error_msg (`record.json[record_per_run][cell].error_msg`)
- wall time
- properly_finished.tag presence (YES/NO)
- rtl.sv line count + first line (verbatim)
- TBGen log line count (must be 0; sanity check)
- RTLEditor log line count (rounds taken)
- For `unexpected` cells: extract pydantic error from
  `mage.rtl_generator.log` if present.

Special check for R1-style behavior: count cells where rtl.sv contains
literal `<think>` or `<answer>` tokens. This is the analog of T15's
`<SYSTEMVERILOG_CODE>` / `<your module here>` placeholder leakage.

### §T16.9 — 4-way comparison table

Single table comparing this run, T14 vanilla 7B, T15 SFT FT, and the
wrong-model baseline. Columns: PASS / unexpected / functional_mismatch
with valid Verilog / functional_mismatch with truncated garbage / effective
schema-format failure rate.

### §T16.10 — PM-facing analysis (4 questions)

1. Did the R1-RL FT outperform the T15 SFT FT (0/10)? If yes by how much.
2. Did it outperform vanilla `qwen2.5-coder:7b` (≥5/6 on T14)?
3. Did the schema-error class change shape? Specifically: do `<think>`
   tokens leak into the `module` field, or does the RL training generalize
   to honor JSON envelope despite the `<think>` bias?
4. Recommendation for Plan v3 Faz 2-FT scoping. Three possible verdicts:
   (a) adopt R1-RL as 7B-tier replacement, (b) keep vanilla 7B, validate
   R1-RL on direct-generation harness only, (c) re-train with agent-loop
   JSON examples.

### §T16.11 — Report

- File: `reports/v2/T16_R1_VERIFY.md`
- Structure mirrors T15: question, config, headline, per-cell table,
  forensic detail, 4-way comparison, RL-context section (analogous to
  T15's CodeV-paper section), recommendation.
- Length budget: 250–400 lines, similar to T15.

### §T16.12 — Commit + push

- Commit message: `[T16] Integrate zhuyaoyu/CodeV-R1-RL-Qwen-7B as bizim-codev-r1-rl-qwen-7b; 10-problem verify`
- Files: `reports/v2/T16_R1_VERIFY.md`, `tasks/T16_R1_MODEL_INTEGRATION.md`
- Delete `tests/test_t16_r1_verify.py` in same commit
- Push: `feat/mage-open-v2` via `ssh://git@ssh.github.com:443/...` if port 22 hangs
- Author/committer email: `157647073+DerinVural@users.noreply.github.com`
  (per email-privacy precedent established in T15)

---

## Acceptance

- T16 commit on `feat/mage-open-v2` remote contains report + spec, no
  scratch runner.
- 10-cell verify completed without pipeline_assert failures.
- Report explicitly answers all 4 §T16.10 questions.
- 4-way comparison table is reproducible from artifacts in
  `output_t16_r1_verify_0/` and `record.json`.

---

## Out of scope

- Direct-generation harness implementation (separate task if §T16.10
  recommendation (a)/(b) requires it).
- Re-fine-tuning or training-data work (separate task tree).
- Any pipeline behavior change. T16 is purely model-substitution.
