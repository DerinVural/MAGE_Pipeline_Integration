# Task T15: Fine-Tuned Model Integration & Verify Run

**Status:** PENDING
**Priority:** HIGH — first task that exercises the project's original FT-vs-base hypothesis on a working pipeline
**Depends on:** T14 merged to `feat/mage-open-v2` (post-T14 pipeline is the substrate)
**Reference:** Plan v3 §5 model registry; previous CODEV_QWEN_7B_BASELINE.md (the wrong-model run)

---

## Context

The previous in-conversation run of `codev-qwen2.5-7b:latest` (Ollama tag,
~15.2 GB F16) produced 1/10 PASS on the 10-problem set and was attributed
to a community fine-tune. **That was the wrong model.** The intended fine-tune
for this project is:

> **HuggingFace repo: [`muratkarahan/codev-qwen2.5-coder-7B-v2`](https://huggingface.co/muratkarahan/codev-qwen2.5-coder-7B-v2)**
>
> - 30.5 GB FP32 safetensors (7 shards)
> - Architecture: `Qwen2ForCausalLM`
> - `bos_token_id == eos_token_id == 151643` → fine-tuned over the **base**
>   `Qwen2.5-Coder-7B`, not the Instruct variant
> - Includes `chat_template.jinja` and a complete tokenizer set
>   (`vocab.json`, `merges.txt`, `added_tokens.json`,
>   `special_tokens_map.json`, `tokenizer.json`, `tokenizer_config.json`)
> - Last updated 11 days before this task
> - Model card is auto-generated boilerplate (no training details disclosed)

T15 has two halves:
1. **Bring the correct model into Ollama** (download → convert → quantize → import).
2. **Re-run the post-T14 verify on this correct model**, producing a clean
   side-by-side with the T14 vanilla baseline.

Pipeline code is **frozen** at T14 head. No source-file edits in T15.

---

## Hard constraints (read before starting)

1. **Use the exact HuggingFace repo named above.** Do not pull a different
   "codev-qwen" model from Ollama's registry. The previous baseline failed
   precisely because the wrong model was used. The Ollama tag for the
   correct one does not exist yet — T15 creates it.
2. **No code changes to `src/mage/`.** This task is a model-substitution
   experiment on the post-T14 pipeline. If the pipeline behaves badly with
   the new model, document it and stop — do NOT patch.
3. **Output Ollama name MUST be `bizim-ft-codev-qwen-7b-v2`.** No `:latest`
   suffix in the Modelfile, no aliasing, no abbreviation. The runner's
   model string in `args_dict` must read literally `bizim-ft-codev-qwen-7b-v2`
   (Ollama will resolve it as `:latest` automatically). This name is the
   only acceptable identifier for this model in this project.
4. **Quantization target is F16 (lossless).** Not Q4_K_M, not Q8_0. The
   GGUF must preserve FP16 weights end-to-end. This is to avoid attributing
   FT performance differences to quantization noise. Disk cost (~15 GB) is
   accepted.
5. **The 10-problem set is identical to T14 verify.** 5 easy
   (Prob001_zero, Prob002_m2014_q4i, Prob003_step_one, Prob004_vector2,
   Prob005_notgate) + 5 hard (Prob119_fsm3, Prob121_2014_q3bfsm,
   Prob124_rule110, Prob127_lemmings1, Prob128_fsm_ps2). Same pipeline
   flags as T14 verify: `bypass_tb_gen=True`, `golden_tb_format=True`,
   `use_golden_tb_in_mage=True`, `temperature=0.85`, `top_p=0.95`,
   `max_token=4096`. Sequential execution.
6. **Per-problem wall time cap: 25 minutes** (same as T14 verify on
   Prob121). If a cell exceeds this, kill it and mark as `timeout`. Do
   NOT extend the budget.

---

## Scope

### T15.1 — Verify the source model identity

Before any download, re-confirm in the report:

- HuggingFace repo URL.
- The hash of `config.json` (sha256). Read from the HuggingFace API
  metadata, do not rely on the file size alone (a 30.5 GB safetensors
  set could theoretically come from elsewhere).
- The first 8 hex chars of the latest commit on `main`
  (currently expected: `97aaa12d…` — verify before fetching).
- If any of the above don't match what's documented here, **STOP and file
  a BLOCKED report**. The model identity question is the whole point of
  T15.

### T15.2 — Download

Use `huggingface-cli` (already standard tooling). Download the full repo,
including all 7 safetensors shards, the index file, the chat template,
and all tokenizer files. Target directory:
`/home/USER/models/codev-qwen-7b-v2-source/` (or equivalent — pick a
path that survives reboots and has ≥ 60 GB free for the safetensors +
intermediate GGUF).

Do NOT use a shallow clone or partial download. The MD5/sha sums
provided by the HF Xet store should be verified for every shard.

### T15.3 — Convert safetensors → GGUF (F16)

Use `llama.cpp/convert_hf_to_gguf.py`. Command shape:

```bash
python llama.cpp/convert_hf_to_gguf.py \
    /home/USER/models/codev-qwen-7b-v2-source \
    --outtype f16 \
    --outfile /home/USER/models/codev-qwen-7b-v2-f16.gguf
```

Expected output: ~15 GB single GGUF file. Confirm:
- File exists
- File size between 14 and 16 GB
- `gguf-py/scripts/gguf_dump.py --no-tensors codev-qwen-7b-v2-f16.gguf`
  succeeds and reports `general.architecture = qwen2`,
  `general.parameter_count` ≈ 7.6 × 10⁹

### T15.4 — Modelfile authoring

Create `/home/USER/models/codev-qwen-7b-v2.Modelfile` with these
requirements:

1. `FROM ./codev-qwen-7b-v2-f16.gguf` — relative path to the F16 GGUF.
2. `TEMPLATE` block — the contents of `chat_template.jinja` from the HF
   repo, escaped for Modelfile syntax. Do NOT substitute the upstream
   Qwen2.5-Coder-Instruct template; this model has its own.
3. `PARAMETER stop "<|endoftext|>"` — matches `eos_token_id=151643`
   established in the model's tokenizer config.
4. `PARAMETER stop "<|im_end|>"` — vocabulary contains it (151645);
   harmless to add as a stop even if eos_token differs, prevents runaway
   generation in chat-format prompts.
5. `PARAMETER num_ctx 32768` — matches the `model_max_length` in the
   model's tokenizer config.

Do not set temperature, top_p, or other sampling parameters in the
Modelfile — those are owned by the runner via T11's per-agent
sampling. Modelfile-level sampling would override our per-agent logic
and is forbidden.

### T15.5 — Ollama import

```bash
ollama create bizim-ft-codev-qwen-7b-v2 \
    -f /home/USER/models/codev-qwen-7b-v2.Modelfile
```

Verify:

```bash
ollama list | grep bizim-ft-codev-qwen-7b-v2
```

Should return one line with model size ~15 GB.

### T15.6 — Sanity check (before any 10-problem run)

Run a 30-second smoke against the new Ollama tag, OUTSIDE the MAGE
pipeline. Two probes:

**Probe 1: JSON schema obedience.**

```bash
ollama run bizim-ft-codev-qwen-7b-v2 \
  'Reply with valid JSON only: {"x": 1, "msg": "hello"}. No prose.'
```

Expected: a string parseable as JSON with both keys present. If the
model emits a list-of-strings for `msg`, omits a key, or wraps in
markdown fences, document the response verbatim and continue (this
mirrors the failure class observed on Prob005/127/128 in the wrong-model
baseline; we want to know if it's a fine-tune family trait or specific
to the previous model).

**Probe 2: Verilog completion.**

```bash
ollama run bizim-ft-codev-qwen-7b-v2 \
  'Write a one-line Verilog module that assigns the constant 0 to an output named zero. Output only the module.'
```

Expected: a `module ... endmodule` block, ideally with `assign zero = 1'b0;`
or equivalent. If the model produces an FSM or unrelated structure, log
the verbatim output. (This is the trivial Prob001 case where the
previous wrong-model produced a 3-state FSM; T15 wants to know if the
correct model also exhibits this.)

Both probes go in the report. They are NOT acceptance gates — even if
both fail, T15 proceeds to the full 10-problem run, because the whole
point is to measure this model on the pipeline.

### T15.7 — 10-problem verify run

Mirror the T14 verify pattern. Reuse `tests/test_top_agent_ollama.py`
(or create a thin wrapper named `tests/test_t15_ft_verify.py`) with:

```python
args_dict = {
    "model": "bizim-ft-codev-qwen-7b-v2",
    "provider": "ollama",
    "temperature": 0.85,
    "top_p": 0.95,
    "max_token": 4096,
    "use_golden_tb_in_mage": True,
    "bypass_tb_gen": True,
    "golden_tb_format": True,
    # ... rest matches T14 verify
}
filter_instance = (
    "^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|"
    "Prob005_notgate|Prob119_fsm3|Prob121_2014_q3bfsm|Prob124_rule110|"
    "Prob127_lemmings1|Prob128_fsm_ps2)$"
)
run_identifier = "t15_ft_verify"
```

Sequential execution. Per-cell wall time cap: 25 min.

If the wrapper file is created, **delete it in the same commit** per
the T11/T12/T13/T14/CODEV_QWEN_7B_BASELINE precedent (no scratch
runners committed to the repo).

### T15.8 — Forensic data collection

For each of the 10 cells, capture (mirror T14 verify report format):

| Field | Source |
|---|---|
| Result (PASS/FAIL/TIMEOUT) | `output_t15_ft_verify_0/<task>/record.json` |
| `failure_type` | `output_t15_ft_verify_0/<task>/failure_info.json` |
| `error_msg` | same |
| Wall time | record.json |
| `properly_finished.tag` exists? | filesystem |
| `tb_need_fix` at exit | grep agent log |
| `rtl_need_fix` at exit | same |
| `sim_mismatch_cnt` at exit | sim_review_output.json |
| TBGen LLM call count | should be 0 (bypass mode) |
| Candidate generation rounds | grep mage.rtl_generator.log |
| RTLEditor rounds | grep mage.rtl_editor.log |

### T15.9 — Side-by-side comparison

The headline table compares three columns per problem:

| Cell | T14 vanilla 7B | wrong-model baseline | T15 correct FT |
|---|---|---|---|
| Prob001 | PASS | FAIL (functional_mismatch) | ? |
| ... | | | |

For metrics that overlap with T14 verify (which only ran 6/10 cells on
7B because of the Prob121 timeout), document the gap honestly — don't
fabricate a comparison cell.

### T15.10 — PM-facing analysis

The report's final section answers:

1. **Did the correct FT model perform better than the wrong one?**
   (1/10 was the wrong-model number; what's T15's?)
2. **Did the correct FT model perform better than vanilla 7B?**
   (≥5/6 was T14's number on the overlap.)
3. **Did the schema-error class (`failure_type=unexpected`) appear?**
   If yes, this is a fine-tune-family trait, not specific to the
   previous wrong model. If no, that confirms the previous model was
   genuinely broken.
4. **Recommendation for Plan v3 Faz 2-FT scoping:** does the project
   continue with `muratkarahan/codev-qwen2.5-coder-7B-v2` as the FT
   candidate, or pivot?

---

## Acceptance criteria

- [ ] No `src/mage/` files modified.
- [ ] HuggingFace source identity verified in §T15.1 (URL, latest
      commit hash, model architecture).
- [ ] Source safetensors downloaded to a documented path; total ≈ 30 GB.
- [ ] F16 GGUF produced; size 14-16 GB; `gguf_dump.py` confirms qwen2
      architecture and ≈ 7.6B parameters.
- [ ] Modelfile created with correct TEMPLATE and stop tokens; no
      sampling parameters.
- [ ] Ollama import succeeds; `ollama list` shows
      `bizim-ft-codev-qwen-7b-v2` at ~15 GB.
- [ ] Two pre-pipeline sanity probes (§T15.6) executed and verbatim
      outputs documented.
- [ ] 10-problem verify run completed (or timed out per spec) with
      `run_identifier=t15_ft_verify`.
- [ ] All 10 cells classified per §T15.8.
- [ ] Side-by-side table (§T15.9) populated.
- [ ] Final analysis (§T15.10) addresses all 4 questions with evidence.
- [ ] Scratch runner files (if any were created) deleted in the same
      commit.
- [ ] Commit message: `[T15] Integrate muratkarahan/codev-qwen2.5-coder-7B-v2 as bizim-ft-codev-qwen-7b-v2; 10-problem verify`
- [ ] Report filed: `reports/v2/T15_FT_VERIFY.md`

---

## Stop conditions

File `reports/v2/T15_BLOCKED.md` if:

- The HuggingFace repo identity check fails (different commit hash than
  expected, or model card has been replaced with content contradicting
  the "fine-tune of Qwen2.5-Coder-7B base" assumption).
- llama.cpp conversion errors out on Qwen2 architecture (rare but
  possible if the FT introduced custom layers — config.json should
  rule this out at §T15.1; if it doesn't, that's a finding worth
  reporting).
- Disk runs out during conversion (need ~60 GB free).
- Ollama import errors with a TEMPLATE parsing error (chat template
  may need escaping fixes — describe what was tried).
- The model loads but runs out of GPU memory on the first probe (DGX
  Spark has limits; if F16 doesn't fit, BLOCK and request guidance —
  do NOT silently fall back to a quantization Q level).
- More than 5 of 10 cells time out at the 25-minute cap (suggests the
  FP16 model is throughput-bound on local hardware; report and stop).

---

## Do NOT

- Pull a community fine-tune from Ollama's registry under any name.
  T15's whole purpose is the specific HF repo. The previous wrong-model
  run is the cautionary tale.
- Modify any `src/mage/` file. The pipeline is frozen at T14 head.
- Rename the Ollama tag. It is `bizim-ft-codev-qwen-7b-v2`. Not
  `bizim_ft_codev`, not `codev-v2`, not anything else.
- Substitute Q4_K_M or Q8_0 for F16 to "save space" — F16 is required.
- Reduce the 10-problem set to "save time" — 10 is required.
- Increase the per-cell wall time beyond 25 min to "let it finish" —
  if a cell needs more than 25 min, that is itself a finding.
- Run anything on `qwen2.5-coder:32b` or vanilla `qwen2.5-coder:7b` in
  this task. This is single-model FT verification.
- Apply any prompt or runner tweak observed in the previous wrong-model
  run. T15 measures this model on T14's pipeline as-is.
- Commit scratch runner files. Build, run, delete in the same commit.
- Use F32 weights (the source format on HF). The conversion to F16 is
  required to avoid loading a 30 GB GGUF that wastes memory without
  improving precision over F16 in practice.

---

## Report template

```markdown
# Task T15: FT Model Integration & Verify Run

**Status:** DONE | BLOCKED | PARTIAL
**Branch:** feat/mage-open-v2
**Commits:** <hash>
**Date:** <YYYY-MM-DD>

## Source model identity (§T15.1)

- HuggingFace repo: `muratkarahan/codev-qwen2.5-coder-7B-v2`
- Latest commit on `main`: `<hash> (<date>)`
- config.json sha256: `<hash>`
- Architecture: `Qwen2ForCausalLM`
- `bos_token_id`/`eos_token_id`: 151643/151643 (confirms base-tuned)

## Conversion pipeline

| Step | Output | Size | Status |
|---|---|---|---|
| HuggingFace download | `.../codev-qwen-7b-v2-source/` | 30.5 GB | ✓ |
| GGUF F16 conversion | `.../codev-qwen-7b-v2-f16.gguf` | <X> GB | ✓ |
| gguf_dump verification | architecture=qwen2, params=<N> | — | ✓ |
| Ollama import | `bizim-ft-codev-qwen-7b-v2` | <Y> GB | ✓ |

## Pre-pipeline sanity probes (§T15.6)

### Probe 1 — JSON
- Prompt: ...
- Verbatim response: ```...```
- Verdict: <follows schema | malformed | wrapped in fences | other>

### Probe 2 — Verilog
- Prompt: ...
- Verbatim response: ```...```
- Verdict: <correct | hallucinated | unrelated>

## 10-problem verify (§T15.7-8)

| Cell | Result | failure_type | Time | tag | tb_need_fix | rtl_need_fix | mismatch | tbgen calls | cand rounds | editor rounds |
|---|---|---|---|---|---|---|---|---|---|---|
| Prob001 | ... | ... | ... | ... | ... | ... | ... | 0 | ... | ... |
| ... 9 more rows ... |

Headline: <X>/10 PASS, <Y>/10 unexpected, <Z>/10 timeout.

## Side-by-side (§T15.9)

| Cell | T14 vanilla | Wrong model | T15 correct FT |
|---|---|---|---|
| ... |

## PM-facing analysis (§T15.10)

1. Correct FT vs wrong-model: ...
2. Correct FT vs vanilla 7B: ...
3. Schema-error class present?: ...
4. Recommendation: ...

## Notes for PM

<Anything surprising. Especially: if the correct FT shows the same
schema-error class as the wrong model, that has implications for
whether to attempt instruction-format prompts in Faz 1.>

## Follow-ups spotted

<Out-of-scope observations.>

## Reproducibility

The integration script `scripts/build_codev_v2.sh` (or whatever name
was used) is committed/deleted as appropriate. To re-do the integration
from scratch: ... <one-paragraph re-runnable instructions> ...
```

---

## After T15

PM reviews the report. Three branches forward:

- **Correct FT performs ≥ vanilla 7B**: project continues to Plan v3
  Faz 2-FT (S2 / S3 ablation scenarios) using this model.
- **Correct FT performs strictly worse than vanilla 7B**: document as
  negative finding, stop FT-track, return to Plan v3 Faz 1
  (Abstraction Layer) with vanilla models only.
- **Correct FT shows the same schema-error pattern as the wrong model**:
  before deciding adopt-or-drop, attempt one prompt-format adjustment
  (e.g., wrap MAGE's JSON requests in chat-format) — but that decision
  is T16, not part of T15. T15's report is sufficient closure either way.

Do not start T16 or any other task. T15 ends with the report and PM
review.
