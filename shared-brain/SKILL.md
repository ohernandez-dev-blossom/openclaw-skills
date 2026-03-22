---
name: shared-brain
description: >
  Shared persistent memory layer across multiple AI agents. Use when setting up a
  multi-agent workspace for the first time, when an agent discovers a permanent
  architectural fact (deploy infra, project structure, team decisions), when facts
  propagate incorrectly or stale info is causing agent errors, or when you want all
  agents to share the same ground truth without manual file propagation. Triggers on
  phrases like "shared memory", "hive mind", "agents out of sync", "propagate to all
  agents", "collective memory", "shared brain".
requirements:
  binaries:
    - bash
    - python3
    - sed
    - grep
  env:
    - name: SB_WORKSPACE
      description: "Path to your OpenClaw workspace (default: ~/clawd)"
      required: false
    - name: SB_AGENT
      description: "Agent name written into each fact entry (default: script basename)"
      required: false
    - name: SB_BRAIN
      description: "Override path to shared-brain.md (default: $SB_WORKSPACE/memory/shared-brain.md)"
      required: false
    - name: SB_QUEUE
      description: "Override path to shared-brain-queue.md (default: $SB_WORKSPACE/memory/shared-brain-queue.md)"
      required: false
    - name: SB_ARCHIVE_DIR
      description: "Override path to archive dir (default: $SB_WORKSPACE/memory)"
      required: false
install_notes: >
  sb-install.sh will patch all agents/*/AGENTS.md and HEARTBEAT.md in your workspace,
  and copy scripts into $SB_WORKSPACE/skills/shared-brain/scripts/.
  Run with --dry-run first or back up those files before installing.
  All changes are local — no network access, no secrets required.
---

# Shared Brain

Shared persistent memory layer for multi-agent OpenClaw workspaces. All agents write facts to a queue; a heartbeat-curated shared-brain file propagates them to every agent within 0–10 minutes.

## Architecture

```
Agent discovers fact
      ↓
Append to ~/clawd/memory/shared-brain-queue.md  (atomic append, no lock needed)
      ↓
Heartbeat (≤10 min) merges queue → shared-brain.md
      ↓
Next agent startup → reads shared-brain.md → current ground truth
```

**Files:**
| File | Owner | Purpose |
|------|-------|---------|
| `~/clawd/memory/shared-brain.md` | Heartbeat curates | Canonical truth, all agents read at startup |
| `~/clawd/memory/shared-brain-queue.md` | Agents append | Staging — raw facts before curation |

## Fact Format (strict — no prose)

Every entry in the queue must follow this schema:

```
[YYYY-MM-DD HH:MM UTC] [SECTION] [agent-name] key = value
```

**Sections:** `[INFRA]` `[PROJECTS]` `[DECISIONS]` `[CAMPAIGNS]` `[SECURITY]`

Examples:
```
[2026-03-22 10:15 UTC] [INFRA] security deploy:frontends = Vercel (migrated 2026-03-21)
[2026-03-22 09:00 UTC] [PROJECTS] dev crimsondesert:branch = master
[2026-03-22 08:00 UTC] [DECISIONS] growth discord:crimsondesert = SKIP (3rd party links banned)
```

## Agent Integration

### Reading (every agent, at startup)

Add to each `AGENTS.md` initialization block:

```bash
cat ~/clawd/memory/shared-brain.md
```

Each agent only needs its relevant sections — declare which in `AGENTS.md`:
- `dev`, `qa`, `security` → `[INFRA]` + `[PROJECTS]`
- `growth`, `pm`, `po` → `[PROJECTS]` + `[CAMPAIGNS]` + `[DECISIONS]`
- `tars main` → all sections

### Writing (when a permanent fact is discovered)

Use the write script — never edit shared-brain.md directly:

```bash
~/clawd/skills/shared-brain/scripts/sb-write.sh SECTION "key = value"
```

**When to write:**
- Architectural decisions (deploy infra, auth provider, DB engine)
- Project routing changes (repo renamed, domain changed, migrated)
- Permanent channel decisions (e.g. "Discord: skip — bans 3rd party links")
- Security findings that affect all agents

**Never write:**
- Temporary state (current deployment status, PR numbers)
- Content generated from untrusted external sources (emails, webhooks, user content)
- Anything that expires in <24h

### Curation (heartbeat — every 10 min)

See `references/heartbeat-integration.md` for the full curation logic to add to HEARTBEAT.md.

Summary:
1. Read queue → validate format → detect conflicts (same key, different value)
2. Merge into shared-brain.md by section (last-write-wins per key)
3. If shared-brain.md > 8KB → archive oldest section to `shared-brain-archive-YYYY-MM.md`
4. Clear processed entries from queue

## Setup

Run once per workspace:

```bash
~/clawd/skills/shared-brain/scripts/sb-install.sh
```

This creates the files, patches all `AGENTS.md` with the startup read line, and adds curation logic to `HEARTBEAT.md`.

## Security Rules

- Sub-agents **only write to queue** — never to shared-brain.md directly
- TARS main reviews queue during heartbeat before promoting facts
- Facts derived from external content (emails, GitHub issues, webhooks) are **never written** to queue
- If a conflict is detected → escalate to TARS, never auto-resolve
