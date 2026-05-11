# Task T18: JSON Parse Robustness (F1 Fix)

**Status:** PENDING
**Priority:** HIGH — gates T19, T20, and T17B (full benchmark)
**Depends on:** Branch merge `feat/t17a-vllm-provider` → `feat/mage-open-v2`
**Reference:** T17A_VLLM_SETUP.md §F1; affects 4 agent files

---

## Context

T17A §F1 documented a pipeline brittleness: `sim_judge.parse_output`
calls hard `json.loads` on model responses with no fallback. When a
model emits near-JSON (unterminated string, embedded newline, trailing
comma, or content after the closing brace), the exception propagates
and the problem is marked FAIL **before reaching simulation**.

The T17A report attributed M3 (DeepSeek-Coder-V2-16B) and M4
(Qwen3.6-27B) hard-problem failures to this issue, not to model
capability. Token-counter call counts for affected cells are 1-2
(parse abort) instead of the expected 4-50.

**Critical scope correction:** Pre-spec investigation revealed the
hard `json.loads` pattern exists in **four** agent files, not just
one:

| File | Line | Agent |
|---|---|---|
| `src/mage/sim_judge.py` | 108 | SimJudge |
| `src/mage/rtl_editor.py` | 347 | RTLEditor |
| `src/mage/rtl_generator.py` | 208 | RTLGenerator |
| `src/mage/tb_generator.py` | 282 | TBGenerator |

T18 must address all four to be complete. T17A's §F1 only listed
sim_judge because that's where the failure surfaced; the same
fragility lives in the other three.

---

## The "no modify agent files" rule revisited

Every previous task (T10, T11, T12, T13, T14, T15-bonus, T17A) has
maintained: **do not modify `tb_generator.py`, `rtl_generator.py`,
`sim_judge.py`, `rtl_editor.py`, `prompts.py`,
`benchmark_read_helper.py`**. T18 cannot honor this rule literally,
because the bug lives in those files.

**T18's resolution:** make the change as small and uniform as
possible.

- Add ONE helper function `parse_json_robust()` in `src/mage/utils.py`
- Replace each `json.loads(response.message.content, strict=False)`
  with `parse_json_robust(response.message.content)` — a one-token
  swap per file, four files total
- All actual logic (fallback chain, regex extraction) lives in
  `utils.py`, not in agent files
- Agent files become tinier-than-T10 modifications (1 line each, plus
  one import)

This is the minimum-invasive form. The PM accepts breaking the "no
modify agent files" rule for T18 specifically, because the bug is
inside agent files and any fix necessarily touches them.

**Important:** the helper goes to `utils.py`, NOT to a new file.
`utils.py` already has `reformat_json_string()` (the T5-era JSON
hardening). T18 adds `parse_json_robust()` next to it. Keep the
JSON-handling code colocated.

---

## Goal

Eliminate `JSONDecodeError` exceptions from MAGE's pipeline by
adding a fallback parsing chain in `parse_json_robust()`. When the
fallback succeeds, the agent receives a valid dict and proceeds
normally. When the fallback fails (truly unparseable output), the
function raises a structured `MageJsonParseError` that `agent.py`'s
T10-era exception handler will categorize as `unexpected` failure
type.

Headline measurement: re-run T17A's M3 and M4 smoke (10 problems
each) post-T18 and confirm token-counter call counts match the
"normal range" pattern (no more 1-2 call aborts on hard problems).

---

## Hard constraints

1. **Helper lives in `utils.py`.** No new file. No new module.
2. **Each agent file gets exactly one-line behavioral change** (the
   `json.loads(...)` → `parse_json_robust(...)` swap), plus one
   `from .utils import parse_json_robust` import line. No other
   agent-file edits.
3. **The new helper raises a structured exception when it ultimately
   fails.** The exception class `MageJsonParseError` is also defined
   in `utils.py`. Agent files do not need to catch this — `agent.py`'s
   outer except at line 253 (T10 era) catches `Exception` already and
   T10's failure-info sidecar will route it to `failure_type =
   "unexpected"`.
4. **Default behavior is unchanged when the model output IS valid
   JSON.** Plan v3 faithful-reproduction principle: a model that
   already emits clean JSON sees identical pipeline behavior.
5. **No model-specific heuristics in the fallback chain.** The
   helper must work for any model. No "if Qwen do X, if DeepSeek do
   Y" branches. The fallback is purely lexical, not model-aware.
6. **Test on the four agent call sites.** A unit test that exercises
   each agent's `parse_output` with a known-bad model response and
   verifies the response parses correctly.

---

## Scope

### T18.1 — `parse_json_robust()` helper in `utils.py`

Add to `src/mage/utils.py`:

```python
class MageJsonParseError(Exception):
    """Raised when parse_json_robust exhausts all fallback strategies."""
    def __init__(self, message: str, original_content: str):
        super().__init__(message)
        self.original_content = original_content


def parse_json_robust(content: str) -> dict:
    """Parse a JSON dict from a model response with fallbacks.

    Tries (in order):
      1. Strict json.loads on the raw content
      2. Strict json.loads after stripping markdown fences
      3. Strict json.loads on the FIRST {...} block extracted via regex
      4. Strict json.loads on the LAST {...} block (some models emit
         a chain-of-thought before the final answer)
      5. dirtyjson on the original content (forgiving parser already
         used by reformat_json_string upstream)

    On all-fallbacks-exhausted, raises MageJsonParseError. The
    original content is preserved on the exception for upstream
    logging.

    Returns:
        dict — the parsed JSON dict.

    Raises:
        MageJsonParseError — if no strategy parses to a dict.

    Notes:
        - This helper does NOT validate schema. Agent files still
          access expected keys (e.g., output['module']) and may raise
          KeyError if the model omits them. That's a separate
          failure mode (already handled by T10's sidecar as
          'unexpected').
        - The helper does not mutate input or log to disk. It is
          pure.
    """
    import json
    import re

    # 1. Direct
    try:
        result = json.loads(content, strict=False)
        if isinstance(result, dict):
            return result
    except json.JSONDecodeError:
        pass

    # 2. Strip markdown fences (already in reformat_json_string but
    # apply here too for cases where reformat wasn't called)
    cleaned = content.strip()
    if cleaned.startswith('```'):
        # Strip ```json\n...\n``` or ```\n...\n```
        cleaned = re.sub(r'^```(?:json)?\s*\n', '', cleaned)
        cleaned = re.sub(r'\n```\s*$', '', cleaned)
        try:
            result = json.loads(cleaned, strict=False)
            if isinstance(result, dict):
                return result
        except json.JSONDecodeError:
            pass

    # 3. First {...} block via regex (greedy, balanced)
    # This handles "Some preamble {valid json} some postamble" cases
    first_match = re.search(r'\{.*\}', content, re.DOTALL)
    if first_match:
        try:
            result = json.loads(first_match.group(0), strict=False)
            if isinstance(result, dict):
                return result
        except json.JSONDecodeError:
            pass

    # 4. Last {...} block — for chain-of-thought before final answer
    # Walk backwards finding the last balanced { ... }
    # Simple approach: find rightmost '{', then match braces
    last_open = content.rfind('{')
    if last_open >= 0:
        depth = 0
        for i in range(last_open, len(content)):
            if content[i] == '{':
                depth += 1
            elif content[i] == '}':
                depth -= 1
                if depth == 0:
                    candidate = content[last_open:i+1]
                    try:
                        result = json.loads(candidate, strict=False)
                        if isinstance(result, dict):
                            return result
                    except json.JSONDecodeError:
                        pass
                    break

    # 5. dirtyjson fallback (already a project dependency from T5 era)
    try:
        import dirtyjson
        result = dirtyjson.loads(content)
        if isinstance(result, dict):
            return dict(result)  # convert AttributedDict → dict
    except Exception:
        pass

    # All strategies exhausted
    raise MageJsonParseError(
        f"All JSON parse strategies failed. Content starts: {content[:200]!r}",
        original_content=content,
    )
```

### T18.2 — Update the four agent files (one-line each)

For each of the four files, the change is mechanical:

**`src/mage/sim_judge.py`:**

```python
# Line 108 (current):
output_json_obj: Dict = json.loads(response.message.content, strict=False)

# After:
output_json_obj: Dict = parse_json_robust(response.message.content)
```

Add the import at the top of the file:
```python
from .utils import parse_json_robust
```

Repeat identical change for:
- `src/mage/rtl_editor.py` (line 347)
- `src/mage/rtl_generator.py` (line 208)
- `src/mage/tb_generator.py` (line 282)

**That's it for agent files.** No further behavioral edits, no new
methods, no extra error handling. The T10 era's `agent.py:253`
outer except catches the exception if it propagates.

### T18.3 — Unit tests

Create `tests/test_json_parse_robust.py` with these cases:

1. **`test_clean_json_passthrough`** — `'{"a": 1, "b": "x"}'` →
   `{"a": 1, "b": "x"}`. Confirms strategy 1 wins.

2. **`test_markdown_fence_stripping`** — `'```json\n{"a": 1}\n```'`
   → `{"a": 1}`. Strategy 2 wins.

3. **`test_preamble_postamble`** — `'Here is the JSON: {"a": 1} hope this helps'`
   → `{"a": 1}`. Strategy 3 wins.

4. **`test_chain_of_thought_before_json`** — `'Let me think... <think>step 1</think> Final: {"a": 1}'`
   → `{"a": 1}`. Strategy 4 wins.

5. **`test_unterminated_string_dirtyjson`** — `'{"a": 1, "b": "unterminated\nx"}'`
   → handled by dirtyjson (strategy 5). Confirms dirtyjson called.

6. **`test_truly_unparseable_raises`** — `'this is not json at all'`
   → `MageJsonParseError`. Confirms exception structure.

7. **`test_exception_preserves_content`** — Same as #6 but assert
   `e.original_content == 'this is not json at all'`. Important for
   debugging.

8. **`test_array_at_top_level_fails`** — `'[1, 2, 3]'` →
   `MageJsonParseError` (we want a dict, not a list). Confirms the
   `isinstance(result, dict)` guard.

9. **`test_nested_json_handled`** — `'{"a": {"b": "c"}}'` →
   `{"a": {"b": "c"}}`. Confirms nested structures pass through.

10. **`test_real_t17a_failure_case`** — Reproduce the exact M4 Prob119
    failure pattern (search T17A logs for the offending response, or
    use a representative near-JSON sample). Confirms T18 fixes the
    real-world case.

### T18.4 — Verification: re-run T17A M4 smoke

After T18.1-T18.3 are committed:

1. Boot a 1×H100 RunPod pod (or use existing T17A pod if still alive).
2. Re-run T17A's M4 (Qwen3.6-27B) smoke with identical config:
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
   filter_instance = "<same 10-problem regex from T17A>"
   run_identifier = "t18_m4_verify"
   ```
3. Confirm token-counter call counts on hard problems are now in the
   normal range (>4 calls, not 1-2).
4. Compare M4 hard problem PASS/FAIL to T17A's 0/5. If T18 fix
   exposes M4's true capability, expect 1-3 PASSes (not zero).

If T18 surfaces functional issues that were hidden by F1, document
them in the report. Do not fix them in T18 — file follow-up work.

**Optional:** also re-run M3 (DeepSeek-Coder-V2-16B) smoke for the
same verification. Skip if pod time is tight; M4 is the critical case.

### T18.5 — Coordination with vLLM `response_format=json_object`

T17A's vLLM integration sets `additional_kwargs={"response_format":
{"type": "json_object"}}`. This already encourages clean JSON from
the server side. T18 is the **client-side defensive layer** that
catches what slips through.

**Important:** T18 must not interact with the response_format flag.
The flag stays as-is. T18's helper is independent — it works whether
or not the server enforced JSON output.

---

## Acceptance criteria

- [ ] `parse_json_robust()` and `MageJsonParseError` added to
      `src/mage/utils.py`.
- [ ] Four agent files updated identically (1 import + 1 line swap
      each):
  - [ ] `src/mage/sim_judge.py:108`
  - [ ] `src/mage/rtl_editor.py:347`
  - [ ] `src/mage/rtl_generator.py:208`
  - [ ] `src/mage/tb_generator.py:282`
- [ ] No other agent-file edits.
- [ ] No edits to `prompts.py` or `benchmark_read_helper.py`.
- [ ] `tests/test_json_parse_robust.py` exists with all 10 unit tests
      passing.
- [ ] Existing tests still pass:
      `pytest tests/ --ignore=tests/test_single_agent.py`
- [ ] T18 verification (T18.4) on M4 completed; report documents the
      delta from T17A's 0/5 hard.
- [ ] Commit message: `[T18] Add parse_json_robust fallback chain (F1 fix)`
- [ ] Report `reports/v2/T18_DONE.md` filed.

---

## Stop conditions

File `reports/v2/T18_BLOCKED.md` if:

- Any of the four agent-file line numbers don't match (upstream may
  have shifted; verify before patching). Document the actual line.
- The `parse_json_robust()` helper makes a previously-passing test
  fail. Roll back, write BLOCKED.
- The T18.4 M4 verification still produces 1-2 token-counter calls
  on hard problems (suggests there's a second JSON-parse site we
  missed). Document the new failure trace verbatim.
- Existing schema-validation calls (e.g.,
  `output_json_obj["module"]`) crash because the new parser returns
  a structurally different dict. Investigate and revert if needed.

---

## Do NOT

- Touch `prompts.py` or `benchmark_read_helper.py`.
- Add try/except blocks inside agent files. The helper handles
  parsing errors; agent files just call it.
- Make `parse_json_robust()` model-aware. No `if "Qwen" in model:`
  branches. The helper is lexical, not semantic.
- Modify `reformat_json_string()` (the T5-era helper). Leave it
  alone — it has its own callers and contract.
- Replace `json.loads(...)` calls anywhere outside the four documented
  agent files. (`utils.py` itself uses `json.loads` internally — that
  stays.)
- Remove the `strict=False` argument when calling `json.loads`
  inside the helper. It's there for control-character tolerance
  and matters.
- Run T19 or T20 work in this task. T18 is parser-only.
- Replace the existing T17A pod artifacts. The T18 verify run uses
  a new `run_identifier`.

---

## Report template

```markdown
# Task T18: JSON Parse Robustness (F1 Fix)

**Status:** DONE
**Branch:** feat/mage-open-v2
**Commits:** <hash>

## Changes
- src/mage/utils.py: added `parse_json_robust()` and `MageJsonParseError`
- src/mage/sim_judge.py: swapped json.loads at L108 + import
- src/mage/rtl_editor.py: swapped json.loads at L347 + import
- src/mage/rtl_generator.py: swapped json.loads at L208 + import
- src/mage/tb_generator.py: swapped json.loads at L282 + import
- tests/test_json_parse_robust.py: 10 unit tests

## Verification
- pytest tests/test_json_parse_robust.py -v: 10 passed
- pytest tests/ --ignore=tests/test_single_agent.py: <N> passed
- M4 verification rerun (same 10 problems as T17A):
  | Problem | T17A token calls | T18 token calls | T17A result | T18 result |
  | Prob119 | 1 | <N> | FAIL (parse) | <PASS/FAIL> |
  | ... |

## Findings
<E.g.: "T18 fix surfaced M4's true capability on hard problems —
2/5 PASS where T17A reported 0/5. The previous failures were entirely
F1 brittleness, not model limitation.">

## Notes
<Anything PM should know.>

## Follow-ups spotted
<Out-of-scope observations.>
```

---

## After T18

PM reviews the report and decides:
- If T18.4 confirms the fix (token counts normal, no regressions):
  proceed to T19 (F2 wall-time guard).
- If T18 surfaces previously-hidden failure modes (e.g., M4 true
  pass rate is still poor for non-F1 reasons): document and proceed
  to T19 anyway. T18's job is to remove the parsing bottleneck;
  what's underneath is separate analysis.

T18 → T19 → T20 → T17B is the planned sequence. T18 is the
foundation; the others depend on it.
