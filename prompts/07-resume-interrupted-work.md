# Resume interrupted work

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Resume [requested Plane work item or bug] in the current project.
Recovery context: [existing task IDs or checkpoint paths, if not already available].

Read the Plane item and relevant linked context for the objective, scope, and acceptance criteria; recover prior authorization and progress from the existing task and checkpoints.

Read lifecycle guidance and project instructions first. Recover the assignment, permissions, snapshot, partial changes, findings, completed checks, unresolved questions, and remaining scope. Verify current state and drift. Treat checkpoints as evidence, not new authority to expand permissions.

Inspect available worker/process/job state. Distinguish active work, unknown progress, pending input, failure, and completed results. Do not interrupt or duplicate healthy work to restart a conversation. Verify ownership before replacement writers. Preserve unsaved work and inspect external outcomes before replaying consequential actions. Report missing visibility or authorization and continue only independent safe work where possible.

Plan before edits. Continue within verified prior authorization; resuming does not grant missing publication, deployment, Git, or external-record permissions. If the preserved task scope authorizes normal Git delivery and final checks pass, follow the `git-delivery.md` procedure from the loaded `$agent-router` skill, reconcile the current branch, commit, remote, and pull-request state, and complete only the missing commit, push, or ready-for-review, non-draft pull-request step. Do not replay a completed delivery or widen the preserved scope. Reuse deliverables and continue existing workers when supported. Assign replacements only unfinished scope with recovery context. Preserve review independence and invalidate coverage affected by drift.

Follow the `testing-handoff.md` reference from the loaded `$agent-router` skill. Recover the prior task-specific testing instructions, snapshot, and execution evidence; invalidate affected steps when drift or new fixes change the candidate, then provide refreshed instructions for the remaining work and final state.

Resuming does not automatically restart adversarial review. Apply it only to major new features, newly introduced frameworks/libraries, or an explicit user request; skip remaining documentation-only, routine, or minor changes.

Complete remaining authorized work and verification. Report recovered versus newly completed work, actual results, unresolved findings, gaps, and active ownership at handoff. Do not claim completion from a prior worker's claim or a returned wait. Honor current stops and explicit budgets.
```
