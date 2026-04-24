# Task T8: 32B Pipeline Test on 5 Problems

**Status:** PENDING
**Priority:** HIGH
**Depends on:** T5, T6, T7 merged
**Objective:** Verify the MAGE pipeline runs end-to-end with
`qwen2.5-coder:32b` on the same 5-problem set used in T5.
No full benchmark; no Phase 2 or Phase 3 work afterward.

---

## Context

Previous smoke tests used `qwen2.5-coder:7b` and produced two findings:
- **T5:** With `json_mode=True`, 3/5 problems pass.
- **T7:** Debug Agent never triggered on 4 kmap problems because
  `qwen2.5-coder:7b` fails at the TB Generator stage — keyword
  hallucinations like `topmodule` produce non-compilable testbenches,
  and the pipeline bails at `agent.py:130` before reaching the
  candidate loop or Debug Agent.

The PM has pivoted the project to reproduction-only mode using
`qwen2.5-coder:32b`. The T5–T7 reports are preserved as-is (they are
part of the project narrative and should not be deleted).

T8 is the single verification step before the project wraps:
**does the larger 32B model get further through the pipeline than 7B did?**
No full benchmark. Run the original 5 T5 problems only.

---

## Scope

### T8.1 — Create the 32B runner

**File:** `tests/test_top_agent_ollama_32b.py` (new)

Clone `tests/test_top_agent_ollama.py` and change only these fields:

```python
"model": "qwen2.5-coder:32b",            # was qwen2.5-coder:7b
"run_identifier": "ollama_32b_5probs",   # was ollama_5probs
```

Everything else stays the same:
- provider: ollama
- filter: `^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|Prob005_notgate)$`
- n=1, temperature=0.85, top_p=0.95, max_token=4096
- use_golden_tb_in_mage=True
- type_benchmark=verilog_eval_v2

Do not modify the T5 runner (`test_top_agent_ollama.py`) — it must
remain as-is for comparability.

### T8.2 — Confirm 32B is available in Ollama

Before running, verify:

```bash
ollama list | grep qwen2.5-coder:32b
```

If the model isn't pulled, pull it:

```bash
ollama pull qwen2.5-coder:32b
```

This is roughly 19 GB. If the pull fails or the disk is full, stop and
file BLOCKED.

### T8.3 — Run

```bash
python tests/test_top_agent_ollama_32b.py
```

Expected wall time: 20–60 minutes (32B is substantially slower than 7B,
and token generation throughput on unified memory systems is
bandwidth-limited).

Monitor the first problem for early warning signs:
- If the first 2 minutes produce no log output, something is stuck
- If `mage_rtl_total.log` shows repeated `Json Decode Error` patterns,
  `json_mode` isn't taking effect — stop and file BLOCKED
- If any problem runs longer than 20 minutes alone, kill the run and
  file BLOCKED

### T8.4 — Forensic comparison

Produce a side-by-side comparison with T5 (7B, json_mode) results.

For each of the 5 problems, collect:

| Evidence | How to get it |
|---|---|
| is_pass | `record.json` per-run entry |
| Wall time | `record.json` per-run entry |
| `properly_finished.tag` present? | File existence in output dir |
| TB Gen retry count | `grep -c "Revised tb:" mage_rtl_total.log` |
| RTL Generator json decode errors | `grep -c "Json Decode Error" mage_rtl_total.log` |
| Candidate generation rounds | `grep -c "Candidate generation: round" mage_rtl_total.log` |
| Debug Agent rounds | `grep -c "RTL Editing: round" mage_rtl_total.log` |
| `mage.rtl_editor.log` size in bytes | `wc -c` |

Quote at least one raw response block (20–40 lines) showing 32B's
output on a non-trivial problem — ideally one that failed on 7B
(Prob004) and either passed or failed differently on 32B.

### T8.5 — Report

Write `reports/T8_DONE.md` with these sections:

**1. Runner diff** — paste the `test_top_agent_ollama_32b.py` creation
as a diff or full file content.

**2. Model availability check** — confirm 32B was pulled; paste
`ollama list` output.

**3. Side-by-side results table** — 5 rows × 2 columns (7B from T5,
32B from T8), pass/fail plus wall time.

**4. Forensic evidence table** — the 8 metrics per problem from T8.4.

**5. Raw response excerpt** — at least one 20–40 line block.

**6. Verdict** — choose one explicitly:

- **(A) 32B materially outperforms 7B.** 4/5 or 5/5 pass, Debug Agent
  triggers at least once, pipeline reaches candidate generation.
- **(B) 32B marginally better.** Similar pass rate (3/5 or 4/5), but
  still no Debug Agent activation.
- **(C) 32B same as 7B.** ~3/5 pass, same failure modes.
- **(D) 32B worse or pipeline hangs.** Regression, unexpected behavior.

---

## Acceptance criteria

- [ ] `tests/test_top_agent_ollama_32b.py` created, commit message `[T8] Add 32B pipeline test runner`
- [ ] 5-problem run completed without pipeline Python exceptions
- [ ] `reports/T8_DONE.md` filed with all 6 sections
- [ ] Explicit verdict (A/B/C/D) stated
- [ ] Raw log excerpt present in the report

## Stop conditions

File `reports/T8_BLOCKED.md` if:
- `qwen2.5-coder:32b` cannot be pulled (disk/network)
- A single problem runs >20 minutes (likely Ollama hang)
- First problem produces `Json Decode Error` pattern (json_mode regression)
- Out-of-memory during model load (32B ~19GB — check system memory
  headroom first)

---

## Do not

- Change any source file. This is observational only.
- Run more than the 5 specified problems.
- Run with `n > 1` (single sampling per problem; we're not measuring
  pass@k, we're checking pipeline reachability).
- Delete or modify T5/T6/T7 reports or artifacts.
- Start any follow-up task after T8.

## Do not proceed after T8

File `reports/T8_DONE.md` and stop. **This is the final task.** The PM
will review the verdict and decide how to close out the project
(narrative, report structure, any final documentation).
