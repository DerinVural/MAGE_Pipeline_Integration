# Task T10: Silent Exception Structured Logging

**Status:** PENDING
**Priority:** HIGH — first task of Faz 0 (Plan v3)
**Depends on:** None (fresh branch work)
**Reference:** `docs/closure_summary.md` Section 1.3 Bulgu 1, item "Silent
exception handling"; `docs/plan_v3.md` §3 T10

---

## Context

The previous project documented a silent-exception bug in
`src/mage/agent.py:253`:

```python
except Exception:
    exc_info = sys.exc_info()
    traceback.print_exception(*exc_info)
    ret = False, f"Exception: {exc_info[1]}"
```

All exceptions — including assertion failures from TB Gen retry
exhaustion, unexpected pipeline crashes, and malformed inputs — are
collapsed into a single `(False, ...)` tuple that the runner writes to
`record.json` as `is_pass: false`. This makes three very different
outcomes indistinguishable in logs and metrics:

1. **Functional mismatch:** RTL is syntactically valid and pipeline
   completed normally, but simulation mismatched golden testbench
2. **Pipeline assertion:** TB Gen couldn't compile a testbench after
   retries, pipeline asserted out before reaching candidate generation
3. **Unexpected exception:** An actual bug (network timeout, malformed
   LLM response, null dereference, etc.)

In T5-T9 we consistently couldn't tell (1) from (2). Before we compare
8 open-source models in Faz 2, we must fix this — otherwise
"Qwen-32B scored 40%, DeepSeek-33B scored 30%" could be meaningless
if one was mostly pipeline crashes and the other mostly functional
fails.

---

## Goal

Distinguish the three failure types in `record.json` with a new
`failure_type` field, without changing the existing `is_pass` semantics
or breaking backward compatibility with any existing runner.

---

## Architecture constraint (read carefully)

**`agent.py` returns `Tuple[bool, str]`.** The runner
(`tests/test_top_agent.py` line 120) writes to `record.json` using
this return value. Expanding the return tuple would require changing
every runner file (`test_top_agent.py`,
`test_top_agent_ollama.py`, `test_top_agent_ollama_32b.py`,
`test_top_agent_ollama_debug.py`, `test_top_agent_ollama_hard.py`).
That's invasive and fragile.

**Do not change the `_run()` return signature.** Instead, use a
sidecar file approach — see §"Implementation" below.

Previous PM-approved architectural decision (from the T5-T9 era):
never modify `rtl_generator.py`, `tb_generator.py`, `sim_judge.py`,
`rtl_editor.py`, `prompts.py`, `benchmark_read_helper.py`. That
constraint still holds for Plan v3.

**Allowed to modify in T10:**
- `src/mage/agent.py` — exception handling in `_run()`
- `tests/test_top_agent.py` — to read the new sidecar and include
  `failure_type` in `record.json`

**Allowed to create:**
- `tests/test_agent_failure_types.py` — unit tests

---

## Implementation

### T10.1 — Write failure metadata sidecar in agent.py

In `src/mage/agent.py`, modify the `_run()` method (currently ending
around line 257) so that every exit path writes a sidecar file
`failure_info.json` in `self.output_dir_per_run/`. The file has
exactly this schema:

```json
{
  "failure_type": "functional_mismatch" | "pipeline_assert" | "unexpected" | "none",
  "error_msg": "<short human-readable message>",
  "trace": "<full traceback, or empty for 'none' and 'functional_mismatch'>"
}
```

Three exit paths to handle:

1. **Normal completion** (the `try` block finishes, `properly_finished.tag`
   is written). Write sidecar with:
   - `failure_type`: `"none"` if `ret[0] is True`, else `"functional_mismatch"`
   - `error_msg`: `""` or the `ret[1]` message
   - `trace`: `""`

2. **AssertionError caught** (TB Gen retry exhausted, etc.). Split out
   `except AssertionError` before the generic `except Exception`:
   - `failure_type`: `"pipeline_assert"`
   - `error_msg`: `str(exc_info[1])`
   - `trace`: full traceback string

3. **Any other Exception caught.** Keep the existing generic
   `except Exception:` block but:
   - `failure_type`: `"unexpected"`
   - `error_msg`: `str(exc_info[1])`
   - `trace`: full traceback string

**Do not remove or reorder** the existing `traceback.print_exception`
call — downstream log parsing may rely on stderr output. Just add the
sidecar write alongside it.

**Do not change** the `ret = False, f"Exception: {exc_info[1]}"`
return value — that's the backward-compat contract.

### T10.2 — Sidecar read in runner

In `tests/test_top_agent.py`, after line 119 (where `is_pass` is
computed), read the sidecar and add `failure_type` to the per-run
record. Extend the record dict:

```python
failure_info_path = f"{output_path}/{benchmark_type_name}_{task_id}/failure_info.json"
try:
    with open(failure_info_path, "r") as f:
        failure_info = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    failure_info = {"failure_type": "unknown", "error_msg": "", "trace": ""}

record_json["record_per_run"][task_id] = {
    "is_pass": is_pass,
    "failure_type": failure_info["failure_type"],
    "error_msg": failure_info["error_msg"],
    "run_token_limit_cnt": f"{run_token_limit_cnt:.2f}",
    "run_token_cost": f"{run_cost:.2f}",
    "run_time": str(run_time),
}
```

**Do not touch** other runners (`test_top_agent_ollama*.py`). They
inherit from `test_top_agent` via imports; if they call the same
`run_round` function, they pick up the change automatically. Verify
this in T10.3.

### T10.3 — Unit tests

Create `tests/test_agent_failure_types.py` with these cases:

1. **`test_functional_mismatch`** — Monkey-patch `run_instance` to
   return `(False, "sim mismatch")`. Call `_run()`. Verify:
   - `failure_info.json` exists in output dir
   - `failure_type == "functional_mismatch"`
   - No traceback

2. **`test_pipeline_assert`** — Monkey-patch `run_instance` to raise
   `AssertionError("tb retry exhausted")`. Call `_run()`. Verify:
   - `failure_type == "pipeline_assert"`
   - `error_msg` contains `"tb retry exhausted"`
   - `trace` is non-empty

3. **`test_unexpected_exception`** — Monkey-patch `run_instance` to
   raise `RuntimeError("llm timeout")`. Call `_run()`. Verify:
   - `failure_type == "unexpected"`
   - `error_msg` contains `"llm timeout"`
   - `trace` is non-empty

4. **`test_normal_pass`** — Monkey-patch `run_instance` to return
   `(True, "")`. Call `_run()`. Verify:
   - `failure_type == "none"`
   - `properly_finished.tag` exists

5. **`test_backward_compat_tuple_shape`** — All four cases above:
   verify `_run()` still returns a 2-tuple of `(bool, str)`.

Use `tempfile.TemporaryDirectory` for `output_dir_per_run` in every
test. Minimum TopAgent fixture — if constructing a real `TopAgent`
is heavy, mock it via `unittest.mock.patch.object`.

---

## Acceptance criteria

- [ ] `src/mage/agent.py` modified only in `_run()`, no other methods touched
- [ ] `tests/test_top_agent.py` reads `failure_info.json` and includes `failure_type` in `record.json`
- [ ] `tests/test_agent_failure_types.py` created with 5 test cases, all passing via `pytest tests/test_agent_failure_types.py -v`
- [ ] Existing tests still pass: `pytest tests/ -x` shows no new failures vs. the main branch baseline
- [ ] `_run()` return signature unchanged (still `Tuple[bool, str]`)
- [ ] Smoke re-run of 1 problem (any existing runner) produces a `record.json` with `failure_type` field present
- [ ] Commit on `feat/mage-open-v2` branch (create it if it doesn't exist)
- [ ] Commit message: `[T10] Add structured failure-type logging to agent pipeline`
- [ ] Report filed: `reports/v2/T10_DONE.md`

---

## Stop conditions

File `reports/v2/T10_BLOCKED.md` if:

- The `_run()` return signature cannot be preserved while adding
  sidecar (unlikely — if you hit this, the design is wrong, ask PM)
- Any of the "do not modify" agent files (rtl_generator.py,
  tb_generator.py, sim_judge.py, rtl_editor.py) needs modification
- Existing tests regress after your changes and the cause is unclear
- `failure_info.json` sidecar conflicts with an existing file convention
  you discover (grep the repo first: `grep -r failure_info src/ tests/`)

---

## Do NOT

- Expand `_run()` return tuple to 3+ elements
- Modify other runner files (`test_top_agent_ollama*.py`) — they
  should pick up the change transparently
- Add `failure_type` classification logic anywhere else (not in
  `rtl_generator`, not in `sim_judge`, not in runners). Classification
  is a single `agent.py` concern: "did we exit normally or catch an
  exception, and of what kind".
- Introduce new dependencies
- Refactor `_run()` beyond what T10 requires
- Add `ValidationError`, `TimeoutError`, etc. as separate failure types
  — just the three specified: functional_mismatch, pipeline_assert,
  unexpected

---

## Report template

`reports/v2/T10_DONE.md` should follow the standard Plan v3 format (see
`docs/plan_v3.md` §8):

```markdown
# Task T10: Silent Exception Structured Logging

**Status:** DONE
**Branch:** feat/mage-open-v2
**Commits:** <hash>

## Changes
- src/mage/agent.py: split except AssertionError, added failure_info.json sidecar
- tests/test_top_agent.py: read sidecar, added failure_type field to record.json
- tests/test_agent_failure_types.py: new, 5 unit tests

## Verification
- pytest tests/test_agent_failure_types.py -v: 5 passed
- pytest tests/ -x: <existing count> passed, no regressions
- Smoke run on Prob001_zero: record.json has failure_type field, value = "none"

## Metrics
(N/A for this task — infrastructure fix, not a benchmark)

## Notes
<Anything PM should be aware of. E.g.: "The backward-compat test
showed that test_top_agent_ollama_32b.py also benefits from this
change automatically — confirmed."; or "Had to add traceback to
sidecar because the default Exception repr loses the chained cause
on Python 3.11; documented in the test.">

## Follow-ups spotted
<Anything noticed that might be worth doing later but isn't in T10 scope.
E.g.: "Noticed agent.py:240 hardcodes the RTLGenerator constructor with
only self.token_counter — when T14 abstraction lands we'll need to
adapt this call site."
>
```

---

## After T10

**Do not start T11.** File the report and wait. The PM will review
and then issue T11 (Judge temperature override) as a separate task
file. T11 depends on T10 being complete because its baseline re-run
in T13 uses the new `failure_type` to distinguish what actually improved.
