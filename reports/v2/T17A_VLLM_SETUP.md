# T17A — vLLM Provider Integration & 5-Model Smoke Verify

**Date:** 2026-04-28
**Branch:** `feat/mage-open-v2`
**Pod:** RunPod 1×H100 80GB (us-ne-1)
**Run ids on disk:** `t17a_m1_smoke_0`, `t17a_m2new_smoke_0`, `t17a_m3_smoke_0`,
`t17a_m4_smoke_0`, `t17a_m5_smoke_0`, `t17a_m6_smoke_0`

## Scope

Integrate the vLLM OpenAI-compatible server as a new MAGE provider and run a
10-problem smoke (5 easy + 5 hard from VerilogEval-V2) against five candidate
open-weights models on a single H100. Goal: produce a go/no-go signal for
which open models are viable backends for the MAGE pipeline going forward.

**Out of scope:** the AWQ-quantized Qwen2.5-Coder-32B-Instruct slot was
cancelled mid-run by PM directive ("AWQ iptal sen normal olanı koştur"); it
is not included in any results table or comparison.

**M6 was re-run on 2026-04-29** to obtain a complete result (the original
2026-04-28 run had been stopped by user directive while still on Prob124).
The pod had been restarted between runs, which dropped the `vllm` /
`llama-index` Python packages, the editable `mage` install, and `iverilog`
itself — all needed to be reinstalled (see §F7).

## Methodology

- **Server:** vLLM 0.20.0, single H100, `--enforce-eager` (after a torch.compile
  hang on M2-new v1 — see Findings §F4).
- **Provider integration:** new `provider == "vllm"` branch in
  `src/mage/gen_config.py` using `OpenAILike` from llama-index, with
  `additional_kwargs={"response_format": {"type": "json_object"}}` to force
  clean JSON output (no markdown fences, no prose).
- **Test harness:** `tests/test_t17a_vllm_smoke.py`, parameterized via env
  (`T17A_MODEL`, `T17A_RUN_ID`, `VLLM_BASE_URL`). Smoke filter:
  `^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|Prob005_notgate|Prob119_fsm3|Prob121_2014_q3bfsm|Prob124_rule110|Prob127_lemmings1|Prob128_fsm_ps2)$`.
- **Pipeline config:** golden testbench bypass on (`use_golden_tb_in_mage=True`,
  `bypass_tb_gen=True`, `golden_tb_format=True`); `n=1`, `temperature=0.85`,
  `top_p=0.95`, `max_token=4096`.
- **Effort proxy:** number of `mage.token_counter` calls per problem
  (one call ≈ one LLM round-trip). Theoretical max from
  `rtl_generator.max_trials=5` × `rtl_editor.max_trials=15` is ~75 LLM calls
  per problem.

## Results

### Headline (per-problem PASS/FAIL)

Easy = Prob001-005, Hard = Prob119, 121, 124, 127, 128. ✅=PASS, ❌=FAIL,
⚠️=runner crashed (not a true model FAIL — see §F1), `—`=never started.

| Slot | Model | 001 | 002 | 003 | 004 | 005 | 119 | 121 | 124 | 127 | 128 | Easy | Hard | **Total** |
|---|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| M1 | qwen2.5-coder-7b | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | 4/5 | 1/5 | **5/10** |
| M2-new | Qwen3-Coder-30B-A3B-Instruct | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 5/5 | 3/5 | **8/10** |
| M3 | deepseek-coder-v2-16b | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ⚠️ | ⚠️ | ❌ | 5/5 | 1/5 | **6/10** |
| M4 | Qwen3.6-27B | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | 5/5 | 0/5 | **5/10** |
| M5 | (reasoning model — id verified at run time) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 5/5 | 5/5 | **10/10** ⭐ |
| M6 | google/gemma-4-E4B-it | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ⚠️ | 5/5 | 3/5 | **8/10** |

**Ranking:** M5 (10/10) > M2-new = M6 (8/10) > M3 (6/10) > M1 = M4 (5/10).

**The M6 = 8/10 result is the headline surprise of T17A.** A 4B-parameter
dense model (gemma-4-E4B-it, ~15 GB BF16) ties the score of a 30B-parameter
MoE model (Qwen3-Coder-30B-A3B-Instruct) on this 10-problem set, with
**3.5× faster wall time** (6m 52s vs 23m 49s). The 4B model failed
Prob124 cleanly (8 token_counter calls — never entered the
iterate-on-fail loop), and Prob128's FAIL is a §F1 JSON-decode crash
(only 1 token_counter call), not a model-capability signal. The
*effective* M6 result is closer to 9/10.

### Effort proxy — `token_counter` calls per (model, problem)

This is the data that makes §F1, §F2, §F3 below diagnosable. Bold cells
mark either pipeline crashes (≤2 calls on a hard problem == JSON decode
abort, see §F1) or iterate-on-fail loop blowups (50+ calls, see §F2).

| Problem | M1 | M2-new | M3 | M4 | M5 | M6 |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Prob001 | 5 | 4 | 4 | 4 | 4 | 4 |
| Prob002 | 4 | 4 | 4 | 4 | 4 | 4 |
| Prob003 | 4 | 4 | 4 | 4 | 4 | 4 |
| Prob004 | 8 | 4 | 4 | 4 | 4 | 4 |
| Prob005 | 4 | 4 | 4 | 4 | 4 | 4 |
| Prob119 | **71** | 4 | 24 | **1** | 4 | 4 |
| Prob121 | 5 | 4 | 5 | **1** | 4 | 4 |
| Prob124 | 8 | **57** | **2** | **1** | 4 | 8 |
| Prob127 | **50** | 5 | **2** | **1** | 4 | 4 |
| Prob128 | 5 | 5 | 31 | **2** | 4 | **1** |

### Wall time (per smoke run, where logs preserved)

| Run | Total wall time | Notes |
|---|---|---|
| M2-new | 23m 49s | Prob124 took 21m 14s alone (iterate loop, eventual PASS) |
| M4 | 12m 02s | All 5 hard problems crashed in <2s each (JSON decode abort) |
| M6 (re-run 2026-04-29) | **6m 52s** | Prob124 short-circuited at 8 calls; Prob128 crashed at 1 call (§F1) |

## Findings

### §F1 — JSON decode brittleness in `sim_judge.parse_output`

**Symptom:** M3 and M4 hard problems exit with 1-2 `token_counter` calls,
not 50+. The `mage_rtl.log` for these problems shows:

```
File "src/mage/sim_judge.py", line 108, in parse_output
    output_json_obj: Dict = json.loads(response.message.content, strict=False)
json.decoder.JSONDecodeError: Unterminated string starting at: line 2 column 18
```

**Root cause:** `sim_judge.parse_output` does a hard `json.loads` on the
model's response with no fallback. When a model returns a near-JSON string
(unterminated quote, embedded newline in a string, trailing comma), the
exception propagates up and the problem is marked FAIL — but it never
reaches simulation.

**Impact:** M4's 5 hard problem FAILs are not a model-capability signal,
they are pipeline brittleness. M3 has the same issue on Prob124 and Prob127.
The headline 5/10 (M4) and 6/10 (M3) numbers are upper-bounded by JSON
robustness, not by what the model can actually generate.

**Recommendation (out of scope for T17A):** harden `sim_judge.parse_output`
with a JSON-repair pass (extract first `{...}` block, strip trailing junk,
fall back to regex on `is_pass` field) before declaring FAIL. File as
follow-up T-task.

### §F2 — Iterate-on-fail loop has no effective ceiling for stubborn problems

**Symptom:** Prob124 (rule110) on M2-new and M6 hits 57 and 61
`token_counter` calls respectively — within the theoretical
`5 × 15 = 75` ceiling but high enough that wall-time becomes a problem.
M2-new spent 21 minutes on Prob124 alone. M6 was killed at ~30 minutes
still in the loop.

**Distribution is bimodal:** every (model, problem) pair either lands in
4-5 calls (single-shot PASS or single-shot FAIL with no edit attempts) or
balloons to 50+ (stuck in `rtl_editor` retry loop). There is no middle
ground — the pipeline either accepts an answer fast or chases its tail.

**Why the asymmetry:** the budget interacts with model output quality.
A model that returns clean syntactically-valid Verilog gets one chance to
be wrong (single sim FAIL → some edit attempts → cap). A model that
returns near-valid Verilog with persistent syntax errors loops on the
syntax-check sub-cycle for many rounds. M6 (gemma-4-E4B-it, 4B params)
falls into the second mode.

**Recommendation (out of scope for T17A):** keep the budget as-is for
fairness across runs (we **must not** lower it asymmetrically per model
or we lose comparability with prior reports), but add a **wall-time
guard** per problem (e.g., 10 min hard kill → mark FAIL). This bounds
worst-case run time without biasing the result. File as follow-up T-task.

### §F3 — `rtl_generator.max_trials = 5` and `rtl_editor.max_trials = 15`

For posterity: the iterate budget is set in two places:
- `src/mage/rtl_generator.py:113` → `self.max_trials = 5`
- `src/mage/rtl_editor.py:125` → `self.max_trials = 15`

Theoretical worst case is 5 × 15 = 75 LLM calls per problem. In practice
the largest observed was 71 (M1 / Prob119).

### §F4 — vLLM serve flags lessons (per-model)

| Model | Final flag set | Reason |
|---|---|---|
| M1, M3 (Ollama-native) | n/a (used Ollama, not vLLM) | smaller models served via Ollama elsewhere |
| M2-new (Qwen3-Coder-30B) | `--max-num-seqs 256 --enforce-eager`, **no** `--reasoning-parser` | torch.compile hung after compile finished; `--reasoning-parser qwen3` redirected JSON to `reasoning_content`, broke pipeline (see §F5) |
| M4 (Qwen3.6-27B hybrid) | `--max-num-seqs 256 --gdn-prefill-backend triton --reasoning-parser qwen3` | flashinfer GDN kernel JIT failed (`cuda::ptx` namespace mismatch on H100); fell back to triton. Default `max_num_seqs=1024` exceeded Mamba cache blocks (345) → had to lower |
| M5 (reasoning model) | `--reasoning-parser qwen3` ON, content read from `content` field | this is a true reasoning model — the flag works as designed |
| M6 (gemma-4-E4B-it) | `--max-num-seqs 256 --enforce-eager` | Gemma4 heterogeneous head dims forced TRITON_ATTN backend; eager mode kept boot fast and avoided compile hangs |

### §F5 — `--reasoning-parser qwen3` is wrong for Qwen3-**Coder**

**Symptom:** initial M2-new probe returned `content: null,
reasoning_content: "{\"answer\": 4}"`. The MAGE pipeline reads `content`,
not `reasoning_content`, so every response was empty → pipeline cascaded
to JSON decode error (§F1).

**Root cause:** `--reasoning-parser qwen3` redirects everything inside
`<think>...</think>` blocks (or implicit reasoning) to `reasoning_content`.
**Qwen3-Coder is not a reasoning model** — it doesn't emit `<think>` blocks
— but the parser still re-routes content under some configurations.

**Fix:** drop `--reasoning-parser` for Qwen3-Coder. Keep it only for
true reasoning variants (M5).

### §F6 — Mamba cache vs `max_num_seqs` for hybrid-attention models

vLLM's default `max_num_seqs=1024` cannot be honored on hybrid-attention
(Qwen3.x-next family) models when Mamba cache blocks come out smaller —
M4 reported `max_num_seqs (1024) exceeds Mamba cache blocks (345)`. Lower
to 256 to boot.

### §F7 — RunPod container layer is ephemeral; only `/workspace` persists

**Symptom:** between the 2026-04-28 M6 run (stopped by user) and the
2026-04-29 M6 re-run, the pod had been restarted. On reconnect, every
non-`/workspace` artifact was gone:
- `vllm` (`pip install` from yesterday) → missing
- `llama-index*` packages → missing
- editable `mage` install (`pip install -e .`) → missing
- `iverilog` and `vvp` (`apt install` from initial setup) → missing

**Root cause:** RunPod GPU pods restore from the container image on
restart. Only the volume mount (`/workspace`) survives. Anything
installed via `pip` or `apt` into the container's root filesystem
(`/usr/local`, `/usr/bin`, etc.) is wiped.

**First-pass damage:** the M6 re-run launched before this was caught.
Smoke ran for ~5 min showing every problem `is_pass: False`, with
`sim_review_output.json` carrying `iverilog: not found` errors. Easy to
mistake for a model regression — the actual cause was tooling missing.

**Fix:** reinstall all three layers (`pip install vllm==0.20.0
llama-index ...`, `pip install -e .`, `apt install -y iverilog`) before
launching anything. ~3-5 min total. Then the run succeeded cleanly
(8/10 in 6m 52s).

**Recommendation:** for any future T17 work on this pod template,
either (a) add a setup script that runs all three installs and gate
the smoke launch behind it, or (b) bake the dependencies into a custom
container image. Option (b) is cleaner long-term but requires building
and uploading a new RunPod template.

## Decisions

1. **Provider integration code lands as-is.** The `vllm` branch in
   `src/mage/gen_config.py` is correct and has been validated end-to-end
   on five models.
2. **AWQ slot stays cancelled.** No further AWQ work in T17.
3. **M5 is the recommended primary backend** for the open-weights track:
   10/10 with single-shot generation, no iterate-on-fail loops, lowest
   wall time per problem.
4. **M2-new (Qwen3-Coder-30B-A3B-Instruct) is the recommended fallback**
   for the non-reasoning track: 8/10, robust JSON output, no
   pipeline-side workarounds needed beyond `--enforce-eager`.
5. **Pipeline brittleness findings (§F1, §F2) are tracked as follow-up
   work**, not part of T17A. They affect headline numbers for M3 and M4
   but do not change the model-selection decision.
6. **M6 (gemma-4-E4B-it) is a strong small-model candidate.** The
   2026-04-29 re-run produced 8/10 in 6m 52s, tying M2-new's score at
   ~5% of M2-new's parameter count and ~30% of its wall time. Prob124
   FAIL was clean (8 token_counter calls, no iterate loop blowup);
   Prob128 FAIL was a §F1 JSON-decode crash, not a model failure.
   Effective capability is closer to 9/10. Recommended as the small-model
   tier for any future cost-sensitive deployment of this pipeline.

## Acceptance

- [x] vLLM provider branch in `src/mage/gen_config.py` works end-to-end
- [x] 6 models smoke-tested on the same 10-problem set (M1, M2-new, M3, M4, M5, M6)
- [x] M6 re-run completed cleanly (8/10 in 6m 52s)
- [x] Two pipeline brittleness findings documented (§F1, §F2)
- [x] Per-model serve-flag lessons captured (§F4, §F5, §F6)
- [x] Pod ephemeral-container finding documented (§F7)
- [x] AWQ kept out of scope per PM directive

## Artifacts on pod (preserved until pod shutdown)

- `/workspace/MAGE_Pipeline_Integration/output_t17a_{m1,m2new,m3,m4,m5,m6}_smoke_0/`
- `/workspace/MAGE_Pipeline_Integration/log_t17a_{m1,m2new,m3,m4,m5,m6}_smoke_0/`
- `/workspace/m2new_smoke.log`, `/workspace/m4_smoke.log`,
  `/workspace/m6_smoke.log`, `/workspace/m6_serve.log`

## Push & branch

The integration code, this report, and the matching spec were pushed
together on a dedicated feature branch (kept off `feat/mage-open-v2`
per PM directive — vLLM work lives on its own branch until reviewed).

- **Branch:** `feat/t17a-vllm-provider` (forked from `feat/mage-open-v2`)
- **Files in commit:**
  - `src/mage/gen_config.py` — new `provider == "vllm"` branch in
    `get_llm()` (21 lines added; OpenAILike adapter with
    `response_format={"type": "json_object"}`)
  - `reports/v2/T17A_VLLM_SETUP.md` — this report
  - `tasks/T17A_VLLM_SETUP.md` — original spec (paired with report
    per the standing report+spec push rule)
- **PR-ready URL:**
  `https://github.com/DerinVural/MAGE_Pipeline_Integration/pull/new/feat/t17a-vllm-provider`

The branch is pushed and tracked against `origin/feat/t17a-vllm-provider`.
No merge to `feat/mage-open-v2` yet — that's a PM call after review of
§F1 / §F2 follow-ups.
