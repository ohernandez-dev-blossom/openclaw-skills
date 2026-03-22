#!/usr/bin/env bash
# hm-write.sh — Append a fact to the shared-brain queue
# Usage: hm-write.sh SECTION "key = value"
# Sections: INFRA PROJECTS DECISIONS CAMPAIGNS SECURITY
# Example: hm-write.sh INFRA "deploy:frontends = Vercel (migrated 2026-03-21)"

set -euo pipefail

_CLAWD="${HIVE_MIND_WORKSPACE:-$HOME/clawd}"
QUEUE="${HIVE_MIND_QUEUE:-$_CLAWD/memory/shared-brain-queue.md}"
VALID_SECTIONS="INFRA PROJECTS DECISIONS CAMPAIGNS SECURITY"

if [ $# -lt 2 ]; then
  echo "Usage: hm-write.sh SECTION \"key = value\"" >&2
  exit 1
fi

SECTION="${1^^}"
FACT="$2"
AGENT="${HIVE_MIND_AGENT:-$(basename "$0")}"
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

# Validate section
if ! echo "$VALID_SECTIONS" | grep -qw "$SECTION"; then
  echo "Invalid section: $SECTION. Valid: $VALID_SECTIONS" >&2
  exit 1
fi

# Validate key=value format
if ! echo "$FACT" | grep -q " = "; then
  echo "Fact must contain ' = ' separator. Got: $FACT" >&2
  exit 1
fi

# Ensure queue file exists
mkdir -p "$(dirname "$QUEUE")"
touch "$QUEUE"

# Atomic append (kernel guarantees atomicity for small writes on ext4)
echo "[$TIMESTAMP] [$SECTION] [$AGENT] $FACT" >> "$QUEUE"
echo "✓ Queued: [$SECTION] $FACT"
