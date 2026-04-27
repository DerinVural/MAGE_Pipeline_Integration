# T12 — TB-Generator Bypass: DONE

**Spec:** `tasks/T12_TB_BYPASS.md`
**Branch:** `feat/mage-open-v2`
**Date:** 2026-04-24

## Goal

Add an opt-in `bypass_tb_gen` flag that loads the golden testbench directly,
skipping the LLM-based `TBGenerator` entirely. This forces the pipeline past
the TB-revision loop into RTL editing, separating TB-quality failures from
RTL-quality failures.

## Changes

### `src/mage/agent.py` — `TopAgent`

Three additions, no other behaviour changed:

1. **Constructor:** `self.bypass_tb_gen: bool = False`
2. **Setter:** `set_bypass_tb_gen(self, bypass_tb_gen: bool) -> None`
3. **Helper:** `_load_golden_tb_directly() -> Tuple[str, str]` — reads
   `self.golden_tb_path` from disk, returns `(testbench, "")`. Empty interface
   relies on the existing `if self.generated_if:` truthy check at
   `rtl_generator.py:169`.

Pipeline wiring in `run_instance()`:

- **Initial TB step (~L78):** if `bypass_tb_gen`, raise `ValueError` when
  `golden_tb_path` is missing; otherwise log `"TB Gen BYPASSED — loaded
  golden testbench from <path>"` and use `_load_golden_tb_directly()`. Else
  fall through to the original `self.tb_gen.chat(spec)`.
- **Revision loop (L139, the v1 leak fix):** when `tb_need_fix` and
  `bypass_tb_gen`, log `"TB Gen BYPASSED in revision loop — judge requested
  fix, but golden TB is never modified."` and `continue`. The original
  reset/`set_failed_trial`/`chat(spec)` path is unreachable under bypass.

### `tests/test_top_agent.py`

- `args_dict["bypass_tb_gen"] = False` (default-off)
- `agent.set_bypass_tb_gen(getattr(args, "bypass_tb_gen", False))` after
  `set_redirect_log(True)`.

### `tests/test_bypass_tb_gen.py` — new, 4 unit tests, all pass

| Test | Asserts |
|---|---|
| `test_load_golden_tb_directly_returns_file_contents` | helper returns file bytes + empty iface |
| `test_bypass_without_golden_path_raises` | `ValueError` + `tb_gen.chat` not called |
| `test_default_calls_tb_gen_chat` | bypass=False → `tb_gen.chat(spec)` called once |
| `test_bypass_skips_tb_gen_in_revision_loop` | judge always says fix → `tb_gen.chat` never called (regression for v1 leak) |

### Files unchanged (per backward-compat constraint)

`tb_generator.py`, `rtl_generator.py`, `sim_judge.py`, `rtl_editor.py`,
`prompts.py`, `benchmark_read_helper.py`.

## Mechanism: side-by-side

| Stage | `use_golden_tb_in_mage=True` (T9 baseline) | `bypass_tb_gen=True` (T12) |
|---|---|---|
| Initial TB | `tb_gen.chat(spec)` with golden as in-prompt hint | `_load_golden_tb_directly()` reads file, `tb_gen.chat` not called |
| Sim-judge says `tb_need_fix=True` | `tb_gen.set_failed_trial(...)` + `tb_gen.chat(spec)` regenerate | `continue` — golden TB never modified |
| `tb_gen.chat` calls per cell | 1 + N revisions (saw 4 in T11 hard cells) | **0** |
| Interface | from `tb_gen.chat` return | `""` (rtl_generator falls back) |

## Acceptance criteria

| Check | Target | Result |
|---|---|---|
| `tb_gen.chat` calls under bypass | 0 | **0/20 cells** (10 × 32B + 10 × 7B) |
| Default behaviour preserved | `tb_gen.chat` called when `bypass_tb_gen=False` | sanity run (Prob001, 7B): 3 calls, no BYPASSED log |
| Unit tests | all pass | 4/4 |
| `golden_tb_path=None` under bypass | `ValueError` | covered by test |

## Smoke runs

10-problem set: `Prob001 Prob002 Prob003 Prob004 Prob005 Prob119 Prob121
Prob124 Prob127 Prob128`. `temperature=0.85`, `top_p=0.95`, default `n=1`.

### qwen2.5-coder:32B + bypass — 7/10 pass, 10:49

| Problem | Pass | Failure type | byp_init | byp_loop | tbg.chat | run_time |
|---|---|---|---|---|---|---|
| Prob001_zero | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:37 |
| Prob002_m2014_q4i | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:31 |
| Prob003_step_one | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:33 |
| Prob004_vector2 | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:47 |
| Prob005_notgate | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:38 |
| Prob119_fsm3 | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 1:31 |
| Prob121_2014_q3bfsm | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 1:18 |
| Prob124_rule110 | ✗ | pipeline_assert | 1 | 0 | 0 | 1:43 |
| Prob127_lemmings1 | ✗ | pipeline_assert | 1 | 0 | 0 | 1:18 |
| Prob128_fsm_ps2 | ✗ | pipeline_assert | 1 | 4 | 0 | 1:50 |

¹ T10 known false-negative: pipeline asserts `rtl_need_fix should be True
only when sim_mismatch_cnt > 0` even when `is_pass=True` and `Mismatches: 0`.

### qwen2.5-coder:7B + bypass — 5/10 pass, 3:53

| Problem | Pass | Failure type | byp_init | byp_loop | tbg.chat | run_time |
|---|---|---|---|---|---|---|
| Prob001_zero | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:09 |
| Prob002_m2014_q4i | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:07 |
| Prob003_step_one | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:09 |
| Prob004_vector2 | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:11 |
| Prob005_notgate | ✓ | pipeline_assert¹ | 1 | 0 | 0 | 0:09 |
| Prob119_fsm3 | ✗ | pipeline_assert | 1 | 0 | 0 | 0:19 |
| Prob121_2014_q3bfsm | ✗ | **functional_mismatch** | 1 | 0 | 0 | 1:28 |
| Prob124_rule110 | ✗ | pipeline_assert | 1 | 0 | 0 | 0:24 |
| Prob127_lemmings1 | ✗ | pipeline_assert | 1 | 0 | 0 | 0:18 |
| Prob128_fsm_ps2 | ✗ | pipeline_assert | 1 | 1 | 0 | 0:14 |

## Headline metrics

- **TB-Gen LLM call count: 0/20 cells** ✓ (acceptance met)
- **byp_init=1 in all 20 cells** (initial bypass log present in every run)
- **byp_loop>0 in 2/20 cells** (32B Prob128: 4 revision-loop bypass logs;
  7B Prob128: 1) — judge re-fires `tb_need_fix` against golden TB; the
  `continue` swallows it correctly.
- **First-ever `functional_mismatch`** in this fork's history: 7B Prob121
  produced syntactically-broken SystemVerilog (`assign z = case(...) endcase`,
  case-as-expression is not legal Verilog) → 5 RTLGen syntax retries
  exhausted → failure_type set by T10 sidecar. Bypass forced the pipeline
  past TB and exposed an RTL-quality failure mode that was previously masked
  by TB-loop exits.
- **RTLEditor rounds: 0/20 cells.** Debug Agent still untriggered. Out of
  T12 scope; documented as the next obstacle.
- **Candidate-generation rounds: 0/20 cells.**

## v1 → v2 bug fix

First implementation patched only the initial TB step. 32B v1 smoke showed
`tbg.chat` called 4× on Prob004/Prob121/Prob128 because the revision loop's
`if tb_need_fix:` branch still ran the regenerate path. Spec wording
("testbench is never modified") demanded a second patch inside the loop.
v2 added the `if self.bypass_tb_gen: continue` guard. Re-ran smokes — 32B v2
confirmed `tbg=0/10`, `byp_loop=4` on Prob128. Added 4th unit test
`test_bypass_skips_tb_gen_in_revision_loop` to lock the regression.

## Out-of-scope follow-ups

- **T10 false-negative on `pipeline_assert`** when `is_pass=True`: 12/20
  cells. The sidecar's classifier is too eager; `rtl_need_fix=True` and
  `sim_mismatch_cnt=0` is reachable on the *previous* iteration before the
  current pass. Not a T12 concern.
- **Debug Agent / RTLEditor still cold:** even with bypass, the pipeline
  exits before `rtl_edit.chat` runs. Suggests the assertion checked above
  fires before edit-loop entry. Candidate for T13.
- **Empty interface side effect:** `_load_golden_tb_directly` returns
  `interface=""`. `rtl_generator.py:169` truthy-check accepts this; no
  observed harm in 20 cells, but worth tracking if a benchmark adds a
  problem whose RTLGen needs a non-empty interface.

## What this means

The bypass works as specified. TBGen is fully removable as a contributor to
failure for these 20 cells. The fact that pass-rates didn't move much
(32B 7/10, 7B 5/10) means **TB quality is not the dominant failure cause
for this benchmark slice** — RTL-quality and pipeline-classifier issues
dominate, and T12 has cleared the path to attack them in T13.
