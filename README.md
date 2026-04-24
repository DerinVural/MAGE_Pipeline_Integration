# MAGE Pipeline Integration — Open-Model Reproducibility Study

Forensic reproducibility study of [MAGE](https://github.com/stable-lab/MAGE)
([Zhao et al., DAC 2025](https://arxiv.org/abs/2412.07822)) using
`qwen2.5-coder` open models via Ollama.

> **Status:** Closed (April 2026). Five forensic tasks (T5–T9) completed.
> Project pivoted once — see [Project narrative](#project-narrative) below.

---

## TL;DR

MAGE achieves **95.7% pass@1** on VerilogEval-Human v2 with Claude 3.5
Sonnet. We tried to (1) extend MAGE to support per-agent LLM routing
for a 4-scenario fine-tuned vs base ablation study, then (2) reproduce
the methodology with Qwen2.5-Coder via Ollama. We found:

- **Initial pass rate** (one-shot generation): **5/5** on simple
  problems with 32B, **3/5** with 7B + JSON-mode fix
- **MAGE multi-agent mechanism activation**: **0 rounds** across
  18 problem-runs — neither candidate generation nor Debug Agent
  triggered, even on functionally subtle FSM problems (T9)
- **Root cause is not model capacity** — for 32B on hard problems,
  the upstream pipeline's `SimJudge` produces oscillating verdicts
  on ambiguous failures, blocking control-flow advance to the
  Debug Agent branch
- **Five Claude-specific implicit dependencies** documented in MAGE
  (3 patched, 2 diagnosed)

This is a **negative reproducibility finding** with concrete
diagnostic value for downstream researchers.

## Final report

See [`docs/closure_summary.md`](docs/closure_summary.md) for the full
executive summary, thesis skeleton, and recommendations.

---

## Project narrative

### Plan v1 — Original ablation hypothesis

The project began as an extension of MAGE: build a 4-scenario ablation
study comparing fine-tuned vs base Qwen2.5-Coder-7B across MAGE's
four agent roles.

| Scenario | TB Agent | RTL Agent | Judge Agent | Debug Agent |
|----------|----------|-----------|-------------|-------------|
| S1 — Base-only | base | base | base | base |
| S2 — FT-only | FT | FT | FT | FT |
| S3 — Hybrid RTL | base | **FT** | base | base |
| S3b — Hybrid Debug | base | base | base | **FT** |

Implementation required extending MAGE's single-LLM design to support
**per-agent LLM routing**. We designed `RoutingTokenCounter`
(`patches/routing_token_counter.py`) to dispatch based on the agent's
class name (`set_cur_tag(self.__class__.__name__)`), without modifying
any agent file. The patch is preserved in the repo but **was never
integrated** — see pivot below.

### Pivot — T7 forensic finding

T7 (Debug Agent live smoke test) revealed that `qwen2.5-coder:7b`
systematically fails at the Testbench Generator stage — keyword
hallucinations like `topmodule` produce non-compilable testbenches,
the pipeline asserts at `agent.py:130` before reaching the candidate
loop or Debug Agent branch. The 4-scenario ablation became
**unmeasurable** because the mechanisms we wanted to compare never ran.

### Plan v2 — Reproduction study

Project re-framed as a single-model reproduction with
`qwen2.5-coder:32b`. Both FT/base ablation and per-agent LLM routing
dropped from scope. New question:

> *Can MAGE's methodology be reproduced with a smaller, open, locally
> hosted model?*

The pivot is documented in [`docs/plan_v2.md`](docs/plan_v2.md);
the original plan is preserved in [`docs/plan.md`](docs/plan.md) for
provenance.

---

## Forensic task series

| Task | Status | Headline finding | Report |
|---|---|---|---|
| T0 | DONE | Project bootstrap | (initial setup) |
| T5 | DONE | JSON-mode fix raised pass rate 1/5 → 3/5 (7B) | [`reports/T5_DONE.md`](reports/T5_DONE.md) |
| T6 | DONE | Whitelisted dangling-input warning, fixed false-negative | [`reports/T6_DONE.md`](reports/T6_DONE.md) |
| T7 | DONE | Debug Agent never triggered on 7B kmap problems (γ) | [`reports/T7_DONE.md`](reports/T7_DONE.md) |
| T8 | DONE | 32B passes 5/5 on simple problems but mechanism still inactive | [`reports/T8_DONE.md`](reports/T8_DONE.md) |
| T9 | BLOCKED | 32B on hard FSM problems: SimJudge oscillation blocks Debug Agent (η) | [`reports/T9_BLOCKED.md`](reports/T9_BLOCKED.md) |

---

## MAGE architecture clarification (important)

MAGE has **four LLM agents** that share a **single LLM**:

- `TBGenerator` — generates optimized testbench
- `RTLGenerator` — generates RTL code, also handles candidate sampling
- `SimJudge` — decides whether testbench needs revision
- `RTLEditor` — Debug Agent, applies targeted fixes

Plus a fifth, non-LLM component:

- `SimReviewer` — deterministic iverilog/vvp wrapper, no LLM

In MAGE's terminology, "multi-agent" means **role-based prompt
specialization**, not model multiplicity. All four LLM agents in
upstream MAGE talk to the same Claude/OpenAI/Ollama endpoint via
`self.token_counter.count_chat()`. Plan v1's `RoutingTokenCounter`
would have been the first per-agent-different-LLM extension; with the
pivot to Plan v2, this extension was no longer needed.

This clarification matters because **SimJudge and RTLEditor share the
same LLM** — a stochastic Judge directly affects whether the Editor
ever gets invoked, which is the root mechanism behind T9's verdict
oscillation finding.

---

## Documented Claude-specific dependencies in MAGE

Across T5–T9 we documented five implicit assumptions in the upstream
MAGE pipeline that hold for Claude 3.5 Sonnet but break for open
models:

1. **JSON output without code-fence wrapping** — MAGE's parser only
   strips ```` ```json ``` ```` fences for Vertex (Gemini) provider.
   Claude returns raw JSON; Qwen wraps in fences. **Fix:** enable
   `json_mode=True` for Ollama (T5).
2. **Stderr "benign warning" allowlist sized to Claude's output style**
   — when Qwen chooses a different port topology, iverilog emits
   warnings the allowlist doesn't cover, causing functionally correct
   RTL to be marked failed. **Fix:** extended allowlist (T6).
3. **TB Generator brittleness on small models** — 7B-class models
   hallucinate keywords (e.g., `topmodule`), producing non-compilable
   testbenches. **Diagnosed (T7), not patched.**
4. **Silent exception masking** — `agent.py:253`'s outer try/except
   converts assertion failures into `is_pass=False` indistinguishable
   from real functional failures. **Diagnosed (T7), not patched.**
5. **SimJudge verdict oscillation** — temperature-based sampling causes
   the Judge to emit alternating "TB needs fix" / "TB OK" verdicts on
   ambiguous failures, blocking exit from the TB-revision loop and
   preventing Debug Agent activation. **Diagnosed (T9), not patched.**

The first two are committed patches (see `src/mage/gen_config.py`,
`src/mage/utils.py`, `src/mage/sim_reviewer.py`,
`src/mage/token_counter.py` for diff against upstream). The latter
three are documented for follow-up work.

---

## Repo structure

```
.
├── README.md                          # this file
├── docs/
│   ├── closure_summary.md             # final executive summary + thesis skeleton
│   ├── plan.md                        # Plan v1 (original ablation design)
│   └── plan_v2.md                     # Plan v2 (post-pivot reproduction design)
├── src/mage/                          # MAGE source (forked from upstream)
│   ├── gen_config.py                  # patched (Ollama provider + json_mode)
│   ├── utils.py                       # patched (hardened JSON reformatter)
│   ├── token_counter.py               # patched (Ollama in reformat allowlist)
│   └── sim_reviewer.py                # patched (extended benign warnings)
├── patches/
│   ├── PATCH_NOTES.md                 # original patch design notes
│   ├── gen_config.py                  # reference patch (alternate)
│   └── routing_token_counter.py       # Plan v1 design — NEVER INTEGRATED
├── tests/
│   ├── test_top_agent_ollama.py       # T5 runner (7B + json_mode, 5 problems)
│   ├── test_top_agent_ollama_32b.py   # T8 runner (32B, same 5 problems)
│   ├── test_top_agent_ollama_debug.py # T7 runner (4 kmap problems)
│   ├── test_top_agent_ollama_hard.py  # T9 runner (5 FSM problems)
│   └── test_sim_reviewer_warnings.py  # T6 unit tests
├── reports/
│   ├── T5_DONE.md
│   ├── T6_DONE.md
│   ├── T7_DONE.md
│   ├── T8_DONE.md
│   └── T9_BLOCKED.md
├── verilog-eval/                      # benchmark submodule (NVlabs)
└── ... (upstream MAGE files)
```

---

## Reproduction instructions

### 1. Setup

```bash
git clone --recursive https://github.com/DerinVural/MAGE_Pipeline_Integration.git
cd MAGE_Pipeline_Integration

conda create -n mage python=3.11 -y
conda activate mage
pip install -e .
pip install llama-index-llms-ollama
```

Install iverilog 12.0 from source:

```bash
sudo apt install -y autoconf gperf flex bison
git clone https://github.com/steveicarus/iverilog.git
cd iverilog && git checkout v12_0
sh autoconf.sh && ./configure && make -j && sudo make install
```

### 2. Ollama + Qwen models

```bash
# Install Ollama (see https://ollama.com)
ollama pull qwen2.5-coder:7b   # ~4 GB, used for T5/T7
ollama pull qwen2.5-coder:32b  # ~19 GB, used for T8/T9
```

### 3. key.cfg

```
OPENAI_API_KEY = 'EMPTY'
```

### 4. Run any of the smoke tests

```bash
# T5: 7B with json_mode, 5 simple problems
python tests/test_top_agent_ollama.py

# T7: 7B on 4 kmap problems (Debug Agent probe)
python tests/test_top_agent_ollama_debug.py

# T8: 32B on same 5 problems as T5
python tests/test_top_agent_ollama_32b.py

# T9: 32B on 5 FSM problems
python tests/test_top_agent_ollama_hard.py
```

Each run produces `output_<run_id>_0/record.json` with per-problem
pass/fail and timing, plus `log_<run_id>_0/<problem>/` per-problem
forensic logs.

---

## Citation

If you use this work, please cite both the original MAGE paper and
this reproducibility study:

```bibtex
@article{zhao2024mage,
  title={MAGE: A Multi-Agent Engine for Automated RTL Code Generation},
  author={Zhao, Yujie and Zhang, Hejia and Huang, Hanxian and Yu, Zhongming and Zhao, Jishen},
  journal={arXiv preprint arXiv:2412.07822},
  year={2024}
}
```

---

## License

MIT (inherited from upstream MAGE).

## Acknowledgments

- Upstream MAGE: [stable-lab/MAGE](https://github.com/stable-lab/MAGE)
- Benchmark: [NVlabs/verilog-eval](https://github.com/NVlabs/verilog-eval)
- Forensic engineering by Claude Code (Opus 4.7) under PM oversight
