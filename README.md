# openclaw-skills

Community AgentSkills for [OpenClaw](https://openclaw.ai) — multi-agent workflow patterns, shared memory, and team coordination primitives.

## Skills

### 🧠 shared-brain

Shared persistent memory layer across multiple AI agents. All agents write facts to a queue; a heartbeat-curated `shared-brain.md` propagates them to every agent within 0–10 minutes.

**Problem it solves:** In multi-agent workspaces, each agent starts with its own context. When something changes (infra migration, new decision, project restructure), you have to manually update 10+ `AGENTS.md` files. Hive Mind makes that automatic.

**Architecture:**
```
Agent discovers fact → append to shared-brain-queue.md
Heartbeat (≤10 min) → merge queue into shared-brain.md
Next agent startup → reads shared-brain.md → current ground truth
```

**Install:**
```bash
# Clone and install
git clone https://github.com/ohernandez-dev-blossom/openclaw-skills
cd openclaw-skills/shared-brain
./scripts/hm-install.sh

# Custom workspace path (default: ~/clawd)
HIVE_MIND_WORKSPACE=~/my-workspace ./scripts/hm-install.sh

# Via ClawhHub CLI (when registry is live)
npx clawhub@latest install shared-brain
```

**Usage:**
```bash
# Agent writes a permanent fact
./scripts/hm-write.sh INFRA "deploy:frontends = Vercel (migrated 2026-03-21)"

# Heartbeat curates queue into shared brain
./scripts/hm-curate.sh

# Dry run to preview
./scripts/hm-curate.sh --dry-run
```

**Fact format:**
```
[YYYY-MM-DD HH:MM UTC] [SECTION] [agent-name] key = value
```

Sections: `INFRA` `PROJECTS` `DECISIONS` `CAMPAIGNS` `SECURITY`

**Edge cases handled:**
- Context overflow — auto-archives oldest section when brain > 8KB
- Write storms — append-only queue, no locks needed (ext4 atomic appends)
- Stale facts — last-write-wins per key, conflicts escalated to human
- Prompt injection — sub-agents write to queue only; main agent curates
- Relevance — agents declare which sections to load (reduces context ~60%)

## Contributing

Skills follow the [OpenClaw AgentSkills spec](https://docs.openclaw.ai). Each skill is a folder with a `SKILL.md` and optional `scripts/`, `references/`, `assets/`.

PRs welcome.
