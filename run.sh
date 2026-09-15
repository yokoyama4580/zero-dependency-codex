#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$ROOT_DIR/run-config.json"
AGENTS_FILE="$ROOT_DIR/AGENTS.md"
WORKSPACE_ROOT="$ROOT_DIR/workspace"

fail() {
  echo "[runner] ERROR: $*" >&2
  exit 1
}

command -v codex >/dev/null 2>&1 || fail "codex CLI was not found in PATH."
command -v git >/dev/null 2>&1 || fail "git was not found in PATH."
command -v node >/dev/null 2>&1 || fail "node was not found in PATH."

[[ -f "$CONFIG_FILE" ]] || fail "run-config.json not found: $CONFIG_FILE"
[[ -f "$AGENTS_FILE" ]] || fail "AGENTS.md not found: $AGENTS_FILE"

# Read and minimally validate the structured run input before creating a workspace.
CONFIG_VALUES="$({ node - "$CONFIG_FILE" <<'NODE'
const fs = require('fs');
const path = require('path');

const configPath = process.argv[2];
const c = JSON.parse(fs.readFileSync(configPath, 'utf8'));

const required = [
  'schema_version',
  'run_id',
  'repository',
  'revision',
  'generated_package_root',
];

for (const key of required) {
  if (!(key in c)) {
    throw new Error(`missing required field: ${key}`);
  }
}

if (c.schema_version !== '1.0') {
  throw new Error(`unsupported schema_version: ${c.schema_version}`);
}

for (const key of [
  'run_id',
  'repository',
  'revision',
  'generated_package_root',
]) {
  if (typeof c[key] !== 'string' || c[key].trim() === '') {
    throw new Error(`${key} must be a non-empty string`);
  }
}

const generatedRoot = c.generated_package_root.trim();

if (path.isAbsolute(generatedRoot)) {
  throw new Error('generated_package_root must be repository-relative');
}

const normalizedGeneratedRoot = generatedRoot.replace(/\\/g, '/');
const segments = normalizedGeneratedRoot.split('/');

if (segments.includes('..')) {
  throw new Error('generated_package_root must not escape the repository with ".."');
}

process.stdout.write([
  c.run_id.trim(),
  c.repository.trim(),
  c.revision.trim(),
  generatedRoot,
].join('\t'));
NODE
} 2>&1)" || fail "Invalid run-config.json: $CONFIG_VALUES"

IFS=$'\t' read -r RUN_ID REPOSITORY REVISION GENERATED_PACKAGE_ROOT <<< "$CONFIG_VALUES"

mkdir -p "$WORKSPACE_ROOT"
WORKDIR="$WORKSPACE_ROOT/$RUN_ID"

if [[ -e "$WORKDIR" ]]; then
  fail "Workspace already exists: $WORKDIR. Use a new run_id or remove/archive the previous workspace explicitly."
fi

echo "[runner] Run ID:                 $RUN_ID"
echo "[runner] Repository:             $REPOSITORY"
echo "[runner] Revision:               $REVISION"
echo "[runner] Generated package root: $GENERATED_PACKAGE_ROOT"
echo "[runner] Cloning into:           $WORKDIR"

git clone "$REPOSITORY" "$WORKDIR"
git -C "$WORKDIR" checkout --detach "$REVISION"

# Avoid silently combining the experiment instructions with repository-provided
# Codex instructions, which would make the run harder to reproduce.
EXISTING_AGENT_FILES="$(find "$WORKDIR" -type f \( -name 'AGENTS.md' -o -name 'AGENTS.override.md' \) -not -path '*/.git/*' -print -quit)"
if [[ -n "$EXISTING_AGENT_FILES" ]]; then
  rm -rf "$WORKDIR"
  fail "Target repository already contains Codex instruction file: $EXISTING_AGENT_FILES. Review instruction precedence before running this experiment."
fi

cp "$AGENTS_FILE" "$WORKDIR/AGENTS.md"
cp "$CONFIG_FILE" "$WORKDIR/run-config.json"

# Keep experiment control files and artifacts out of the target repository's
# ordinary git status without changing tracked files.
{
  echo "/AGENTS.md"
  echo "/run-config.json"
  echo "/.zero-dependency/"
} >> "$WORKDIR/.git/info/exclude"

RUN_DIR="$WORKDIR/.zero-dependency/runs/$RUN_ID"
mkdir -p "$RUN_DIR"

cp "$CONFIG_FILE" "$RUN_DIR/run-config.snapshot.json"
cp "$AGENTS_FILE" "$RUN_DIR/AGENTS.snapshot.md"

{
  echo "runner_started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "codex_version=$(codex --version 2>/dev/null || true)"
  echo "git_version=$(git --version 2>/dev/null || true)"
  echo "node_version=$(node --version 2>/dev/null || true)"
  echo "workspace=$WORKDIR"
  echo "generated_package_root=$GENERATED_PACKAGE_ROOT"
} > "$RUN_DIR/runner-metadata.txt"

TRIGGER='Start execution. Read run-config.json and follow AGENTS.md. Use run-config.json as the sole source of run-specific target information. Continue autonomously until the run is complete or the instructions require you to stop.'

echo "[runner] Starting Codex non-interactively..."
echo "[runner] Event log: $RUN_DIR/codex-events.jsonl"
echo "[runner] Stderr log: $RUN_DIR/codex-stderr.log"

set +e
codex --ask-for-approval never exec \
  --sandbox workspace-write \
  -c 'sandbox_workspace_write.network_access=true' \
  -C "$WORKDIR" \
  --json \
  "$TRIGGER" \
  2> >(tee "$RUN_DIR/codex-stderr.log" >&2) \
  | tee "$RUN_DIR/codex-events.jsonl"
CODEX_STATUS=${PIPESTATUS[0]}
set -e

{
  echo "runner_finished_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "codex_exit_status=$CODEX_STATUS"
} >> "$RUN_DIR/runner-metadata.txt"

echo "[runner] Codex exit status: $CODEX_STATUS"
echo "[runner] Run artifacts: $RUN_DIR"
exit "$CODEX_STATUS"
