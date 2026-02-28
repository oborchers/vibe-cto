# MECE Decomposition

## What It Is

Break a problem into parts that are Mutually Exclusive (no overlap) and Collectively Exhaustive (nothing missing). This ensures systematic coverage of the entire problem space without redundancy or gaps.

**Counteracts:** Vague decomposition. LLMs naturally break problems into overlapping, incomplete categories. The result is analysis that feels thorough but has blind spots and redundancy. MECE forces rigor.

## Step-by-Step Process

1. **State what is being decomposed.** The problem, the solution space, the decision criteria, or the stakeholder groups.
2. **Choose a decomposition dimension.** A single axis along which to divide. Examples:
   - By user type (admin, regular user, anonymous)
   - By data flow (ingestion, processing, storage, retrieval)
   - By lifecycle stage (creation, active use, archival, deletion)
   - By failure mode (network, compute, storage, dependency)
   - By time horizon (immediate, short-term, long-term)
3. **List the categories.** Each category must be non-overlapping with every other category, and together they must cover everything.
4. **Test for ME (Mutually Exclusive).** For any item in the problem space, it should belong to exactly one category. If something could fit in two categories, the boundaries are unclear — redefine them.
5. **Test for CE (Collectively Exhaustive).** Can you think of anything in the problem space that does not fit any category? If so, add a category or broaden an existing one.
6. **Decompose each category further if needed.** Apply MECE recursively to sub-categories until each leaf node is small enough to analyze directly.

## Decomposition Dimensions for Software

Common MECE dimensions when decomposing software problems:

| Dimension | Categories | Works For |
|-----------|-----------|-----------|
| **Data lifecycle** | Create, Read, Update, Delete | API design, permissions, data flow |
| **System layers** | Presentation, Business Logic, Data, Infrastructure | Architecture, debugging, performance |
| **User journey** | Discovery, Onboarding, Active Use, Retention, Churn | Product features, UX |
| **Request lifecycle** | Receive, Validate, Process, Respond, Log | API design, error handling |
| **Failure domains** | Network, Compute, Storage, External Dependencies | Resilience, monitoring |
| **Environment** | Development, Testing, Staging, Production | DevOps, configuration |
| **Access level** | Public, Authenticated, Authorized, Admin | Security, permissions |

## Application Prompts

- "What are the non-overlapping parts of this problem?"
- "If I categorize every [request/user/failure/...] into buckets, what buckets do I need?"
- "Is there anything that doesn't fit into these categories?"
- "Do any of these categories overlap? Can a single item belong to two categories?"
- "What happens if I decompose along [dimension] instead?"

## Common Pitfalls

- **Overlapping categories.** "Frontend issues" and "performance issues" overlap because frontend can have performance issues. Choose one dimension at a time.
- **Missing categories.** Listing "read, write, delete" misses "create" (or conflates it with "write"). Always ask "what else?" after the initial list.
- **Wrong decomposition level.** Decomposing too finely creates noise. Decomposing too coarsely hides important distinctions. The right level depends on the decision being made.
- **Multiple dimensions in one level.** Mixing "by user type" and "by data flow" in the same level breaks MECE. Use one dimension per level, then decompose sub-categories along different dimensions.
- **Assuming the first decomposition is correct.** Try at least two different decomposition dimensions before committing. Different dimensions reveal different insights.

## When to Use

- Structuring a complex problem before analyzing it
- Ensuring nothing is missed in a review or audit
- Breaking a large task into work items
- Analyzing a decision with multiple factors
- Any time a list needs to be comprehensive and non-redundant
