---
name: technical-docs
description: Create and maintain developer-facing documentation for architecture, APIs, contributor workflows, implementation guides, and operational behavior.
---

# Technical Documentation

Use this skill for documentation consumed by developers, maintainers, operators, or integrators. Explain how the system actually behaves and how a reader can work with it, while keeping the document aligned with repository conventions.

## Understand the source

- Read applicable repository instructions and identify the target document, audience, lifecycle, and established documentation structure.
- Inspect the implementation, configuration, interfaces, schemas, tests, scripts, and existing docs that support each claim. Verify names, paths, commands, defaults, prerequisites, and version constraints against current repository evidence.
- Preserve established terminology, heading hierarchy, link style, examples, and formatting conventions unless the request changes them.
- Distinguish stable contracts from implementation details, inferred behavior, examples, and unresolved questions.

## Write useful documentation

- Lead with the purpose and the reader's task. Explain architecture, responsibilities, interfaces, data flow, constraints, lifecycle, workflows, failure modes, recovery, and operational implications when they help the reader make a correct decision.
- Document contracts at the boundary where they matter: inputs, outputs, invariants, errors, side effects, ownership, ordering, compatibility, and migration requirements.
- Use examples that are minimal, valid, and representative. Explain non-obvious fields and choices rather than copying large blocks of source.
- Keep the prose human-readable and specific. Do not use documentation as a dump for model memory or every implementation detail that happens to exist.
- Edit only the requested documentation scope. Documentation edits may describe implementation behavior; do not change application source or production configuration unless separately delegated.
- Use the repository-local `.work` directory for temporary documentation artifacts when practical and avoid giant shell commands for multiline files.

## Useful document shape

- Start with purpose, audience, prerequisites, and the boundary of what the document covers.
- Describe the normal workflow from the reader's entry point to the expected result.
- Place contracts, configuration, examples, failure modes, recovery, and compatibility notes beside the workflow they explain.
- Use a diagram or table only when it clarifies ownership, data flow, mappings, or state transitions better than prose.
- Link to authoritative source files or adjacent docs without duplicating their entire content.
- Mark planned, deprecated, experimental, and version-specific behavior so it cannot be mistaken for the current contract.

## Verify the document

- Recheck every factual claim after editing, including links, filenames, symbols, commands, configuration keys, and examples.
- Run the repository's relevant documentation checks, formatter, link checker, or example validation when available and proportionate. Inspect the final diff for accidental scope or terminology changes.
- Report modified docs, checks run, and factual gaps that could not be verified.

## Maintenance

- Prefer wording that will remain true across routine implementation changes; name versions or paths when they are part of the contract.
- Remove stale instructions when the requested update makes them false, but do not rewrite unrelated sections for consistency alone.
- Keep examples synchronized with the actual interface and note their expected output when it prevents ambiguity.
- Leave a clear factual gap for the next maintainer when repository evidence is incomplete.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
