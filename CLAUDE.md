# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**vibe-cto** is a Claude Code plugin marketplace containing opinionated, research-backed plugins for building SaaS products. It is purely markdown/JSON/bash — no build system, no runtime dependencies, no tests to run.

## Local Development

```bash
# Test a plugin locally
claude --plugin-dir /path/to/vibe-cto/api-design-principles
claude --plugin-dir /path/to/vibe-cto/saas-design-principles
```

There is no build step, linter, or test suite. Validation is manual: start a Claude session with the plugin and verify hooks fire, skills invoke, and commands work.

## Architecture

### Marketplace Registry

`.claude-plugin/marketplace.json` is the central registry listing all available plugins. Each plugin lives in its own top-level directory (e.g., `api-design-principles/`, `saas-design-principles/`).

### Plugin Structure (both plugins follow the same pattern)

```
<plugin-name>/
├── .claude-plugin/plugin.json   # Plugin manifest (name, version, keywords)
├── README.md                    # Plugin docs and principle overview
├── hooks/
│   ├── hooks.json               # Registers SessionStart hook
│   └── session-start.sh         # Injects meta-skill index into session context
├── commands/
│   └── <name>-review.md         # Manual review command (/api-review, /saas-review)
├── agents/
│   └── <name>-reviewer.md       # Comprehensive audit agent (model: sonnet)
└── skills/
    ├── using-<name>-principles/ # Meta-skill: index of all 12 principles
    └── <principle-name>/        # 12 principle skills, each with:
        ├── SKILL.md             #   Principles, checklists, good/bad patterns
        └── examples/            #   Code examples (React/Vue/Svelte or Node.js/Python)
```

### Activation Flow

1. **SessionStart hook** (`hooks/hooks.json` → `hooks/session-start.sh`) fires on startup/resume/clear/compact
2. `session-start.sh` reads the meta-skill (`using-*-principles/SKILL.md`), escapes it, and outputs JSON with `additional_context`
3. Claude now knows the 12 available principle skills and when to invoke each
4. Skills are invoked automatically when Claude detects relevant work, or manually via `/api-review` or `/saas-review`

### Key Design Decisions

- **Skills are YAML-frontmattered markdown** with `name`, `description`, and `version` fields
- **Commands use `disable-model-invocation: true`** — they guide Claude to invoke skills, not execute code
- **Agents specify `model: sonnet`** and include severity guides (Critical/Important/Suggestion)
- **`session-start.sh` uses `${CLAUDE_PLUGIN_ROOT}`** to resolve paths relative to the plugin root
- **Examples cover multiple frameworks** — SaaS: React/Vue/Svelte; API: Node.js/Python

## Adding a New Plugin

1. Create a new top-level directory following the plugin structure above
2. Add the 13 skills (12 principles + 1 meta-skill index)
3. Create a command, agent, and SessionStart hook mirroring existing plugins
4. Register the plugin in `.claude-plugin/marketplace.json`

## Adding a New Skill to an Existing Plugin

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`, `version`)
2. Add examples in `skills/<skill-name>/examples/` if applicable
3. Update the meta-skill index (`skills/using-*-principles/SKILL.md`) to include the new skill
4. Update the agent and command markdown to reference the new skill
5. Update the plugin `README.md`

## Conventions

- Skill directory names use kebab-case
- SKILL.md files include review checklists and good/bad pattern comparisons
- All principles cite real-world sources (Stripe, GitHub, Twilio, Nielsen Norman Group, etc.)
- Three meta-principles anchor each plugin (documented in the meta-skill and README)
