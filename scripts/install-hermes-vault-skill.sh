#!/usr/bin/env bash
# Install the vault-writing Hermes skill into the active Hermes home.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
target="$HERMES_HOME/skills/project-knowledge-base"

if [ -e "$target" ]; then
  echo "Refusing to overwrite existing skill: $target" >&2
  exit 1
fi
install -d -m 0750 "$target"
install -m 0640 "$REPO_ROOT/hermes-skill/project-knowledge-base/SKILL.md" "$target/SKILL.md"
printf 'Installed project-knowledge-base skill at %s\n' "$target"
