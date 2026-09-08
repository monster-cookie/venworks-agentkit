# Bug investigation and repair

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Investigate and fix [requested Plane bug or work item] in the current project.

Read the Plane item and relevant linked context for expected behavior, reproduction evidence, scope, constraints, and acceptance criteria.

Read project instructions, record the snapshot, and preserve unrelated work. Establish a reproduction or concrete source evidence, trace the cause and affected callers, then plan before edits. Do not infer a cause solely from an error message.

This authorizes a scoped fix, meaningful regression coverage where appropriate, project-authorized test outputs, reports, and relevant documentation/end-user changelog updates. Do not change Git state, publish, deploy, or mutate external records without separate authorization. Surface scope expansions and consequential reproduction steps needing approval.

Use research/architecture when diagnosis requires them, coding for implementation, and independent code review. Do not add adversarial review for routine bug fixes; it applies only to major new features, a newly introduced framework/library, or an explicit user request. Have specialists load their matching skills and lifecycle guidance. Preserve diagnostics and partial work; inspect side effects before retrying.

Make the smallest complete correction, run relevant checks, and confirm the original failure is corrected when reproducible. State limits if only source reasoning or a model supports it. Resolve supported in-scope review findings and recheck affected behavior. Deliver cause, changed behavior/paths, regression evidence, original findings and disposition, actual validation, and remaining uncertainty. Update the existing changelog with the observable fix without claiming a release shipped.
```
