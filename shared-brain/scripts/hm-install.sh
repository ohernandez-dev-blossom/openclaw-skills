#!/usr/bin/env bash
# hm-install.sh — One-time setup for a workspace
# Patches all agents/*/AGENTS.md with shared-brain read at startup
# Adds curation step to HEARTBEAT.md

set -euo pipefail

CLAWD="${HIVE_MIND_WORKSPACE:-$HOME/clawd}"
BRAIN="$CLAWD/memory/shared-brain.md"
QUEUE="$CLAWD/memory/shared-brain-queue.md"
AGENTS_DIR="$CLAWD/agents"
HEARTBEAT="$CLAWD/HEARTBEAT.md"
SKILL_DEST="$CLAWD/skills/shared-brain/scripts"

echo "=== Hive Mind Install ==="
echo "    Workspace: $CLAWD"

# 1. Create brain and queue files
mkdir -p "$(dirname "$BRAIN")"
if [ ! -f "$BRAIN" ]; then
  cat > "$BRAIN" << 'EOF'
# Shared Brain — Hive Mind
> Canonical ground truth for all agents. Curated by heartbeat every ≤10 min.
> Written by: hm-write.sh | Curated by: hm-curate.sh | Do not edit manually.
> Sections: [INFRA] [PROJECTS] [DECISIONS] [CAMPAIGNS] [SECURITY]

## [INFRA]

## [PROJECTS]

## [DECISIONS]

## [CAMPAIGNS]

## [SECURITY]
EOF
  echo "✓ Created $BRAIN"
else
  echo "  $BRAIN already exists — skipped"
fi

touch "$QUEUE"
echo "✓ Queue ready: $QUEUE"

# 2. Patch each agent's AGENTS.md — use actual workspace path, not hardcoded ~/clawd
READ_LINE="- **SHARED BRAIN:** \`cat $BRAIN\` (read relevant sections at startup)"
PATCHED=0
SKIPPED=0

for agents_md in "$AGENTS_DIR"/*/AGENTS.md; do
  [ -f "$agents_md" ] || continue
  if grep -q "shared-brain.md" "$agents_md" 2>/dev/null; then
    echo "  $(dirname "$agents_md" | xargs basename) — already patched"
    SKIPPED=$((SKIPPED+1))
    continue
  fi
  if grep -qE "^## (Init|Iniciali)" "$agents_md"; then
    sed -i "/^## \(Init\|Iniciali\)/a $READ_LINE" "$agents_md"
  else
    sed -i "0,/^##/{/^##/a $READ_LINE
}" "$agents_md"
  fi
  echo "  ✓ Patched: $agents_md"
  PATCHED=$((PATCHED+1))
done

echo "✓ Agents: $PATCHED patched, $SKIPPED already done"

# 3. Add curation step to HEARTBEAT.md — use actual script path
if [ -f "$HEARTBEAT" ] && ! grep -q "hm-curate.sh" "$HEARTBEAT"; then
  cat >> "$HEARTBEAT" << HEREDOC

## Hive Mind Curation (every heartbeat)
\`\`\`bash
$SKILL_DEST/hm-curate.sh
\`\`\`
- Merges shared-brain-queue.md → shared-brain.md
- Reports conflicts to TARS for resolution
- Archives if brain > 8KB
HEREDOC
  echo "✓ Patched HEARTBEAT.md"
else
  echo "  HEARTBEAT.md already patched or not found"
fi

# 4. Copy scripts to workspace skills directory
mkdir -p "$SKILL_DEST"
cp "$(dirname "$0")"/*.sh "$SKILL_DEST/"
chmod +x "$SKILL_DEST"/*.sh
echo "✓ Scripts installed to $SKILL_DEST"

echo ""
echo "=== Done. All agents will read shared-brain.md on next startup. ==="
echo "    Write facts:  $SKILL_DEST/hm-write.sh SECTION \"key = value\""
echo "    Curate now:   $SKILL_DEST/hm-curate.sh"
