# Repository tooling policy example

This inert example is a repository override for `.codex/tooling-policy.md`. Replace every `replace-with-*` value and review the targets and operation grants before configuring it. The infrastructure entry uses `dev-infrastructure` from the repository credential example; replace its identity and target details together before authorizing the standing grant. Examples document the policy contract; they do not activate runtime behavior.

Before using a configured policy-defined credential or standing grant, require explicit authorization in the current task or explicit retained user standing authorization for the unchanged operation and target, then verify the concrete target through the actual consuming tool and, when credentials are required, verify the effective account or service principal there as well. Use an isolated process or dedicated integration for authorized credential setup, do not switch shared login state or silently use a personal account, keep account and credential metadata private, and stop if the tool, identity, or target cannot be verified. This policy cannot grant external permissions or override task restrictions.

Policy-Version: 1

## Tool: infrastructure

| Field | Value |
| --- | --- |
| Service | infrastructure |
| Roles | tech-ops |
| Requirement | required |
| Tool | OpenTofu |
| Identity | dev-infrastructure |
| Target | this repository; account=replace-with-development-account; region=replace-with-region; workspace=replace-with-development-workspace; backend=replace-with-state-backend |
| Operations | standing grant when explicitly authorized and retained by the user: provider/backend reads and infrastructure plans, including normal transient plan-lock acquisition/release, only for the Target above; explicit task restrictions still apply. No apply, import, persistent state update/migration, destroy, force-unlock, or other remote mutation is authorized by this entry. |
| Fallbacks | none |

## Tool: diagrams

| Field | Value |
| --- | --- |
| Service | diagrams |
| Roles | software-architecture, technical-docs |
| Requirement | preferred |
| Tool | Mermaid fenced Markdown diagrams |
| Identity | none |
| Target | architecture and technical documentation in this repository |
| Operations | task-scoped; add or update diagrams when they clarify architecture, dependencies, data flow, or lifecycle |
| Fallbacks | none |
