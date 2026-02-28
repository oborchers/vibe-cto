# Inversion and Pre-Mortem

## What It Is

Instead of asking "how do I make this succeed?", ask "what would make this fail?" Work backwards from failure to identify risks, blind spots, and fragile assumptions. A pre-mortem imagines the project has already failed and asks why.

**Counteracts:** Sycophancy. LLMs are trained to be helpful and optimistic, which suppresses critical thinking. Inversion forces explicit pessimism — the one mode LLMs resist most.

## Step-by-Step Process

### Inversion

1. **State the goal.** What does success look like?
2. **Invert it.** "How would I guarantee this fails?" or "What is the opposite of the desired outcome?"
3. **Generate failure paths.** List at least 5 concrete ways to achieve the inverted goal. Be specific — not "it could be slow" but "the N+1 query problem on the order-items join causes 200ms latency per page load at 1000 orders."
4. **For each failure path, identify the prevention.** What design decision prevents this specific failure?
5. **Check the original solution against each prevention.** Does the proposed approach actually prevent these failures?

### Pre-Mortem

1. **Assume the project launched and failed.** Set the scene: "It's 6 months from now. This system is in production and it's a disaster."
2. **Write the post-mortem.** What went wrong? Be vivid and specific.
3. **Categorize failures.** Technical (architecture, performance, data), Operational (deployment, monitoring, incident response), Organizational (team skills, ownership, communication).
4. **Rank by likelihood and impact.** Which failures are most likely? Which are most damaging?
5. **For top-ranked failures, design mitigations now.** What changes to the current plan prevent or reduce each failure?

## Application Prompts

- "It's 6 months from now and this is considered a failure. What happened?"
- "How would I guarantee this system goes down in production?"
- "What is the laziest, most careless implementation of this design? What breaks?"
- "If an adversary wanted to exploit this system, what would they target?"
- "What will the on-call engineer hate about this at 3 AM?"
- "What will the next developer who inherits this codebase struggle with?"

## Common Pitfalls

- **Being vague about failures.** "It might be slow" is not useful. "The full-text search query scans 10M rows without an index because we assumed the dataset stays small" is useful.
- **Listing only technical failures.** Organizational and operational failures are often more damaging. Include team, process, and communication failures.
- **Stopping at identification.** Inversion is only valuable if failure paths lead to concrete design decisions. Every failure identified must map to a prevention or mitigation.
- **Succumbing to optimism bias mid-exercise.** LLMs will naturally want to reassure. Resist the urge to qualify failures with "but this probably won't happen." During inversion, every failure is assumed likely.

## When to Use

- Evaluating a proposed architecture or design before committing
- The user asks "is this a good approach?" (default tendency: say yes)
- Risk assessment for production systems
- Any situation where the cost of failure is high
- When the user seems overly confident about an approach
