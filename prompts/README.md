# Workflow prompt library

Open a Codex task in the intended project, choose a template, replace bracketed fields, and paste the complete text block. Install the packaged agents and skills first. These are assignments, not slash commands or extra skills. The skills and shared lifecycle reference remain the source of workflow procedures.

Use a Plane work-item ID or URL as the primary input. Each template reads the item and relevant linked context for its requirements instead of asking you to paste them. Resolve material missing information using project context or a focused question; do not invent requirements. Reading a Plane item does not authorize changing it. For work without a Plane item, replace that input and retrieval sentence with a direct assignment.

| Template | Purpose |
| --- | --- |
| [Full feature delivery](01-full-feature-delivery.md) | Architecture, assets, implementation, reviews, documentation, and changelog |
| [Review and fix](02-review-and-fix.md) | Review/correction cycles within a specified scope |
| [Independent review only](03-independent-review-only.md) | Original reports and coverage before approving fixes |
| [Marketing refresh](04-marketing-refresh.md) | Site and platform copy grounded in shipped behavior |
| [Bug investigation and repair](05-bug-investigation-and-repair.md) | Focused diagnosis, correction, and regression verification |
| [Release readiness](06-release-readiness.md) | Evidence-based readiness and blockers |
| [Resume interrupted work](07-resume-interrupted-work.md) | Recovery and continuation of unfinished authorized work |
| [Documentation audit](08-documentation-audit.md) | Technical and user documentation accuracy |

Read the permissions inside the selected prompt. Editing templates authorize scoped local deliverables and relevant checks; review-only and readiness templates authorize reports only. Change permissions explicitly if publication or other external actions are required. Preserve existing approvals rather than re-requesting them. Leave optional budgets/deadlines unspecified unless you actually intend a limit.

Specify a base revision and working-tree scope for change reviews, or explicitly request a whole-project review. File counts do not prove substantive coverage. When adversarial review is required, both initial reviewers inspect the same snapshot independently before reconciliation. After fixes, recheck affected coverage and interactions rather than automatically repeating every full-project scan.

Adversarial review runs only for major new features, introduction of a new framework/library, or an explicit user request. Skip documentation-only changes, routine fixes, and minor changes unless explicitly requested; size, statefulness, or risk alone is not a trigger. Later documentation/changelog edits do not restart the stage. Use proportionate accuracy/editorial checks for documentation. Security review applies to meaningful trust boundaries. Use graphic-design for art and visual assets and 3d-modeling for 3D work. Each specialist loads its matching skill and uses the tools available in the current setup. Missing tools and unverified asset integration must be disclosed.

The installer copies agents, skills, and this prompt folder into the selected Codex home. Existing config.toml is preserved; -InitializeConfig can create a missing config from the example. See the repository installation guide. The installed prompts are copyable templates; no automatic prompt UI registration is assumed.
