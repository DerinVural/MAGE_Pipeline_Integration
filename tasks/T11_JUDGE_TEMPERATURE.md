# Task T11: Per-Agent Temperature Override (Judge = 0)

**Status:** PENDING
**Priority:** CRITICAL — highest-value task in Faz 0
**Depends on:** T10 merged to `feat/mage-open-v2`
**Reference:** `tasks/T11` notes, Plan v3 §3, prior T9 verdict η report
                (`reports/T9_BLOCKED.md`)

---

## Context

T9 (Debug Agent hard-problem smoke test) documented a concrete
pipeline-level bug: **`SimJudge` issues oscillating verdicts on the same
simulation data**. Example from `Prob127_lemmings1`:

```
"tb_needs_fix": false
"tb_needs_fix": true     ← same data, different verdict
"tb_needs_fix": false
"tb_needs_fix": true
"tb_needs_fix": false
"tb_needs_fix": false
```

Root cause: `SimJudge` runs under the same global sampling settings
as every other agent (`temperature=0.85`, `top_p=0.95`). For a judge
whose job is a binary yes/no decision on a deterministic input,
this high temperature introduces stochastic noise that the
`sim_max_retry=4` budget can't absorb. The pipeline gets stuck in
the TB-revision loop and **never reaches the Debug Agent branch**.

Across 18 problem-runs (T5×5 + T7×4 + T8×5 + T9×4), `RTLEditor`
round count was **0** in every single run. T11's hypothesis is that
forcing `SimJudge` to sample at `temperature=0` will stabilize its
verdicts, break the oscillation, allow the TB loop to exit, and let
the pipeline finally reach candidate generation and Debug Agent.

**If T11 succeeds, the T13 baseline re-run will produce the first
Debug Agent activation this project has ever observed.**

---

## Scope boundary: T11 is model-agnostic, not model-family-adaptive

This clarification matters because Plan v3 tests multiple model
families (Qwen, DeepSeek, Gemma, Codestral). An implementer might
reasonably ask: "Should `SimJudge` temperature depend on which model
is loaded?"

**No.** T11 applies a single, fixed override across all models:
`SimJudge → temperature=0.0, top_p=1.0`. The reasoning:

1. **Temperature=0 is model-theoretically universal.** Regardless of
   backbone architecture (Qwen, DeepSeek, Gemma, Codestral), calling
   `chat(temperature=0)` collapses sampling to argmax. There is no
   model family for which `temperature=0` means something qualitatively
   different. The fix is correct at the same value for every model.

2. **Family-adaptive sampling belongs to T17, not T11.** Plan v3 §4
   T17 introduces `configs/families/<family>.yaml` where each family
   gets its own recommended `T`, `top_p`, `top_k`, `repeat_penalty`
   for the **generative** agents (`TBGenerator`, `RTLGenerator`,
   `RTLEditor`). T17 is layered on top of T11 and can override global
   defaults per family. But it should **not** touch the SimJudge
   override; SimJudge stays at `temperature=0` regardless of family.

3. **Precedence (final, after all tasks land):**
   ```
   Priority 1 (highest): Agent-specific override  [T11 sets SimJudge = 0]
   Priority 2:           Family-specific config   [T17 tunes TB/RTL/Debug]
   Priority 3 (default): Global ExperimentSetting [paper default 0.85]
   ```
   T11 only implements Priority 1 for `SimJudge`. All other agents
   fall through to Priority 3 until T17 lands.

**Practical consequence for the implementer:** Do not thread any
model-family parameter through `get_agent_sampling()`. The signature
is `get_agent_sampling(agent_tag: str) -> Tuple[float, float]`,
nothing more. No `family` parameter, no model-name lookups, no
conditional logic on the LLM instance. A flat dict keyed only by
agent class name.

---

## Architectural windfall

Initial task estimation was "~2 days, LlamaIndex wrapper non-trivial".
Inspection of the code during task prep revealed the actual structure
is much simpler:

1. `token_counter.py:187` — every chat call already passes temperature
   and top_p as kwargs directly to the LLM: `llm.chat(messages,
   top_p=settings.top_p, temperature=settings.temperature)`. Per-call
   override is a supported path. No LlamaIndex internals work needed.

2. `token_counter.py:164` — `set_cur_tag(tag)` is already called by
   every agent right before chatting. The tag is the agent's class name
   (`"TBGenerator"`, `"RTLGenerator"`, `"SimJudge"`, `"RTLEditor"`).
   This is the exact hook T11 uses.

3. `gen_config.py:142-158` — `ExperimentSetting` holds global temp/top_p;
   `set_exp_setting()` is how runners tune them. T11 extends this
   module with a separate per-agent override dict.

The task is now ~1 day, not 2. But implementation must still be
careful — see the "do not" section.

---

## Scope

### T11.1 — Add per-agent override data structure to `gen_config.py`

In `src/mage/gen_config.py`, next to the existing `ExperimentSetting`
and `global_exp_setting`, add a parallel mechanism for agent-specific
temperature and top_p overrides.

**Design:**

```python
# Default per-agent overrides. Keys are agent class names (the same
# strings used by TokenCounter.set_cur_tag()). Values of None mean
# "use the global setting". Only override what differs from the
# global.

AGENT_SAMPLING_OVERRIDES: Dict[str, Dict[str, float | None]] = {
    "SimJudge": {"temperature": 0.0, "top_p": 1.0},
    # Other agents intentionally absent -> use global settings.
}


def get_agent_sampling(agent_tag: str) -> Tuple[float, float]:
    """Resolve (temperature, top_p) for a given agent tag.

    Returns agent-specific override if defined; otherwise the global
    ExperimentSetting value. Unknown tags fall back to global silently.
    """
    settings = get_exp_setting()
    override = AGENT_SAMPLING_OVERRIDES.get(agent_tag, {})
    temperature = override.get("temperature")
    top_p = override.get("top_p")
    if temperature is None:
        temperature = settings.temperature
    if top_p is None:
        top_p = settings.top_p
    return temperature, top_p


def set_agent_sampling(
    agent_tag: str,
    temperature: float | None = None,
    top_p: float | None = None,
) -> None:
    """Runtime override, for test harnesses and future flexibility."""
    if agent_tag not in AGENT_SAMPLING_OVERRIDES:
        AGENT_SAMPLING_OVERRIDES[agent_tag] = {}
    if temperature is not None:
        AGENT_SAMPLING_OVERRIDES[agent_tag]["temperature"] = temperature
    if top_p is not None:
        AGENT_SAMPLING_OVERRIDES[agent_tag]["top_p"] = top_p
```

Rationale:
- `top_p=1.0` alongside `temperature=0.0` is the safe default for
  deterministic decoding. Some backends treat top_p as dominant even
  with temp=0; setting to 1.0 makes intent unambiguous.
- Using a module-level dict keeps the existing global-settings pattern;
  don't introduce a singleton class or registry just for this.
- `set_agent_sampling()` exposed for future task use (T17 family config,
  and for unit tests) but not yet required by T11 runtime.

### T11.2 — Wire it into `token_counter.py`

Modify `src/mage/token_counter.py` at the chat call sites. There are
four:

| Class | Method | Line |
|---|---|---|
| `TokenCounter` | `count_chat` | 186-188 |
| `TokenCounter` | `count_achat` | 205-207 |
| `TokenCounter` | `count_chat_batch` | (check existing, if present) |
| `TokenCounterCached` | `count_chat` | 333-335 |

At each site, replace:

```python
response = llm.chat(
    messages, top_p=settings.top_p, temperature=settings.temperature
)
```

with:

```python
from .gen_config import get_agent_sampling  # import at top of file
# ...
temperature, top_p = get_agent_sampling(self.cur_tag)
logger.info(
    "TokenCounter count_chat [agent=%s] at temp: %s, top_p: %s"
    % (self.cur_tag, temperature, top_p)
)
response = llm.chat(messages, top_p=top_p, temperature=temperature)
```

Do the same for `count_achat` and the cached variant. Replace all
four call sites. The logger string should be updated in each spot so
the per-agent info is visible.

**The `from .gen_config import get_agent_sampling` goes at the top
of `token_counter.py` alongside existing `from .gen_config import
get_exp_setting`.** Do not inline-import inside methods.

### T11.3 — Unit tests

Create `tests/test_agent_sampling.py` with these cases:

1. **`test_default_global_for_unknown_agent`** — Call
   `get_agent_sampling("TBGenerator")`. Expect `(0.85, 0.95)` — the
   global default.

2. **`test_simjudge_override`** — Call `get_agent_sampling("SimJudge")`.
   Expect `(0.0, 1.0)`.

3. **`test_set_sampling_runtime`** — Call
   `set_agent_sampling("RTLGenerator", temperature=0.5)`. Then call
   `get_agent_sampling("RTLGenerator")`. Expect temperature=0.5,
   top_p=0.95 (global, because we only overrode temp).

4. **`test_global_settings_change_propagates`** — Change
   `set_exp_setting(temperature=0.3)`. Call
   `get_agent_sampling("TBGenerator")`. Expect `(0.3, 0.95)` — the
   NEW global.

5. **`test_simjudge_immune_to_global_change`** — With
   `set_exp_setting(temperature=0.3)` still in effect from #4,
   call `get_agent_sampling("SimJudge")`. Expect `(0.0, 1.0)` —
   override wins over global.

6. **`test_tokencounter_invokes_override`** — Mock the `llm.chat` call.
   Construct a `TokenCounter`, call `set_cur_tag("SimJudge")`, then
   call `count_chat([fake_message], llm=mock_llm)`. Assert that
   `mock_llm.chat` was called with `temperature=0.0, top_p=1.0`.

Tests 4 and 5 matter because they guard against a subtle regression:
a future contributor might refactor `get_agent_sampling` to snapshot
the global on import, which breaks runtime global-setting changes.
Keep the global lookup lazy.

**Reset override state between tests.** Use a `pytest.fixture` with
`autouse=True` that saves and restores the module's
`AGENT_SAMPLING_OVERRIDES` and the global `ExperimentSetting`.

### T11.4 — Faz 0 micro-smoke (Prob127 only)

After T11.1-3 are complete, run one targeted smoke test:

```bash
# Reuse the existing T9 runner, but filter to just Prob127
python tests/test_top_agent_ollama_hard.py  # or create a variant
# with filter_instance='^(Prob127_lemmings1)$' and run_identifier='t11_prob127_verify'
```

Inspect the log. Look for:

1. **Agent temperature traces** — new log lines `TokenCounter count_chat
   [agent=SimJudge] at temp: 0.0, top_p: 1.0` should appear. And
   `[agent=TBGenerator] at temp: 0.85, top_p: 0.95` (global).
2. **Judge verdict stability** — grep the log for `"tb_needs_fix":`
   entries. In the T9 baseline these alternated false/true/false/true.
   Under T11 they should either all converge to false (no TB retry)
   or all be true (consistent retry until exit).
3. **Whether Debug Agent now triggers** — `grep -c "RTL Editing:
   round"` in the log. Target: **≥1**. If this is ≥1 it is this
   project's first ever Debug Agent activation.

**Do not claim success on raw pass/fail.** The point of T11.4 is to
observe the mechanistic effect, not the benchmark number.

---

## Acceptance criteria

- [ ] `src/mage/gen_config.py` gains `AGENT_SAMPLING_OVERRIDES`,
      `get_agent_sampling()`, `set_agent_sampling()`. No other additions.
- [ ] `src/mage/token_counter.py` wires `get_agent_sampling()` at all
      chat call sites (count_chat, count_achat, count_chat_batch if
      present, TokenCounterCached.count_chat). The existing
      `from .gen_config import get_exp_setting` import line remains;
      `get_agent_sampling` is added to it.
- [ ] `tests/test_agent_sampling.py` passes all 6 cases:
      `pytest tests/test_agent_sampling.py -v`
- [ ] Full-suite regression still passes (ignoring the pre-existing
      `test_single_agent.py` backoff-import failure, same as T10):
      `pytest tests/ --ignore=tests/test_single_agent.py`
- [ ] Prob127 micro-smoke was executed and logs inspected; the
      `TokenCounter count_chat [agent=SimJudge] at temp: 0.0` log
      line is present at least once.
- [ ] Commit on `feat/mage-open-v2`, message:
      `[T11] Per-agent temperature override (SimJudge = 0)`
- [ ] Report filed: `reports/v2/T11_DONE.md`

---

## Stop conditions

File `reports/v2/T11_BLOCKED.md` if:

- `llm.chat(..., temperature=X)` throws because the underlying
  LlamaIndex Ollama version doesn't accept that kwarg at call time
  (unlikely — the code already passes it, but verify).
- Full-suite regression introduces failures not present on
  `feat/mage-open-v2` pre-T11.
- The micro-smoke run hangs for >15 minutes on Prob127 (Ollama
  health issue, not T11-related).
- The log shows `[agent=SimJudge] at temp: 0.0` but `tb_needs_fix`
  oscillation **still appears**. This would invalidate the core
  hypothesis of T11 and is a major finding — stop, do not proceed to
  T12, write a BLOCKED report with the full log.

---

## Do NOT

- Modify any agent file (`tb_generator.py`, `rtl_generator.py`,
  `sim_judge.py`, `rtl_editor.py`). The per-agent routing comes from
  `set_cur_tag()` calls that these files already make — don't edit
  them.
- Add temperature overrides for any agent other than `SimJudge`.
  Other agents intentionally stay on global settings in T11. T17
  (family config) will handle broader agent tuning.
- Touch `prompts.py`, `benchmark_read_helper.py`, or any runner file
  other than for the optional Prob127 variant mentioned in T11.4.
- Change the default global temperature (still 0.85). Only the
  SimJudge override is in scope.
- Introduce a singleton class, registry, or dependency-injection
  framework. A module-level dict + two functions is enough.
- Rename `cur_tag`, `set_cur_tag`, or the agent class-name
  convention. Downstream tasks (T14, T17) depend on these.
- Expand the Prob127 smoke beyond a single run. If you need more
  evidence, leave a note in the Follow-ups section of the report;
  the full validation run is T13, not T11.

---

## Report template

```markdown
# Task T11: Per-Agent Temperature Override (Judge = 0)

**Status:** DONE
**Branch:** feat/mage-open-v2
**Commits:** <hash>

## Changes
- src/mage/gen_config.py: added AGENT_SAMPLING_OVERRIDES dict,
  get_agent_sampling(), set_agent_sampling()
- src/mage/token_counter.py: wired get_agent_sampling() at N chat
  call sites (list them)
- tests/test_agent_sampling.py: 6 unit tests, all passing

## Verification
- pytest tests/test_agent_sampling.py -v: 6 passed
- pytest tests/ --ignore=tests/test_single_agent.py: X passed, no regressions
- Prob127 micro-smoke: log confirms [agent=SimJudge] at temp: 0.0 present;
  tb_needs_fix sequence observed: <paste ≤10 lines>
- Debug Agent rounds observed: <count> (0 means not yet; 1+ means first
  activation of this project)

## Metrics
- SimJudge temp trace: 0.0 (confirmed in log)
- Other agents temp trace: 0.85 (confirmed in log)
- tb_needs_fix oscillation: <eliminated | reduced | unchanged>
- RTL Editing rounds: <N>

## Notes
<Anything surprising. Especially:
- If Debug Agent triggered for the first time, quote the relevant log block.
- If oscillation is eliminated but some other stall replaces it.
- Any unexpected interaction with T10's failure_type sidecar.>

## Follow-ups spotted
<Out-of-scope observations. E.g. "TokenCounterCached.count_chat uses
the old two-llm caching pattern; if we ever want to enable caching
for the Anthropic provider again, the override will need a cache
key update — noted here, not done in T11.">
```

---

## After T11

**Do not start T12.** File the report and wait. PM will review
before issuing T12.

T12 is the golden-TB bypass mode — lower risk, mostly orthogonal to
T11. T13 (Faz 0 baseline re-run) comes after T12 and will definitively
measure whether T11 + T12 together allow Debug Agent to trigger
across the T5 + T9 problem set. T11 alone gives us a single data
point (Prob127); T13 gives us 10.
