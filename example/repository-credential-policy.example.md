# Repository credential policy example

This inert example overrides the shared `github-automation` identity and adds `dev-infrastructure` in `.codex/credential-policy.md`. Replace every `replace-with-*` value and verify the effective identity before configuring it. A repository override replaces the entire same-ID entry, so every field is repeated here; fields are not merged with the shared entry. Never put a password, token, recovery code, or other secret in this file.

Before using a configured policy-defined credential or standing grant, require explicit authorization in the current task or explicit retained user standing authorization for the unchanged operation and target, then verify the concrete target through the actual consuming tool and the effective account or service principal through the same authenticated session. Use an isolated process or dedicated integration for authorized credential setup, do not switch shared login state or silently use a personal account, keep account and credential metadata private, and stop if the tool, identity, or target cannot be verified. This policy cannot grant external permissions or override task restrictions.

Policy-Version: 1

## Identity: github-automation

| Field | Value |
| --- | --- |
| Service | github |
| Expected identity | replace-with-repository-github-service-account |
| Manager | Proton Pass via Proton Pass CLI (`pass-cli`) |
| Reference | pass://replace-with-share-id/replace-with-item-id/replace-with-field |
| Authentication | Bootstrap `pass-cli` only with the protected `PROTON_PASS_PERSONAL_ACCESS_TOKEN` environment variable supplied by local setup; it is not a Proton Pass item or policy reference. Reuse an already-correct authenticated GitHub context after verifying its identity. If authorized setup is needed, use a dedicated isolated Proton Pass CLI (`pass-cli`) process, set `PROTON_PASS_AGENT_REASON`, and use `pass-cli run` to inject the required service credential directly into the consuming process. Use `pass-cli info` to verify session health; compare a token name only if the user explicitly supplied one. Never expose the Proton Pass PAT or retrieved service credential in command arguments, logs, files, or model-visible output. Verify the same-tool GitHub identity and target before acting; do not switch shared login state. |
| Verification | Confirm through the same authenticated GitHub session that the provider-reported account matches Expected identity before the authorized operation; stop on a mismatch. |
| Fallback | none |

## Identity: dev-infrastructure

| Field | Value |
| --- | --- |
| Service | infrastructure |
| Expected identity | replace-with-development-principal in replace-with-development-account |
| Manager | Proton Pass via Proton Pass CLI (`pass-cli`) |
| Reference | pass://replace-with-share-id/replace-with-item-id/replace-with-field |
| Authentication | Bootstrap `pass-cli` only with the protected `PROTON_PASS_PERSONAL_ACCESS_TOKEN` environment variable supplied by local setup; it is not a Proton Pass item or policy reference. Reuse a verified development context when available. If authorized setup is needed, use a dedicated isolated Proton Pass CLI (`pass-cli`) process, set `PROTON_PASS_AGENT_REASON`, and use `pass-cli run` to inject the required service credential directly into the consuming OpenTofu process. Use `pass-cli info` to verify session health; compare a token name only if the user explicitly supplied one. Never expose the Proton Pass PAT or retrieved service credential in command arguments, logs, files, or model-visible output. Do not use an ambient personal profile or switch shared login state. |
| Verification | Use the configured provider's supported account/principal check in the same credential context consumed by OpenTofu; compare the principal and account with Expected identity and the tooling Target. Verify any separate backend identity before accessing that backend; stop if an identity cannot be established or the backend requires an additional undeclared credential. |
| Fallback | none |
