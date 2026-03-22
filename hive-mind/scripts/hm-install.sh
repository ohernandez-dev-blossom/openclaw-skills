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

echo "=== Hive Mind Install ==="

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

# 2. Patch each agent's AGENTS.md
READ_LINE='- **SHARED BRAIN:** `cat ~/clawd/memory/shared-brain.md` (read relevant sections at startup)'
PATCHED=0
SKIPPED=0

for agents_md in "$AGENTS_DIR"/*/AGENTS.md; do
  [ -f "$agents_md" ] || continue
  if grep -q "shared-brain.md" "$agents_md" 2>/dev/null; then
    echo "  $(dirname "$agents_md" | xargs basename) — already patched"
    SKIPPED=$((SKIPPED+1))
    continue
  fi
  # Insert after first line starting with "## Init" or "## Iniciali" or after first heading
  if grep -qE "^## (Init|Iniciali)" "$agents_md"; then
    sed -i "/^## \(Init\|Iniciali\)/a $READ_LINE" "$agents_md"
  else
    # Append to end of first ## section
    sed -i "0,/^##/{/^##/a $READ_LINE
}" "$agents_md"
  fi
  echo "  ✓ Patched: $agents_md"
  PATCHED=$((PATCHED+1))
done

echo "✓ Agents: $PATCHED patched, $SKIPPED already done"

# 3. Add curation step to HEARTBEAT.md if not already there
if [ -f "$HEARTBEAT" ] && ! grep -q "hm-curate.sh" "$HEARTBEAT"; then
  cat >> "$HEARTBEAT" << 'EOF'

## Hive Mind Curation (every heartbeat)
```bash
~/clawd/skills/hive-mind/scripts/hm-curate.sh
```
- Merges shared-brain-queue.md → shared-brain.md
- Reports conflicts to TARS for resolution
- Archives if brain > 8KB
EOF
  echo "✓ Patched HEARTBEAT.md"
else
  echo "  HEARTBEAT.md already patched or not found"
fi

# 4. Make scripts executable
chmod +x "$(dirname "$0")"/*.sh
echo "✓ Scripts executable"

echo ""
echo "=== Done. All agents will read shared-brain.md on next startup. ==="
echo "    Write facts:  ~/clawd/skills/hive-mind/scripts/hm-write.sh SECTION \"key = value\""
echo "    Curate now:   ~/clawd/skills/hive-mind/scripts/hm-curate.sh"
