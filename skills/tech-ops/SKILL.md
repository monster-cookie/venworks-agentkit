---
name: tech-ops
description: Maintain infrastructure-as-code and environment configuration, plan and troubleshoot provisioning and CI/CD infrastructure workflows, and investigate drift using the project's actual toolchain.
---

# Tech Ops

Use this skill for infrastructure-as-code, cloud or on-premises environment configuration, provisioning plans, CI/CD infrastructure workflows, deployment plumbing, and drift troubleshooting. Work from the repository's actual toolchain and operational contracts; names such as Terraform, OpenTofu, Bicep, CloudFormation, Pulumi, Ansible, and Kubernetes are illustrative examples rather than a vendor default.

## Tooling and credential policies

Before selecting project tools or using an authenticated service, follow [tooling and credential policies](../agent-router/references/tooling-and-credentials.md). Resolve optional adopted shared and repository-root policies for this role, target, and operation; verify the required identity through the actual consuming tool. Missing policies retain existing workflow behavior. Existing but invalid or conflicting policies block affected operations, not unrelated work. Tool access and credentials do not independently authorize mutations. Direct invocation follows the same discovery rules as delegated work.

## Establish the target

- Read applicable repository instructions and identify the project toolchain, configuration roots, modules, manifests, provider or plugin pins, CI workflows, and existing operational documentation.
- Before any provider-facing operation, identify the applicable account, subscription, project, region, environment, workspace or stack, and state backend that the request concerns.
- Inspect backend configuration, state or lock conventions, variable and secret references, credentials source, environment selection, and the intended owner of each change.
- Determine whether the requested outcome is a local code/configuration change, a read or plan, an apply, an import, a state migration, a destroy, or a diagnosis of drift.
- Treat an unconfirmed target, backend, workspace, or environment as a blocker to external mutation; do not guess from a default profile or current shell context.

## Preserve infrastructure state

- Keep the existing state backend, locking behavior, provider pins, module pins, naming, dependencies, and lifecycle settings unless the request explicitly changes them.
- Inspect state and lock status before operations that may mutate shared state. Respect an active lock and determine whether it belongs to a live operation before intervening.
- Keep credentials, tokens, private values, rendered secrets, and sensitive provider output out of messages, source control, logs, and public artifacts.
- Treat generated plans, state snapshots, debug logs, and rendered manifests as potentially sensitive; store them only in an appropriately private working location and remove or protect them according to project practice.
- Make the smallest change that satisfies the requested behavior and preserve existing environment boundaries. Do not introduce a new provider, backend, module pattern, or deployment system without a demonstrated need.

## Plan and validate

- Use the repository's configured formatter, validation, lint, type, policy, and plan commands when available; do not invent a replacement toolchain.
- Local edits and validation alone do not authorize provider-backed planning. An already-authorized plan for an identified target includes the provider/backend reads and normal transient plan-lock acquisition and release required by that operation, without repetitive approval. Explicit task restrictions, including a prohibition on remote mutations, still apply; clarify a conflict before acquiring a remote lock. Plan authorization does not include apply, import, persistent state updates or migrations, destroy, force-unlock, or unrelated external-record updates.
- Distinguish refreshing provider observations for a plan from persisting refreshed state. Inspect the actual configured command and workflow for additional side effects; the word "plan" does not authorize them. Report provider access and locking separately from local validation. Preserve existing locks; normal plan authorization never permits force-unlock.
- Distinguish clearly between a proposed plan and an applied change. A successful plan does not prove that resources changed, and a successful command does not prove the target reached the desired state.
- Check dependency ordering, replacements, destructive actions, drift, missing variables, provider version changes, and output sensitivity in the plan or validation result.
- Validate generated configuration and plan artifacts without committing secrets or machine-specific state. Keep temporary artifacts in the repository-local `.work` directory when practical.
- Do not invoke Codex Security scans or automatically add a security review merely because infrastructure is involved; route security work only when the user explicitly requests it.
- Prepare the [testing handoff](../agent-router/references/testing-handoff.md) with exact target and state prerequisites, local validation, authorized plan/apply/runtime boundaries, expected observations, cleanup or recovery, and explicit executed versus not-run checks; refresh it after changes or target drift.

## Execute and recover

- Apply, import, state migration, and destroy only against the exact identified target and within the user's existing authorization. Record the command, scope, operation result, and any resulting resource or state identifiers without exposing secrets.
- Before an apply or destroy, review the resulting actions for unexpected replacements, deletions, cross-environment changes, and lock ownership. Stop when the plan contradicts the requested scope.
- If an operation returns an unknown timeout or loses its client connection, inspect provider/job status, state, locks, and destination resources before retrying. An unknown outcome is not evidence that nothing happened.
- For drift, compare the declared configuration, recorded state, provider reality, and recent operation history. Separate remediation choices such as configuration correction, refresh, import, state repair, or intentional exception.
- For state migration or lock recovery, preserve a recoverable checkpoint and follow the project's established backup and rollback procedure; never edit shared state casually.

## Handoff

Return the target and state context, the files or resources affected, the distinction between local validation and provider operations, commands or checks actually run, sensitive-artifact handling, and remaining risks or recovery steps. Include the current [testing handoff](../agent-router/references/testing-handoff.md), and state explicitly when a plan was generated but no apply occurred, or when an external result remains uncertain.

## Pull-request handoff

When preparing or creating a PR, follow [diagram and pull-request guidance](../agent-router/references/diagrams-and-prs.md) and the [Git delivery procedure](../agent-router/references/git-delivery.md): include a relevant Mermaid diagram for structural or behavioral flows and use PR Lens when available and appropriate. Keep the description and visuals aligned with the final change and actual validation. The coordinator owns Git delivery once after integration, review, and testing; a directly invoked tech-ops specialist without a coordinator owns delivery for its task; delegated tech-ops specialists return scoped work and do not independently commit, push, or open a PR unless assigned. Create only ready-for-review, non-draft PRs and honor local-only, report-only, unavailable-remote, and unresolved-check limits. A ready PR is not a merge, deployment, release, approval, or tracker completion.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

Before retrying an interrupted provider operation, inspect partial artifacts, lock ownership, job status, state, and destination resources. Honor explicit user stops and budgets, and hand back incomplete coverage and recovery state honestly; never claim an unverified apply, migration, import, or destroy succeeded.
