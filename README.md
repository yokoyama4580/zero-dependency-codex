# Zero-Dependency PoC runner for Codex CLI

This directory contains the fixed Codex instructions, structured run input, and launcher for one Zero-Dependency PoC run.

## Files

- `AGENTS.md` — fixed Zero-Dependency instructions for Codex.
- `run-config.json` — structured run-specific input.
- `run.sh` — clones the target revision into an isolated run workspace and launches `codex exec`.
- `workspace/` — created automatically. Each `run_id` gets its own cloned repository.

## Before running

Verify that these commands work:

```bash
codex --version
git --version
node --version
```

Ensure Codex CLI is already authenticated.

## Run PoC 1

From this directory:

```bash
chmod +x run.sh
./run.sh
```

The runner will:

1. validate `run-config.json`;
2. clone the configured repository into `workspace/<run_id>/`;
3. check out the configured revision;
4. refuse to continue if the target repository already contains `AGENTS.md` or `AGENTS.override.md`, so hidden repository instructions do not silently alter the experiment;
5. copy the experiment `AGENTS.md` and `run-config.json` into the cloned repository root;
6. launch Codex non-interactively with a writable workspace sandbox;
7. save Codex JSONL events, stderr, runner metadata, and the Agent's experiment artifacts under `.zero-dependency/runs/<run_id>/` inside the cloned workspace.

## Important security note

The launcher enables network access inside Codex's `workspace-write` sandbox because dependency installation may require npm registry access. Run this only on repositories you are willing to execute and analyze. Do not place secrets in the experiment workspace. For stronger isolation, run the entire experiment inside a disposable VM or container.

## Re-running

A run is not overwritten. If `workspace/<run_id>/` already exists, `run.sh` exits. For a new execution, change `run_id` in `run-config.json` (for example `_002`). This keeps each run independent and auditable.
