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

/** Extract just the binary/first word from a command string */
function cmdName(cmd: string): string {
  const first = cmd.trimStart().split(/\s+/)[0];
  // Strip any path prefix (e.g. /usr/bin/git -> git)
  return first.split("/").pop() ?? first;
}

function buildMessage(input: HookInput): string {
  const { hook_type, tool_name, tool_input } = input;

  // Stop event — task finished
  if (hook_type === "Stop" || !tool_name) {
    return "Hey Eric, I just finished up!";
  }

  // PermissionRequest — short, natural descriptions (never read out raw commands/paths)
  switch (tool_name) {
    case "Bash": {
      const cmd = String(tool_input?.command ?? "");
      const bin = cmdName(cmd);
      if (bin === "git") {
        const sub = cmd.trimStart().split(/\s+/)[1] ?? "";
        if (sub === "push") return "Hey Eric, I want to push to the remote.";
        if (sub === "commit") return "Hey Eric, I want to make a commit.";
        if (sub === "checkout" || sub === "switch") return "Hey Eric, I want to switch branches.";
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

  // Read hook input from stdin
  let input: HookInput = {};
  try {
    const raw = await Bun.stdin.text();
    if (raw.trim()) input = JSON.parse(raw);
  } catch {
    // If stdin parsing fails, fall back to a generic message
  }

  const text = buildMessage(input);
  const client = new ElevenLabsClient({ apiKey });

  const audio = await client.textToSpeech.convert(VOICE_ID, {
    text,
    modelId: MODEL_ID,
    outputFormat: "pcm_24000",
  });

  // play() doesn't pass PCM format flags to ffplay, so we spawn it directly
  const ffplay = spawn("ffplay", [
    "-autoexit", "-nodisp",
    "-f", "s16le",      // raw signed 16-bit little-endian PCM
    "-ar", "24000",      // 24 kHz sample rate
    "-ac", "1",          // mono
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
  process.exit(0); // Always exit cleanly so we don't block Claude
});
