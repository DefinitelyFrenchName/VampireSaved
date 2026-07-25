# re/ghidra — Ghidra headless project area

The Ghidra project itself is gitignored (binary, machine-local). This
directory holds only: import/analyze scripts, exported annotations, and this
note. Recreate the project by running the (future) import script against the
decrypted opcode images in `build/out/` — never against raw ROM files
(byte-order trap: docs/GOTCHAS.md).
