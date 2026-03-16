#!/bin/bash
# deploy.sh — copy agent-contexts templates to a target repository
#
# Usage:
#   ./deploy.sh /path/to/target-repo
#
# This copies:
#   core/        → target repo root     (always-in-context files)
#   standards/   → target standards/    (reference standards)
#   skills/      → target .claude/skills/ (on-demand skills)

set -euo pipefail

TARGET="${1:?Usage: ./deploy.sh /path/to/target-repo}"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET is not a directory"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying agent-contexts to $TARGET"

# Tier 1: always-in-context files → repo root
echo "  Copying core/ → $TARGET/"
cp -r "$SCRIPT_DIR/core/." "$TARGET/"

# Tier 3: reference standards → standards/
echo "  Copying standards/ → $TARGET/standards/"
mkdir -p "$TARGET/standards"
cp -r "$SCRIPT_DIR/standards/." "$TARGET/standards/"

# Tier 2: skills → .claude/skills/
echo "  Copying skills/ → $TARGET/.claude/skills/"
mkdir -p "$TARGET/.claude/skills"
cp -r "$SCRIPT_DIR/skills/." "$TARGET/.claude/skills/"

echo ""
echo "Done. Next steps:"
echo "  1. Fill in [CONFIGURE] sections in $TARGET/AGENTS.md"
echo "  2. Fill in [CONFIGURE] sections in $TARGET/CLAUDE.md"
echo "  3. Fill in [CONFIGURE] sections in $TARGET/.github/copilot-instructions.md"
echo "  4. Review $TARGET/.claude/settings.json and adjust permissions/hooks"
