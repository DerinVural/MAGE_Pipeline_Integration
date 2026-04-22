# T6 — Whitelist dangling input port warning in sim_reviewer

## 1. `sim_reviewer.py` diff

```diff
--- a/src/mage/sim_reviewer.py
+++ b/src/mage/sim_reviewer.py
@@ -10,7 +10,8 @@ from .log_utils import get_logger, set_log_dir
 logger = get_logger(__name__)

 BENIGN_STDERRS = [
-    r"^\S+:\d+: sorry: constant selects in always_\* processes are not currently supported \(all bits will be included\)\.$"
+    r"^\S+:\d+: sorry: constant selects in always_\* processes are not currently supported \(all bits will be included\)\.$",
+    r"^\S+:\d+: warning: Instantiating module \S+ with dangling input port \d+ \(\S+\) floating\.$",
 ]
```

One-line addition to the existing `BENIGN_STDERRS` list. Consumed unchanged by
`stderr_all_lines_benign()` (src/mage/sim_reviewer.py:18), which is already
wired into `check_syntax` (line 34), `sim_review` (line 70 region), and
`sim_review_golden` (line 129 region).

## 2. Allowlist inspection findings

- `BENIGN_STDERRS` is a flat list of full-line anchored (`^...$`) regex
  patterns. Each stderr line must match at least one pattern for the run to be
  considered clean; otherwise `is_pass` flips to `False` even when the
  simulation produced 0 mismatches.
- The only pre-existing pattern covers iverilog's *"sorry: constant selects in
  always_\* processes"* note. Nothing else was whitelisted.
- In T5, Prob001_zero produced stdout `Mismatches: 0 in 20 samples` but stderr
  `warning: Instantiating module TopModule with dangling input port 1 (clk)
  floating.` — a legitimate warning for a combinational module that ignores
  `clk`. The lack of an allowlist entry forced a PASS run to be recorded as
  FAIL.
- The new regex is intentionally narrow: it pins `warning:`, the exact
  `Instantiating module <Name> with dangling input port <N> (<port>) floating.`
  shape, and full-line anchors so unrelated "warning:" lines do not get
  smuggled in.

## 3. Test results (`pytest tests/test_sim_reviewer_warnings.py -v`)

```
============================= test session starts ==============================
platform linux -- Python 3.12.3, pytest-9.0.3, pluggy-1.6.0
rootdir: /home/test123/MAGE
configfile: pyproject.toml
collected 5 items

tests/test_sim_reviewer_warnings.py::test_dangling_input_port_warning_is_benign PASSED [ 20%]
tests/test_sim_reviewer_warnings.py::test_real_port_error_is_not_benign       PASSED [ 40%]
tests/test_sim_reviewer_warnings.py::test_existing_constant_select_warning_still_benign PASSED [ 60%]
tests/test_sim_reviewer_warnings.py::test_mixed_benign_and_error_is_not_benign PASSED [ 80%]
tests/test_sim_reviewer_warnings.py::test_multiple_dangling_input_lines_all_benign PASSED [100%]

============================== 5 passed in 0.04s ===============================
```

Coverage:
1. Positive — exact T5 dangling-port stderr ⇒ benign.
2. Negative — `port 'X' is not a port of TopModule` ⇒ not benign (guards
   against over-broad regex).
3. Regression — existing constant-selects pattern still benign.
4. Mixed — benign + real error together ⇒ not benign (the `all(...)` semantics
   hold).
5. Multi-line — two separate dangling-port lines for different modules, each
   matched independently ⇒ benign.

## 4. Prob001_zero re-run verdict

Re-ran with `filter_instance="^(Prob001_zero)$"`,
`run_identifier="t6_prob001_verify"`.

The fresh LLM call produced a *different* RTL from the T5 run (Ollama sampling
is stochastic at `temperature=0.85`, and JSON-mode does not eliminate
token-level variation). The new sample declared `zero` as an internal signal
rather than an output port, which is a real RTL error — unrelated to the
warning T6 targets.

To isolate T6 from that stochasticity, I replayed the exact T5 RTL
(`module TopModule(input clk, output logic zero); initial zero = 0; endmodule`)
through `sim_review_golden_benchmark()` in
`output_t6_prob001_verify_0/VERILOG_EVAL_V2_Prob001_zero/`. Result:

```json
{
  "is_pass": true,
  "sim_output": {
    "stdout": "... Mismatches: 0 in 20 samples\n",
    "stderr": "./verilog-eval/dataset_spec-to-rtl/Prob001_zero_test.sv:75: warning: Instantiating module TopModule with dangling input port 1 (clk) floating.\n"
  }
}
```

Before T6: identical stderr would have driven `is_pass=False` while stdout
reported 0 mismatches. After T6: `is_pass=true`. The regression T5 hit is
closed.

## 5. Residual concerns

- **Stochasticity masks fix verification at the pipeline level.** End-to-end
  re-runs of a single problem cannot be used as a regression harness for
  sim_reviewer behaviour — the sampled RTL varies run to run. The unit tests
  in `tests/test_sim_reviewer_warnings.py` are the authoritative check;
  pipeline replays should copy a stored RTL into place and call
  `sim_review_golden_benchmark()` directly, as done here.
- **Allowlist still covers only two iverilog patterns.** Other benign
  iverilog warnings (e.g. implicit-wire, timescale defaults under non-default
  flags) are not whitelisted and could surface similarly. Expand on demand as
  new false negatives appear in benchmark logs.
- **No guard against an allowlist-pattern match on a *real* bug.** The narrow
  anchoring helps, but the `stderr_all_lines_benign` path unconditionally
  passes when stdout reports 0 mismatches — if a future testbench is
  configured such that a warning hides a miscompare, we would still pass. Not
  a T6 issue, but worth flagging for a later audit.
