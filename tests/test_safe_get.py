"""T21.4 unit tests for safe_get + MageSchemaError."""

import pytest

from mage.utils import MageSchemaError, safe_get


def test_safe_get_returns_value_when_present():
    d = {"a": 1, "b": "x"}
    assert safe_get(d, "a") == 1
    assert safe_get(d, "b") == "x"


def test_safe_get_returns_default_when_missing_non_critical():
    d = {"a": 1}
    assert safe_get(d, "missing") is None
    assert safe_get(d, "missing", default="fallback") == "fallback"


def test_safe_get_raises_when_missing_critical():
    d = {"a": 1}
    with pytest.raises(MageSchemaError) as exc_info:
        safe_get(d, "module", critical=True)
    assert exc_info.value.missing_key == "module"
    assert exc_info.value.dict_keys == ["a"]


def test_safe_get_critical_with_present_key_works():
    d = {"module": "module top; endmodule"}
    assert safe_get(d, "module", critical=True) == "module top; endmodule"


def test_safe_get_preserves_falsy_values():
    d = {"a": "", "b": 0, "c": False}
    assert safe_get(d, "a", default="DEFAULT") == ""
    assert safe_get(d, "b", default=99) == 0
    assert safe_get(d, "c", default=True) is False


def test_mage_schema_error_carries_dict_keys():
    try:
        safe_get({"x": 1, "y": 2}, "z", critical=True)
        assert False, "should have raised"
    except MageSchemaError as e:
        assert "x" in e.dict_keys
        assert "y" in e.dict_keys
        assert "z" in str(e)
