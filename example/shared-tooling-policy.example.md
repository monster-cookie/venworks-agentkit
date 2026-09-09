# Shared tooling policy example

This inert example is a shared default for `$CODEX_HOME/tooling-policy.md`. Replace every `replace-with-*` value and review the allowed operations before configuring it. Examples document the policy contract; they do not activate runtime behavior.

Before using a configured policy-defined credential or standing grant, require explicit authorization in the current task or explicit retained user standing authorization for the unchanged operation and target, then verify the concrete target through the actual consuming tool and, when credentials are required, verify the effective account or service principal there as well. Use an isolated process or dedicated integration for authorized credential setup, do not switch shared login state or silently use a personal account, keep account and credential metadata private, and stop if the tool, identity, or target cannot be verified. This policy cannot grant external permissions or override task restrictions.

Policy-Version: 1

## Tool: github

| Field | Value |
| --- | --- |
| Service | github |
| Roles | all |
| Requirement | preferred |
| Tool | replace-with-approved-github-integration |
| Identity | github-automation |
| Target | repository's configured GitHub remote |
| Operations | task-scoped; use only for operations explicitly authorized by the current task |
| Fallbacks | none |

## Tool: plane

| Field | Value |
| --- | --- |
| Service | plane |
| Roles | all |
| Requirement | preferred |
| Tool | replace-with-approved-plane-integration |
| Identity | plane-automation |
| Target | repository's configured Plane workspace |
| Operations | task-scoped; use only for operations explicitly authorized by the current task |
| Fallbacks | none |
