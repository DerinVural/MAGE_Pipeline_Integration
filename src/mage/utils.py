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


class MageJsonParseError(Exception):
    """Raised when parse_json_robust exhausts all fallback strategies."""

    def __init__(self, message: str, original_content: str):
        super().__init__(message)
        self.original_content = original_content


def parse_json_robust(content: str) -> dict:
    """Parse a JSON dict from a model response with fallbacks.

    Tries (in order):
      1. Strict json.loads on the raw content
      2. Strict json.loads after stripping markdown fences
      3. Strict json.loads on the FIRST {...} block extracted via regex
      4. Strict json.loads on the LAST {...} block (chain-of-thought tail)
      5. dirtyjson on the original content (forgiving parser)

    Raises MageJsonParseError when every strategy fails. The original
    content is preserved on the exception for upstream logging.
    """
    if content is None:
        raise MageJsonParseError(
            "parse_json_robust received None (model returned no content)",
            original_content="",
        )

    try:
        result = json.loads(content, strict=False)
        if isinstance(result, dict):
            return result
    except json.JSONDecodeError:
        pass

    cleaned = content.strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*\n", "", cleaned)
        cleaned = re.sub(r"\n```\s*$", "", cleaned)
        try:
            result = json.loads(cleaned, strict=False)
            if isinstance(result, dict):
                return result
        except json.JSONDecodeError:
            pass

    first_match = re.search(r"\{.*\}", content, re.DOTALL)
    if first_match:
        try:
            result = json.loads(first_match.group(0), strict=False)
            if isinstance(result, dict):
                return result
        except json.JSONDecodeError:
            pass

    last_open = content.rfind("{")
    if last_open >= 0:
        depth = 0
        for i in range(last_open, len(content)):
            if content[i] == "{":
                depth += 1
            elif content[i] == "}":
                depth -= 1
                if depth == 0:
                    candidate = content[last_open : i + 1]
                    try:
                        result = json.loads(candidate, strict=False)
                        if isinstance(result, dict):
                            return result
                    except json.JSONDecodeError:
                        pass
                    break

    if dirtyjson is not None:
        try:
            result = dirtyjson.loads(content)
            if isinstance(result, dict):
                return dict(result)
        except Exception:
            pass

    raise MageJsonParseError(
        f"All JSON parse strategies failed. Content starts: {content[:200]!r}",
        original_content=content,
    )


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
