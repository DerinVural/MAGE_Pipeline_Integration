import os
import sys
from unittest.mock import MagicMock

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from mage import gen_config  # noqa: E402
from mage.gen_config import (  # noqa: E402
    get_agent_sampling,
    set_agent_sampling,
    set_exp_setting,
)


@pytest.fixture(autouse=True)
def _reset_state():
    saved_overrides = {k: dict(v) for k, v in gen_config.AGENT_SAMPLING_OVERRIDES.items()}
    saved_temperature = gen_config.global_exp_setting.temperature
    saved_top_p = gen_config.global_exp_setting.top_p
    yield
    gen_config.AGENT_SAMPLING_OVERRIDES.clear()
    gen_config.AGENT_SAMPLING_OVERRIDES.update(saved_overrides)
    gen_config.global_exp_setting.temperature = saved_temperature
    gen_config.global_exp_setting.top_p = saved_top_p


def test_default_global_for_unknown_agent():
    assert get_agent_sampling("TBGenerator") == (0.85, 0.95)


def test_simjudge_override():
    assert get_agent_sampling("SimJudge") == (0.0, 1.0)


def test_set_sampling_runtime():
    set_agent_sampling("RTLGenerator", temperature=0.5)
    assert get_agent_sampling("RTLGenerator") == (0.5, 0.95)


def test_global_settings_change_propagates():
    set_exp_setting(temperature=0.3)
    assert get_agent_sampling("TBGenerator") == (0.3, 0.95)


def test_simjudge_immune_to_global_change():
    set_exp_setting(temperature=0.3)
    assert get_agent_sampling("SimJudge") == (0.0, 1.0)


def test_tokencounter_invokes_override():
    from mage.token_counter import TokenCounter

    mock_llm = MagicMock()
    mock_llm.messages_to_prompt.return_value = "prompt"
    mock_response = MagicMock()
    mock_response.message.content = "response"
    mock_llm.chat.return_value = mock_response

    counter = TokenCounter.__new__(TokenCounter)
    counter.llm = mock_llm
    counter.token_cnts = {"": [], "SimJudge": []}
    counter.cur_tag = "SimJudge"
    counter.enable_reformat_json = False
    encoding = MagicMock()
    encoding.encode.return_value = [1, 2, 3]
    counter.encoding = encoding

    counter.count_chat([MagicMock()], llm=mock_llm)

    mock_llm.chat.assert_called_once()
    _, kwargs = mock_llm.chat.call_args
    assert kwargs["temperature"] == 0.0
    assert kwargs["top_p"] == 1.0
