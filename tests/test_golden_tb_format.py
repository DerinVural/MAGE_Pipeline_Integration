import json
from unittest.mock import patch

from mage.sim_reviewer import (
    SimReviewer,
    sim_review,
    sim_review_mismatch_cnt,
)


def _mock_run_bash_command(stdout: str, stderr: str = "", returncode_ok: bool = True):
    payload = json.dumps({"stdout": stdout, "stderr": stderr})
    return (returncode_ok, payload)


# -----------------------------------------------------------------------------
# Spec-required tests (6)
# -----------------------------------------------------------------------------


def test_golden_tb_format_pass(tmp_path):
    stdout = "Hint: Output 'out' has no mismatches.\nMismatches: 0 in 100 samples\n"
    with patch(
        "mage.sim_reviewer.run_bash_command",
        return_value=_mock_run_bash_command(stdout),
    ):
        is_pass, mismatch_cnt, _ = sim_review(
            output_path_per_run=str(tmp_path), golden_tb_format=True
        )
    assert is_pass is True
    assert mismatch_cnt == 0


def test_golden_tb_format_fail_with_mismatches(tmp_path):
    stdout = "Hint: Output 'out' has 7 mismatches.\nMismatches: 7 in 100 samples\n"
    with patch(
        "mage.sim_reviewer.run_bash_command",
        return_value=_mock_run_bash_command(stdout),
    ):
        is_pass, mismatch_cnt, _ = sim_review(
            output_path_per_run=str(tmp_path), golden_tb_format=True
        )
    assert is_pass is False
    assert mismatch_cnt == 7


def test_default_format_unchanged_pass(tmp_path):
    stdout = "Some prelude\nSIMULATION PASSED\n"
    with patch(
        "mage.sim_reviewer.run_bash_command",
        return_value=_mock_run_bash_command(stdout),
    ):
        is_pass, mismatch_cnt, _ = sim_review(output_path_per_run=str(tmp_path))
    assert is_pass is True
    assert mismatch_cnt == 0


def test_default_format_unchanged_fail(tmp_path):
    stdout = "SIMULATION FAILED - 3 MISMATCHES DETECTED\n"
    with patch(
        "mage.sim_reviewer.run_bash_command",
        return_value=_mock_run_bash_command(stdout),
    ):
        is_pass, mismatch_cnt, _ = sim_review(output_path_per_run=str(tmp_path))
    assert is_pass is False
    assert mismatch_cnt == 3


def test_stderr_blocks_pass(tmp_path):
    stdout = "Mismatches: 0 in 100 samples\n"
    stderr = "tb.sv:42: error: something went wrong\n"
    with patch(
        "mage.sim_reviewer.run_bash_command",
        return_value=_mock_run_bash_command(stdout, stderr=stderr),
    ):
        is_pass, mismatch_cnt, _ = sim_review(
            output_path_per_run=str(tmp_path), golden_tb_format=True
        )
    assert is_pass is False
    assert mismatch_cnt == 0


def test_simreviewer_passes_flag_through(tmp_path):
    stdout = "Mismatches: 0 in 100 samples\n"
    reviewer = SimReviewer(
        output_path_per_run=str(tmp_path),
        golden_rtl_path=None,
        golden_tb_format=True,
    )
    assert reviewer.golden_tb_format is True
    with patch(
        "mage.sim_reviewer.run_bash_command",
        return_value=_mock_run_bash_command(stdout),
    ):
        is_pass, mismatch_cnt, _ = reviewer.review()
    assert is_pass is True
    assert mismatch_cnt == 0


# -----------------------------------------------------------------------------
# Parser tests (4) — sim_review_mismatch_cnt
# -----------------------------------------------------------------------------


def test_parser_legacy_simulation_failed_format():
    stdout = "blah blah\nSIMULATION FAILED - 12 MISMATCHES DETECTED\nmore output"
    assert sim_review_mismatch_cnt(stdout) == 12


def test_parser_new_mismatches_n_in_m_format():
    stdout = "Hint: Output 'q' has 5 mismatches.\nMismatches: 5 in 100 samples\n"
    assert sim_review_mismatch_cnt(stdout) == 5


def test_parser_format_1_priority_when_both_present():
    stdout = (
        "Mismatches: 9 in 100 samples\n"
        "SIMULATION FAILED - 3 MISMATCHES DETECTED\n"
    )
    assert sim_review_mismatch_cnt(stdout) == 3


def test_parser_default_zero_when_neither_pattern_present():
    stdout = "Some random output\nNo recognized markers here\n"
    assert sim_review_mismatch_cnt(stdout) == 0
