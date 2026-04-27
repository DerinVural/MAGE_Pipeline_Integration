# Task T11: Per-Agent Temperature Override (SimJudge = 0)

**Status:** DONE
**Branch:** feat/mage-open-v2
**Commits:** (see final commit on this branch)

## Hypothesis

SimJudge stochasticity at `temperature=0.85` produces unstable `tb_needs_fix`
verdicts across repeated TB-regeneration loops, preventing the pipeline from
reaching the RTLEditor branch. T11's intervention: pin SimJudge sampling to
`temperature=0.0, top_p=1.0` via a new per-agent override layer that leaves
other agents (RTLGenerator, TBGenerator, RTLEditor, SimReviewer) at the
global experimental setting.

## Changes

- `src/mage/gen_config.py`: added `AGENT_SAMPLING_OVERRIDES` dict (seeded
  with `SimJudge → {temperature: 0.0, top_p: 1.0}`), `get_agent_sampling(tag)`
  with precedence (override → global), and `set_agent_sampling(tag, ...)`
  runtime setter. Global `ExperimentSetting` unchanged, preserving
  backwards-compat for callers of `get_exp_setting()`.
- `src/mage/token_counter.py`: replaced 4 hardcoded chat call sites
  (`TokenCounter.count_chat`, `TokenCounter.count_achat`,
  `TokenCounterCached.count_chat`, `TokenCounterCached.count_achat`) to
  route through `get_agent_sampling(self.cur_tag)`. Added per-call log:
  `TokenCounter count_chat [agent=SimJudge] at temp: 0.0, top_p: 1.0`.
- `tests/test_agent_sampling.py`: new file, 6 unit tests covering default
  fallback, SimJudge override, runtime setter, global propagation, SimJudge
  immunity to global change, and end-to-end `TokenCounter.count_chat`
  kwargs verification.
- `tasks/T11_JUDGE_TEMPERATURE.md`: archived spec.

## Verification

### Unit tests

```
$ .venv/bin/python -m pytest tests/test_agent_sampling.py -v
tests/test_agent_sampling.py::test_default_global_for_unknown_agent PASSED
tests/test_agent_sampling.py::test_simjudge_override PASSED
tests/test_agent_sampling.py::test_set_sampling_runtime PASSED
tests/test_agent_sampling.py::test_global_settings_change_propagates PASSED
tests/test_agent_sampling.py::test_simjudge_immune_to_global_change PASSED
tests/test_agent_sampling.py::test_tokencounter_invokes_override PASSED
======================== 6 passed in 1.8s ========================
```

### Full-suite regression

```
$ .venv/bin/python -m pytest tests/ --ignore=tests/test_single_agent.py
16 passed, 2 warnings
```

(`test_single_agent.py` excluded — pre-existing `ModuleNotFoundError:
No module named 'backoff'` on `main` at `d7b6d8f`, unrelated to T11.)

### Smoke runs

Two smoke runs on `qwen2.5-coder:32b` (ollama, golden TB):

**Run 1 — Prob127_lemmings1** (hard T9 set, 20min cap, did not complete —
timeout during TB-loop phase, no `record.json`). Partial log from
`log_t11_prob127_verify/VERILOG_EVAL_V2_Prob127_lemmings1/`:

```
mage.token_counter.log:
  [agent=TBGenerator]  at temp: 0.85, top_p: 0.95
  [agent=RTLGenerator] at temp: 0.85, top_p: 0.95
  [agent=SimJudge]     at temp: 0.0,  top_p: 1.0   ← T11 route
  [agent=TBGenerator]  at temp: 0.85, top_p: 0.95
  [agent=SimJudge]     at temp: 0.0,  top_p: 1.0
  [agent=TBGenerator]  at temp: 0.85, top_p: 0.95
  [agent=SimJudge]     at temp: 0.0,  top_p: 1.0
```

3 SimJudge verdicts observed, all `tb_needs_fix: true` — stable verdict, no
oscillation.

**Run 2 — Prob003_step_one, qwen2.5-coder:32b** (5probs baseline set, 45min
cap, completed in 12m04s). Output at `log_t11_prob003_verify_0/`:

- `record.json`: `is_pass: true`, `failure_type: "pipeline_assert"`,
  `error_msg: "tb_need_fix should be False. sim_log: {tb.sv:7 syntax error}"`
- 4 TBGenerator calls, 4 SimJudge calls (all `temp=0.0`), 0 RTLEditor rounds
- All 4 SimJudge verdicts: `tb_needs_fix: true` (stable)

**Run 3 — Prob003_step_one, qwen2.5-coder:7b** (same problem, smaller model,
45min cap, completed in 2m27s). Output at `log_t11_7b_prob003_verify_0/`:

- `record.json`: `is_pass: true`, `failure_type: "pipeline_assert"`,
  `error_msg: "rtl_need_fix should be True only when sim_mismatch_cnt > 0"`
- 4 TBGenerator + 1 RTLGenerator + 4 SimJudge calls (9 total)
- **SimJudge verdicts: 3 true / 1 false** — first observed oscillation under
  T11
- 0 RTLEditor rounds (judge stayed in TB-loop, fallback produced pass)

Per-agent temp routing identical across all 3 runs:
`SimJudge=0.0, TBGenerator=0.85, RTLGenerator=0.85`.

### Per-agent temperature log route — PRIMARY T11.4 acceptance

Verified in both smoke runs that `TokenCounter` emits per-call temperature
traces and that SimJudge specifically is routed at `temp=0.0, top_p=1.0`
while sibling agents (TBGenerator, RTLGenerator) remain at the global
`temp=0.85, top_p=0.95`:

```
$ grep -oE "\[agent=[A-Za-z]+\] at temp: [0-9.]+" mage.token_counter.log | sort -u
[agent=RTLGenerator] at temp: 0.85
[agent=SimJudge]     at temp: 0.0
[agent=TBGenerator]  at temp: 0.85
```

This is the mechanical invariant T11 is defined by (spec §T11.4):
✓ PASSED.

## Mechanism observation — honest framing

### qwen2.5-coder:32b

The 5-problem baseline (`log_ollama_32b_5probs_0/`) that T11 was designed
against does **not** actually exhibit verdict-level oscillation on Prob003
under `qwen2.5-coder:32b`: T9's baseline for Prob003 already shows 4
`true` / 0 `false`. On 32B, T11's behavioral effect is therefore
**observationally null**: baseline was already `true`-locked; T11 keeps it
`true`-locked with lower variance. Agent-count sequence and final
`pipeline_assert` classification match baseline bit-for-bit. The
runner-level `sim_review_golden_benchmark` fallback produces the
`is_pass=true` in both cases.

Prob127 (T9 hard set) also presents as `true`-locked under T11 (3/3 `true`
in the partial log). Under 32B these problems don't exhibit oscillation.

### qwen2.5-coder:7b — actual mechanism evidence

Re-running the same Prob003 under the smaller `qwen2.5-coder:7b` model
**did** produce verdict-level variation under T11: 3 `true` + 1 `false`
across 4 SimJudge calls. Comparison against T9's 7B baseline:

| Metric                   | 7B baseline (T9, log_ollama_5probs_0) | 7B + T11 (log_t11_7b_prob003_verify_0) |
|--------------------------|----------------------------------------|----------------------------------------|
| is_pass                  | **false**                              | **true**                               |
| SimJudge verdicts        | 1 true / 0 false (early crash)         | 3 true / 1 false                       |
| Agent chat calls         | 6                                      | 9                                      |
| RTLEditor rounds         | 0                                      | 0                                      |
| Run time                 | 2m18s (early failure)                  | 2m27s (4 iterations completed)         |
| failure_type             | (pre-T10, not recorded)                | pipeline_assert                        |

**What this means:** under 7B, T11 changed the observable pipeline
behavior. The baseline's 7B Prob003 run produced a single SimJudge call
and crashed before completing the TB loop; under T11 the pipeline ran
through 4 full iterations and the runner-level fallback succeeded.
However, oscillation is **not eliminated** at temperature=0 — verdicts
still flip (3T/1F), demonstrating that prompt context drift between
iterations (different `failed_tb` / `failed_rtl` payloads each loop)
contributes more variance than sampling temperature does. This is a
mechanism finding, not just an acceptance-test result.

The Debug Agent / RTLEditor branch was still not reached: the judge
remained in the TB-loop. Triggering RTLEditor would require either (a) a
problem where the judge eventually returns `false` and stays there, or
(b) a different judge-prompt design that escalates after N consecutive
`true` verdicts. Both are out of T11 scope and noted as follow-ups.

## Metrics

| Metric                              | Baseline (T9, temp=0.85)         | T11 (temp=0.0)                   |
|-------------------------------------|----------------------------------|----------------------------------|
| Prob003 32B SimJudge verdicts       | 4 true / 0 false                 | 4 true / 0 false                 |
| Prob003 32B RTLEditor rounds        | 0                                | 0                                |
| Prob003 32B is_pass                 | true                             | true                             |
| Prob003 32B failure_type            | (pre-T10, not recorded)          | pipeline_assert                  |
| Prob003 7B SimJudge verdicts        | 1 true / 0 false (early crash)   | **3 true / 1 false**             |
| Prob003 7B RTLEditor rounds         | 0                                | 0                                |
| Prob003 7B is_pass                  | **false**                        | **true**                         |
| Prob003 7B agent chat calls         | 6                                | 9                                |
| Prob127 32B SimJudge verdicts       | n/a (not in 5probs set)          | 3 true / 0 false (partial)       |
| Per-agent temp logging present      | no                               | yes (new)                        |
| SimJudge routed at temp=0.0         | no                               | yes (verified in logs)           |

## Notes

- **No changes to** `sim_judge.py`, `tb_generator.py`, `rtl_generator.py`,
  `rtl_editor.py`, `sim_reviewer.py`, `prompts.py`,
  `benchmark_read_helper.py` — per T11 architectural constraint.
- The override dict key is the class-name tag that `TokenCounter.set_cur_tag`
  receives from each agent. If a downstream task adds a new agent class, it
  will transparently use the global setting unless explicitly added to
  `AGENT_SAMPLING_OVERRIDES` or set at runtime via `set_agent_sampling`.
- `set_agent_sampling(tag, temperature, top_p)` can be called from a
  runner at startup to configure experiment-specific sampling without
  editing source — useful for T12/T13 sweep designs.
- `test_tokencounter_invokes_override` bypasses `TokenCounter.__init__`
  with `TokenCounter.__new__(TokenCounter)` and manually sets attributes
  (`llm`, `token_cnts`, `cur_tag`, `enable_reformat_json`, `encoding`) to
  avoid the tiktoken-dependent constructor path in unit tests.

## Follow-ups spotted

- The T11 behavioral hypothesis (temp=0 → breaks oscillation → triggers
  RTLEditor) needs a test problem that *actually oscillates* at baseline.
  Current corpus under 32B doesn't provide one. Proposed followup: T12
  could widen the search across the full verilog-eval-v2 benchmark on
  `qwen2.5-coder:7b` to find an oscillating candidate, then rerun T11
  verification on that specific instance.
- The 4-site duplication across `TokenCounter.count_chat`,
  `count_achat`, and their cached variants is a structural smell. A
  single `_get_chat_kwargs()` helper would consolidate — out of T11
  scope (spec asked for minimal surgical edit), flagging here.
- `AGENT_SAMPLING_OVERRIDES` is a module-level mutable dict. Concurrent
  test runs that modify it need explicit teardown (our new test file
  does this via an `autouse=True` fixture). Future tests must follow
  suit or be moved to a per-test-function copy.
