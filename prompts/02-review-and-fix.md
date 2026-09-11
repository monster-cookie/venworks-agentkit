# Review and fix

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Review and repair the implementation for [requested Plane work item or bug] in the current project.

Read the Plane item and relevant linked context for review scope, constraints, and acceptance criteria.

Read project instructions and contracts, record the starting snapshot, inventory scope, preserve unrelated work, and plan before edits. This authorizes supported in-scope fixes, relevant tests, necessary documentation/changelog updates, and reports in project-authorized locations. After the scoped fixes and required checks are complete, follow the `git-delivery.md` procedure from the loaded `$agent-router` skill: by default, commit the scoped changes, push to the intended origin or delivery remote, and open or update a ready-for-review, non-draft pull request. If higher-priority project instructions require Git mutations in an approved task-specific plan, name task-branch creation or reuse, the scoped commit, the explicit push destination, and the ready-for-review PR in the initial plan; after that plan is approved, do not request the same approval again. Explicit local-only, report-only, review-only, unavailable remote, or unresolved required-check limits prevail and stop that delivery step when applicable. Other publication, merge, deployment, release, and external-record updates still require authorization unless already granted. Report scope expansions before pursuing them.

Use an actual independent code-review specialist. Include adversarial review only for major new features, a newly introduced framework/library, or an explicit user request. Skip it for documentation-only changes, routine fixes, and minor changes. Have each load its matching skill and shared lifecycle guidance. When adversarial review is required, complete initial normal review first, then independently review the same snapshot without revealing normal conclusions until the adversarial original is recorded.

Before spawning work, state the current milestone, prerequisite checkpoint, and ownership. Delegate only independently executable work needed for this review and correction. Five or six active specialists are acceptable when their work is independent and ownership-safe; unused capacity is not a reason to create tasks. Reuse suitable existing agents for follow-up work, keep one writer per subsystem, and do not advance documentation, tracker closeout, or broad acceptance work ahead of the corrected implementation checkpoint.

Preserve original reports, stable finding IDs, severity, exact locations, triggers, impact, evidence, confidence, and proposed corrections. Maintain substantive/context-only/unreviewed coverage with evidence. Reconcile duplicates and preserve rejected/downgraded findings with reasons.

Route supported findings to coding in one correction pass, verify the affected behavior, and independently re-review the changed coverage and interactions once. Record the fix-batch snapshot and invalidate stale affected coverage. If a concrete supported defect remains or new evidence invalidates coverage, record why another cycle is necessary and have the coordinator reassess the critical path before continuing. Do not repeat equivalent review, correction, or broad-test cycles without a relevant change in source, inputs, failure evidence, or risk. Honor explicit user stops and budgets. If blocked, preserve progress and explain the blocker rather than repeat identical attempts or declare success.

Follow the `testing-handoff.md` reference from the loaded `$agent-router` skill for the correction snapshot, and refresh the task-specific testing instructions after the final correction. Include steps, expected outcomes, affected regression or failure checks, cleanup, and passed, failed, or not-run evidence. Run focused checks while the candidate changes and the broad integrated suite once at the milestone boundary; repeat a passing broad check only when affected source or inputs changed, an earlier check failed, or a reviewer identified a concrete uncovered risk.

Limit adversarial follow-up to corrections affecting the qualifying feature or integration; do not restart it for later documentation/changelog edits or unrelated routine changes. Update relevant documentation and the existing end-user changelog for actual behavior changes and check their accuracy. Deliver originals, a finding-to-fix-and-verification ledger, final coverage, actual checks, unrun checks, and uncertainty. Do not promise that no possible defect exists or replace requested reports with “all findings resolved.”
```
