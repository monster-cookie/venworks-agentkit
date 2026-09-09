# Repository credential policy example

This inert example overrides the shared `github-automation` identity and adds `dev-infrastructure` in `.codex/credential-policy.md`. Replace every `replace-with-*` value and verify the effective identity before configuring it. A repository override replaces the entire same-ID entry, so every field is repeated here; fields are not merged with the shared entry. Never put a password, token, recovery code, or other secret in this file.

Before using a configured policy-defined credential or standing grant, require explicit authorization in the current task or explicit retained user standing authorization for the unchanged operation and target, then verify the concrete target through the actual consuming tool and the effective account or service principal through the same authenticated session. Use an isolated process or dedicated integration for authorized credential setup, do not switch shared login state or silently use a personal account, keep account and credential metadata private, and stop if the tool, identity, or target cannot be verified. This policy cannot grant external permissions or override task restrictions.

Policy-Version: 1

## Identity: github-automation

| Field | Value |
| --- | --- |
| Service | github |
| Expected identity | replace-with-repository-github-service-account |
| Manager | replace-with-repository-password-manager |
| Reference | vault=replace-with-repository-vault; card=replace-with-repository-github-card; field=replace-with-repository-credential-field |
| Authentication | Reuse an already-correct authenticated GitHub context after verifying its identity. When authorized setup is needed, supply the credential through the approved password-manager integration to an isolated process or dedicated GitHub integration for this repository identity; do not switch shared login state. |
| Verification | Confirm through the same authenticated GitHub session that the provider-reported account matches Expected identity before the authorized operation; stop on a mismatch. |
| Fallback | none |

## Identity: dev-infrastructure

| Field | Value |
| --- | --- |
| Service | infrastructure |
| Expected identity | replace-with-development-principal in replace-with-development-account |
| Manager | replace-with-approved-password-manager-or-managed-auth-source |
| Reference | replace-with-development-vault-card-field-or-managed-connection-reference |
| Authentication | Reuse a verified development context when available. If authorized setup is needed, use the configured provider's supported protected credential channel in an isolated process or dedicated context; do not use an ambient personal profile or switch shared login state. |
| Verification | Use the configured provider's supported account/principal check in the same credential context consumed by OpenTofu; compare the principal and account with Expected identity and the tooling Target. Verify any separate backend identity before accessing that backend; stop if an identity cannot be established or the backend requires an additional undeclared credential. |
| Fallback | none |
