# Kokoro TTS Hook for Claude Code (WSL2)

A Claude Code hook that uses [Kokoro TTS](https://github.com/hexgrad/kokoro) to speak a notification when Claude is waiting for tool approval.

This is the WSL2-specific version of the [Linux guide](../linux/kokoro-tts-hook.md). Everything from the Linux guide applies, plus the WSL2 gotchas documented below.

---

## Prerequisites

Same as the Linux guide:

- [uv](https://docs.astral.sh/uv/)
- `espeak-ng`
- Optional: NVIDIA GPU with CUDA

### WSL2-specific requirements

- Windows 10/11 host with working audio
- Access to Windows executables from WSL (`/mnt/c/Windows/...`)

---

## Setup

Follow steps 1-6 from the [Linux guide](../linux/kokoro-tts-hook.md), with the following differences:

### Audio Playback (the big WSL2 gotcha)

WSL2's PipeWire/PulseAudio typically runs with a **dummy output sink** — no actual audio device. You can verify this:

```bash
pw-cli ls Node
```

If you see `node.name = "auto_null"` and `node.description = "Dummy Output"`, your audio has nowhere to go. `pw-play` will exit 0 (success) but produce no sound.

**The fix:** play audio through Windows directly using PowerShell's `Media.SoundPlayer`:

```python
POWERSHELL = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

def play_wav(path):
    """Play a wav file through Windows audio via PowerShell."""
    win_path = subprocess.check_output(["wslpath", "-w", path], text=True).strip()
    subprocess.run(
        [POWERSHELL, "-Command", f"(New-Object Media.SoundPlayer '{win_path}').PlaySync()"],
        check=True,
    )
```

This converts the Linux path to a Windows path with `wslpath -w`, then uses .NET's `SoundPlayer` to play through the Windows audio stack.

### Full WSL2 hook script

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
POWERSHELL = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

def play_wav(path):
    """Play a wav file through Windows audio via PowerShell."""
    win_path = subprocess.check_output(["wslpath", "-w", path], text=True).strip()
    subprocess.run(
        [POWERSHELL, "-Command", f"(New-Object Media.SoundPlayer '{win_path}').PlaySync()"],
        check=True,
    )

def main():
    data = json.load(sys.stdin)
    tool_name = data.get("tool_name", "a tool")
    text = f"Hey, I need approval for {tool_name}."

    pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    generator = pipeline(text, voice=VOICE, speed=SPEED)

    for _, _, audio in generator:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            sf.write(f.name, audio, 24000)
            play_wav(f.name)
            os.unlink(f.name)

if __name__ == "__main__":
    main()
```

### Test it

```bash
echo '{"tool_name": "Bash", "tool_input": {"command": "ls"}}' | \
  cd ~/.claude/hooks/kokoro-tts && uv run python hook.py
```

You should hear "Hey, I need approval for Bash" through your Windows speakers.

### Configure the hook

Same as the Linux guide — add to `~/.claude/settings.json`:

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

---

## WSL2 Gotchas (What Went Wrong and Why)

Here's every issue encountered setting this up on WSL2, in the order they appeared:

### 1. Python 3.14 is too new

uv defaults to the latest Python. Kokoro depends on spacy, which uses pydantic v1 internals that are broken on Python 3.14+. The error:

```
pydantic.v1.errors.ConfigError: unable to infer type for attribute "REGEX"
```

**Fix:** Pin to Python 3.12 in `pyproject.toml` (`requires-python = ">=3.12"`) and run `uv python pin 3.12`.

### 2. Pipeline init hangs silently

`KPipeline(lang_code="a")` hangs forever with no error. The root cause chain:

1. Kokoro's G2P engine (`misaki`) uses spacy
2. On first use, spacy tries to download `en_core_web_sm` via `spacy.cli.download()`
3. `spacy.cli.download()` calls pip under the hood
4. uv venvs don't include pip by default
5. The subprocess fails silently and blocks

The only visible clue is a stderr line you'll miss in the noise:

```
/path/to/.venv/bin/python3: No module named pip
```

**Fix:**
```bash
uv pip install pip
uv run python -m spacy download en_core_web_sm
```

### 3. `pw-play` succeeds but no sound

PipeWire runs in WSL2 but only has a "Dummy Output" null sink. `pw-play` writes audio to `/dev/null` essentially, and returns exit code 0 as if everything worked.

```bash
$ pw-cli ls Node
# Shows: node.name = "auto_null", node.description = "Dummy Output"
```

**Fix:** Bypass Linux audio entirely. Play through Windows using PowerShell's `Media.SoundPlayer` via `wslpath -w` to convert paths.

### 4. `powershell.exe` not on PATH

WSL2 interop usually puts Windows executables on PATH, but this isn't always the case. `powershell.exe` wasn't found directly.

**Fix:** Use the full path: `/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe`

### 5. `espeak-ng` not installed (non-blocking)

Without `espeak-ng`, Kokoro prints a warning and skips out-of-vocabulary words, but still generates speech fine for normal English text. It needs `sudo` to install, which may not be available in all contexts.

**Fix:** `sudo apt-get install -y espeak-ng` when you can, or live without it for basic usage.

### 6. GPU access

NVIDIA GPU access in WSL2 works via the Windows GPU driver (not a Linux driver). The `nvidia-smi` output shows "Driver Version" from the Windows side. CUDA 12.x works out of the box with modern WSL2 + Windows 11. No extra setup needed — torch auto-detects it.

---

## Customization

Same options as the [Linux guide](../linux/kokoro-tts-hook.md#customization) — change voice, message text, force CPU, etc.
