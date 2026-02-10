# Kokoro TTS Hook for Claude Code (Linux)

A Claude Code hook that uses [Kokoro TTS](https://github.com/hexgrad/kokoro) to speak a notification when Claude is waiting for tool approval.

Kokoro is a lightweight, open-source TTS model (82M params, ~350MB) that runs locally on CPU or GPU.

---

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (Python package manager)
- `espeak-ng` (phoneme backend for Kokoro)
- A working audio setup (PipeWire/PulseAudio with a real output sink)
- Optional: NVIDIA GPU with CUDA for faster generation

### Install espeak-ng

```bash
sudo apt-get install -y espeak-ng
```

### Install uv (if not already installed)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

---

## Setup

### 1. Create the project

```bash
mkdir -p ~/.claude/hooks/kokoro-tts
cd ~/.claude/hooks/kokoro-tts
uv init --no-readme
```

### 2. Pin Python 3.12

Kokoro depends on spacy, which requires pydantic v1 compatibility. Python 3.14+ breaks this. Pin to 3.12:

Edit `pyproject.toml` and change `requires-python` to:

```toml
requires-python = ">=3.12"
```

Then pin the version:

```bash
uv python pin 3.12
```

### 3. Install dependencies

```bash
uv add kokoro soundfile sounddevice
```

This pulls in torch (with CUDA if you have an NVIDIA GPU), the Kokoro model pipeline, spacy, and audio libraries. Expect ~2-3GB of downloads.

### 4. Install pip and the spacy model

Kokoro's G2P (grapheme-to-phoneme) engine uses spacy internally and calls `spacy.cli.download()` which requires pip. uv venvs don't include pip by default, so you need to add it:

```bash
uv pip install pip
uv run python -m spacy download en_core_web_sm
```

> **Why?** Without pip installed in the venv, `KPipeline()` hangs silently when it tries to auto-download the spacy model. This is the single most confusing failure mode — there's no error, it just freezes.

### 5. Pre-download the model and voice

The first run downloads the Kokoro model (~350MB) and voice files from HuggingFace. Do this ahead of time so the hook doesn't timeout:

```bash
uv run python -c "
from huggingface_hub import hf_hub_download
hf_hub_download('hexgrad/Kokoro-82M', 'kokoro-v1_0.pth')
hf_hub_download('hexgrad/Kokoro-82M', 'voices/af_bella.pt')
print('Done')
"
```

### 6. Create the hook script

Create `~/.claude/hooks/kokoro-tts/hook.py`:

```python
#!/usr/bin/env python3
"""Claude Code hook: speak a notification when waiting for tool approval."""

import json
import os
import subprocess
import sys
import tempfile

from kokoro import KPipeline
import soundfile as sf

VOICE = "af_bella"
SPEED = 1.0

def main():
    data = json.load(sys.stdin)
    tool_name = data.get("tool_name", "a tool")
    text = f"Hey, I need approval for {tool_name}."

    pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    generator = pipeline(text, voice=VOICE, speed=SPEED)

    for _, _, audio in generator:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            sf.write(f.name, audio, 24000)
            subprocess.run(["pw-play", f.name], check=True)
            os.unlink(f.name)

if __name__ == "__main__":
    main()
```

> **Note:** This uses `pw-play` (PipeWire). If you use PulseAudio, swap to `paplay`. If you have neither, install `sox` and use `play`.

### 7. Test it

```bash
echo '{"tool_name": "Bash", "tool_input": {"command": "ls"}}' | \
  cd ~/.claude/hooks/kokoro-tts && uv run python hook.py
```

You should hear "Hey, I need approval for Bash."

### 8. Configure the hook

Add the `PermissionRequest` hook to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "cd ~/.claude/hooks/kokoro-tts && uv run python hook.py",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

- `matcher: ""` matches all tools. You can filter with a regex like `"Bash"` or `"Bash|Edit"`.
- `timeout: 30` gives 30 seconds for model loading + generation + playback.

---

## How It Works

When Claude Code needs permission to run a tool (e.g. a Bash command), it fires the `PermissionRequest` hook event. The hook receives JSON on stdin:

```json
{
  "session_id": "abc123",
  "hook_event_name": "PermissionRequest",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf node_modules",
    "description": "Remove node_modules directory"
  }
}
```

The script reads `tool_name`, generates speech with Kokoro, and plays it.

---

## Customization

### Change the voice

Kokoro has 50+ voices. Replace `VOICE` in the script:

```python
VOICE = "am_adam"      # American male
VOICE = "bf_emma"      # British female
VOICE = "am_michael"   # American male
```

Full list: [hexgrad/Kokoro-82M voices](https://huggingface.co/hexgrad/Kokoro-82M/tree/main/voices)

### Change the message

Edit the `text` variable in `main()`. You have access to the full hook JSON, so you can include details:

```python
tool_input = data.get("tool_input", {})
command = tool_input.get("command", "")
text = f"Approve {tool_name}? Command is: {command}"
```

### Force CPU

If you want to avoid GPU usage:

```python
pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M", device="cpu")
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Hangs at "Creating pipeline" | pip not installed in venv, spacy model download fails silently | `uv pip install pip && uv run python -m spacy download en_core_web_sm` |
| `pydantic.v1.errors.ConfigError` | Python 3.14+ incompatible with spacy's pydantic v1 usage | Pin to Python 3.12 |
| No audio output | `pw-play` targets a dummy/null sink | Check `pw-cli ls Node` for real audio sinks |
| `espeak-ng` warning | espeak-ng not installed | `sudo apt-get install espeak-ng` (speech still works without it, but OOD words are skipped) |
| Slow first run | Model download from HuggingFace | Pre-download with the `hf_hub_download` command above |
| Timeout in hook | Cold start takes ~8-10s loading torch + model | Increase `timeout` in settings, or consider a persistent daemon |
