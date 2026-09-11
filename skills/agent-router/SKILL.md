---
name: agent-router
description: Route non-trivial Codex work to specialized subagents for implementation, infrastructure operations, architecture, graphic design, 3D modeling, research, technical documentation, end-user documentation, marketing/platform documentation, normal code review, adversarial logic review, and explicitly requested security review. Use when a task spans multiple stages, benefits from independent review, or the user asks for agents, delegation, orchestration, or subagents.
---

# Agent Router

The user's explicit instructions take precedence over this skill.

## Tooling and credential policies

Before selecting project tools or using an authenticated service, follow [tooling and credential policies](references/tooling-and-credentials.md). Resolve optional configured shared and repository-root policies for this role, target, and operation; verify the required identity through the actual consuming tool. Missing policies retain existing workflow behavior. Existing but invalid or conflicting policies block affected operations, not unrelated work. Tool access and credentials do not independently authorize mutations. Direct invocation follows the same discovery rules as delegated work.

When the user or selected credential policy specifies Proton Pass, load [Proton Pass CLI for agents](references/proton-pass.md) for `pass-cli` session isolation, PAT login, access reasons, credential retrieval, and recovery. Load it only when that manager is needed and pass the reference to workers performing the credential operation.

## Goal

Use the root agent as the orchestrator and integrator.

The root should classify the work, delegate bounded specialist tasks, wait for required results, resolve conflicts, integrate findings, and present the final result.

## Project scope

Use this workflow across software, infrastructure, creative, and documentation projects. Establish the project's domain, toolchain, target environments, and conventions from its instructions and actual files. Do not assume a game engine, vendor, cloud provider, repository layout, or deployment target. Load platform-specific guidance only when that platform is part of the requested work.

Each packaged agent definition owns that role's model, reasoning-effort, service-tier, and sandbox defaults. Treat the matching agent TOML as the authoritative source for those settings; do not duplicate them in routing instructions. Preserve explicit user and live runtime choices. Override a role's configured defaults only for a concrete task need or observed result, explain the reason, and use only settings supported by the current runtime. If an override is unavailable, report that limitation and continue with the available configuration when viable; do not rewrite installed settings or claim an active worker changed models. Model choice or higher effort does not replace independent review or verification.

Future OpenRouter targets are documented but disabled in the affected agent TOML files until Codex correctly honors mixed-provider subagent configuration.

## Specialist workflow skills

Each named agent has a matching skill: `coding`, `tech-ops`, `software-architecture`, `graphic-design`, `3d-modeling`, `code-review`, `adversarial-review`, `security-review`, `research`, `technical-docs`, `user-docs`, and `marketing-docs`. The agent TOML defines the role and runtime settings; the skill contains its procedure. Ask the selected specialist to load its matching skill. Load only the workflows relevant to the task, and do not delegate again merely because a specialist skill is used. The root can also use a workflow directly for a bounded task.

## Delegation Gate

Before substantive work, establish the requested outcome, acceptance criteria, explicit replacement or removal requirements, dependency order, current milestone, and the checkpoint that permits downstream work. Then classify the task as either:

- root-only
- delegated

Root-only is appropriate for cohesive work the root can complete safely without losing a material specialist or independence benefit. Multiple files, repository investigation, or task size alone do not require delegation.

Delegate a bounded assignment when its result is required by the current milestone and at least one is true:

- two or more independently executable workstreams exist now
- a real architecture decision benefits from separate context
- external or version-specific facts require focused research
- independent review is required or materially useful
- the user explicitly asks for agents, delegation, orchestration, or subagents
- specialized visual, 3D, infrastructure, documentation, or other domain work is required

Use available concurrency for work that is independent, immediately useful, and ownership-safe. Five or six active specialists can be healthy; a configured thread ceiling is capacity, not a target or a reason to create work. Do not start a downstream consumer, integration, documentation, tracker, or acceptance stage before its prerequisite checkpoint is complete. Keep one writer per subsystem, and do not let the root edit a worker-owned subsystem concurrently. Reuse an existing suitable agent for follow-up work instead of creating an equivalent replacement.

When delegation is required, actually spawn the named subagent. Do not merely simulate delegation in the root thread.

If spawning a required agent fails, inspect whether a worker was actually created before retrying. Report and recover the failure without duplicate workers. A bounded wait timeout is not a failed spawn or a completed stage.

## Routing

Use `coding` for:

- production implementation
- bug fixes
- refactoring
- build failures
- targeted tests
- implementation validation

Use `tech-ops` for:

- infrastructure-as-code configuration, modules, and provisioning plans
- cloud or on-premises infrastructure operations and drift investigation
- infrastructure delivery pipelines, environment configuration, and state/backend handling
- executing an authorized infrastructure change and verifying its outcome

Use the project's existing infrastructure tools and target environment. Coordinate with `software-architecture` for material design decisions and `coding` for application code. Local edits and validation alone do not authorize provider-backed planning. An already-authorized plan for an identified target includes the provider/backend reads and normal transient plan-lock acquisition and release required by that operation, without repetitive approval. Explicit task restrictions, including a prohibition on remote mutations, still apply; clarify a conflict before acquiring a remote lock. Plan authorization does not include apply, import, persistent state updates or migrations, destroy, force-unlock, or unrelated external-record updates.

Use `software-architecture` for:

- system design
- component boundaries
- public contracts and interfaces
- data ownership
- major dependency decisions
- cross-cutting design changes
- migration strategy

Do not invoke architecture for routine implementation work.

Use `graphic-design` for:

- art, branding, icons, logos, graphics, and visual layouts
- UI visual direction and image assets
- editable visual sources and platform-ready exports

Use `3d-modeling` for:

- Blender or other configured 3D tools
- scenes, meshes, materials, UVs, textures, and rigs
- game assets, export preparation, and validation in the target application

For asset work, define references, source/export formats, dimensions or scale, and target requirements before production. Have each specialist load its matching skill and use available tools. Preserve editable sources and report missing tools or unverified target integration. Do not treat a specification or preview as proof that a usable asset was produced.

Use `research` for:

- repository reconnaissance
- current API/framework behavior
- dependency and version questions
- primary-source verification
- compatibility research
- external technical facts

Use `technical-docs` for:

- architecture documentation
- API documentation
- contributor documentation
- developer guides
- implementation and operational references
- maintainer-facing technical material

Use `user-docs` for:

- changelogs
- release notes
- installation guides
- feature explanations
- usage instructions
- end-user help content

Use `marketing-docs` for:

- website and landing-page copy
- product listings and publishing-channel formatting
- public announcements
- product and service descriptions
- launch and release posts
- marketing-oriented feature summaries

Use `code-review` for normal independent review:

- correctness
- regressions
- maintainability
- compatibility
- error handling
- resource lifecycle
- meaningful test gaps

Run `adversarial-review` only for major new features, introduction of a new framework or library, or an explicit user request. Skip it for documentation-only changes, routine fixes, and minor changes unless explicitly requested. Change size, statefulness, or perceived risk alone is not a trigger. For documentation, use a proportionate accuracy/editorial check.

When that condition is met, use `adversarial-review` for deep logic challenge:

- hidden assumptions
- edge cases
- invariants
- lifecycle and ordering
- state transitions
- race conditions
- boundary conditions
- failure sequences
- negative tests
- attempts to falsify the implementation

### Security review is opt-in

Do not add a security-review stage to ordinary delivery, fixes, reviews, documentation, marketing, release readiness, or recovery. Within AgentKit, `security-review` is available for any project, but runs only when the user explicitly requests a security review. A network, filesystem, plugin, or other trust boundary does not request a review by itself.

AgentKit's `security-review` is a local, read-only specialist using its matching skill. Do not load `codex-security:*` skills, call Codex Security access/preflight/scan tools, or launch a Codex Security scan as part of this assignment. A request for a security review does not request that separate product. Only an explicit user request for a Codex Security product scan starts that separate workflow, which must follow its own access requirements. Do not treat Daybreak, Cyber, TAC access, or scan preflight as prerequisites for this local review, and do not automatically escalate findings to that product.

Report an evident defect encountered during already-authorized work within that work's scope. Its presence does not start another review stage or a scan.

## Review Responsibilities

`code-review` asks:
"Is this implementation correct, maintainable, compatible, and appropriately tested?"

`adversarial-review` asks:
"How can this implementation fail even if the normal review looks good?"

`security-review` asks:
"Can an attacker or untrusted input cross a real security boundary or gain capabilities they should not have?"

Do not substitute one review type for another.

## Normal Delivery Workflow

For substantial implementation work, use only the stages that materially apply:

1. research, when repository or external investigation is needed
2. software-architecture, when a real architectural decision is required
3. graphic-design and/or 3d-modeling, when the task needs visual or 3D assets
4. coding for application work or tech-ops for infrastructure work, as appropriate
5. code-review
6. adversarial-review, only for major new features, a new framework/library, or an explicit user request
7. the appropriate documentation specialist when behavior or public information changed
8. testing handoff for every implemented change, owned by the implementing specialist and checked by the coordinator
9. commit, push, and ready-for-review PR for repository implementation work, owned by the coordinator unless explicitly assigned

Dependent stages must run in order. Record the checkpoint that closes each prerequisite, and do not start downstream work merely because capacity is available.

Independent research or documentation preparation may run in parallel when it is required by the current milestone and does not depend on unfinished implementation details. Batch final documentation, changelog, tracker closeout, and broad acceptance work at stable milestone boundaries instead of refreshing them after every intermediate edit.

Do not invoke every specialist mechanically.

The testing handoff also applies to small root-only changes, direct specialist invocation, fixes, assets, infrastructure, and documentation edits. Follow [testing instructions and handoff](references/testing-handoff.md). The implementer supplies concrete steps and expected results; use `technical-docs` to assemble a larger developer/operator guide or `user-docs` for end-user acceptance steps when that adds value. Finalize the instructions after the last fixes and documentation updates, and include them or a direct artifact link in the final delivery. This is a required deliverable, not a requirement to spawn another agent. Review-only work retains its read-only scope.

For implementation tasks in a Git repository, commit, push, and a ready-for-review PR are part of the default definition of done. Follow [Git delivery and definition of done](references/git-delivery.md). At task start, state whether this default applies. When a higher-priority instruction requires Git mutations in an approved task-specific plan, include task-branch creation or reuse, the scoped commit, the explicit push destination, and the ready-for-review PR in that plan, then wait for the user to approve that plan. An earlier implementation request or request for those delivery steps does not satisfy this plan-approval gate. Once the user approves the task-specific plan, do not ask again. When no such gate applies, follow the default or an explicit delivery request without an extra confirmation. If a required approval was omitted, ask once for the missing boundary instead of silently stopping at local changes. The coordinator delivers the integrated result once; delegated specialists hand back their changes unless explicitly assigned Git delivery ownership. Explicit local-only/no-Git/no-remote restrictions and review, research, planning, or report-only scope take precedence. This does not include merge, deployment, release publication, or external tracker completion.

When adversarial review is required, run it independently after normal review and preserve its original findings before reconciliation. Re-review corrections affecting the qualifying feature or integration as needed; do not restart adversarial review for later documentation/changelog edits, unrelated routine fixes, or minor changes. A previously completed adversarial stage does not make it mandatory for every subsequent change.

## Review Independence

The implementation agent must not be the only reviewer of its own work.

When a reviewer reports a credible implementation defect, preserve it and send it back to the responsible `coding` or `tech-ops` specialist for correction only when fixes are authorized, then rerun relevant verification or review. For review-only work, deliver the findings and stop before source changes.

Do not silently discard reviewer findings.

## Delegation Contract

Every spawned task should include:

- Objective: one concrete outcome
- Scope: exact files, module, subsystem, or question when known
- Context: only what the agent needs
- Constraints: what must not change
- Effective policy: source paths, selected tool/identity IDs, concrete target, existing task or user authorization, account-verification results, allowed fallback, and unresolved gaps; pass only relevant non-secret details and preserve the worker's own scope restrictions. Do not require an adoption record, policy hashes, or a stored execution manifest.
- Deliverable: what the agent must return or implement
- Acceptance criteria: how success will be judged
- Progress contract: useful milestones, authorized checkpoint location or message channel, current operation, remaining scope, and explicit user deadlines/budgets if any
- Recovery context: ownership, snapshot/task/job IDs when available, completed work to preserve, and side effects that must not be repeated blindly

Prefer narrow tasks that can finish independently. Before spawning, identify the current critical-path milestone, why this result is needed now, and the prerequisite checkpoint already satisfied. Track both active agents and cumulative assignments; neither a free slot nor a completed agent is by itself a reason to create another task.

Do not send multiple writing agents to edit the same file at the same time unless the root explicitly coordinates ownership.

## Temporary And Generated Files

Use the repository-local `.work` directory for temporary, generated, intermediate, diagnostic, downloaded, extracted, and scratch artifacts whenever practical.

Do not use system-wide TEMP/TMP locations for project work when `.work` can be used instead.

Do not create multi-line reports, documentation, scripts, or other files using one enormous shell command with repeated `echo`, `printf`, or redirection. Use proper file editing/writing tools. If a shell command is unavoidable, keep individual permission-requiring commands short enough to review comfortably.

## Task Lifecycle

For all delegated work and long-running root-owned operations, read and apply [task progress, interruption, and recovery](references/task-lifecycle.md). Include the applicable progress contract in specialist assignments, including tasks with no named specialist skill. Small tasks need only a proportionate completion checkpoint.

A wait timeout means check progress, not cancel, finalize, restart, or mark failed. Quiet execution and unanswered checkpoint requests do not prove a stall. Use available evidence to distinguish running, progress unknown, blocked on input, execution failed, cancelled, partial, and completed states. User stop requests, explicit budgets/deadlines, and concrete safety concerns still apply.

Request checkpoints at useful milestones without interrupting healthy work. Preserve partial results within existing permissions, inspect side-effect outcomes before retry, and verify ownership has ended before launching a replacement writer. Resume existing work or assign only remaining scope when recovery is necessary. Do not impose fixed heartbeat requirements or infer execution deadlines from repeated waits.

When the user questions agent count, sequencing, scope, looping, or progress, freeze new spawning, inspect active and cumulative assignments, answer the concern, and restate the critical path before continuing. Do not interrupt healthy existing work unless the user asks or another authorized stopping reason applies.

## Diagrams and generated pull requests

Require Mermaid Markdown diagrams in software architecture and technical documentation when explaining structure, interactions, data flow, or lifecycle. Apply [diagram and pull-request guidance](references/diagrams-and-prs.md) to every generated PR description. Include a relevant Mermaid diagram when the change affects those relationships, and use PR Lens when available and appropriate under that guidance. Keep diagrams aligned with the final reviewed change. Create only ready-for-review PRs as part of default implementation delivery, subject to [Git delivery scope and ownership](references/git-delivery.md).

## Completion Gate

Before claiming the overall task complete, confirm:

- every required subagent was actually spawned and its actual deliverable retrieved
- material findings and coverage were accounted for, including unresolved or rejected findings and their reasons
- fixes were performed only when authorized, with appropriate verification
- checks reported as passed actually ran and passed; unverified worker claims remain labelled
- every implemented change has current, actionable testing instructions and expected results, with completed checks distinguished from remaining verification
- when Git delivery applies, the integrated changes are committed and pushed and the task PR is verified open and ready for review; report the commit, branch, and PR URL, or the explicit restriction/non-Git scope that makes those steps inapplicable
- no required work is still running, blocked, missing, or otherwise incomplete

Do not terminate a required worker to satisfy this gate. If work cannot complete, report partial results and the evidence-based status, responsible worker/task IDs, remaining scope, and next action. An explicit handoff may preserve an active task with its ownership and continuation documented; do not call that underlying work complete.

The root owns synthesis, conflict resolution, integration, and honest status reporting.

## User-Facing Reporting

Do not narrate every subagent action unless the user asks.

The final result should focus on:

- what changed
- what was verified
- how to test the delivered change, with steps and expected results or a direct link to those instructions
- the commit, pushed branch, and ready-for-review PR link when Git delivery applies, or the precise restricted/partial delivery status
- important review findings
- remaining risks or limitations

When orchestration visibility is requested, report each contributing agent's name, task ID, progress evidence, and outcome. Distinguish configured model/reasoning from runtime metadata actually verified. Disclose cancellations, replacements, missing results, and remaining coverage; do not replace requested review reports with “all findings resolved.”
