# Light Tier Example: API Versioning Decision

## User Prompt

"Should I use URL path versioning (/v1/users) or header versioning (Accept: application/vnd.api+json;version=1) for my REST API?"

## Problem Restatement

Choosing between URL path versioning (/v1/users) and header-based versioning (Accept header with version parameter) for a REST API. The decision affects client integration patterns, debuggability, and future flexibility.

## Tier Assessment

**Light** — Clear scope, two well-understood options, low risk of premature convergence because the options are already defined.

## Method Application

### First Principles Decomposition

**What is the fundamental requirement?** Clients need to call a specific version of an endpoint. The server needs to route to the correct handler. Both sides need to agree on which version is active.

**What are the actual constraints?**
- Clients are mobile apps and a web frontend (both controlled by the same team)
- API is internal (no third-party consumers)
- Likely 1-2 breaking changes per year

Stripped to fundamentals: internal consumers, infrequent version changes, no third-party compatibility requirement.

### Assumption Surfacing

**Assumption 1:** "We need formal API versioning." Challenge: With only internal consumers and 1-2 breaking changes per year, do we need versioning at all? Could we coordinate breaking changes via feature flags and synchronized deploys?

**Assumption 2:** "We'll have many versions running simultaneously." Challenge: With internal consumers, the typical scenario is a brief migration window where two versions coexist for days, not months.

**Assumption 3:** "This choice is permanent." Challenge: With internal consumers, switching versioning strategies later is feasible (painful but possible).

## Convergence

Both methods point the same direction: for an internal API with infrequent changes, URL path versioning (/v1/) is simpler, more debuggable (version visible in logs, URLs, browser), and the migration cost of "choosing wrong" is low because consumers are controlled.

**Recommendation:** URL path versioning. The simplicity and debuggability advantages outweigh header versioning's theoretical purity. If the API ever opens to third parties, revisit — but making that decision now is premature optimization.

**Open question:** Consider whether you need versioning at all. With internal consumers and synchronized deploys, a feature flag on the breaking endpoint might be simpler than a full versioning scheme.
