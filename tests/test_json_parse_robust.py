import os
import sys

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from mage.utils import MageJsonParseError, parse_json_robust  # noqa: E402


def test_clean_json_passthrough():
    assert parse_json_robust('{"a": 1, "b": "x"}') == {"a": 1, "b": "x"}


def test_markdown_fence_stripping():
    assert parse_json_robust('```json\n{"a": 1}\n```') == {"a": 1}


def test_preamble_postamble():
    raw = 'Here is the JSON: {"a": 1} hope this helps'
    assert parse_json_robust(raw) == {"a": 1}


def test_chain_of_thought_before_json():
    raw = 'Let me think... <think>step 1</think> Final: {"a": 1}'
    assert parse_json_robust(raw) == {"a": 1}


def test_unterminated_string_dirtyjson():
    raw = '{"a": 1, "b": "unterminated\nx"}'
    result = parse_json_robust(raw)
    assert isinstance(result, dict)
    assert result.get("a") == 1


def test_truly_unparseable_raises():
    with pytest.raises(MageJsonParseError):
        parse_json_robust("this is not json at all")


def test_exception_preserves_content():
    raw = "this is not json at all"
    with pytest.raises(MageJsonParseError) as exc_info:
        parse_json_robust(raw)
    assert exc_info.value.original_content == raw


def test_array_at_top_level_fails():
    with pytest.raises(MageJsonParseError):
        parse_json_robust("[1, 2, 3]")


def test_nested_json_handled():
    assert parse_json_robust('{"a": {"b": "c"}}') == {"a": {"b": "c"}}


def test_real_t17a_failure_case():
    raw = (
        "I'll analyze the testbench failure for the FSM3 problem.\n\n"
        "```json\n"
        '{"reasoning": "The testbench expects state outputs but the RTL '
        'uses one-hot encoding which doesn\'t match", "tb_needs_fix": false}\n'
        "```\n\n"
        "Let me know if you need more analysis."
    )
    result = parse_json_robust(raw)
    assert isinstance(result, dict)
    assert result.get("tb_needs_fix") is False
    assert "reasoning" in result
