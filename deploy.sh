#!/bin/bash
# deploy.sh — copy agent-contexts templates to a target repository
#
# Usage:
#   ./deploy.sh /path/to/target-repo
#
# This copies:
#   core/        → target repo root     (always-in-context files + .context/index + conventions)
#   standards/   → target .context/standards/  (reference standards)
#   playbooks/   → target .context/playbooks/  (on-demand playbooks)
#
# Then generates:
#   target .claude/skills/  (Claude Code skill wrappers pointing to playbooks)
#   target .github/skills/  (GitHub Copilot skill wrappers pointing to playbooks)

set -euo pipefail

usage() {
  cat <<EOF
Usage: ./deploy.sh <target-repo>

Copy agent-contexts templates to a target repository and generate skill wrappers.

This copies:
  core/        → target repo root     (always-in-context files + .context/index + conventions)
  standards/   → target .context/standards/  (reference standards)
  playbooks/   → target .context/playbooks/  (on-demand playbooks)

Then generates:
  .claude/skills/  (Claude Code skill wrappers pointing to playbooks)
  .github/skills/  (GitHub Copilot skill wrappers pointing to playbooks)

Arguments:
  <target-repo>   Path to the target repository directory

Options:
  -h, --help      Show this help message and exit
EOF
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  -*)
    echo "Error: unknown option '$1'" >&2
    echo "" >&2
    usage >&2
    exit 1
    ;;
esac

TARGET="$1"

if [ ! -d "$TARGET" ]; then
  echo "Error: '$TARGET' is not a directory" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying agent-contexts to $TARGET"

# Tier 1: always-in-context files → repo root
echo "  Copying core/ → $TARGET/"
cp -r "$SCRIPT_DIR/core/." "$TARGET/"

# Standards → .context/standards/
echo "  Copying standards/ → $TARGET/.context/standards/"
mkdir -p "$TARGET/.context/standards"
cp -r "$SCRIPT_DIR/standards/." "$TARGET/.context/standards/"

# Playbooks → .context/playbooks/
echo "  Copying playbooks/ → $TARGET/.context/playbooks/"
mkdir -p "$TARGET/.context/playbooks"
cp -r "$SCRIPT_DIR/playbooks/." "$TARGET/.context/playbooks/"

# Generate skill wrappers from playbooks for agents with native skill systems
echo "  Generating skill wrappers from playbooks..."
echo "    → .claude/skills/ (Claude Code)"
echo "    → .github/skills/ (GitHub Copilot)"
mkdir -p "$TARGET/.claude/skills"
mkdir -p "$TARGET/.github/skills"

generate_skill() {
  local playbook_path="$1"
  local target_dir="$2"
  local rel_path="$3"
  local allowed_tools="${4:-}"

  # Extract frontmatter fields
  local name description
  name=$(sed -n 's/^name: *//p' "$playbook_path" | head -1)
  description=$(sed -n 's/^description: *//p' "$playbook_path" | head -1 | sed 's/^"//;s/"$//')

  if [ -z "$name" ] || [ -z "$description" ]; then
    return
  fi

  local skill_dir="$target_dir/$name"
  mkdir -p "$skill_dir"

  if [ -n "$allowed_tools" ]; then
    cat > "$skill_dir/SKILL.md" << SKILL_EOF
---
name: $name
description: "$description"
allowed-tools: "$allowed_tools"
---

Read and follow \`.context/playbooks/$rel_path\` in full.
SKILL_EOF
  else
    cat > "$skill_dir/SKILL.md" << SKILL_EOF
---
name: $name
description: "$description"
---

Read and follow \`.context/playbooks/$rel_path\` in full.
SKILL_EOF
  fi
}

generate_skills_for_all_agents() {
  local playbook_path="$1"
  local rel_path="$2"
  local allowed_tools="${3:-Read, Grep, Glob, Bash(git *), Write, Edit, Agent}"

  generate_skill "$playbook_path" "$TARGET/.claude/skills" "$rel_path" "$allowed_tools"
  generate_skill "$playbook_path" "$TARGET/.github/skills" "$rel_path" ""
}

for playbook in "$SCRIPT_DIR"/playbooks/assess/*.md; do
  filename=$(basename "$playbook")
  generate_skills_for_all_agents "$playbook" "assess/$filename"
done

for playbook in "$SCRIPT_DIR"/playbooks/review/*.md; do
  filename=$(basename "$playbook")
  # Review playbooks get read-only tools for Claude Code
  generate_skills_for_all_agents "$playbook" "review/$filename" "Read, Grep, Glob, Bash(git *)"
done

for playbook in "$SCRIPT_DIR"/playbooks/plan/*.md; do
  filename=$(basename "$playbook")
  generate_skills_for_all_agents "$playbook" "plan/$filename"
done

for playbook in "$SCRIPT_DIR"/playbooks/refactor/*.md; do
  filename=$(basename "$playbook")
  generate_skills_for_all_agents "$playbook" "refactor/$filename"
done

echo ""
echo "Done. Next steps:"
echo "  1. Fill in [CONFIGURE] sections in $TARGET/AGENTS.md"
echo "  2. Fill in [CONFIGURE] sections in $TARGET/CLAUDE.md"
echo "  3. Review $TARGET/.claude/settings.json and adjust permissions/hooks"
