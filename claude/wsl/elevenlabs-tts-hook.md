# ElevenLabs TTS Hook for Claude Code (WSL2)

A Claude Code hook that uses ElevenLabs to speak TTS notifications when Claude needs approval or finishes a task.

## Prerequisites

- **Bun** runtime
- **ffplay** (from ffmpeg): `sudo apt install ffmpeg`
- **ElevenLabs API key** set as `ELEVENLABS_API_KEY` environment variable
- WSL2 with audio passthrough working (Windows 11 ships this by default via PipeWire/PulseAudio)

## Setup

```bash
mkdir -p ~/.claude/hooks/elevenlabs-tts
cd ~/.claude/hooks/elevenlabs-tts

# Create package.json
cat <<'EOF' > package.json
{
  "name": "elevenlabs-tts-hook",
  "version": "1.0.0",
  "scripts": { "start": "bun run index.ts" },
  "dependencies": {
    "@elevenlabs/elevenlabs-js": "^2.35.0"
  }
}
EOF

bun install
```

Then copy `index.ts` (see below) and add the hook to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "cd ~/.claude/hooks/elevenlabs-tts && bun run index.ts", "timeout": 30 }]
      }
    ],
    "PermissionRequest": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "cd ~/.claude/hooks/elevenlabs-tts && bun run index.ts", "timeout": 30 }]
      }
    ]
  }
}
```

## Key Learnings

### 1. Don't use the built-in `play()` helper with PCM output

The `play()` function from `@elevenlabs/elevenlabs-js` spawns ffplay as:

```
ffplay -autoexit - -nodisp
```

This works for **MP3** (a self-describing format where ffplay can detect codec/sample rate from the stream headers), but **fails silently for raw PCM** because ffplay has no way to know the sample rate, bit depth, or channel count from a raw byte stream.

**Fix:** Spawn ffplay yourself with explicit format flags:

```ts
const ffplay = spawn("ffplay", [
  "-autoexit", "-nodisp",
  "-f", "s16le",      // raw signed 16-bit little-endian PCM
  "-ar", "24000",     // must match the outputFormat sample rate
  "-ac", "1",         // mono
  "-",
], { stdio: ["pipe", "ignore", "ignore"] });

Readable.from(audio).pipe(ffplay.stdin);
```

### 2. PCM output format is tier-restricted

ElevenLabs restricts certain PCM sample rates by subscription tier:

| Format       | Free/Starter | Pro+ |
|--------------|:------------:|:----:|
| `pcm_16000`  | Yes          | Yes  |
| `pcm_22050`  | Yes          | Yes  |
| `pcm_24000`  | Yes          | Yes  |
| `pcm_44100`  | No           | Yes  |

If you request a format your tier doesn't support, the API returns a **403** with `output_format_not_allowed`. Use `pcm_24000` as a safe default — it sounds good and is available on all tiers.

### 3. The `-ar` flag must match the `outputFormat`

If you use `outputFormat: "pcm_24000"` but tell ffplay `-ar 44100`, the audio will play at the wrong speed (either chipmunk-fast or slow-motion). Always keep them in sync:

| `outputFormat` | `-ar` flag |
|----------------|------------|
| `pcm_16000`    | `16000`    |
| `pcm_22050`    | `22050`    |
| `pcm_24000`    | `24000`    |
| `pcm_44100`    | `44100`    |

### 4. WSL2 audio just works (Windows 11)

Windows 11 WSL2 includes built-in PipeWire/PulseAudio passthrough. No extra configuration needed — `ffplay` outputs audio through the Windows host automatically. You can verify with:

```bash
ffplay -f lavfi -i "sine=frequency=440:duration=0.5" -autoexit -nodisp
```

If you don't hear a beep, check that your WSL2 distro is up to date (`wsl --update`).

## Environment Variables

| Variable             | Description                          | Default                          |
|----------------------|--------------------------------------|----------------------------------|
| `ELEVENLABS_API_KEY` | Your ElevenLabs API key (required)   | —                                |
| `ELEVEN_VOICE_ID`    | Voice to use                         | `kdmDKE6EkgrWrrykO9Qt`          |
| `ELEVEN_MODEL_ID`    | TTS model                            | `eleven_v3`                      |

## Full index.ts

```ts
import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";
import { spawn } from "node:child_process";
import { Readable } from "node:stream";

const VOICE_ID = process.env.ELEVEN_VOICE_ID ?? "kdmDKE6EkgrWrrykO9Qt";
const MODEL_ID = process.env.ELEVEN_MODEL_ID ?? "eleven_v3";

interface HookInput {
  hook_type?: string;
  tool_name?: string;
  tool_input?: Record<string, unknown>;
}

function cmdName(cmd: string): string {
  const first = cmd.trimStart().split(/\s+/)[0];
  return first.split("/").pop() ?? first;
}

function buildMessage(input: HookInput): string {
  const { hook_type, tool_name, tool_input } = input;

  if (hook_type === "Stop" || !tool_name) {
    return "Hey Eric, I just finished up!";
  }

  switch (tool_name) {
    case "Bash": {
      const cmd = String(tool_input?.command ?? "");
      const bin = cmdName(cmd);
      if (bin === "git") {
        const sub = cmd.trimStart().split(/\s+/)[1] ?? "";
        if (sub === "push") return "Hey Eric, I want to push to the remote.";
        if (sub === "commit") return "Hey Eric, I want to make a commit.";
        if (sub === "checkout" || sub === "switch")
          return "Hey Eric, I want to switch branches.";
        return `Hey Eric, I need to run a git ${sub} command.`;
      }
      if (["npm", "bun", "pnpm", "yarn"].includes(bin))
        return "Hey Eric, I need to run a package manager command.";
      if (bin === "rm") return "Hey Eric, I need to delete some files.";
      if (bin === "mkdir") return "Hey Eric, I need to create a directory.";
      if (["docker", "docker-compose"].includes(bin))
        return "Hey Eric, I need to run a Docker command.";
      return `Hey Eric, I need to run a ${bin} command.`;
    }
    case "Write": {
      const filename = String(tool_input?.file_path ?? "").split("/").pop();
      return `Hey Eric, I want to create a file called ${filename}.`;
    }
    case "Edit": {
      const filename = String(tool_input?.file_path ?? "").split("/").pop();
      return `Hey Eric, I want to edit ${filename}.`;
    }
    default:
      return `Hey Eric, I need your approval.`;
  }
}

async function main() {
  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (!apiKey) {
    console.error("ELEVENLABS_API_KEY not set in .env");
    process.exit(0);
  }

  let input: HookInput = {};
  try {
    const raw = await Bun.stdin.text();
    if (raw.trim()) input = JSON.parse(raw);
  } catch {}

  const text = buildMessage(input);
  const client = new ElevenLabsClient({ apiKey });

  const audio = await client.textToSpeech.convert(VOICE_ID, {
    text,
    modelId: MODEL_ID,
    outputFormat: "pcm_24000",
  });

  const ffplay = spawn("ffplay", [
    "-autoexit", "-nodisp",
    "-f", "s16le",
    "-ar", "24000",
    "-ac", "1",
    "-",
  ], { stdio: ["pipe", "ignore", "ignore"] });

  Readable.from(audio).pipe(ffplay.stdin);

  await new Promise<void>((resolve, reject) => {
    ffplay.on("close", (code) =>
      code === 0 ? resolve() : reject(new Error(`ffplay exited with code ${code}`))
    );
    ffplay.on("error", reject);
  });
}

main().catch((err) => {
  console.error("TTS hook error:", err.message);
  process.exit(0);
});
```
