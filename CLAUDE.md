# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```sh
make solve-dependencies  # Install Emacs dependencies (~/.emacs.d/lisp/)
make test                # Run ERT tests
```

Run a single test: `emacs --batch -l tests/tests.el -e '(ert-run-tests-batch "test-name")'`

## Project Structure

Single-file Emacs Lisp library (`mijia.el`) for controlling Xiaomi MiJia smart home devices.

**Architecture:**
- Internal functions prefixed with `--` (e.g., `mijia--command-run`, `mijia--parse-output`)
- Interactive functions for user commands (e.g., `mijia-list-devices`, `mijia-list-scenes`)
- Communicates with external `mijiaAPI` CLI tool via `shell-command-to-string`
- Uses `ctable` for rendering device/scene tables in buffers

**Dependencies:**
- `ctable` - Emacs package for table display (managed via `dependencies.txt` + `dependencies.sh`)
- `mijiaAPI` - External CLI tool (configured via `mijia-command` variable)

## Key Functions

| Function | Description |
|----------|-------------|
| `mijia-list-devices` | Display devices in ctable buffer |
| `mijia-list-scenes` | Display scenes in ctable buffer (clickable to run) |
| `mijia-run-scene` | Execute selected scene |
| `mijia--command-run` | Execute mijiaAPI command with optional parsing |
| `mijia--parse-output` | Parse CLI output into list of hash tables |
