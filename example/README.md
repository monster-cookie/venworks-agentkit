# Policy examples

These files are inert templates for optional AgentKit tooling and credential policies. Read the [tooling and credential policy guide](../skills/agent-router/references/tooling-and-credentials.md) before configuring one; do not use this directory as a live policy location.

The installer excludes this directory and leaves your configured policy files untouched.

## Choose a destination

Copy only the examples you need, then place the reviewed result at the matching active location.

| Example | Active destination |
| --- | --- |
| [shared-tooling-policy.example.md](shared-tooling-policy.example.md) | `$CODEX_HOME/tooling-policy.md`, or the user's `.codex/tooling-policy.md` when `CODEX_HOME` is unset |
| [shared-credential-policy.example.md](shared-credential-policy.example.md) | `$CODEX_HOME/credential-policy.md`, or the user's `.codex/credential-policy.md` when `CODEX_HOME` is unset |
| [repository-tooling-policy.example.md](repository-tooling-policy.example.md) | `<repository-root>/.codex/tooling-policy.md` |
| [repository-credential-policy.example.md](repository-credential-policy.example.md) | `<repository-root>/.codex/credential-policy.md` |

## Configure a policy

1. Replace every `replace-with-*` placeholder with a reviewed value, remove irrelevant entries, and confirm each tool, target, operation, and fallback is supported by the environment.
2. Treat a repository entry with the same ID as a whole-entry replacement of the shared entry; repeat every required field and do not merge targets, identities, permissions, or fallback lists across files.
3. Keep credential policies limited to non-secret manager and vault/card/field references. Never add passwords, tokens, recovery codes, or other secret values to a policy or commit them to the repository.
4. Use a configured policy only when the current task explicitly authorizes the operation or the user has explicitly retained standing authorization for that unchanged operation and target. A template's presence in this directory, a checkout, or a pull request is not authorization.
5. Verify the concrete target through the actual consuming tool before the authorized operation; when credentials are required, verify the expected account or service principal through that tool and authenticated session as well. A credential-card reference does not reauthenticate a connector; reuse an already-correct context only after verification, use an isolated process or dedicated integration when authorized setup is needed, and do not switch shared login state or silently use a personal account.

A policy file cannot grant external permissions, create credentials, select an account without verification, or override current-task restrictions and higher-priority permissions. Keep account and credential metadata private, including in reports and examples. If the tool, effective identity, or target cannot be verified, stop the affected operation while unrelated credential-free work can continue.

### Upgrading from the previous template location

A previous package version installed these templates under `skills/agent-router/references/policies`. During a normal update, unchanged managed copies are retired; locally edited retired copies cause an installer conflict, while `-Force` preserves modified retired files. Review and manually relocate any retained old copies before relying on the new separation; an update does not guarantee that every old copy is removed.

For explicit retained user standing authorization across tasks, the user can add an instruction to the applicable `AGENTS.md` that names the active policies and limits the standing authorization to the explicitly retained operations and targets. Apply that instruction manually; AgentKit does not edit `AGENTS.md` or `AGENT-REPO-CONTEXT.md` directly.
