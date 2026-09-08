# Independent review only

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Review the implementation for [requested Plane work item or bug] in the current project.
Adversarial review: [use the standard gate, or explicitly request it].

Read the Plane item and relevant linked context for review scope, contracts, concerns, and acceptance criteria.

Read project instructions, record the branch/commit and local changes, inventory the entire selected scope, and state exclusions with reasons. This is review-only: only reports under .work/reviews/ are authorized writes. Do not fix source, change Git state, publish, or mutate external records. Inspect checks before running them; checks writing elsewhere require authorization or must be reported as unrun.

Follow the `testing-handoff.md` reference from the loaded `$agent-router` skill. Review any task-specific testing instructions and recorded evidence for the reviewed snapshot, and report missing, stale, or unrun checks as review gaps; this adds no execution permission beyond the existing review scope.

Use an actual code-review specialist. Use adversarial review only for major new features, a newly introduced framework/library, or an explicit user request. Skip it for documentation-only changes, routine fixes, and minor changes unless explicitly requested. Have each load its matching skill and shared lifecycle reference. When adversarial review is required, complete normal review first, then independently review the same snapshot without revealing normal conclusions until the adversarial original is recorded. Disclose if a required reviewer cannot run.

Trace callers, consumers, and cross-file behavior. Maintain per-file coverage distinguishing substantive evidence, context-only inspection, and unreviewed work. Preserve originals before reconciliation. Each finding needs a stable ID, reviewer, severity, exact location, trigger, impact, evidence, confidence, and proposed correction. Separate source-confirmed defects, executed reproductions, and runtime assumptions. Preserve rejected/downgraded candidates and reasons.

Apply lifecycle guidance: preserve healthy workers across waits and retrieve actual deliverables. Resolve affected stale coverage if the snapshot changes. Deliver originals, consolidated findings, coverage, actual checks/results, reviewer IDs/status, and gaps. Distinguish configured models from observed runtime metadata. Stop after reporting for separate fix approval.
```
