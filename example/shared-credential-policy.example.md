# Shared credential policy example

This inert example is a shared default for `$CODEX_HOME/credential-policy.md`. Replace every `replace-with-*` value and review the identity references before configuring it. Never put a password, token, recovery code, or other secret in this file.

Before using a configured policy-defined credential or standing grant, require explicit authorization in the current task or explicit retained user standing authorization for the unchanged operation and target, then verify the concrete target through the actual consuming tool and the effective account or service principal through the same authenticated session. Use an isolated process or dedicated integration for authorized credential setup, do not switch shared login state or silently use a personal account, keep account and credential metadata private, and stop if the tool, identity, or target cannot be verified. This policy cannot grant external permissions or override task restrictions.

Policy-Version: 1

## Identity: github-automation

| Field | Value |
| --- | --- |
| Service | github |
| Expected identity | replace-with-github-service-account |
| Manager | replace-with-approved-password-manager |
| Reference | vault=replace-with-vault; card=replace-with-github-card; field=replace-with-credential-field |
| Authentication | Reuse an already-correct authenticated GitHub context after verifying its identity. When authorized setup is needed, supply the credential through the approved password-manager integration to an isolated process or dedicated GitHub integration for this identity; do not switch shared login state. |
| Verification | Confirm through the same authenticated GitHub session that the provider-reported account matches Expected identity before the authorized operation; stop on a mismatch. |
| Fallback | none |

## Identity: plane-automation

| Field | Value |
| --- | --- |
| Service | plane |
| Expected identity | replace-with-plane-service-account |
| Manager | replace-with-approved-password-manager |
| Reference | vault=replace-with-vault; card=replace-with-plane-card; field=replace-with-credential-field |
| Authentication | Reuse an already-correct authenticated Plane context after verifying its identity. When authorized setup is needed, supply the credential through the approved password-manager integration to an isolated process or dedicated Plane integration for this identity; do not switch shared login state. |
| Verification | Confirm through the same authenticated Plane session that the service-reported account matches Expected identity before the authorized operation; stop on a mismatch. |
| Fallback | none |
