---
name: coding
description: Implement, debug, refactor, build, and validate bounded software changes while preserving repository contracts and scope.
---

# Coding

Use this skill when the requested outcome requires changing application code, scripts, configuration, tests, or build behavior. The deliverable is a working, reviewable change whose behavior matches the request and the repository's existing contracts.

## Tooling and credential policies

Before selecting project tools or using an authenticated service, follow [tooling and credential policies](../agent-router/references/tooling-and-credentials.md). Resolve optional adopted shared and repository-root policies for this role, target, and operation; verify the required identity through the actual consuming tool. Missing policies retain existing workflow behavior. Existing but invalid or conflicting policies block affected operations, not unrelated work. Tool access and credentials do not independently authorize mutations. Direct invocation follows the same discovery rules as delegated work.

## Establish the change

- Read every applicable `AGENTS.md` and repository context file before editing, including instructions inherited from parent directories.
- Inspect the current implementation, call sites, data flow, tests, and configuration that govern the behavior being changed. Treat names in the request as leads to verify, not as proof that a file or interface exists.
- Identify the smallest set of files that can implement the requirement and state a short plan before making edits.
- Separate confirmed behavior, assumptions, and decisions that require the parent orchestrator. Stop and report when satisfying the request would require an unapproved architecture, public API, schema, dependency, or scope change.

## Implement

- Follow the repository's established architecture, language version, dependency policy, formatting, error-handling conventions, and file organization.
- Prefer the smallest complete change. Reuse existing helpers and interfaces when they express the same contract; avoid speculative abstractions and unrelated cleanup.
- Preserve public APIs, serialized formats, compatibility behavior, and user-visible wording unless the requirement explicitly changes them.
- Keep validation and error handling at the boundary where invalid input or an unavailable dependency first becomes meaningful. Preserve useful context when propagating failures.
- Treat existing uncommitted work as user-owned. Inspect overlapping changes and avoid rewriting or reverting them.
- Use the repository-local `.work` directory for temporary, generated, intermediate, diagnostic, downloaded, extracted, and scratch artifacts when practical.
- Use the repository's normal editing tools. Do not create multiline files with giant shell `echo`, `printf`, or redirection commands.

## Scope decisions

- Keep changes to the requested behavior and the files that own it. Include a neighboring fix only when leaving it unchanged would make the requested behavior incorrect or unsafe.
- Treat generated files, vendored code, lockfiles, and deployment artifacts according to repository instructions; do not update them merely because a tool can regenerate them.
- Preserve backward compatibility when callers or stored data may outlive the change. If a breaking change is required, describe the migration and get the parent orchestrator's decision before implementing it.
- If a requirement depends on an unavailable service, platform, credential, or binary, implement only what can be verified locally and record the unverified boundary.
- When the task reveals a broader design issue, finish the bounded fix if it remains correct and report the wider issue separately rather than expanding the patch.

## Verify

- Add or update a test when a meaningful behavior, regression, boundary, or failure mode can be checked reliably and the repository's test structure supports it. Do not add tests that merely mirror implementation details.
- Run the narrowest relevant formatter, linter, type check, unit test, integration test, build, or runtime probe. Broaden checks when the change crosses a component boundary or the first check reveals a new risk.
- Check both the requested path and an important nearby failure path when the change affects parsing, persistence, lifecycle, concurrency, configuration, or user data.
- Report exactly which checks ran and their outcomes. Never imply that an unrun test, build, deployment, or runtime behavior was validated.
- If a check cannot run, preserve the failure output and explain whether it is an environment limitation, an unrelated failure, or a defect introduced by the change.

## Failure handling

- Stop before destructive or irreversible operations when the target, backup, rollback, or authorization is unclear.
- Keep a recoverable copy or use the repository's established rollback path when the requested change can overwrite user data or generated state.
- On a failed edit or partial command, inspect the resulting state before retrying; do not assume the operation was atomic.
- Report unresolved failures with the exact affected path or component and the next decision needed from the parent orchestrator.

## Handoff

Return a concise summary of the behavior changed, modified files, validation performed, and remaining risks or decisions. Include exact commands or test names when they make the result reproducible.

## Pull-request handoff

When preparing or creating a PR, follow [diagram and pull-request guidance](../agent-router/references/diagrams-and-prs.md): include a relevant Mermaid diagram for structural or behavioral flows and use PR Lens when available and appropriate. Keep the description and visuals aligned with the final change and actual validation. PR creation requires task authorization; create only ready-for-review PRs.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
