# Task T17 — Part A: vLLM Provider Integration & 5-Model Setup on RunPod

**Status:** PENDING
**Priority:** CRITICAL — gates Part B (the paid full benchmark run)
**Depends on:** T15-bonus rename merged (`feat/mage-open-v2` HEAD)
**Reference:** Plan v3 §3 T15 (vLLM adapter was scoped here, never built)
**Hardware:** 1×H100 RunPod pod (~$3/hr; budget for this task: $30-100)

---

## Context

Plan v3 §3 reserved vLLM adapter integration as part of Faz 1 abstraction
work; it was never implemented. T17-Part B (the full 5-model benchmark on
4×H100) requires this adapter to exist and be tested. Part A's job is to
build and validate it on a cheap 1×H100 pod before Part B opens the
4×H100 pod (where every minute costs $0.20-0.30).

Part A runs **on RunPod**, not locally. The PM's directive is "do
vLLM integration on RunPod"; this Part A spec implements that with the
narrowest possible H100 footprint (1×H100, not 4×).

The five target models for Part B:

| # | Model | HF Path | Approx. weight size | Expected MAGE-pipeline behavior |
|---|---|---|---|---|
| M1 | Vanilla Qwen2.5-Coder-7B | `Qwen/Qwen2.5-Coder-7B-Instruct` | ~15 GB BF16 | Baseline; T14 verify ≥5/6 |
| M2 | Vanilla Qwen2.5-Coder-32B | `Qwen/Qwen2.5-Coder-32B-Instruct` | ~65 GB BF16 | Baseline; T14 verify 9/10 |
| M3 | CodeV-R1-RL Qwen-7B (FT) | `zhuyaoyu/CodeV-R1-RL-Qwen-7B` | ~15 GB BF16 | T15-bonus 6/10; uses `<think>` tokens |
| M4 | Qwen3.6-27B | `Qwen/Qwen3.6-27B` | ~54 GB BF16 | New (Apr 2026); reasoning mode default-on |
| M5 | Gemma-4-26B-A4B-it | `google/gemma-4-26B-A4B-it` | ~52 GB BF16 (4B active MoE) | New; built-in thinking mode |

M4 and M5 emit `<think>` reasoning blocks before the answer. T15-bonus
showed that the ChatML envelope **suppressed** R1-RL's `<think>` leakage
into the JSON `module` field. Whether the same suppression works for
Qwen3.6 and Gemma-4 is unverified — Part A measures it.

---

## Goal

Produce a working vLLM adapter and a 10-problem smoke verification for
each of the five models, all on a single 1×H100 pod, before Part B opens
4×H100. Deliverable is a Part A report that lets the PM make a go/no-go
decision per model for Part B.

---

## Hard constraints

1. **No source-file edits to MAGE agent files** (`tb_generator.py`,
   `rtl_generator.py`, `sim_judge.py`, `rtl_editor.py`, `prompts.py`,
   `benchmark_read_helper.py`). Every "do not modify" rule from T10–T15
   carries forward.
2. **vLLM adapter goes through the existing `gen_config.py` provider
   pattern.** Add a new `provider == "vllm"` branch alongside Ollama
   and OpenAI. Do not introduce a parallel adapter class system.
3. **Use 1×H100, not 4×H100 for Part A.** Even if 4× is available, do
   not use it. If model M2 or M4 doesn't fit on 1×H100 in BF16, use Q8
   GGUF or AWQ quantization for the smoke test only — Part B will use
   full-precision on tensor-parallel.
4. **Reasoning mode handling: keep enabled** (PM directive). M4 and M5
   ship reasoning-mode-on by default. Part A's job is to find out
   whether MAGE's existing JSON parser can survive `<think>...</think>`
   prefixes, NOT to disable thinking. If the parser cannot survive,
   document the failure and propose a parser-side fix in the report.
   Do not silently disable thinking and pretend the test was clean.
5. **The 10-problem set is identical to T14 / T15 / T15-bonus**:
   5 easy + 5 hard, listed in §A.4 below.
6. **Per-cell wall time cap: 25 min** (same as before).
7. **Pod uptime budget: 12 hours.** Anything exceeding this writes a
   BLOCKED report from the current state. RunPod auto-shutdown should
   be configured for the pod.

---

## Scope

### A.1 — Pod provisioning

On RunPod, provision:

- **GPU**: 1×H100 80GB (community cloud preferred for cost).
- **Container**: PyTorch 2.5 with CUDA 12.4, or vLLM official image
  (`vllm/vllm-openai:v0.7.0` or newer).
- **Disk**: 200 GB persistent volume mounted at `/workspace`. Five
  models at BF16 plus GGUF quants will need ~200 GB total.
- **Network**: HTTP endpoint exposed for vLLM serving (port 8000).
- **Auto-shutdown**: 30 min idle → shut down. Configure before any
  setup begins.

Document the pod ID and a link to the RunPod dashboard in the report.

### A.2 — Repo and dependencies

```bash
git clone https://github.com/DerinVural/MAGE_Pipeline_Integration.git
cd MAGE_Pipeline_Integration
git checkout feat/mage-open-v2
git pull

pip install vllm==0.7.0  # or current stable
pip install llama-index-llms-openai-like
```

The Apache iverilog build is also needed (already documented in
upstream MAGE README). Confirm `iverilog --version` returns ≥12.0.

### A.3 — vLLM provider in `gen_config.py`

Add a new branch in `setup_llm_from_config()`. The shape:

```python
elif provider == "vllm":
    from llama_index.llms.openai_like import OpenAILike
    llm = OpenAILike(
        model=kwargs["model"],
        api_base="http://localhost:8000/v1",  # vLLM serves OpenAI-compatible
        api_key="EMPTY",  # vLLM doesn't check
        max_tokens=kwargs.get("max_token", 4096),
        is_chat_model=True,
        is_function_calling_model=False,
        timeout=600,
    )
```

Use `OpenAILike` because vLLM exposes the OpenAI Chat Completions API.
This avoids writing a custom MAGE adapter — we just point MAGE's
existing OpenAI-flavored path at the vLLM URL.

**Key implementation note:** vLLM's OpenAI server doesn't accept the
exact same kwargs as upstream OpenAI. Specifically `temperature=0` may
need to be passed via `extra_body` rather than directly. Test this on
the smoke runs and document any quirks in the Part A report's "Provider
caveats" section.

Acceptance for A.3:
- A new `elif provider == "vllm"` branch exists in `gen_config.py`
- No other branches touched
- The branch is reachable when a runner sets `provider="vllm"` in
  `args_dict`
- Existing Ollama and OpenAI paths produce byte-identical behavior
  (run any prior test like `tests/test_top_agent_ollama.py` and
  confirm log-level identical output to pre-T17 commits)

### A.4 — Per-model serving config

For each of the five models, document the exact `vllm serve` command
and any per-model nuances. Below is the template; fill in concrete
values during execution:

```bash
# M1 — Vanilla Qwen2.5-Coder-7B-Instruct
vllm serve Qwen/Qwen2.5-Coder-7B-Instruct \
    --port 8000 \
    --max-model-len 32768 \
    --dtype bfloat16

# M2 — Vanilla Qwen2.5-Coder-32B-Instruct (single H100 may need quant)
# If BF16 OOMs on 1×H100, use AWQ:
vllm serve Qwen/Qwen2.5-Coder-32B-Instruct-AWQ \
    --port 8000 --max-model-len 16384 --dtype auto
# Document the choice in the report; Part B will use BF16 on TP=2.

# M3 — CodeV-R1-RL-Qwen-7B (HF, NOT the bizim-codev-r1-rl-qwen-7b
# Ollama tag from T15-bonus; vLLM loads safetensors directly)
vllm serve zhuyaoyu/CodeV-R1-RL-Qwen-7B \
    --port 8000 --max-model-len 32768 --dtype bfloat16

# M4 — Qwen3.6-27B (reasoning mode)
vllm serve Qwen/Qwen3.6-27B \
    --port 8000 --max-model-len 32768 \
    --dtype bfloat16 \
    --reasoning-parser qwen3
# Note: --reasoning-parser ensures vLLM extracts <think> properly.

# M5 — Gemma-4-26B-A4B-it (thinking mode)
vllm serve google/gemma-4-26B-A4B-it \
    --port 8000 --max-model-len 32768 \
    --dtype bfloat16 \
    --enable-prefix-caching
# Gemma-4's thinking mode is controlled by the chat template
# (enable_thinking=True default); leave enabled per PM directive.
```

For each model, before running smoke tests:
1. Start vLLM server with the documented command
2. `curl http://localhost:8000/v1/models` returns the loaded model
3. Smoke probe via curl: send a JSON envelope request, observe response
4. Note startup time (vLLM cold-start can be 60-300 sec depending on size)

**If a model OOMs on 1×H100 in BF16, document the exact OOM line in the
report and use the smallest viable quantization for the smoke. Do NOT
skip the model — the smoke is the whole point of Part A.**

### A.5 — Smoke probe (per model, before pipeline run)

For each of the 5 models, before invoking the MAGE pipeline, run two
isolated probes via direct vLLM API call (no MAGE involvement):

**Probe 1: JSON envelope obedience**

```python
import openai
client = openai.OpenAI(api_base="http://localhost:8000/v1", api_key="EMPTY")
resp = client.chat.completions.create(
    model="<model>",
    messages=[
        {"role": "user", "content":
         "Reply with valid JSON only: {\"reasoning\": \"...\", \"module\": \"module top; endmodule\"}. "
         "No prose, no markdown fences, no <think> tags in the JSON content."}
    ],
    max_tokens=512,
)
print(repr(resp.choices[0].message.content))
```

Record the verbatim response. Test against pydantic:

```python
from src.mage.rtl_generator import RTLOutputFormat
import json
RTLOutputFormat.model_validate(json.loads(resp.choices[0].message.content))
```

If pydantic raises, document the exact exception and the response.

**Probe 2: Reasoning-mode `<think>` placement**

For M4 and M5 specifically, send the same prompt but observe whether
`<think>...</think>` appears before the JSON, inside the JSON, or
nowhere. This determines what MAGE's parser must tolerate.

Record three categories:
- `<think>...</think>{"reasoning":"...","module":"..."}` — leakage
  in stream prefix (hopefully separable)
- `{"reasoning":"<think>...</think>...","module":"..."}` — leakage
  inside JSON field (parser-breaking)
- `{"reasoning":"...","module":"..."}` only, no `<think>` — clean

Knowing which mode each model is in lets us decide whether MAGE's
parser needs a thin "strip leading `<think>` block" preprocessor or
not.

### A.6 — MAGE 10-problem smoke for each model

For each model, with vLLM serving on port 8000, run the MAGE pipeline
on the 10-problem set:

```python
args_dict = {
    "provider": "vllm",
    "model": "<HF-model-id>",  # the same string vLLM was served with
    "temperature": 0.85,
    "top_p": 0.95,
    "max_token": 4096,
    "use_golden_tb_in_mage": True,
    "bypass_tb_gen": True,
    "golden_tb_format": True,
}
filter_instance = (
    "^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|"
    "Prob005_notgate|Prob119_fsm3|Prob121_2014_q3bfsm|Prob124_rule110|"
    "Prob127_lemmings1|Prob128_fsm_ps2)$"
)
run_identifier = f"t17a_{model_short_name}_smoke"
```

Per-cell wall time: 25 min cap. Run sequentially. After each model's
10-cell run completes, **shut down the vLLM server** (release GPU
memory) before starting the next model's vLLM startup.

For each cell capture:
- `is_pass`, `failure_type`, `error_msg` (T10 sidecar)
- `tb_need_fix`, `rtl_need_fix`, `sim_mismatch_cnt` at exit
- TBGen / RTLGen / RTLEditor call counts
- Any `<think>` token leakage observation in `rtl.sv`

### A.7 — Reasoning-mode handling decision

After the smoke runs, for **each of M4 and M5** specifically, decide:

- Did `<think>` blocks leak into `module` field? (failure mode 1)
- Did the model's response time blow past the budget because of long
  reasoning chains? (failure mode 2)
- Did pydantic schema validation succeed at the same rate as M1/M3?
  (success criterion)

If failure mode 1 or 2 dominates, the report's recommendation section
proposes either:
- (a) A parser-side strip helper added in `utils.py` (a future task,
  not Part A's scope)
- (b) Disable reasoning at vLLM level for Part B (revising the PM
  directive based on data)

The PM decides which path during the Part A → Part B handoff. Part A
documents and recommends; Part A does not patch parsers.

---

## Acceptance criteria

- [ ] RunPod 1×H100 pod provisioned with auto-shutdown configured.
- [ ] `gen_config.py` has new `provider == "vllm"` branch; no other
      MAGE source files modified.
- [ ] Existing Ollama-based tests still pass on the pod (regression
      sanity check, run any prior test like
      `tests/test_top_agent_ollama.py`).
- [ ] All 5 models loaded into vLLM at least once; per-model serving
      command documented in the report with full output.
- [ ] All 5 models passed Probe 1 (JSON envelope) — or, where they
      failed, the failure is documented verbatim.
- [ ] M4 and M5 specifically have Probe 2 (`<think>` placement)
      results documented.
- [ ] All 5 models completed the 10-problem MAGE smoke verify.
- [ ] Report `reports/v2/T17A_VLLM_SETUP.md` filed with:
  - Per-model 10-cell results table
  - 5-way headline pass-rate comparison
  - Reasoning-mode behavior summary for M4/M5
  - Provider caveats (vLLM kwargs, OpenAILike quirks)
  - Per-model recommended Part B serving config (TP size, dtype)
- [ ] Pod total runtime ≤12 hours.
- [ ] Pod shut down at task completion.
- [ ] Commit message: `[T17A] vLLM provider integration & 5-model smoke verify`

---

## Stop conditions

File `reports/v2/T17A_BLOCKED.md` if:

- The vLLM `provider == "vllm"` branch can be added but `OpenAILike`
  routing through `count_chat()` produces unexpected output that
  crashes pre-existing tests. (Don't try to debug agents — bail.)
- 3 or more of the 5 models fail Probe 1 (JSON envelope) — suggests
  fundamental MAGE-vs-vLLM incompatibility, not a per-model issue.
- Pod uptime exceeds 10 hours and only 2 or fewer models are smoke-
  tested. (Stop, write report, save the rest for a re-provisioning.)
- Disk fills (200 GB exceeded by model downloads) — document and stop.
- Network bandwidth issues prevent model downloads — common on
  community RunPod pods, document and stop.

---

## Do NOT

- Modify any agent file (rtl_generator, tb_generator, sim_judge,
  rtl_editor, prompts, benchmark_read_helper).
- Use 4×H100 for Part A. 1×H100 only.
- Disable reasoning mode on M4 / M5. Leave it on, observe behavior,
  recommend in report.
- Patch MAGE's JSON parser even if `<think>` blocks break it. Document
  the failure mode; the PM decides whether parser patching is in
  Part B scope.
- Skip a model if it OOMs. Use a quantized variant for the smoke and
  note that Part B will need TP scale-up.
- Run more than the 10-problem smoke set. Part A is for go/no-go
  evidence, not full benchmarks.
- Run more than one model in vLLM simultaneously. Each model gets its
  own serve cycle: start, smoke, stop, next.
- Leave the pod running after Part A completes. Auto-shutdown is your
  safety net but explicit shutdown is the disciplined ending.

---

## Report template

```markdown
# Task T17A — vLLM Provider Integration & 5-Model Smoke

**Status:** DONE | BLOCKED | PARTIAL
**Branch:** feat/mage-open-v2
**Commits:** <hash>
**RunPod pod ID:** <id>
**Total pod runtime:** <hours>
**Estimated cost:** $<amount>

## Setup
- Container: <vLLM image>
- vLLM version: <version>
- iverilog version: <version>
- Disk used: <GB>

## Provider integration

`gen_config.py` `vllm` branch added at lines <range>. Implementation
notes: <any caveats with OpenAILike, kwarg passing, etc.>

Regression test: `pytest tests/test_top_agent_ollama.py` ran with
identical output to pre-T17 baseline. Confirmed.

## Per-model serving

### M1 — Qwen2.5-Coder-7B-Instruct
- Serve command: `vllm serve ...`
- Cold-start time: <sec>
- Memory used: <GB>
- Probe 1 (JSON): pass | fail (<reason>)
- Probe 2 (<think>): n/a (not a reasoning model)

### M2 — Qwen2.5-Coder-32B-Instruct
- Serve command: ...
- Memory used: <GB> (BF16) or <GB> (AWQ if used)
- Probe 1: ...

### M3 — CodeV-R1-RL-Qwen-7B
- Serve command: ...
- Probe 1: ...
- Probe 2: <think> placement = <prefix | inside | none>

### M4 — Qwen3.6-27B
- Serve command: ...
- Probe 1: ...
- Probe 2: <think> placement = ...

### M5 — Gemma-4-26B-A4B-it
- Serve command: ...
- Probe 1: ...
- Probe 2: <think> placement = ...

## 10-problem smoke results

| Cell | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| Prob001 | PASS/FAIL | ... | ... | ... | ... |
| ...(10 rows)... |

Headline pass rates: M1 X/10, M2 X/10, M3 X/10, M4 X/10, M5 X/10.

## Reasoning-mode summary (M4, M5 only)

- M4 `<think>` behavior in MAGE pipeline: <observation>
- M5 thinking-mode behavior in MAGE pipeline: <observation>
- Pipeline impact: <`unexpected` schema fail / functional fail / clean>

## Part B recommendation

For each model, recommended serving config on 4×H100:

| Model | TP size | dtype | max_model_len | Notes |
|---|---|---|---|---|
| M1 | 1 | bfloat16 | 32768 | fits single H100 |
| M2 | 2 | bfloat16 | 32768 | needs 2 GPUs for BF16 |
| M3 | 1 | bfloat16 | 32768 | same as M1 |
| M4 | 2 | bfloat16 | 32768 | reasoning needs context budget |
| M5 | 2 | bfloat16 | 32768 | MoE active 4B, but full weights need 2 GPUs |

Go/no-go per model:
- M1: GO / NO-GO (reason)
- M2: GO / NO-GO (reason)
- M3: GO / NO-GO (reason)
- M4: GO / NO-GO (reason)
- M5: GO / NO-GO (reason)

## Provider caveats

<vLLM-OpenAILike specific findings, kwarg handling, etc.>

## Notes
<Anything PM should know.>
```

---

## After Part A

PM reviews the Part A report and decides:
- Which models GO to Part B (full benchmark)
- Whether reasoning-mode-on stays for M4/M5 or gets disabled
- Whether MAGE's JSON parser needs a `<think>` strip helper before Part B
- Per-model TP and dtype configs for the 4×H100 pod

Only after these decisions are made does Part B open the 4×H100 pod.
The PM expects the Part A → Part B gap to be 1-2 days (review,
parser-fix decisions if needed, then pod provisioning).

Part B is a separate spec (`T17_PART_B_RUNPOD_FULL_BENCHMARK.md`)
that the PM will issue once Part A is reviewed.
