import contextlib
import json
import os
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from mage.agent import TopAgent  # noqa: E402


@contextlib.contextmanager
def _patch_subagents():
    with patch("mage.agent.SimReviewer", return_value=MagicMock()), \
         patch("mage.agent.RTLGenerator", return_value=MagicMock()), \
         patch("mage.agent.TBGenerator", return_value=MagicMock()), \
         patch("mage.agent.SimJudge", return_value=MagicMock()), \
         patch("mage.agent.RTLEditor", return_value=MagicMock()):
        yield


def _make_agent(tmpdir):
    with patch.object(TopAgent, "__init__", lambda self, llm=None: None):
        agent = TopAgent()
    agent.llm = MagicMock()
    agent.token_counter = MagicMock()
    agent.token_counter.reset = MagicMock()
    agent.token_counter.log_token_stats = MagicMock()
    agent.sim_max_retry = 4
    agent.rtl_max_candidates = 20
    agent.rtl_selected_candidates = 2
    agent.is_ablation = False
    agent.redirect_log = False
    agent.output_path = tmpdir
    agent.log_path = tmpdir
    agent.golden_tb_path = None
    agent.golden_rtl_blackbox_path = None
    agent.golden_tb_format = False
    agent.output_dir_per_run = tmpdir
    agent.tb_gen = None
    agent.rtl_gen = None
    agent.sim_reviewer = None
    agent.sim_judge = None
    agent.rtl_edit = None
    return agent


def _read_sidecar(tmpdir):
    with open(os.path.join(tmpdir, "failure_info.json")) as f:
        return json.load(f)


class TestFailureTypes(unittest.TestCase):
    def test_functional_mismatch(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            with _patch_subagents(), patch.object(
                TopAgent, "run_instance", return_value=(False, "sim mismatch")
            ):
                ret = agent._run("spec")
            info = _read_sidecar(tmp)
            self.assertEqual(info["failure_type"], "functional_mismatch")
            self.assertEqual(info["error_msg"], "sim mismatch")
            self.assertEqual(info["trace"], "")
            self.assertEqual(ret, (False, "sim mismatch"))

    def test_pipeline_assert(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            with _patch_subagents(), patch.object(
                TopAgent,
                "run_instance",
                side_effect=AssertionError("tb retry exhausted"),
            ):
                ret = agent._run("spec")
            info = _read_sidecar(tmp)
            self.assertEqual(info["failure_type"], "pipeline_assert")
            self.assertIn("tb retry exhausted", info["error_msg"])
            self.assertTrue(len(info["trace"]) > 0)
            self.assertFalse(ret[0])
            self.assertIn("tb retry exhausted", ret[1])

    def test_unexpected_exception(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            with _patch_subagents(), patch.object(
                TopAgent,
                "run_instance",
                side_effect=RuntimeError("llm timeout"),
            ):
                ret = agent._run("spec")
            info = _read_sidecar(tmp)
            self.assertEqual(info["failure_type"], "unexpected")
            self.assertIn("llm timeout", info["error_msg"])
            self.assertTrue(len(info["trace"]) > 0)
            self.assertFalse(ret[0])
            self.assertIn("llm timeout", ret[1])

    def test_normal_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            with _patch_subagents(), patch.object(
                TopAgent, "run_instance", return_value=(True, "")
            ):
                ret = agent._run("spec")
            info = _read_sidecar(tmp)
            self.assertEqual(info["failure_type"], "none")
            self.assertEqual(info["trace"], "")
            self.assertTrue(os.path.exists(os.path.join(tmp, "properly_finished.tag")))
            self.assertEqual(ret, (True, ""))

    def test_backward_compat_tuple_shape(self):
        cases = [
            ("return", {"return_value": (False, "sim mismatch")}),
            ("assert", {"side_effect": AssertionError("x")}),
            ("runtime", {"side_effect": RuntimeError("y")}),
            ("pass", {"return_value": (True, "")}),
        ]
        for label, kw in cases:
            with tempfile.TemporaryDirectory() as tmp:
                agent = _make_agent(tmp)
                with _patch_subagents(), patch.object(
                    TopAgent, "run_instance", **kw
                ):
                    ret = agent._run("spec")
                self.assertIsInstance(ret, tuple, msg=label)
                self.assertEqual(len(ret), 2, msg=label)
                self.assertIsInstance(ret[0], bool, msg=label)
                self.assertIsInstance(ret[1], str, msg=label)


if __name__ == "__main__":
    unittest.main()
