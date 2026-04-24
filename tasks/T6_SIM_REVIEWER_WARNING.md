# Task T6: Sim-Reviewer Benign Warning Extension

**Status:** PENDING
**Priority:** MEDIUM — fixes false-negative PASS verdicts
**Depends on:** T5 merged (commit `1a48256` or later)
**Reference:** T5_DONE.md sections 4 and 5 (Prob001 false regression)

---

## Context

In T5 the 5-problem smoke test showed a paradoxical result: **Prob001_zero
regressed from PASS to FAIL under `json_mode=True`, even though the
generated RTL is functionally correct** (0 mismatches out of 20 samples).

The root cause is in `src/mage/sim_reviewer.py`: a simulation is marked
`is_pass=False` whenever iverilog stderr is non-empty (unless the stderr
matches a whitelist of "benign" patterns). Under `json_mode` the model
chose a different — still valid — module interface for Prob001, adding
an unused `input clk` port. iverilog emits:

```
Prob001_zero_test.sv:75: warning: Instantiating module TopModule
with dangling input port 1 (clk) floating.
```

This is a benign linting warning about an unused port. The simulation
still ran, produced correct output, and the testbench reported 0
mismatches. But because the warning string isn't in the benign list,
`sim_reviewer` flips the verdict to FAIL.

This is a genuine bug in the pass/fail semantics: **a functionally
correct design should not fail benchmarking because of a stylistic
choice that doesn't affect runtime behavior.** Left unfixed, our full
VerilogEval run will systematically under-count pass rate relative to
the paper's numbers, and our S1/S2/S3 comparisons become noisy.

## Scope

### T6.1 — Locate the benign-warning allowlist

**File:** `src/mage/sim_reviewer.py`

Find the code that decides `is_pass` from iverilog/vvp stderr. There is
an existing allowlist pattern around lines 128-131 (referenced in the
T5 report). Read the surrounding 40-50 lines to understand:

1. How the allowlist is structured (regex? substring? line-by-line?)
2. What patterns are currently allowed
3. Whether the filter operates per-line or on the whole stderr blob

Do not modify anything yet; just understand the existing logic.

### T6.2 — Add the dangling-input-port warning to the allowlist

Add a pattern that matches iverilog's dangling input warning. A
minimal matcher is a substring: `"dangling input port"`. A more
robust matcher is a regex that accepts variations:

```
warning:\s+Instantiating module \S+ with dangling input port \d+ \(\S+\) floating\.
```

Prefer the substring form if the existing allowlist uses substrings;
use the regex if it already uses regexes. Match the existing style —
do not rewrite the allowlist mechanism.

### T6.3 — Unit test

Create `tests/test_sim_reviewer_warnings.py` with at minimum these two
cases:

1. **Regression test** — a fabricated iverilog stderr containing only
   the dangling-input warning should result in `is_pass=True` when
   the simulation stdout reports 0 mismatches.
2. **Negative test** — a fabricated stderr containing a genuine error
   (e.g., `error: port 'X' is not a port of TopModule`) should still
   result in `is_pass=False`. We must not accidentally whiten real
   errors.

Use `pytest` fixtures or monkeypatching if you need to stub subprocess
calls. If `sim_reviewer.py`'s structure makes this impractical,
fabricate the stderr text and call the pass-judgment function
directly.

### T6.4 — Re-run Prob001 only, verify PASS

```bash
# Edit tests/test_top_agent_ollama.py temporarily (or create a variant
# test_top_agent_ollama_prob001.py) with filter:
"filter_instance": "^(Prob001_zero)$",
"run_identifier": "t6_prob001_verify",
```

Execute and confirm `output_t6_prob001_verify_0/record.json` shows
`is_pass: true`.

Do not commit the runner filter change — revert it to the 5-problem
filter after verification.

### T6.5 — Report

Write `reports/T6_DONE.md` with these sections:

**1. sim_reviewer.py diff** — the committed change, verbatim.

**2. Allowlist inspection findings** — what was already in the list,
what you added, why the new pattern fits the existing style.

**3. Test results** — output of `pytest tests/test_sim_reviewer_warnings.py -v`.

**4. Prob001 re-run verdict** — the relevant section of the new
`record.json` showing PASS.

**5. Residual concerns** — any other benign warnings you noticed in
existing logs that might cause similar false negatives. List them but
don't fix them in this task.

---

## Acceptance criteria

- [ ] `src/mage/sim_reviewer.py` committed with allowlist extension — nothing else in the file changed
- [ ] `tests/test_sim_reviewer_warnings.py` committed with ≥2 test cases, both passing
- [ ] Commit message: `[T6] Whitelist dangling input port warning in sim_reviewer`
- [ ] Prob001_zero re-run yields PASS
- [ ] `pytest tests/test_sim_reviewer_warnings.py -v` green
- [ ] `reports/T6_DONE.md` filed with all 5 sections

## Stop conditions

File `reports/T6_BLOCKED.md` if:

- The existing allowlist logic can't be extended without rewriting the
  mechanism (this means the task scope is wrong — PM needs to know)
- The dangling-input warning matches an existing pattern already, but
  Prob001 still fails (means the root cause is somewhere else, possibly
  in how stderr is collected or compared)
- The unit test infrastructure doesn't exist in the repo and creating
  it is beyond scope (flag it; PM will decide whether to defer)

---

## Do not

- Refactor or reorganize `sim_reviewer.py` beyond the allowlist addition
- Add or remove patterns from the allowlist other than the one specified
- Modify any agent file, `utils.py`, or `gen_config.py`
- Re-run the full 5-problem suite (only Prob001 is in scope here)
- Change the definition of `is_pass` anywhere else

## Do not proceed after T6

File `reports/T6_DONE.md` and stop. The PM reviews before authorizing T7.
