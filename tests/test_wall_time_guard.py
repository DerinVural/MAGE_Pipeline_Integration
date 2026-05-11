"""T21.4 unit tests for per-problem wall-time guard."""

import json
import os
import sys
import tempfile
import time
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from mage.agent import TopAgent  # noqa: E402
from mage.utils import MageTimeoutError  # noqa: E402


def _make_agent(tmpdir):
    with patch.object(TopAgent, "__init__", lambda self, llm=None: None):
        agent = TopAgent()
    agent.llm = MagicMock()
    agent.token_counter = MagicMock()
    agent.sim_max_retry = 4
    agent.rtl_max_candidates = 20
    agent.rtl_selected_candidates = 2
    agent.is_ablation = False
    agent.redirect_log = False
    agent.output_path = tmpdir
    agent.log_path = tmpdir
    agent.golden_tb_path = None
    agent.golden_rtl_blackbox_path = None
    agent.bypass_tb_gen = False
    agent.golden_tb_format = False
    agent.per_problem_timeout_min = None
    agent.output_dir_per_run = tmpdir
    agent.tb_gen = MagicMock()
    agent.rtl_gen = MagicMock()
    agent.sim_reviewer = MagicMock()
    agent.sim_judge = MagicMock()
    agent.rtl_edit = MagicMock()
    return agent


class TestWallTimeGuard(unittest.TestCase):
    def test_default_per_problem_timeout_min_is_none(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            self.assertIsNone(agent.per_problem_timeout_min)

    def test_setter_accepts_int_and_none(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            agent.set_per_problem_timeout_min(10)
            self.assertEqual(agent.per_problem_timeout_min, 10)
            agent.set_per_problem_timeout_min(None)
            self.assertIsNone(agent.per_problem_timeout_min)

    def test_check_wall_time_noop_when_default(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            agent._check_wall_time(time.time() - 3600)

    def test_check_wall_time_raises_when_exceeded(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            agent.set_per_problem_timeout_min(1)
            with self.assertRaises(MageTimeoutError) as cm:
                agent._check_wall_time(time.time() - 120)
            self.assertEqual(cm.exception.timeout_min, 1)
            self.assertGreater(cm.exception.elapsed_sec, 60)

    def test_check_wall_time_no_raise_under_budget(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            agent.set_per_problem_timeout_min(10)
            agent._check_wall_time(time.time() - 5)

    def test_run_wraps_timeout_error_into_failure_info(self):
        """_run catches MageTimeoutError and writes failure_type=timeout."""
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            agent.set_per_problem_timeout_min(1)

            def raise_timeout(_spec):
                raise MageTimeoutError(timeout_min=1, elapsed_sec=120.0)

            with patch.object(agent, "run_instance", side_effect=raise_timeout):
                with patch("mage.agent.SimReviewer"), patch(
                    "mage.agent.RTLGenerator"
                ), patch("mage.agent.TBGenerator"), patch(
                    "mage.agent.SimJudge"
                ), patch(
                    "mage.agent.RTLEditor"
                ):
                    ret = agent._run("dummy spec")

            self.assertFalse(ret[0])
            with open(os.path.join(tmp, "failure_info.json")) as f:
                info = json.load(f)
            self.assertEqual(info["failure_type"], "timeout")
            self.assertIn("wall-time", info["error_msg"])


if __name__ == "__main__":
    unittest.main()
