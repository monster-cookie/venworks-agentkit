# Full feature delivery

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Deliver [requested Plane work item or bug] in the current project.
Art/3D requirements: [none, assess need, or asset requirements].

Read the Plane item and relevant linked context for scope, constraints, and acceptance criteria.

Read project instructions and contracts, record the starting commit and working-tree state, and preserve unrelated work. Resolve material missing requirements and plan before edits. This authorizes scoped local implementation, assets, documentation, reports, and relevant tests/build outputs in project-authorized locations. Respect project approval requirements and approvals already given. Do not change Git state, publish, deploy, or mutate external records without separate authorization. When a provider-backed infrastructure plan is already authorized for an identified target, its required provider/backend reads and normal transient plan-lock acquisition and release are included as a narrow exception to this external-record restriction. Local implementation or validation alone does not grant that authorization. Explicit task restrictions still apply; clarify a conflict before acquiring a remote lock. Plan authorization excludes apply, import, persistent state updates or migrations, destroy, force-unlock, and unrelated external-record updates.

Coordinate architecture for material design decisions; graphic-design for art and visual assets or 3d-modeling for 3D assets when needed, using their matching skills and available tools; implementation through coding or tech-ops as appropriate; and independent normal review. Run adversarial review only for major new features, a newly introduced framework/library, or an explicit user request. Skip it for documentation-only changes, routine fixes, and minor changes. Explain omitted conditional stages and disclose missing capabilities rather than inventing specialist roles.

For assets, establish style/references, editable source format, export format, dimensions/scale, naming, and integration acceptance criteria before production. Preserve editable sources and verify exports in the consumer when possible; disclose unverified integration.

Have actual specialists load their matching skills and shared lifecycle reference. Define ownership, milestones, deliverables, and recovery context. Preserve healthy work across bounded waits. When adversarial review is required, complete normal review first, then independently review the same snapshot without exposing normal conclusions until the adversarial original is recorded. Preserve original reports before reconciliation. Later documentation/changelog edits do not restart adversarial review; use a proportionate accuracy/editorial check.

Fix supported in-scope findings, verify corrections, and independently review resulting changes and affected interactions until no supported findings remain unresolved, relevant checks pass, and the latest review finds no new supported defect. Investigate repeated failures instead of repeating unchanged cycles. Report blocked/unverifiable findings and scope expansions explicitly. Do not silently fix unrelated defects or claim blocked work is clean.

Update technical and user documentation for the final behavior, then update the existing end-user changelog using its established filename and conventions. If none exists, create changelog.md with an Unreleased section. Describe observable improvements and migration steps; do not invent release dates or shipped status. Review documentation and changelog accuracy.

Deliver the implemented outcome, asset/document paths, original reports, reconciliation and finding disposition, coverage, actual checks/results, and remaining gaps. Distinguish configured models from observed runtime metadata. Do not claim completion while required work remains unresolved.
```
