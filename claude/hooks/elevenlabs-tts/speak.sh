#!/bin/bash
cd ~/.claude/hooks/elevenlabs-tts && bun run speak.ts "$@"
