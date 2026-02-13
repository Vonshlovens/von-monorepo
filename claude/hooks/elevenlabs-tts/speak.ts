import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";
import { spawn } from "node:child_process";
import { Readable } from "node:stream";

const VOICE_ID = process.env.ELEVEN_VOICE_ID ?? "kdmDKE6EkgrWrrykO9Qt";
const MODEL_ID = process.env.ELEVEN_MODEL_ID ?? "eleven_v3";

async function main() {
  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (!apiKey) {
    console.error("ELEVENLABS_API_KEY not set in .env");
    process.exit(1);
  }

  // Accept message from CLI args
  const message = process.argv.slice(2).join(" ").trim();
  if (!message) {
    console.error("Usage: bun run speak.ts <message>");
    process.exit(1);
  }

  console.log(`Speaking: "${message}"`);

  const client = new ElevenLabsClient({ apiKey });

  const audio = await client.textToSpeech.convert(VOICE_ID, {
    text: message,
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

  console.log("Done speaking.");
}

main().catch((err) => {
  console.error("TTS error:", err.message);
  process.exit(1);
});
