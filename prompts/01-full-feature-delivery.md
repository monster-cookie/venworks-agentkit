# Full feature delivery

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Deliver [requested Plane work item or bug] in the current project.
Art/3D requirements: [none, assess need, or asset requirements].

Read the Plane item and relevant linked context for scope, constraints, and acceptance criteria.

Read project instructions and contracts, record the starting commit and working-tree state, and preserve unrelated work. Resolve material missing requirements and plan before edits. This authorizes scoped local implementation, assets, documentation, reports, and relevant tests/build outputs in project-authorized locations. Respect project approval requirements and approvals already given. After the scoped work and required checks are complete, follow the `git-delivery.md` procedure from the loaded `$agent-router` skill: by default, commit the scoped changes, push to the intended origin or delivery remote, and open or update a ready-for-review, non-draft pull request. If higher-priority project instructions require Git mutations in an approved task-specific plan, name task-branch creation or reuse, the scoped commit, the explicit push destination, and the ready-for-review PR in the initial plan; after that plan is approved, do not request the same approval again. Explicit task restrictions, including local-only, report-only, review-only, unavailable remote, or unresolved required-check limits, prevail and stop that delivery step when applicable. Other publication, merge, deployment, release, and external-record updates still require authorization unless already granted. When a provider-backed infrastructure plan is already authorized for an identified target, its required provider/backend reads and normal transient plan-lock acquisition and release are included as a narrow exception to this external-record restriction. Local implementation or validation alone does not grant provider-operation authorization. Clarify a conflict before acquiring a remote lock. Plan authorization excludes apply, import, persistent state updates or migrations, destroy, force-unlock, and unrelated external-record updates.

Coordinate architecture for material design decisions; graphic-design for art and visual assets or 3d-modeling for 3D assets when needed, using their matching skills and available tools; implementation through coding or tech-ops as appropriate; and independent normal review. Run adversarial review only for major new features, a newly introduced framework/library, or an explicit user request. Skip it for documentation-only changes, routine fixes, and minor changes. Explain omitted conditional stages and disclose missing capabilities rather than inventing specialist roles.

Before spawning implementation work, state the critical path, current milestone, prerequisite checkpoints, and ownership. Delegate only independently executable work required by the current milestone. Five or six active specialists are acceptable when their work is independent and ownership-safe; unused capacity is not a reason to create tasks. Do not advance consumers, integration, final documentation, tracker closeout, or broad acceptance work ahead of an unmet prerequisite. Reuse suitable existing agents for follow-up work and keep one writer per subsystem.

For assets, establish style/references, editable source format, export format, dimensions/scale, naming, and integration acceptance criteria before production. Preserve editable sources and verify exports in the consumer when possible; disclose unverified integration.

Provide testing instructions following the `testing-handoff.md` reference from the loaded `$agent-router` skill while implementing, and refresh the task-specific instructions after the final review fixes and documentation changes. Include copyable steps, expected results, proportionate regression or failure checks, cleanup, and explicit executed versus unrun checks with runtime or platform limits.

Have actual specialists load their matching skills and shared lifecycle reference. Define ownership, milestones, deliverables, and recovery context. Preserve healthy work across bounded waits. When adversarial review is required, complete normal review first, then independently review the same snapshot without exposing normal conclusions until the adversarial original is recorded. Preserve original reports before reconciliation. Later documentation/changelog edits do not restart adversarial review; use a proportionate accuracy/editorial check.

Complete one independent normal review, route its supported in-scope findings through one correction pass, run affected verification, and perform one focused re-review of the changed coverage and interactions. If a concrete supported defect remains or new evidence invalidates coverage, record why another correction cycle is necessary and have the coordinator reassess the critical path before continuing. Do not repeat equivalent review, correction, or broad-test cycles without a relevant change in source, inputs, failure evidence, or risk. Report blocked or unverifiable findings and scope expansions explicitly. Do not silently fix unrelated defects or claim blocked work is clean.

At a stable implementation milestone, update technical and user documentation for the final behavior, then update the existing end-user changelog using its established filename and conventions. If none exists, create changelog.md with an Unreleased section. Describe observable improvements and migration steps; do not invent release dates or shipped status. Review documentation and changelog accuracy.

Deliver the implemented outcome, asset/document paths, original reports, reconciliation and finding disposition, coverage, actual checks/results, and remaining gaps. Distinguish configured models from observed runtime metadata. Do not claim completion while required work remains unresolved.
```
