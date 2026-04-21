import json
import re

import anthropic
from llama_index.llms.anthropic import Anthropic

try:
    import dirtyjson
except ImportError:
    dirtyjson = None


def add_lineno(file_content: str) -> str:
    lines = file_content.split("\n")
    ret = ""
    for i, line in enumerate(lines):
        ret += f"{i+1}: {line}\n"
    return ret


def _strip_code_fences(output: str) -> str:
    for tag in ("json", "xml", ""):
        pat = rf"```{tag}\s*(.*?)```" if tag else r"```\s*(.*?)```"
        m = re.search(pat, output, re.DOTALL)
        if m:
            return m.group(1).strip()
    return output.strip()


def _extract_outer_braces(s: str) -> str:
    start = s.find("{")
    if start < 0:
        return s
    depth = 0
    in_str = False
    esc = False
    for i in range(start, len(s)):
        c = s[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return s[start : i + 1]
    return s[start:]


def _escape_unescaped_in_strings(s: str) -> str:
    """Escape raw newlines/tabs/carriage returns that appear inside JSON string
    literals. JSON forbids literal control characters inside strings; small LLMs
    routinely emit them for embedded source code. Whitespace outside strings is
    left untouched."""
    out = []
    in_str = False
    esc = False
    for c in s:
        if in_str:
            if esc:
                out.append(c)
                esc = False
                continue
            if c == "\\":
                out.append(c)
                esc = True
                continue
            if c == '"':
                out.append(c)
                in_str = False
                continue
            if c == "\n":
                out.append("\\n")
                continue
            if c == "\r":
                out.append("\\r")
                continue
            if c == "\t":
                out.append("\\t")
                continue
            if c == "\b":
                out.append("\\b")
                continue
            if c == "\f":
                out.append("\\f")
                continue
            out.append(c)
        else:
            if c == '"':
                in_str = True
            out.append(c)
    return "".join(out)


def reformat_json_string(output: str) -> str:
    """Best-effort normalizer for LLM JSON output.

    Handles three common failure modes observed with small/local models:
      1. Markdown fences (```json ... ```) around the payload.
      2. Preamble/postamble prose around the object.
      3. Raw newlines/tabs inside string values (invalid per RFC 8259).

    Returns a string that is either valid JSON or — if repair fails — the
    original content so the caller's existing error path still fires.
    """
    candidate = _strip_code_fences(output)
    candidate = _extract_outer_braces(candidate)

    try:
        json.loads(candidate, strict=False)
        return candidate
    except json.JSONDecodeError:
        pass

    repaired = _escape_unescaped_in_strings(candidate)
    try:
        json.loads(repaired, strict=False)
        return repaired
    except json.JSONDecodeError:
        pass

    if dirtyjson is not None:
        try:
            obj = dirtyjson.loads(candidate)
            return json.dumps(obj)
        except Exception:
            pass

    return candidate


class VertexAnthropicWithCredentials(Anthropic):
    def __init__(self, credentials, **kwargs):
        """
        In addition to all parameters accepted by Anthropic, this class accepts a
        new parameter `credentials` that will be passed to the underlying clients.
        """
        # Pop parameters that determine client type so we can reuse them in our branch.
        region = kwargs.get("region")
        project_id = kwargs.get("project_id")
        aws_region = kwargs.get("aws_region")

        # Call the parent initializer; this sets up a default _client and _aclient.
        super().__init__(**kwargs)

        # If using AnthropicVertex (i.e., region and project_id are provided and aws_region is None),
        # override the _client and _aclient with the additional credentials parameter.
        if region and project_id and not aws_region:
            self._client = anthropic.AnthropicVertex(
                region=region,
                project_id=project_id,
                credentials=credentials,  # extra argument
                timeout=self.timeout,
                max_retries=self.max_retries,
                default_headers=kwargs.get("default_headers"),
            )
            self._aclient = anthropic.AsyncAnthropicVertex(
                region=region,
                project_id=project_id,
                credentials=credentials,  # extra argument
                timeout=self.timeout,
                max_retries=self.max_retries,
                default_headers=kwargs.get("default_headers"),
            )
        # Optionally, you could add similar overrides for the aws_region branch if needed.
