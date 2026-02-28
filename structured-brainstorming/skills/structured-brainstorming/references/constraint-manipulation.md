# Constraint Manipulation

## What It Is

Systematically add, remove, or reverse constraints on a problem to force genuinely different solution paths. Adapted from SCAMPER (Substitute, Combine, Adapt, Modify, Put to other use, Eliminate, Reverse) and TRIZ (inventive problem solving), but simplified for AI application.

**Counteracts:** Mode collapse. LLMs generate "different" ideas that are actually minor variations of the same approach. Constraint manipulation forces the search into genuinely different regions of the solution space by changing the problem itself.

## Step-by-Step Process

1. **List the current constraints.** Everything the solution must satisfy: technical (language, platform, latency), business (budget, timeline, team), and assumed (patterns, conventions, existing systems).
2. **For each constraint, apply the manipulation operators:**

| Operator | Question | Example |
|----------|----------|---------|
| **Remove** | "What if this constraint didn't exist?" | "What if we had unlimited budget?" |
| **Reverse** | "What if the opposite were required?" | "What if we needed maximum latency?" |
| **Tighten** | "What if this constraint were 10x stricter?" | "What if latency budget were 10ms, not 100ms?" |
| **Substitute** | "What if I replaced this with something else?" | "What if we used a queue instead of a database?" |
| **Combine** | "What if two constraints merged?" | "What if auth and billing were the same service?" |
| **Eliminate** | "What if I removed this component entirely?" | "What if there were no backend at all?" |

3. **For each manipulation, generate a solution that fits the modified problem.** Do not evaluate yet — just generate.
4. **Review the generated solutions.** Which ones reveal a genuinely different approach? Which ones are surprisingly viable even when the original constraint is restored?
5. **Select the most promising alternatives** and evaluate them against the real constraints.

## Application Prompts

- "What if we had to build this with zero infrastructure?"
- "What if the data volume were 1000x larger?"
- "What if this had to work offline?"
- "What if we couldn't use [the obvious technology choice]?"
- "What if a junior developer had to maintain this alone?"
- "What if this had to be rebuilt from scratch every deployment?"
- "What if we combined [component A] and [component B] into one?"

## Common Pitfalls

- **Only removing constraints.** Removal is the easiest manipulation but produces the least surprising results. Reversal and tightening produce more creative solutions.
- **Evaluating too early.** The point is to generate solutions under modified constraints first, then evaluate. Premature evaluation kills the novel ideas.
- **Manipulating only technical constraints.** Business, team, and organizational constraints often yield the most interesting alternatives when manipulated.
- **Generating only one solution per manipulation.** Each manipulation should produce at least one concrete solution sketch, even if it seems impractical at first.

## When to Use

- All proposed solutions feel like variations of the same idea
- The problem feels over-constrained ("we can't do anything because of X, Y, Z")
- Breaking out of a technology or pattern rut
- Exploring whether constraints are real or self-imposed
- Creative ideation where conventional approaches are insufficient
