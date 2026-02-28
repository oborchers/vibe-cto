# Assumption Surfacing

## What It Is

Systematically identify every assumption embedded in a problem statement, proposed solution, or design decision, then challenge each one. Most "obvious" solutions rest on unexamined assumptions that, when questioned, reveal better alternatives.

**Counteracts:** Authority bias. LLMs absorb and reproduce the dominant assumptions in their training data — "you need a database," "use microservices at scale," "REST is the default API style." Assumption surfacing makes these implicit beliefs explicit and testable.

## Step-by-Step Process

1. **State the problem or proposed solution.**
2. **Extract assumptions at three levels:**

| Level | Question | Examples |
|-------|----------|---------|
| **Technical** | "What technology, architecture, or pattern am I assuming?" | "We need a relational database," "Services communicate via HTTP," "Users authenticate with passwords" |
| **Business** | "What business constraints am I assuming?" | "We'll have 10K users in 6 months," "The team has 3 backend engineers," "We can't change the billing system" |
| **Problem** | "What am I assuming about the problem itself?" | "Users want real-time updates," "This data needs to be consistent," "Performance is the bottleneck" |

3. **For each assumption, ask the challenge questions:**
   - "Is this actually true, or did I assume it?"
   - "What evidence supports this?"
   - "What would change if this were false?"
   - "What if the opposite were true?"
4. **Classify each assumption:**
   - **Validated:** Evidence confirms it. Keep it.
   - **Unvalidated:** No evidence either way. Flag it as a risk.
   - **Challenged:** Evidence or reasoning suggests it may be wrong. Explore alternatives.
5. **For challenged assumptions, generate alternative solutions** that do not depend on the challenged assumption.

## Application Prompts

- "What am I taking for granted about this problem?"
- "What would a complete newcomer question about this design?"
- "What 'everyone knows' statements am I relying on?"
- "If I had to defend each assumption to a skeptic, which ones would I struggle with?"
- "What has changed recently that might invalidate old assumptions?"
- "What if [assumption] were false — what would I build instead?"

## Assumption Categories for Software

Common assumption categories to check:

| Category | Check For |
|----------|----------|
| **Scale** | "How many users/requests/records?" Is this based on data or hope? |
| **Team** | "Who will build and maintain this?" Assuming skills that don't exist? |
| **Timeline** | "When does this need to work?" Real deadline or artificial urgency? |
| **Technology** | "What stack/platform/service?" Chosen for this problem or inherited? |
| **Requirements** | "What must it do?" Are these actual user needs or assumed needs? |
| **Constraints** | "What can't we change?" Is this truly immovable or just uncomfortable? |
| **Environment** | "Where will this run?" Cloud assumptions, network assumptions, availability assumptions? |

## Common Pitfalls

- **Listing only technical assumptions.** Business and problem-level assumptions are often more consequential. "Users want real-time updates" is an assumption that, if wrong, eliminates enormous complexity.
- **Not going deep enough.** "We need a database" surfaces an assumption, but keep asking: "Why?" → "We need persistent state" → "Why?" → "Users expect data to survive a restart" → NOW challenge that: does ALL data need to survive? Which data? For how long?
- **Treating all assumptions as equal.** Some assumptions, if wrong, change nothing. Others, if wrong, invalidate the entire approach. Focus challenge energy on high-impact assumptions.
- **Challenging without alternatives.** Identifying a shaky assumption is only half the work. For each challenged assumption, generate at least one alternative approach that does not depend on it.

## When to Use

- Before committing to an architecture or technology choice
- When a solution feels "obvious" (obvious = heavily assumption-laden)
- When the user says "we need to use X" — probe whether X is a constraint or an assumption
- When revisiting a decision made months ago under different circumstances
- Any time "it depends" is the honest answer — surface what it depends on
