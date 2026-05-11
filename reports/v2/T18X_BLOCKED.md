# T18.x — Parse Robustness Follow-Up: BLOCKED

**Date:** 2026-04-29
**Branch:** `feat/t17a-vllm-provider`
**Spec:** `tasks/T18X_PARSE_ROBUSTNESS_FOLLOWUP.md`
**Status:** BLOCKED (pre-flight check failed)

## Why BLOCKED

The spec's §T18.x.3 (rtl_editor.py wrap) requires returning an
`ActionInput(command="do_nothing", args={})` from `parse_output()` on
parse failure, and explicitly states (caveat):

> If the command doesn't exist, the spec needs revision; do NOT invent
> behavior. If `do_nothing` doesn't exist, file BLOCKED and ask PM how
> to handle.

§Stop conditions §1 reinforces:

> `do_nothing` command does NOT exist in `RTLEditor`. Stop, ask PM how
> to handle (don't invent fallback behavior).

### Pre-flight check result

`do_nothing` is **not** a method on `RTLEditor` in the current branch
(`feat/t17a-vllm-provider`, head `1e6887d`). All the methods that look
like editor commands:

```
write_rtl, read_rtl, replace_sanity_check, judge_replace_action_execution,
replace_content_by_matching
```

Verified by:

```bash
grep -nE "^    def [a-z_]+\(" src/mage/rtl_editor.py
# (no do_nothing line)
```

### Why this also blocks the proposed fallback at `run_action`

`run_action` (line 358-363) dispatches via:

```python
action = getattr(self, action_input.command)
action_output = action(**action_input.args)
```

So even if `parse_output` returned a `do_nothing` `ActionInput`, the
next call would `getattr(self, "do_nothing")` → `AttributeError` →
agent crash. The proposed fallback wouldn't actually shield the agent;
it would just shift the crash from `parse_output` to `run_action`. The
spec's §T18.x.3 design assumes a method that does not exist and was
never added.

## Other T18.x sub-tasks: NOT executed (atomic spec)

Per spec discipline, T18.x.1, T18.x.2, T18.x.4, T18.x.5, T18.x.6 are
also held — the spec is presented as an atomic unit (single commit
message `[T18.x] Widen exception handlers + None guard for
parse_json_robust` per §Acceptance criteria). Splitting into a partial
commit risks acceptance-criteria drift.

The deferred sub-tasks that ARE safe to execute on their own merits
(no spec dependency on `do_nothing`):

- **T18.x.1** (None guard in `parse_json_robust`) — local utility-only
  change, 2 lines, zero risk to agent flow.
- **T18.x.2** (widen except clause in `rtl_generator.py:212`,
  `tb_generator.py:288`) — these are the actual T18 regression fix
  from T18_DONE.md §F1. Both have existing retry loops that would
  benefit immediately from catching `MageJsonParseError`.
- **T18.x.4** (one new unit test for None case).
- **T18.x.5/6** (M4 verify rerun, headline measurement) — would be
  partially valid even without T18.x.3, but the headline table assumes
  all four files are patched.

I did NOT execute any of these to avoid producing a partial T18.x that
contradicts the spec's atomic acceptance gate.

## Options for PM

1. **Add `do_nothing` to `RTLEditor`** (probably ~5 lines: a method
   that returns an empty dict and is registered into the action prompt
   so the model doesn't get confused; spec then proceeds unchanged).
2. **Replace the fallback design** for rtl_editor.py to NOT invent a
   command — e.g., re-raise after logging, or return a tagged error
   the outer chat loop already knows how to handle (need to inspect
   `RTLEditor.chat`'s for-loop tolerance for raised exceptions).
3. **Drop §T18.x.3 entirely.** Land just T18.x.1 + T18.x.2 + T18.x.4
   (utility-level + the two files with existing retry paths) and
   accept that `rtl_editor.py` and `sim_judge.py` retain their crash
   semantics until a separate task addresses them. This is a smaller
   surface-area change with most of the F1 closure win, since the
   T18_DONE traceback came from `rtl_generator.py`, not the editor or
   judge paths.
4. **Author the spec differently** — e.g., use `replace_content_by_matching`
   with empty args as a "no-op" since it's an existing command. But
   that has its own behavior (it actually tries to match text), so
   this is also "inventing" — not recommended.

My weak recommendation: **option 3**. T18_DONE.md §F1 specifically
called out the `rtl_generator` and `tb_generator` regression as the
load-bearing one — the editor / judge paths were called out as
pre-existing crash sites that T18 didn't make worse. A scoped T18.x
that fixes the actual T18-introduced regression (None guard + the two
widened except clauses + matching unit test) is a clean atomic commit
and a clear F1 closure measurement. Then a separate task can revisit
the editor / judge fallback design with the right command surface.

## Files touched

```
tasks/T18X_PARSE_ROBUSTNESS_FOLLOWUP.md   (spec, copied in for pairing)
reports/v2/T18X_BLOCKED.md                (this file)
```

No source files modified. No verify run started. No pod time consumed.
