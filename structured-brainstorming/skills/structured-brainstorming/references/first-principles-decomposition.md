# First Principles Decomposition

## What It Is

Strip away assumptions, conventions, and "how it's usually done" to identify the fundamental truths of a problem. Then rebuild a solution from those truths instead of reasoning by analogy to existing solutions.

**Counteracts:** Shallow exploration, authority bias. Without this method, LLM responses default to the most common solution pattern in training data rather than examining whether that pattern actually fits the problem.

## Step-by-Step Process

1. **State the problem as given.** Write it exactly as the user framed it.
2. **List every assumption embedded in that framing.** What does the problem statement take for granted? What technology, architecture, pattern, or constraint is assumed but not proven?
3. **For each assumption, ask: "Is this actually required, or is it convention?"** Mark each as FUNDAMENTAL (physically/logically necessary) or CONVENTIONAL (how it's usually done).
4. **Discard the conventional assumptions.** Restate the problem using only the fundamental constraints.
5. **Generate solutions from the stripped-down problem.** What approaches become possible when the conventional constraints are removed?
6. **Reintroduce practical constraints one at a time.** For each constraint added back, note what it eliminates and what it preserves.

## Application Prompts

Use these questions during the decomposition:

- "What would I build if I had never seen the existing solution?"
- "What is the actual input, the actual output, and the actual transformation required?"
- "Which constraints are physics/logic and which are tradition?"
- "If I remove [this assumption], what becomes possible?"
- "What would a solution look like if this system didn't exist yet?"

## Common Pitfalls

- **Stopping at one level.** "We need a database" is still an assumption. WHY do we need persistent state? What kind? How much? How often accessed? Keep decomposing.
- **Confusing convention with constraint.** "We need a REST API" is convention. "Clients need to fetch data over HTTP" is closer to fundamental but still has assumptions. "Two systems need to exchange structured data" is closer to ground truth.
- **Rebuilding the same thing.** The value of first principles is generating genuinely different solutions. If the rebuilt solution looks identical to the conventional one, the decomposition did not go deep enough.

## When to Use

- The user asks "how should I build X?" and the obvious answer is "the way everyone builds X"
- Evaluating whether an established pattern (microservices, event sourcing, GraphQL) actually fits a specific problem
- The user is stuck because all options feel similar
- Greenfield design where conventions have not yet been established
