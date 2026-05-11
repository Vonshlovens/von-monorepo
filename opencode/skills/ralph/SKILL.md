---
name: ralph
description: Supervise headless agent loops called ralphs. Use when the user wants to spawn autonomous agents, choose a Claude/Codex/OpenCode/GitHub Copilot harness, check ralph status, tail or review logs, kill agents, clean stale metadata, or analyze what a ralph accomplished.
compatibility: "opencode"
metadata:
  short-description: "Supervise headless agent loops"
---

# Ralph Supervisor

You supervise headless agent loops called "ralphs" (named after the Ralph Wiggum technique by Geoffrey Huntley). Each ralph drives one of four agent harnesses in non-interactive full-autonomy mode.

## Harnesses

Pass `-H <name>` to pick the agent CLI driving the loop. Each harness is invoked with full-autonomy flags and its event stream is parsed into a uniform log.

| Harness | Binary | Default model | Reasoning |
| --- | --- | --- | --- |
| `claude` (default) | `claude` | `opus` | none |
| `codex` | `codex` | `gpt-5.5` | `xhigh` |
| `opencode` | `opencode` | `github-copilot/claude-sonnet-4.6` | `--variant max` |
| `gh` | `copilot` (GitHub Copilot CLI) | `claude-sonnet-4.6` | `--effort high` |

Default to `claude` when the user does not name a harness. Map loose preferences such as "use codex", "the OpenAI one", "use opencode with sonnet", or "the GitHub Copilot one" to `-H codex`, `-H opencode`, or `-H gh`.

Use `-m <model>` when the user asks for a specific model. For opencode, use the `provider/model` format, such as `github-copilot/claude-opus-4.7`.

## Commands

Parse the user's request to determine the action.

### Spawn

For `spawn`, `start`, or `run`, launch a new ralph in the background:

```bash
nohup ~/von-ralph/ralph "See AGENT_PROMPT.md" 5 -d ~/cwl-api -n kanban-worker > /dev/null 2>&1 &
nohup ~/von-ralph/ralph "Refactor utils" 5 -d ~/myproj -n codex-refactor -H codex > /dev/null 2>&1 &
nohup ~/von-ralph/ralph "Add tests" 5 -d ~/myproj -n oc-tests -H opencode > /dev/null 2>&1 &
nohup ~/von-ralph/ralph "Triage TODOs" 5 -d ~/myproj -n gh-todos -H gh > /dev/null 2>&1 &
nohup ~/von-ralph/ralph "..." 5 -d ~/proj -n oc-opus -H opencode -m github-copilot/claude-opus-4.7 > /dev/null 2>&1 &
nohup ~/von-ralph/ralph "See AGENT_PROMPT.md" --marathon -d ~/cwl-api -n marathon-1 > /dev/null 2>&1 &
```

When spawning:

- Always use `nohup ... > /dev/null 2>&1 &` so the ralph survives terminal close.
- Suggest a descriptive `-n` name based on the task and harness, such as `codex-refactor`, `oc-tests`, or `gh-triage`.
- Default to `~/cwl-api` unless the user specifies another project.
- Default to 5 runs unless specified.
- Default to harness `claude` unless the user names another.
- Confirm the prompt, harness, directory, name, run count, and model options with the user before launching.
- If the ralph script reports a missing harness binary, relay the error and install hint instead of retrying.

### Status

For `status`, `list`, or `ls`, check running ralphs:

```bash
~/von-ralph/ralph-status list
```

### Tail Logs

For `tail`, `log`, or `check`, review a ralph's output:

```bash
~/von-ralph/ralph-status tail [name] [lines]
~/von-ralph/ralph-status log [name]
```

Use the returned log path for a deeper read when needed.

### Review

For `review` or `analyze`, review what a ralph accomplished:

1. Get recent log output with `~/von-ralph/ralph-status tail [name] 200`.
2. Check git history in the ralph's working directory for recent commits.
3. Summarize tasks picked up, completed work, errors, blockers, and anything needing Eric's attention.
4. If the ralph left notes in `AGENT_PROMPT.md`, read those too.

### Kill

For `kill` or `stop`, kill a specific ralph or all ralphs:

```bash
~/von-ralph/ralph-status kill <name|all>
```

### Clean

Remove stale metadata for dead ralphs:

```bash
~/von-ralph/ralph-status clean
```

### Logs

List available log files:

```bash
~/von-ralph/ralph-status logs
```

## Supervision Guidelines

- When reviewing output, look for errors, rate limits, completed tasks, blocked tasks, and anything that needs Eric's attention.
- If a ralph is stuck repeating the same action, recommend killing it and adjusting the prompt.
- After reviewing, suggest concrete next steps: spawn another ralph, adjust `AGENT_PROMPT.md`, or flag items for Eric.
- When multiple ralphs are running, watch for conflicts such as agents working on the same files or tasks.
- Use `/tts` only if Eric has explicitly asked for audio alerts.

## Harness Log Quirks

The normalized logs include assistant-text, tool-call, and tool-result markers, but the underlying event streams differ:

- `claude`: assistant text, per-tool calls, and tool results.
- `codex`: assistant text, shell commands with `[exit N]`, and file-change summaries. Rate-limit messages differ from Claude's wording.
- `opencode`: no assistant text events; only tool calls and `step_finish` lines. If a ralph looks empty, it may simply not have called tools. To see the final reply, run `opencode export <sessionID>` using the session ID from the raw event stream.
- `gh`: schema is undocumented and changing; unknown event shapes are logged as raw informational lines. Treat these as informational, not errors.

## No Arguments

If the user invokes this skill without a specific action:

1. Run `~/von-ralph/ralph-status list`.
2. Run `~/von-ralph/ralph-status logs`.
3. Briefly summarize the overview and ask what they want to do next.
