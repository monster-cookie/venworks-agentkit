---
name: software-architecture
description: Analyze existing system boundaries, interfaces, dependencies, data flow, lifecycle, and migration choices before a substantial technical change.
---

# Software Architecture

Use this skill when a request involves system design, cross-cutting behavior, component boundaries, public contracts, dependency decisions, or migration strategy. Produce implementation-ready guidance grounded in the current repository rather than a generic redesign.

## Build the current-state model

- Read applicable repository instructions and inspect the relevant entry points, modules, configuration, schemas, tests, and operational documentation.
- Trace the behavior far enough to identify ownership, data flow, persistence, external interfaces, lifecycle, cleanup, and error propagation.
- Record confirmed facts with file and symbol references. Mark inferences, missing evidence, and proposed behavior separately.
- Identify the contract that callers, stored data, external systems, operators, and users rely on. Include compatibility assumptions and version boundaries.

## Evaluate the change

- Translate the requirement into affected responsibilities and invariants before proposing a design.
- Check whether the current boundary can support the requirement with a local change. Prefer the smallest change that preserves ownership and avoids duplicated state.
- Evaluate alternatives against correctness, operational complexity, failure recovery, compatibility, migration cost, observability, and future maintenance. Explain the tradeoff that selects one option.
- Examine lifecycle and ordering: initialization, retries, partial completion, shutdown, concurrent access, stale state, rollback, and recovery after interruption.
- Call out changes to public APIs, serialized formats, permissions, dependencies, deployment, data migration, or operational runbooks that require explicit implementation decisions.
- Do not recommend a rewrite or new abstraction without evidence that the existing boundary cannot meet the requirement.

## Questions to answer

- Which component owns each piece of state, and where is the authoritative value stored?
- Which interface or schema is the compatibility boundary, and which callers depend on its current shape?
- What happens on duplicate, delayed, missing, malformed, or partially applied input?
- Which operations must be ordered or serialized, and what happens when they interleave?
- How are failures observed, retried, rolled back, or repaired after restart?
- What changes must be deployed together, migrated, feature-gated, or documented for operators and users?

## Deliver the handoff

- Keep the analysis read-only unless the parent explicitly delegates a documentation edit. Do not modify application source, production configuration, schemas, or generated artifacts as part of an architecture analysis.
- Use the repository-local `.work` directory for temporary diagrams, notes, and analysis artifacts when practical.
- Return the current-state model, the selected design, alternatives considered, affected interfaces/components, migration or rollout steps, failure modes, validation strategy, and unresolved decisions.
- Make the handoff specific enough that a coding agent can implement it without rediscovering the architecture. Cite exact paths, symbols, configuration keys, or contracts where useful.

## Decision record shape

- Begin with the decision and the requirement it satisfies.
- Describe the current boundary and the smallest affected surface.
- Name rejected alternatives and the concrete tradeoff that ruled them out.
- List compatibility, rollout, observability, and rollback implications.
- End with assumptions that need verification and decisions the parent must make.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
