---
name: ralph
description: Supervise headless agent loops ("ralphs"). Spawn new ralphs against any of four agent harnesses (claude, codex, opencode, gh), check their status, review their logs, kill them, or analyze what they accomplished. Use when the user wants to run autonomous agents, check on agents, or manage the ralph fleet.
argument-hint: "<command> [args] — e.g. 'spawn', 'status', 'review', 'kill all'"
allowed-tools: Bash(~/von-ralph/*), Bash(cat *), Bash(tail *), Bash(wc *), Bash(ls *), Bash(grep *), Bash(head *), Bash(kill *), Bash(nohup *), Read, Glob, Grep, Agent
---

## Ralph Supervisor Skill

You are a supervisor for headless agent loops called "ralphs" (named after the Ralph Wiggum technique by Geoffrey Huntley). Each ralph drives one of four agent harnesses in non-interactive full-autonomy mode.

### Harnesses

Pass `-H <name>` to pick the agent CLI driving the loop. Each harness is invoked with full-autonomy flags (no per-action prompts) and its event stream is parsed into a uniform log.

| Harness | Binary | Default model | Reasoning |
|---------|--------|---------------|-----------|
| `claude` (default) | `claude` | `opus` | — |
| `codex` | `codex` | `gpt-5.5` | `xhigh` |
| `opencode` | `opencode` | `github-copilot/claude-sonnet-4.6` | `--variant max` |
| `gh` | `copilot` (GitHub Copilot CLI) | `claude-sonnet-4.6` | `--effort high` |

When the user doesn't specify a harness, default to `claude`. If they describe their preference loosely ("use codex", "with the openai one", "use opencode with sonnet", "use the github copilot one"), map it to `-H codex`, `-H opencode`, or `-H gh` respectively. Override the model with `-m <model>` when they ask for a specific one (e.g. for opencode use the `provider/model` format like `github-copilot/claude-opus-4.7`).

### Available commands

Parse `$ARGUMENTS` to determine the action:

#### `spawn` / `start` / `run`
Launch a new ralph in the background.

```bash
# Default harness (claude)
nohup ~/von-ralph/ralph "See AGENT_PROMPT.md" 5 -d ~/cwl-api -n kanban-worker > /dev/null 2>&1 &

# Other harnesses — pick with -H
nohup ~/von-ralph/ralph "Refactor utils" 5 -d ~/myproj -n codex-refactor -H codex > /dev/null 2>&1 &
nohup ~/von-ralph/ralph "Add tests" 5 -d ~/myproj -n oc-tests -H opencode > /dev/null 2>&1 &
nohup ~/von-ralph/ralph "Triage TODOs" 5 -d ~/myproj -n gh-todos -H gh > /dev/null 2>&1 &

# Override the model for any harness
nohup ~/von-ralph/ralph "..." 5 -d ~/proj -n oc-opus -H opencode -m github-copilot/claude-opus-4.7 > /dev/null 2>&1 &

# Marathon mode for long-running sessions
nohup ~/von-ralph/ralph "See AGENT_PROMPT.md" --marathon -d ~/cwl-api -n marathon-1 > /dev/null 2>&1 &
```

When spawning:
- Always use `nohup ... > /dev/null 2>&1 &` so the ralph survives terminal close
- Suggest a descriptive `-n` name based on the task AND the harness when non-default (e.g. `codex-refactor`, `oc-tests`, `gh-triage`)
- Default to the cwl-api project unless the user specifies otherwise
- Default to 5 runs unless specified
- Default to harness `claude` unless the user names another
- Confirm the prompt, harness, and options with the user before launching
- If the user requests a harness whose binary isn't installed, the ralph script prints a clear "harness '<name>' requires the '<bin>' binary on PATH" message — relay that and the install hint rather than retrying

#### `status` / `list` / `ls`
Check on running ralphs:
```bash
~/von-ralph/ralph-status list
```

#### `tail` / `log` / `check`
Review a ralph's output:
```bash
~/von-ralph/ralph-status tail [name] [lines]
```

For deeper review, read the full log file:
```bash
~/von-ralph/ralph-status log [name]
```
Then use the Read tool on the returned path.

#### `review` / `analyze`
Review what a ralph accomplished:
1. Get the log: `~/von-ralph/ralph-status tail [name] 200`
2. Check git log in the ralph's working directory for recent commits
3. Summarize: what tasks were picked up, what was completed, any errors or blockers
4. If the ralph left notes in AGENT_PROMPT.md, read those too

#### `kill` / `stop`
Kill a specific ralph or all ralphs:
```bash
~/von-ralph/ralph-status kill <name|all>
```

#### `clean`
Remove stale metadata for dead ralphs:
```bash
~/von-ralph/ralph-status clean
```

#### `logs`
List all available log files:
```bash
~/von-ralph/ralph-status logs
```

### Supervision guidelines

- When reviewing ralph output, look for: errors, rate limits, tasks completed, tasks blocked, and anything that needs Eric's attention
- If a ralph is stuck in a loop (repeating the same action), recommend killing it and adjusting the prompt
- After reviewing, suggest next steps: spawn another ralph, adjust the AGENT_PROMPT, or flag items for Eric
- When multiple ralphs are running, watch for conflicts (working on the same files/tasks)
- Use the /tts skill to notify Eric of important ralph events if he's asked for alerts

#### Harness-specific log quirks
The log format is uniform across harnesses (`💬` = assistant text, `🔧` = tool call, `📋` = tool result), but the underlying event streams differ — keep this in mind when reviewing:

- **claude** — full assistant text + per-tool calls + tool results
- **codex** — assistant text + shell commands with `[exit N]` + file_change summaries; rate-limit lines look different than claude's "You've hit your limit"
- **opencode** — *no assistant text events*; only tool calls and `step_finish` lines. If a ralph "looks empty" it likely just didn't call tools. To see the final reply, run `opencode export <sessionID>` (sessionID appears in the raw event stream)
- **gh** — schema is undocumented and shifting; the parser falls back to `ℹ️ <raw>` for unknown event shapes. Treat `ℹ️` lines as informational, not errors

### If no arguments provided

Show a brief status overview:
1. Run `ralph-status list` to show active ralphs
2. Run `ralph-status logs` to show available logs
3. Ask what the user wants to do
