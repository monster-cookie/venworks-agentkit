# Review and fix

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Review and repair the implementation for [requested Plane work item or bug] in the current project.

Read the Plane item and relevant linked context for review scope, constraints, and acceptance criteria.

Read project instructions and contracts, record the starting snapshot, inventory scope, preserve unrelated work, and plan before edits. This authorizes supported in-scope fixes, relevant tests, necessary documentation/changelog updates, and reports in project-authorized locations. Do not change Git state, publish, deploy, or update external records without separate authorization. Report scope expansions before pursuing them.

Use an actual independent code-review specialist. Include adversarial review only for major new features, a newly introduced framework/library, or an explicit user request. Skip it for documentation-only changes, routine fixes, and minor changes. Include security review for meaningful trust boundaries. Have each load its matching skill and shared lifecycle guidance. When adversarial review is required, complete initial normal review first, then independently review the same snapshot without revealing normal conclusions until the adversarial original is recorded.

Preserve original reports, stable finding IDs, severity, exact locations, triggers, impact, evidence, confidence, and proposed corrections. Maintain substantive/context-only/unreviewed coverage with evidence. Reconcile duplicates and preserve rejected/downgraded findings with reasons.

Route supported findings to coding, verify corrections, and independently review new changes and affected interactions. Record each fix-batch snapshot and invalidate stale affected coverage. Repeat until no supported in-scope findings remain unresolved, relevant verification passes, and the latest review finds no new supported defect. Do not invent a cycle limit or treat accumulated waits as a deadline. Honor explicit user stops and budgets. Investigate repeated findings or failures; if blocked, preserve progress and explain the blocker rather than repeat identical attempts or declare success.

Limit adversarial follow-up to corrections affecting the qualifying feature or integration; do not restart it for later documentation/changelog edits or unrelated routine changes. Update relevant documentation and the existing end-user changelog for actual behavior changes and check their accuracy. Deliver originals, a finding-to-fix-and-verification ledger, final coverage, actual checks, unrun checks, and uncertainty. Do not promise that no possible defect exists or replace requested reports with “all findings resolved.”
```
