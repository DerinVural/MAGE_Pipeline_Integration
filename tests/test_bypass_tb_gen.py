import os
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from mage.agent import TopAgent  # noqa: E402


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
    agent.output_dir_per_run = tmpdir
    agent.tb_gen = MagicMock()
    agent.rtl_gen = MagicMock()
    agent.sim_reviewer = MagicMock()
    agent.sim_judge = MagicMock()
    agent.rtl_edit = MagicMock()
    return agent


class TestBypassTbGen(unittest.TestCase):
    def test_load_golden_tb_directly_returns_file_contents(self):
        with tempfile.TemporaryDirectory() as tmp:
            golden = os.path.join(tmp, "golden_tb.sv")
            golden_text = "module tb_golden;\n  initial $finish;\nendmodule\n"
            with open(golden, "w") as f:
                f.write(golden_text)
            agent = _make_agent(tmp)
            agent.golden_tb_path = golden
            agent.bypass_tb_gen = True
            tb, iface = agent._load_golden_tb_directly()
            self.assertEqual(tb, golden_text)
            self.assertEqual(iface, "")

    def test_bypass_without_golden_path_raises(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            agent.bypass_tb_gen = True
            agent.golden_tb_path = None
            with self.assertRaises(ValueError) as ctx:
                agent.run_instance("dummy spec")
            self.assertIn("bypass_tb_gen=True requires a golden_tb_path", str(ctx.exception))
            agent.tb_gen.chat.assert_not_called()

    def test_default_calls_tb_gen_chat(self):
        with tempfile.TemporaryDirectory() as tmp:
            agent = _make_agent(tmp)
            agent.bypass_tb_gen = False
            agent.tb_gen.chat.return_value = ("module tb;endmodule", "module if;endmodule")
            agent.rtl_gen.chat.return_value = (False, "syntax fail short-circuit")
            agent.run_instance("dummy spec")
            agent.tb_gen.chat.assert_called_once_with("dummy spec")

    def test_bypass_skips_tb_gen_in_revision_loop(self):
        with tempfile.TemporaryDirectory() as tmp:
            golden = os.path.join(tmp, "golden_tb.sv")
            with open(golden, "w") as f:
                f.write("module tb_golden; initial $finish; endmodule\n")
            agent = _make_agent(tmp)
            agent.bypass_tb_gen = True
            agent.golden_tb_path = golden
            agent.sim_max_retry = 3
            agent.rtl_gen.chat.return_value = (True, "module rtl;endmodule")
            agent.sim_reviewer.review.return_value = (False, 0, "fake sim log")
            agent.sim_judge.chat.return_value = True
            with self.assertRaises(AssertionError):
                agent.run_instance("dummy spec")
            agent.tb_gen.chat.assert_not_called()


if __name__ == "__main__":
    unittest.main()
