# Task T5: Ollama JSON-Mode Fix + Debug Agent Forensics

**Status:** PENDING
**Priority:** HIGH — blocks full benchmark run
**Depends on:** Phase 1 infrastructure complete, 5-problem smoke test completed
**Reference:** `MAGE_local_pipeline_issues.md` (smoke test #1 report)

---

## Context

The first smoke test on 5 VerilogEval-v2 problems with `qwen2.5-coder:7b`
via Ollama scored 1/5 pass. Three failure types were observed:

- **Type A** (Prob002, Prob005) — TB Agent JSON parser retries exhausted
  due to unescaped `"` inside the `testbench` field value. `rtl.sv` was
  never written; `sim_reviewer` failed on "No such file".
- **Type B** (Prob003) — Model produced `module TopModule;` with ports
  declared inside the body instead of the header. iverilog rejected it.
- **Type C** (Prob004) — Model declared `logic [7:0] byteN = ...` inside
  `always @(*)` without `automatic`, causing static init. 109/110
  mismatches despite syntactically valid RTL.

The team's previous instinct was to keep hardening the post-hoc JSON
repair in `utils.reformat_json_string` (handle `\n`, `\t`, then embedded
`"`, etc.). The PM's assessment: that road is endless because the
underlying problem is **model output correctness**, not parser robustness.

The remedy in this task is to **constrain generation at the token level**
using Ollama's `format=json` grammar-constrained sampling. Invalid JSON
becomes physically impossible for the model to emit.

We also do NOT yet know whether Type B and Type C failures are genuine
model-capacity problems or whether the Debug Agent is silently failing
on its own JSON parsing (same root cause as Type A, cascading into
downstream agents). Before recommending a model upgrade, we verify the
Debug Agent actually ran and produced actionable attempts.

---

## Scope

### T5.1 — Enable Ollama JSON-mode

**File:** `src/mage/gen_config.py` — `elif provider == "ollama":` branch only.

Add `json_mode=True` to the `Ollama(...)` constructor. LlamaIndex's
`Ollama` class translates this to Ollama's native `format=json` request
parameter, which applies grammar-constrained sampling. The model
cannot emit tokens that would produce invalid JSON.

Keep `reformat_json_string` and all of `utils.py` untouched — it remains
as a safety net (empty responses, timeouts, etc.).

**Do not:**
- Remove or modify `utils.py` parser logic
- Modify other provider branches (anthropic, openai, vertex, vertexanthropic)
- Change temperature, top_p, context_window, request_timeout, or num_predict defaults
- Touch any agent file: `tb_generator.py`, `rtl_generator.py`, `sim_judge.py`, `rtl_editor.py`
- Modify `token_counter.py` (the `isinstance(llm, (Vertex, Ollama))` line stays as is)

### T5.2 — Debug Agent forensic analysis

**Input logs:** `log_ollama_5probs_0/VERILOG_EVAL_V2_Prob003_step_one/mage_rtl_total.log`
and `...Prob004_vector2/mage_rtl_total.log`

Answer these four questions with **direct log evidence** — line
numbers or quoted excerpts inline in the report:

1. Did `RTLEditor` (Debug Agent) enter its iteration loop? Search for
   `"RTL Editing: round N / 15"` lines.
2. How many rounds did it actually execute before the loop exited?
3. Are there `"Json Decode Error"` messages inside those Debug Agent
   rounds? If yes, the Debug Agent is failing on JSON silently — same
   root cause as Type A, hidden one layer deeper.
4. What does the model's raw response look like in at least one Debug
   Agent round? Quote 20-40 lines verbatim into the report.

**This step is non-optional.** If you skip it, the delta analysis in
T5.4 is not interpretable. Without evidence, we cannot distinguish
"Debug Agent couldn't fix the bug" from "Debug Agent never got a
chance to try".

### T5.3 — Re-run the 5-problem smoke test

After T5.1 is committed, re-run without changing anything else:

```bash
python tests/test_top_agent_ollama.py
```

The filter is already locked to:
`^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|Prob005_notgate)$`

Do not modify the runner, config, benchmark set, model, or Ollama
server settings. A controlled A/B delta requires identical conditions
except for the one variable we're testing.

### T5.4 — Compose the report

Write `reports/T5_DONE.md` (or `reports/T5_BLOCKED.md` on failure) with
exactly these five sections:

**1. T5.1 diff** — Paste the committed change verbatim (git diff or the
3-5 line change itself).

**2. T5.2 forensic findings** — Answers to the four Debug Agent
questions, each with evidence (quoted log excerpt or line number).

**3. T5.3 new `record.json`** — Full content of
`output_ollama_5probs_0_json_mode/record.json` (or whatever output dir
the runner produced — use a new `run_identifier` so we don't overwrite
the baseline).

**4. Delta table**

| Problem | Before (smoke #1) | After (T5) | Change |
|---|---|---|---|
| Prob001_zero | PASS | ... | |
| Prob002_m2014_q4i | FAIL (Type A) | ... | |
| Prob003_step_one | FAIL (Type B) | ... | |
| Prob004_vector2 | FAIL (Type C) | ... | |
| Prob005_notgate | FAIL (Type A) | ... | |

**5. Conclusion** — One of three verdicts, stated explicitly:

- **(a)** "Type A fully resolved, Type B/C persist" → model capacity is
  the likely next bottleneck; PM will open T6 (model upgrade eval).
- **(b)** "All 5 pass" → unexpected upside; PM authorizes Phase 2
  (full VerilogEval run).
- **(c)** "New or regressed failure modes" → list them with log
  excerpts; wait for PM before any further change.

---

## Acceptance criteria

- [ ] `src/mage/gen_config.py` committed with `json_mode=True` addition, nothing else changed in the file
- [ ] Commit message: `[T5] Enable Ollama JSON-mode for constrained generation`
- [ ] Debug Agent log analysis completed with quoted log evidence in the report
- [ ] 5-problem smoke re-run completed with a fresh `run_identifier`
- [ ] `reports/T5_DONE.md` written with all 5 required sections
- [ ] No other source files modified
- [ ] `pytest tests/ -x` still passes (no regression in existing tests)

## Stop conditions

Stop immediately and file `reports/T5_BLOCKED.md` if:

- `json_mode=True` is not a valid parameter in your installed
  `llama-index-llms-ollama` version
- Ollama server rejects the `format=json` parameter (API error)
- The re-run produces Python exceptions that didn't exist before T5.1
- `pytest tests/ -x` starts failing after T5.1

In the BLOCKED report include: exact error + stack trace,
`pip show llama-index-llms-ollama`, `ollama --version`, and confirmation
of whether the untouched baseline still runs.

## Do not proceed after T5

After filing `reports/T5_DONE.md`, **stop**. Do not start T6 or any
Phase 2 work. The PM reviews the delta table and the Debug Agent
findings before authorizing the next step. The decision depends on
whether Debug Agent is functionally operational or silently broken.

---

## References

- LlamaIndex Ollama source (verify `json_mode` parameter exists in your version):
  https://github.com/run-llama/llama_index/tree/main/llama-index-integrations/llms/llama-index-llms-ollama
- Ollama `format=json` API docs:
  https://github.com/ollama/ollama/blob/main/docs/api.md
- MAGE agent architecture (which agents depend on JSON output):
  `src/mage/agent.py` orchestrates TBGenerator → RTLGenerator → SimJudge → RTLEditor
- Previous smoke test evidence: `MAGE_local_pipeline_issues.md`

## PM rationale (why this and not parser hardening)

Grammar-constrained sampling (`format=json`) is a one-line fix that
eliminates an entire class of failures at the source. Regex-based
output repair (the current approach in `reformat_json_string`) can only
handle patterns we've seen and written code for; every new model or
prompt combination can produce a new failure mode we have to patch.

The parser stays as a belt-and-suspenders safety net, but it should
never be the primary defense when the provider supports constrained
generation natively.
