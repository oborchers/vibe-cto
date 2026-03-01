---
description: "Brainstorm solutions for a problem using structured thinking methods that counteract LLM reasoning biases"
argument-hint: "<problem statement>"
---

Apply structured brainstorming to the given problem using the `structured-brainstorming` skill.

Follow this process:

## Step 1: Problem Capture

If no problem statement was provided as an argument, ask the user to describe the problem they want to brainstorm.

## Step 2: Problem Restatement

Restate the problem in your own words: what is being decided, what constraints exist, and what a good outcome looks like. Present this restatement to the user.

## Step 3: Dispatch or Rephrase

Use `AskUserQuestion` to ask the user how to proceed:

- **Dispatch brainstorm-explorer agents** — launch parallel agents to explore the problem from multiple angles using structured thinking methods
- **Rephrase the problem statement** — iterate on the problem framing before committing to exploration

If the user chooses to rephrase, they provide a new or refined problem statement. Return to Step 2 with the updated statement. This loop can repeat until the user is satisfied with the framing.

## Step 4: Method Selection and Agent Assignment

Select methods from the method selection table in the `structured-brainstorming` skill based on the problem type. Assign methods to 4 `brainstorm-explorer` agents following the agent dispatch pattern in the skill. Present the dispatch plan (which agent gets which methods) as information — the model selects methods to maximize exploration variance.

## Step 5: Agent Dispatch

Spawn 4 `brainstorm-explorer` subagents in parallel. Each agent receives:
- The problem statement
- Its assigned methods (1-2 per agent)
- Instructions to read the relevant method reference files from the skill

## Step 6: Synthesis

After all agents complete, synthesize their findings into the standard output structure:
- **Problem restatement** — the confirmed problem framing
- **Method application** — labeled sections showing each agent's findings per method
- **Convergence** — where methods agree, disagree, and surprise
- **Recommendation** — concrete next step(s) with explicit trade-offs
- **Open questions** — what remains uncertain and how to resolve it

## Step 7: Next Steps

Use `AskUserQuestion` to ask the user what to do next:

- **Explore a finding deeper** — the user picks a specific finding or theme to investigate further (Claude explores inline)
- **Brainstorm a different angle** — return to Step 2 with the same problem to explore from a new perspective
- **Done** — take the recommendation forward and end the brainstorming session

Consult the reference files in the structured-brainstorming skill for detailed method descriptions when applying each method.

## Mandatory Use of AskUserQuestion

**Every user decision point MUST use the `AskUserQuestion` tool.** Never ask for decisions via inline text like "Ready to dispatch?" or listing options in prose. The interactive selector UI provides a consistent, navigable experience.

### Main Conversation Owns All User Interaction

`AskUserQuestion` must be called from **this command** (the main conversation), never from subagents. The `brainstorm-explorer` subagents handle exploration and return results. This command presents those results and calls `AskUserQuestion` for every decision gate.

**Pattern:** present problem restatement → call `AskUserQuestion` (dispatch/rephrase) → invoke subagents for exploration → receive results → synthesize → call `AskUserQuestion` (next steps).

### Decision Points

This applies to ALL decision points with fixed options, including but not limited to:
- Dispatch or rephrase (Step 3)
- Next steps after synthesis (Step 7)

Open-ended questions (problem description, rephrase input, which finding to explore) may use free-text prompts.
