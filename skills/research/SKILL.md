---
name: research
description: Gather repository and authoritative external evidence for technical, version, dependency, compatibility, and implementation questions.
---

# Research

Use this skill when a conclusion depends on repository reconnaissance, current technical facts, version-specific behavior, dependency compatibility, source comparison, or an external specification. The deliverable is evidence that lets another agent make a defensible decision.

## Frame the question

- Restate the exact question, scope, target versions, environment, and decision the research must support.
- Read repository instructions and inspect the local code, manifests, lockfiles, configuration, tests, and documentation before searching externally.
- Search for the actual symbols, paths, versions, and call sites. Verify that a referenced file or feature exists and is used in the claimed way.

## Gather evidence

- Prefer primary and authoritative sources: repository implementation and tests, official specifications and documentation, release notes, vendor sources, standards, and original research.
- For time-sensitive or version-sensitive claims, verify the exact version, publication or update date, supported platform, and relevant configuration. Do not blend behavior from different releases.
- Compare sources when behavior is ambiguous. Record the source name or URL, the fact it supports, and any scope or reliability limit.
- Separate verified facts, reasoned inferences, recommendations, community reports, and unresolved gaps. Do not turn a likely architecture into a confirmed implementation claim.
- Use the repository-local `.work` directory for downloaded excerpts, structured notes, and temporary comparison artifacts when practical.

## Source record

- Record the exact file, symbol, release, version, URL, or publication date that supports a material claim.
- Prefer a primary source over a summary, and explain when only a secondary or community source is available.
- Keep excerpts short and capture the relevant surrounding context so a later reader can recheck the conclusion.
- Resolve conflicts by comparing scope, version, authority, and observed behavior rather than averaging incompatible claims.
- Treat a missing local binary, service, account, or platform as a research boundary and do not fill it with memory.

## Deliver the result

- Return findings organized around the decision, with concise evidence and exact paths, symbols, versions, URLs, or citations where useful.
- Explain implementation or compatibility implications and identify what remains unverified. State the research boundary when local binaries, live services, or platform behavior were unavailable.
- Keep the work read-only unless the parent explicitly delegates a documentation update. Do not change production code, configuration, dependencies, or external systems.

## Stop conditions

- Stop searching when the question is answered with sufficient evidence for the stated decision; do not accumulate unrelated background.
- Continue when a material claim is time-sensitive, version-specific, or contradicted by a stronger source.
- State what would need a live probe, user access, a newer source, or repository change before it can be confirmed.
- Make recommendations only after showing the facts and constraints they depend on.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
