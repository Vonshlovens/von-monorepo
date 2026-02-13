---
name: tts
description: Speak a voice message aloud to the user using ElevenLabs TTS. Use this to deliver verbal reminders, alerts, notifications, or any spoken message. Invoke proactively when a timer/sleep completes, when the user asks to be reminded of something, or whenever a voice notification would be helpful.
argument-hint: "<message to speak>"
allowed-tools: Bash(~/.claude/hooks/elevenlabs-tts/speak.sh *)
---

## Text-to-Speech Voice Message

Speak a message aloud to the user through ElevenLabs TTS.

### How to use

Run this command with the message text:

```bash
~/.claude/hooks/elevenlabs-tts/speak.sh $ARGUMENTS
```

### Rules

- The message in `$ARGUMENTS` is what gets spoken aloud — craft it naturally and conversationally
- Always address the user as "Eric"
- Keep messages concise and clear — they are spoken, not read
- If no arguments are provided, ask the user what they'd like you to say

### Example workflows

**Timer reminder:**
User says: "Set a 5 minute timer then remind me to check the domain certificate"
1. Run `sleep 300` in the background
2. When the sleep completes, invoke this skill: `/tts Hey Eric, your 5 minute timer is up! Time to check that domain certificate.`

**Task completion alert:**
After finishing a long build or test run, invoke: `/tts Hey Eric, the build just finished successfully.`

**Custom message:**
User says: `/tts Don't forget to push your changes before lunch`
Runs the TTS with that exact message.
