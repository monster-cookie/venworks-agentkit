# Repository tooling policy example

This inert example is a repository override for `.codex/tooling-policy.md`. Replace every `replace-with-*` value and review the targets and operation grants before adopting it. The infrastructure entry uses `dev-infrastructure` from the repository credential example; replace its identity and target details together before adopting the standing grant. Examples document the policy contract; they do not activate runtime behavior.

Before using policy-defined credentials or standing grants, require a matching user-approved adoption baseline for the policy bytes, checkout and concrete targets, and reviewed execution evidence for any credential-bearing command or verification probe. Do not execute changed repository wrappers with credentials or proceed through an unverified named Git transport.

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
| Operations | standing grant after adoption: provider/backend reads and infrastructure plans, including normal transient plan-lock acquisition/release, only for the Target above; explicit task restrictions still apply. No apply, import, persistent state update/migration, destroy, force-unlock, or other remote mutation is authorized by this entry. |
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
