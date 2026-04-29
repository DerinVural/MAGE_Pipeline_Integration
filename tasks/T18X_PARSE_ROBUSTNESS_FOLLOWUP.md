# Task T18.x: Parse Robustness Follow-Up (T18 Regression Fix + None Guard)

**Status:** PENDING
**Priority:** HIGH — closes T18's known follow-up gaps before T19
**Depends on:** T18 (`a1244e6` on `feat/t17a-vllm-provider`)
**Reference:** `reports/v2/T18_DONE.md` §F1, §F3
**Estimated effort:** 2-3 hours total (1h coding + 1h verify rerun + 30min report)
**Estimated cost:** ~$10 (RunPod 1×H100 for M4 verify rerun, ~30min)

---

## Context

T18 introduced `parse_json_robust()` and swapped four agent files to use
it. Two issues surfaced during T18.4 verify that the spec did not
anticipate:

1. **F1 regression**: `rtl_generator.py:212` and `tb_generator.py:288`
   have existing `except json.decoder.JSONDecodeError` blocks that route
   parse failures into `reasoning="Json Decode Error: ..."` — this lets
   the agent's outer retry loop (`max_trials=5`) re-prompt the model and
   often recover. T18 swapped `json.loads` to `parse_json_robust` but
   did NOT widen the except clauses. The new `MageJsonParseError`
   propagates past these handlers and aborts the agent run.

2. **F3 None guard**: `parse_json_robust(None)` raises `TypeError` from
   `re.search(pattern, None)` inside strategy 3, before any of the five
   strategies declare failure. The agent.py outer except catches it but
   classifies as `unexpected` rather than as a parse failure.

3. **No retry path in rtl_editor.py and sim_judge.py**: These two files'
   `parse_output()` methods have NO `try/except` at all (they were
   upstream's no-fallback design assuming Claude always emits clean
   JSON). T18 added robust parsing but left no retry escape. On
   unrecoverable parse failure, the exception propagates and ends the
   agent run.

T18.x addresses all three with minimal-invasive edits, then re-verifies
the M4 (Qwen/Qwen3.6-27B) smoke run to measure the actual delta.

---

## Hard constraints

1. **Continue T18's "agent files modify is acceptable" exception.** This
   is the one-task-after-another extension of the rule break. Once T18.x
   merges, the agent-modify exception is closed; no further agent files
   modifications are pre-approved without a new PM directive.
2. **No new helper functions in `utils.py`.** T18 added two
   (`parse_json_robust`, `MageJsonParseError`); T18.x reuses them
   without addition. The None guard is a 2-line addition INSIDE
   `parse_json_robust`, not a new function.
3. **No prompt edits.** No changes to `prompts.py` or any prompt string
   embedded in agent files. The retry path's success depends on the
   existing prompt's robustness, which is upstream's design.
4. **Verify rerun config is identical to T18.4.** Same vLLM v4 serve
   command (no `--reasoning-parser` flag), same 10-problem regex, same
   sampling kwargs. Different `run_identifier` to keep artifacts
   separate.
5. **Verify rerun must complete or write BLOCKED.** Per-cell wall-time
   cap is 25 min as before. If pod runtime exceeds 1.5 hours, write
   BLOCKED.

---

## Scope

### T18.x.1 — `parse_json_robust` None guard

**File:** `src/mage/utils.py`

Add at the very top of `parse_json_robust()`, before strategy 1:

```python
def parse_json_robust(content: str) -> dict:
    """..."""
    if content is None:
        raise MageJsonParseError(
            "parse_json_robust received None (model returned no content)",
            original_content="",
        )

    # Strategy 1: direct json.loads
    ...
```

Acceptance: existing 10 unit tests still pass; one new test added (see
T18.x.4).

### T18.x.2 — Widen existing except clauses (rtl_generator, tb_generator)

**File:** `src/mage/rtl_generator.py`

Around line 212 (the existing `except json.decoder.JSONDecodeError`),
widen to also catch `MageJsonParseError`:

```python
# Before:
except json.decoder.JSONDecodeError as e:
    reasoning = f"Json Decode Error: {e}"
    ...

# After:
except (json.decoder.JSONDecodeError, MageJsonParseError) as e:
    reasoning = f"Json Decode Error: {e}"
    ...
```

Add the import at the top of the file (next to existing
`from .utils import ... parse_json_robust`):

```python
from .utils import add_lineno, parse_json_robust, MageJsonParseError
```

**File:** `src/mage/tb_generator.py`

Same change at line 288 (the existing
`except json.decoder.JSONDecodeError`). Same import update.

### T18.x.3 — Add try/except to rtl_editor.py and sim_judge.py

These two files have **no** existing try/except around their
`parse_output()` calls. T18.x adds minimal try/except blocks that mirror
the rtl_generator pattern but are NOT new retry mechanisms — they just
prevent the exception from killing the agent.

**File:** `src/mage/rtl_editor.py:347-348` (current):

```python
def parse_output(self, response: ChatResponse) -> RTLEditorStepOutput:
    output_json_obj: Dict = parse_json_robust(response.message.content)
    ...
```

After T18.x:

```python
def parse_output(self, response: ChatResponse) -> RTLEditorStepOutput:
    try:
        output_json_obj: Dict = parse_json_robust(response.message.content)
    except (json.decoder.JSONDecodeError, MageJsonParseError) as e:
        # Surface as a structured no-op edit so the outer retry loop
        # can re-prompt. The "do_nothing" command leaves RTL unchanged
        # and lets the next iteration request a fresh edit.
        logger.warning(f"RTLEditor parse_output failed: {e}; emitting no-op")
        return RTLEditorStepOutput(
            reasoning=f"Parse error: {e}",
            action_input=ActionInput(command="do_nothing", args={}),
        )
    action_input = output_json_obj["action_input"]
    ...
```

Add the import at the top:
```python
import json
from .utils import parse_json_robust, MageJsonParseError
```

**Important caveat:** the no-op fallback assumes RTLEditor's
`do_nothing` command exists. **Verify this before the patch lands.** If
the command doesn't exist, the spec needs revision; do NOT invent
behavior. If `do_nothing` doesn't exist, file BLOCKED and ask PM how
to handle (options: do nothing and propagate the exception, mark RTL as
unfixable, etc.).

**File:** `src/mage/sim_judge.py:107-108` (current):

```python
def parse_output(self, response: ChatResponse) -> TBOutputFormat:
    output_json_obj: Dict = parse_json_robust(response.message.content)
    ...
```

After T18.x:

```python
def parse_output(self, response: ChatResponse) -> TBOutputFormat:
    try:
        output_json_obj: Dict = parse_json_robust(response.message.content)
    except (json.decoder.JSONDecodeError, MageJsonParseError) as e:
        # Surface as a "TB needs fix" verdict so the outer loop
        # retries TB regeneration. This is conservative: if we can't
        # parse the judge's output, assume the TB is suspect.
        logger.warning(f"SimJudge parse_output failed: {e}; default tb_needs_fix=True")
        return TBOutputFormat(
            reasoning=f"Parse error: {e}",
            tb_needs_fix=True,
        )
    return TBOutputFormat(
        reasoning=output_json_obj["reasoning"],
        tb_needs_fix=output_json_obj["tb_needs_fix"],
    )
```

Add the import at the top:
```python
import json
from .utils import add_lineno, parse_json_robust, MageJsonParseError
```

**Caveat:** SimJudge's parse_output is invoked from rtl_editor's TB
review path. Defaulting to `tb_needs_fix=True` will trigger TB
regeneration, which is the **safer** failure mode (the alternative
would be to silently accept a bad TB). This is conservative on purpose.

### T18.x.4 — Unit test additions

In `tests/test_json_parse_robust.py`, add ONE test:

```python
def test_none_input_raises_mage_error():
    """parse_json_robust(None) raises MageJsonParseError, not TypeError."""
    with pytest.raises(MageJsonParseError) as exc_info:
        parse_json_robust(None)
    assert "None" in str(exc_info.value)
    assert exc_info.value.original_content == ""
```

In `tests/test_top_agent.py` (or a new `tests/test_t18x_regression.py`),
add tests for the four agent-file try/except paths if upstream's test
pattern allows. If creating a new test file feels too invasive (most
agent-method tests in MAGE require live LLM mocks), document the gap
in the report and rely on the M4 verify rerun for end-to-end
validation.

### T18.x.5 — M4 verify rerun

Identical to T18.4 with new run identifier:

```python
args_dict = {
    "provider": "vllm",
    "model": "Qwen/Qwen3.6-27B",
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
run_identifier = "t18x_m4_verify"
```

vLLM serve config: same v4 as T18.4 — NO `--reasoning-parser` flag.

Pod: 1×H100 RunPod, ≤1.5 hours total. Auto-shutdown configured.

For each cell capture (mirror T18 report format):
- `is_pass`, `failure_type`, wall time
- `parse_json_robust` call success rate (grep logs for the warning lines
  added in T18.x.3)
- Whether retry path was actually exercised (compare token_counter call
  counts to T18.4's; expected: hard problems now show >5 calls instead
  of 1-2 calls because retry kicks in)

### T18.x.6 — Headline measurement

The T18.x report's headline numbers:

| Metric | T17A M4 | T18 M4 | T18.x M4 (target) |
|---|---|---|---|
| Easy 5/5 | 5/5 ✅ | 5/5 ✅ | 5/5 ✅ |
| Hard 0/5 mode | runner-abort | recorded fail | retry-recovery PASS or recorded fail |
| Token calls (hard) | varies | 1-2 (parse abort) | >5 (retry kicks in) |
| Total pass rate | 5/10 | 5/10 | **expected 5-7/10** |

The realistic target is 5-7/10. If T18.x produces 6/10 or 7/10,
that is the F1 closure measurement and the project's M4 number for
T17B planning.

If T18.x still produces 5/10 with the retry path intact (no
runner-abort, no parse failures in logs), the residual 0/5 hard
indicates either (a) the model genuinely cannot solve those problems
with this pipeline config, or (b) max_token=4096 is the actual binding
constraint (T18 report's hypothesis). Either is informative.

---

## Acceptance criteria

- [ ] `parse_json_robust` has None guard at top.
- [ ] `tests/test_json_parse_robust.py` has 11 tests passing (T18's
      10 + T18.x's 1).
- [ ] `rtl_generator.py:212` except clause widened to also catch
      `MageJsonParseError`. Import updated.
- [ ] `tb_generator.py:288` except clause widened. Import updated.
- [ ] `rtl_editor.py:348` parse_output wrapped in try/except returning
      no-op. Import added. **`do_nothing` command verified to exist
      before this lands.**
- [ ] `sim_judge.py:108` parse_output wrapped in try/except returning
      `tb_needs_fix=True`. Import added.
- [ ] No edits to `prompts.py`, `benchmark_read_helper.py`, or any
      other agent file.
- [ ] M4 verify rerun completes; per-cell wall time ≤25 min; pod
      runtime ≤1.5 hours.
- [ ] Pod shut down after rerun.
- [ ] Report `reports/v2/T18X_DONE.md` filed with side-by-side
      T17A/T18/T18.x table on M4.
- [ ] Commit message: `[T18.x] Widen exception handlers + None guard for parse_json_robust`

---

## Stop conditions

File `reports/v2/T18X_BLOCKED.md` if:

- `do_nothing` command does NOT exist in `RTLEditor`. Stop, ask PM
  how to handle (don't invent fallback behavior).
- M4 verify rerun produces NEW failure modes not seen in T17A or T18
  (e.g., agent crashes inside the new try/except blocks). Document
  verbatim, do not patch in T18.x.
- M4 verify pass rate **drops below 5/10**. Suggests the new fallback
  paths cause regressions on previously-passing easy problems.
- vLLM v4 serve config no longer reproduces (model file evicted from
  HF cache, dependency rot). Document and stop.
- Pod runtime exceeds 1.5 hours.

---

## Do NOT

- Modify any agent file beyond the four documented files.
- Edit `prompts.py`, `benchmark_read_helper.py`.
- Add new helper functions to `utils.py` beyond the None guard.
- Re-implement the retry loop. The retry path EXISTS in
  rtl_generator and tb_generator already; T18.x just makes the new
  exception class visible to it. Don't add new retry logic.
- Change the `max_token=4096` setting. The 4096 truncation hypothesis
  is a separate finding (out of T18.x scope).
- Run additional models in T18.x. M4 only — that's where the
  regression surfaced and where the F1 closure measurement matters.
- Touch the vLLM serve config. v4 from T18.4 is the reference.
- Modify `--reasoning-parser` handling. T18 already removed the flag.

---

## Report template

```markdown
# T18.x — Parse Robustness Follow-Up

**Date:** 2026-04-29 or later
**Branch:** feat/t17a-vllm-provider
**Commits:** <hash>
**Pod:** RunPod 1×H100 80GB
**Run id:** t18x_m4_verify_0

## Scope
Close T18's three known follow-up issues:
1. None guard in parse_json_robust
2. Widened except clauses in rtl_generator, tb_generator
3. New try/except in rtl_editor, sim_judge

## Implementation summary
- src/mage/utils.py: None guard added (line N)
- src/mage/rtl_generator.py: except clause widened (line 212)
- src/mage/tb_generator.py: except clause widened (line 288)
- src/mage/rtl_editor.py: parse_output wrapped (lines 347-355)
- src/mage/sim_judge.py: parse_output wrapped (lines 107-115)
- tests/test_json_parse_robust.py: +1 test

## Pre-flight checks
- `do_nothing` command exists in RTLEditor: YES | NO (cite line)
- All 4 import statements verified: YES

## M4 verify rerun

| Problem | T17A result | T18 result | T18.x result | T18.x mode |
|---|---|---|---|---|
| Prob001 | ✅ | ✅ | ✅ | clean |
| ...10 rows... |

Pass rate: T17A 5/10 → T18 5/10 → **T18.x X/10**

## Retry path activation evidence

Hard problem token call counts:
| Problem | T18 calls | T18.x calls | Retry kicked in? |
|---|---|---|---|
| Prob119 | 1 | <N> | yes/no |
| ...5 hard rows... |

## Findings
<E.g., "T18.x raised hard-problem pass rate from 0/5 to 2/5 by enabling
the retry path; remaining 3/5 fail consistent with max_token=4096
truncation, not parser brittleness.">

## Status
**T18.x PASS / PARTIAL / BLOCKED.**

## Follow-ups spotted
<E.g., "max_token=4096 truncation surfaced as a binding constraint;
T19 or a new task should consider raising max_token for reasoning
models.">
```

---

## After T18.x

PM reviews the T18.x report and decides:

- **If hard pass rate is 1-3/5 and retry path is exercised**: F1 is
  closed. Move to T19 (F2 wall-time guard).
- **If hard pass rate is still 0/5 but retry is exercised**: F1 is
  closed mechanically; remaining failures are model-or-prompt issues,
  not parser. Note in T19 spec, move on.
- **If hard pass rate dropped below 5/10**: T18.x introduced a
  regression. Investigate, possibly roll back specific patches.
- **If `do_nothing` doesn't exist**: T18.x BLOCKED, PM rewrites
  rtl_editor handling section.

After T18.x closes, branch merge `feat/t17a-vllm-provider` →
`feat/mage-open-v2` is recommended (consolidates vLLM provider + T17A
+ T18 + T18.x in one merge commit). Then T19 (F2 wall-time guard)
opens on the main branch.
