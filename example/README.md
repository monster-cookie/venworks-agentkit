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
| [policy-adoption-record.example.json](policy-adoption-record.example.json) | `$CODEX_HOME/policy-adoptions.json`, or the user's `.codex/policy-adoptions.json` when `CODEX_HOME` is unset; keep this record outside the repository and its worktrees |

## Adopt a policy

1. Replace every `replace-with-*` placeholder with a reviewed value, remove irrelevant entries, and confirm each tool, target, operation, and fallback is supported by the environment.
2. Treat a repository entry with the same ID as a whole-entry replacement of the shared entry; repeat every required field and do not merge targets, identities, permissions, or fallback lists across files.
3. Keep credential policies limited to non-secret manager and vault/card/field references. Never add passwords, tokens, recovery codes, or other secret values to a policy or commit them to the repository.
4. Explicitly adopt the resulting file for the intended shared setup or repository before relying on it. A template's presence in this directory, a checkout, or a pull request is not adoption or authorization.
5. Verify the expected identity separately through the same consuming tool and authenticated session only after the applicable adoption record and reviewed execution boundary match; this gate also applies to reusing ambient logged-in state and to identity probes. A credential-card reference does not reauthenticate a connector; reuse only a reviewed context when possible, use an isolated process or dedicated integration when authorized setup is required, and do not switch shared login state or silently use a personal account.

## Record reviewed adoption

The [policy-adoption-record.example.json](policy-adoption-record.example.json) is an inactive record template, not a policy file and not an installer input. Read the [reviewed adoption and execution evidence guide](../skills/agent-router/references/policy-adoption.md), then prepare the active record only at the user-controlled location shown in the table after the user authorizes the exact reviewed snapshot.

1. Replace the synthetic paths, target values, execution details, and placeholder hashes only after the concrete policy snapshot and execution boundary have been reviewed. `approval_reference` must identify that user authorization; a generated record, an approval boolean, or a self-asserted field is not evidence.
2. Keep exactly four policy slots in every record: shared tooling, shared credentials, repository tooling, and repository credentials. Record `present` slots with raw-byte SHA-256 values, `absent` slots with `resolved_path` and `sha256` set to `null`, and `not-applicable` repository slots when outside a repository; do not omit a slot.
3. Bind each operation to a concrete Codex home, checkout/worktree root, endpoint, repository, account, region, workspace/stack, or backend as applicable. A description such as “configured remote” is incomplete until the record supplies the reviewed concrete target.
4. Before retrieving or injecting a credential, reusing an ambient logged-in context, or running an identity probe, require a matching adoption record and reviewed execution boundary for the actual consuming path. Record the consuming tool, identity, resolved executable, invocation and context constraints, protected credential destination, working directory, allowed arguments, non-secret environment controls, and the resolved file closure with raw-byte hashes for wrappers, imports, hooks, configuration, and other code that can select a destination.
5. A fresh task needs matching durable evidence for a standing grant or policy-named credential. A new grant or any path, hash, target, policy, execution-context, or identity mismatch stops the dependent authentication or standing operation until the changed snapshot is reviewed and adopted; unrelated credential-free work can continue.
6. When all policies are absent, no adoption evidence exists, and the task does not require policy-defined identity or permissions, the existing authorized workflow can continue. An adoption record that expected a policy to be present is a mismatch, and absent policies do not blanket-block unrelated work.
7. A verified GitHub API identity does not establish the identity used by Git transport. Inspect the push transport separately and stop the push when its effective identity cannot be established.

The example record contains two shared present slots, a present repository-tooling slot, and an absent repository-credentials slot to illustrate explicit absence. Its synthetic hashes are not approval evidence, and the record must stay outside the repository, worktrees, repository-controlled redirects, and installer-managed files.

An absent `.codex` directory or absent policy file only means that no adopted repository policy was found; it is not an authentication, authorization, or security boundary. A present policy or credential reference does not grant access or authorize a mutation, and explicit task restrictions and higher-priority permissions still apply.

The installer does not install this top-level `example/` directory, activate these templates, or discover, create, update, or adopt `policy-adoptions.json`. Active policy files and adoption records remain user-owned and outside the installer-managed payload, so installer updates do not overwrite them.

### Upgrading from the previous template location

A previous package version installed these templates under `skills/agent-router/references/policies`. During a normal update, unchanged managed copies are retired; locally edited retired copies cause an installer conflict, while `-Force` preserves modified retired files. Review and manually relocate any retained old copies before relying on the new separation; an update does not guarantee that every old copy is removed.

For persistent adoption across tasks, use the proposed `AGENTS.md` instruction in the [policy guide](../skills/agent-router/references/tooling-and-credentials.md) and apply it manually. AgentKit does not edit `AGENTS.md` or `AGENT-REPO-CONTEXT.md` directly.
