# Policy examples

These files are inert templates for optional AgentKit tooling and credential policies. Read the [tooling and credential policy guide](../skills/agent-router/references/tooling-and-credentials.md) before adopting one; do not use this directory as a live policy location.

## Choose a destination

Copy only the examples you need, then place the reviewed result at the matching active location.

| Example | Active destination |
| --- | --- |
| [shared-tooling-policy.example.md](shared-tooling-policy.example.md) | `$CODEX_HOME/tooling-policy.md`, or the user's `.codex/tooling-policy.md` when `CODEX_HOME` is unset |
| [shared-credential-policy.example.md](shared-credential-policy.example.md) | `$CODEX_HOME/credential-policy.md`, or the user's `.codex/credential-policy.md` when `CODEX_HOME` is unset |
| [repository-tooling-policy.example.md](repository-tooling-policy.example.md) | `<repository-root>/.codex/tooling-policy.md` |
| [repository-credential-policy.example.md](repository-credential-policy.example.md) | `<repository-root>/.codex/credential-policy.md` |

## Adopt a policy

1. Replace every `replace-with-*` placeholder with a reviewed value, remove irrelevant entries, and confirm each tool, target, operation, and fallback is supported by the environment.
2. Treat a repository entry with the same ID as a whole-entry replacement of the shared entry; repeat every required field and do not merge targets, identities, permissions, or fallback lists across files.
3. Keep credential policies limited to non-secret manager and vault/card/field references. Never add passwords, tokens, recovery codes, or other secret values to a policy or commit them to the repository.
4. Explicitly adopt the resulting file for the intended shared setup or repository before relying on it. A template's presence in this directory, a checkout, or a pull request is not adoption or authorization.
5. Verify the expected identity separately through the same consuming tool and authenticated session before a remote operation. A credential-card reference does not reauthenticate a connector; reuse a verified context when possible, use an isolated process or dedicated integration when authorized setup is required, and do not switch shared login state or silently use a personal account.

An absent `.codex` directory or absent policy file only means that no adopted repository policy was found; it is not an authentication, authorization, or security boundary. A present policy or credential reference does not grant access or authorize a mutation, and explicit task restrictions and higher-priority permissions still apply.

The installer does not install this top-level `example/` directory or activate these templates. Active policy files remain user-owned and outside the installer-managed payload, so installer updates do not overwrite them.

### Upgrading from the previous template location

A previous package version installed these templates under `skills/agent-router/references/policies`. During a normal update, unchanged managed copies are retired; locally edited retired copies cause an installer conflict, while `-Force` preserves modified retired files. Review and manually relocate any retained old copies before relying on the new separation; an update does not guarantee that every old copy is removed.

For persistent adoption across tasks, use the proposed `AGENTS.md` instruction in the [policy guide](../skills/agent-router/references/tooling-and-credentials.md) and apply it manually. AgentKit does not edit `AGENTS.md` or `AGENT-REPO-CONTEXT.md` directly.
