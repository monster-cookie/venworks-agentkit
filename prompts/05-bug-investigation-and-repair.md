# Bug investigation and repair

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Investigate and fix [requested Plane bug or work item] in the current project.

Read the Plane item and relevant linked context for expected behavior, reproduction evidence, scope, constraints, and acceptance criteria.

Read project instructions, record the snapshot, and preserve unrelated work. Establish a reproduction or concrete source evidence, trace the cause and affected callers, then plan before edits. Do not infer a cause solely from an error message.

This authorizes a scoped fix, meaningful regression coverage where appropriate, project-authorized test outputs, reports, and relevant documentation/end-user changelog updates. After the scoped fix and required checks are complete, follow the `git-delivery.md` procedure from the loaded `$agent-router` skill: by default, commit the scoped changes, push to the intended origin or delivery remote, and open or update a ready-for-review, non-draft pull request. Explicit task restrictions, including local-only, report-only, review-only, unavailable remote, or unresolved required-check limits, prevail and stop that delivery step when applicable. Other publication, merge, deployment, release, and external-record updates still require authorization unless already granted. When a provider-backed infrastructure plan is already authorized for an identified target, its required provider/backend reads and normal transient plan-lock acquisition and release are included as a narrow exception to this external-record restriction. Local implementation or validation alone does not grant provider-operation authorization. Clarify a conflict before acquiring a remote lock. Plan authorization excludes apply, import, persistent state updates or migrations, destroy, force-unlock, and unrelated external-record updates. Surface scope expansions and consequential reproduction steps needing approval.

Use research/architecture when diagnosis requires them, coding for application changes or tech-ops for infrastructure changes, and independent code review. Do not add adversarial review for routine bug fixes; it applies only to major new features, a newly introduced framework/library, or an explicit user request. Have specialists load their matching skills and lifecycle guidance. Preserve diagnostics and partial work; inspect side effects before retrying.

Make the smallest complete correction, run relevant checks, and confirm the original failure is corrected when reproducible. State limits if only source reasoning or a model supports it. Resolve supported in-scope review findings and recheck affected behavior. Deliver cause, changed behavior/paths, regression evidence, original findings and disposition, actual validation, and remaining uncertainty. Update the existing changelog with the observable fix without claiming a release shipped.

Provide testing instructions following the `testing-handoff.md` reference from the loaded `$agent-router` skill, with the original reproduction, corrected outcome, regression or failure-path steps, expected results, cleanup or recovery, and exact executed versus not-run evidence; refresh them after any review correction.
```
