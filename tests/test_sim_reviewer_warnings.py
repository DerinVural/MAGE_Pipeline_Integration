from mage.sim_reviewer import stderr_all_lines_benign


def test_dangling_input_port_warning_is_benign():
    stderr = (
        "./verilog-eval/dataset_spec-to-rtl/Prob001_zero_test.sv:75: warning: "
        "Instantiating module TopModule with dangling input port 1 (clk) floating."
    )
    assert stderr_all_lines_benign(stderr) is True


def test_real_port_error_is_not_benign():
    stderr = (
        "./verilog-eval/dataset_spec-to-rtl/Prob003_step_one_test.sv:75: "
        "error: port ``one'' is not a port of top_module1."
    )
    assert stderr_all_lines_benign(stderr) is False


def test_existing_constant_select_warning_still_benign():
    stderr = (
        "./output/rtl.sv:42: sorry: constant selects in always_* processes "
        "are not currently supported (all bits will be included)."
    )
    assert stderr_all_lines_benign(stderr) is True


def test_mixed_benign_and_error_is_not_benign():
    stderr = (
        "./foo.sv:10: warning: Instantiating module TopModule with "
        "dangling input port 1 (clk) floating.\n"
        "./foo.sv:20: error: port ``x'' is not a port of TopModule."
    )
    assert stderr_all_lines_benign(stderr) is False


def test_multiple_dangling_input_lines_all_benign():
    stderr = (
        "./a.sv:1: warning: Instantiating module TopModule with "
        "dangling input port 1 (clk) floating.\n"
        "./b.sv:2: warning: Instantiating module OtherModule with "
        "dangling input port 3 (rst) floating."
    )
    assert stderr_all_lines_benign(stderr) is True
