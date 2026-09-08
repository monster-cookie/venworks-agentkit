---
name: code-review
description: Perform an independent read-only review for correctness, regressions, compatibility, lifecycle, error handling, maintainability, and meaningful test gaps.
---

# Code Review

Use this skill for an independent review of a working tree, commit, branch, pull request, patch, or proposed implementation. Judge the behavior against the request and the repository's contracts; do not turn the review into a style rewrite.

## Tooling and credential policies

Before selecting project tools or using an authenticated service, follow [tooling and credential policies](../agent-router/references/tooling-and-credentials.md). Resolve optional adopted shared and repository-root policies for this role, target, and operation; verify the required identity through the actual consuming tool. Missing policies retain existing workflow behavior. Existing but invalid or conflicting policies block affected operations, not unrelated work. Tool access and credentials do not independently authorize mutations. Direct invocation follows the same discovery rules as delegated work.

## Review the change

- Read applicable repository instructions, the change description, and the relevant surrounding code before judging a diff.
- Establish what the code is intended to do, then trace changed inputs, outputs, state, side effects, and error paths through their callers and consumers.
- Check concrete correctness, regressions, lifecycle and cleanup, ordering or concurrency, data integrity, resource ownership, API compatibility, configuration behavior, and meaningful test coverage.
- Exercise boundary conditions mentally or with focused read-only checks: missing, empty, malformed, repeated, partial, stale, oversized, or unexpected inputs when those cases can reach the changed code.
- Distinguish a defect from a preference. Do not report formatting, naming, or speculative concerns unless they create a concrete maintenance or behavior risk.
- Treat tests as evidence of a requirement, not as proof by existence. Identify assertions that can pass while the requested behavior is broken and note high-value missing negative cases.

## Review order

- Start with the changed behavior and its acceptance criteria, then inspect the smallest surrounding call graph needed to verify them.
- Follow data and control flow from inputs through state changes and side effects to the observable result.
- Compare error, retry, cleanup, and cancellation paths with the success path.
- Check configuration defaults, version assumptions, migration behavior, and callers that the diff did not update.
- Inspect tests for both the intended result and a meaningful failure or boundary case.
- Use focused commands or probes only when they can provide evidence without mutating the reviewed target.

## Report findings

- Report findings in priority order. Each material finding needs a severity, exact file and symbol or line, concrete failure scenario, impact, evidence, and correction direction.
- Use the lowest severity that accurately describes the impact and state prerequisites when a problem needs an unusual condition.
- Do not edit production files while reviewing. Use the repository-local `.work` directory for temporary review artifacts when practical.
- If no material defect is supported by the evidence, say so clearly and mention any meaningful validation limitation instead of inventing findings.

When implementation or testing instructions are in scope, inspect the [testing handoff](../agent-router/references/testing-handoff.md) for meaningful coverage, stale snapshot references, expected outcomes, and unrun runtime or platform checks. Report gaps as review findings or coverage limits without editing source or granting execution permission.

## Finding threshold

- A finding should identify a reachable condition, incorrect behavior, or contract risk that a maintainer can act on.
- State prerequisites when the impact depends on a particular configuration, platform, input, timing, or caller.
- Do not downgrade a data-loss or compatibility defect to a style note because the normal path works.
- Do not upgrade a speculative concern without evidence that the triggering path is reachable.
- Keep recommendations proportional to the defect and avoid prescribing unrelated redesign.

## Handoff

Return findings first, followed by concise coverage notes and unresolved questions. Keep proposed corrections at the level needed to fix the defect; leave implementation choices to the coding agent unless the review request asks for a patch.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
