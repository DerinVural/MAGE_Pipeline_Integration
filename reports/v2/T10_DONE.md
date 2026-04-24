# Task T10: Silent Exception Structured Logging

**Status:** DONE
**Branch:** feat/mage-open-v2
**Commits:** (see final commit on this branch)

## Changes

- `src/mage/agent.py`: split `except AssertionError` before `except Exception`
  in `_run()`, added `failure_info.json` sidecar write on every exit path
  (normal pass, functional mismatch, pipeline assert, unexpected). Return
  signature unchanged: still `Tuple[bool, str]`.
- `tests/test_top_agent.py`: reads `failure_info.json` from
  `{output_path}/{benchmark_type_name}_{task_id}/` and adds `failure_type`
  and `error_msg` fields to the per-run record in `record.json`. Missing or
  malformed sidecar falls back to `{"failure_type": "unknown", ...}`.
- `tests/test_agent_failure_types.py`: new file, 5 unit tests covering
  functional_mismatch / pipeline_assert / unexpected / normal_pass /
  backward-compat tuple shape.

## Verification

### Unit tests

```
$ .venv/bin/python -m pytest tests/test_agent_failure_types.py -v
tests/test_agent_failure_types.py::TestFailureTypes::test_backward_compat_tuple_shape PASSED
tests/test_agent_failure_types.py::TestFailureTypes::test_functional_mismatch PASSED
tests/test_agent_failure_types.py::TestFailureTypes::test_normal_pass PASSED
tests/test_agent_failure_types.py::TestFailureTypes::test_pipeline_assert PASSED
tests/test_agent_failure_types.py::TestFailureTypes::test_unexpected_exception PASSED
======================== 5 passed, 2 warnings in 1.72s =========================
```

### Full-suite regression check

```
$ .venv/bin/python -m pytest tests/ --ignore=tests/test_single_agent.py
tests/test_agent_failure_types.py .....                                  [ 50%]
tests/test_sim_reviewer_warnings.py .....                                [100%]
======================== 10 passed, 2 warnings in 1.71s ========================
```

`tests/test_single_agent.py` is excluded because it fails to import on this
branch for a pre-existing reason (`ModuleNotFoundError: No module named
'backoff'`) — unrelated to T10. Confirmed the same import error exists on
`main` at commit `d7b6d8f`.

### Smoke run

Ran 1 problem (Prob005_notgate, `qwen2.5-coder:7b`, ollama, golden TB)
through `run_round()` from `test_top_agent.py`:

```
$ cat output_t10_smoke/record.json | python -m json.tool
{
    "record_per_run": {
        "Prob005_notgate": {
            "is_pass": true,
            "failure_type": "pipeline_assert",
            "error_msg": "tb_need_fix should be False. sim_log: { ... tb.sv:44: syntax error ... }",
            "run_token_limit_cnt": "0.00",
            "run_token_cost": "0.00",
            "run_time": "0:03:07.109311"
        }
    },
    "total_record": { "pass_cnt": 1, "total_cnt": 1, ... }
}
```

And the sidecar in `output_t10_smoke/VERILOG_EVAL_V2_Prob005_notgate/failure_info.json`:

```json
{
    "failure_type": "pipeline_assert",
    "error_msg": "tb_need_fix should be False. sim_log: {...}",
    "trace": "Traceback (most recent call last):\n  File \".../agent.py\", line 250, in _run\n    self.run_instance(spec)\n  File \".../agent.py\", line 131, in run_instance\n    assert not tb_need_fix, f\"tb_need_fix should be False. sim_log: {sim_log}\"\n           ^^^^^^^^^^^^^^^\nAssertionError: ..."
}
```

This smoke result happens to be the **exact diagnostic case** T10 was designed
for: `is_pass: true` (via runner-level `sim_review_golden_benchmark`
fallback) but `failure_type: "pipeline_assert"` (TB Gen failed, pipeline
asserted). Before T10 these two outcomes — "RTL was correct and pipeline
completed happily" vs. "RTL was correct but pipeline asserted and the
runner-level fallback found a pass" — were indistinguishable in
`record.json`. Now they are.

## Metrics

N/A — infrastructure fix, not a benchmark task.

## Notes

- The sidecar write is placed **after** the `try/except` block so every
  exit path reaches it. Wrapped in its own `try/except OSError` so a
  filesystem failure on the sidecar write can never mask the actual
  pipeline result.
- Re-confirmed architectural constraint: `_run()` still returns
  `Tuple[bool, str]`. No runner other than `test_top_agent.py` needed
  changes — `test_top_agent_ollama*.py` files all call `run_round()`
  from `test_top_agent`, so they inherit the new `failure_type` field
  transparently (no edits required, matches task spec §T10.2 "verify
  this in T10.3").
- The smoke-run proof above is on `qwen2.5-coder:7b` because that's the
  model with the known TB-Gen-assertion failure mode from T5 era; it
  produces the exact `pipeline_assert` classification on demand. On 32B
  the same problem would classify as `"none"` (T8 data).
- Used `unittest.mock.patch` to bypass `TopAgent.__init__`'s LLM-dependent
  `TokenCounter` construction in the unit tests. Clean per spec — no new
  dependencies introduced, no source changes outside agent.py/runner.

## Follow-ups spotted

- `tests/test_single_agent.py` has a broken import (`backoff`) that predates
  T10. Not in T10 scope; could be a separate cleanup task if the PM wants
  the full suite to collect cleanly.
- The sidecar schema keeps `trace` empty for `functional_mismatch` and
  `"none"` per spec. If downstream Plan v3 tasks (T11/T13) want to
  attribute functional mismatches to which subagent produced them, they
  would need additional structured fields — out of T10 scope, noted here
  for T13 baseline-rerun design.
- `record.json` schema has changed (new `failure_type` / `error_msg`
  keys). Any external tool parsing past run records will keep working
  because we only added keys, didn't rename or drop any. Worth mentioning
  in Plan v3 release notes if those exist.
