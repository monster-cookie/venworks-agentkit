# Reviewed adoption and execution evidence

Use this procedure before relying on policy-defined standing permissions or using a policy-named credential, including an already-authenticated session or an identity-verification probe. It supplies change-detection evidence for the [policy workflow](tooling-and-credentials.md); it is not an executable enforcement engine or a replacement for task authorization and runtime permissions.

## Store the reviewed baseline

The default adoption record is `$CODEX_HOME/policy-adoptions.json`, using the effective Codex home. It must be user-controlled and outside the current repository, its worktrees, and repository-controlled redirects. If that location lies in a checkout or resolves into one, require an alternate user-controlled location explicitly designated by the user or applicable user-level instructions. A repository policy cannot nominate its own trusted adoption record. The installer never creates, updates, or adopts this record.

Record format version 1 has `record_version: 1` and an `adoptions` array. Each adoption has a unique `id`, an `approval_reference` identifying the user's authorization of that exact snapshot, and the fields below. A boolean claiming approval, a template, or a newly generated record is not evidence of user approval. Create or update records only after the user authorizes the concrete reviewed snapshot; preserve unrelated entries. Existing authorization to record that snapshot does not require a second confirmation, but never rewrite a mismatch as an automatic repair.

| Field | Required content |
| --- | --- |
| `codex_home` | Canonical resolved absolute Codex-home path. |
| `repository_root` | Canonical resolved absolute checkout/worktree root, or `null` outside a repository. Do not infer adoption for a different clone or checkout from a matching remote name. |
| `policy_files` | Exactly four unique slots: `shared-tooling`, `shared-credentials`, `repository-tooling`, `repository-credentials`. Each supplies `slot`, logical absolute `path`, resolved absolute `resolved_path`, `state`, and `sha256`. |
| `targets` | Explicit map from logical service/target identifiers to reviewed concrete endpoints, repositories, accounts, regions, workspaces/stacks, and backends as applicable. Bind dynamic descriptions such as "configured remote" to these concrete values. |
| `executions` | Reviewed credential-bearing execution contexts where local or repository-controlled code can consume credentials, described below; use an empty array only when no such execution is adopted. |

A present slot has `state: present` and the SHA-256 of its raw file bytes. An absent slot has `state: absent`, its expected absolute `path`, and `resolved_path`/`sha256` set to `null`. Outside a repository, the two repository slots have `state: not-applicable` and all three path/hash fields set to `null`. Do not drop absent slots: creating, deleting, redirecting, or replacing a policy must change the reviewed tuple. Modification time and a Git commit are useful context but cannot replace the byte hashes; line-ending changes also require a matching reviewed baseline.

Shared policy files remain reusable across repositories; adoption records bind their use to concrete checkout and target scopes. A single user-approved setup can record several reviewed scopes. Unchanged scopes do not require per-task reconfirmation. Never copy another scope's approval merely because the policy bytes happen to match.

## Compare before using policy authority

1. Locate any applicable record and inspect all four active policy slots with credential-free filesystem/repository inspection. Do this even when a previously recorded policy is now absent. Validate record structure and scope; duplicate matches or inconsistent fields block affected policy-dependent operations.
2. Compare the current paths, resolved paths, raw-byte hashes or absence states, Codex home, checkout root, and concrete operation targets with the adopted record. Recompute evidence after checkout/configuration/policy changes and immediately before credential-bearing or standing-authorized operations; do not rely solely on a handoff's cached hash.
3. A missing, unreadable, invalid, or mismatched record cannot authorize a standing remote grant or policy-named credential use. Stop the dependent operation and prepare the changed snapshot for adoption. Do not use old shared grants, a personal account, or an alternate record to bypass the mismatch. An authenticated identity probe is also dependent credential use.
4. When all policies are absent, no applicable adoption record or prior adoption evidence exists, and the task does not require policy-defined identity/permissions, retain the existing authorized workflow. If an applicable record expected a present policy, its disappearance is a mismatch, not permission to return to defaults.
5. A retained current-task approval may authorize an exact freshly reviewed snapshot before it is persisted, but a later fresh task needs matching durable evidence. Generic persistent instructions to "use my policies" only select this procedure; they do not adopt future contents. Unrelated local inspection, documentation, and other credential-free work may continue while adoption is unresolved.

## Bind execution before exposing credentials

This applies to every authenticated service, not only infrastructure plans. Before retrieving/injecting a managed credential or invoking code that can access an existing authenticated context, establish the actual consuming execution path. Verification commands must satisfy the same rule; do not run an unreviewed wrapper with credentials to discover its identity.

An `executions` entry records `tool_id`, `identity_id`, the resolved executable, the invocation/context constraints, concrete credential destinations, and the reviewed local/repository file closure as resolved paths and raw-byte SHA-256 values. Tie it to the adoption's user approval. The closure includes relevant wrappers, imported scripts/modules, hooks, startup files, credential helpers, configuration, and inputs that can select code or destinations. Record the allowed arguments, working directory, non-secret environment controls, and executable/dependency versions or other supported integrity evidence needed to reproduce the reviewed boundary. Store references and constraints, never credential values.

Resolve aliases, PATH shims, interpreters, repository task runners, and indirect commands before execution. A hash of the top-level script alone is insufficient when it loads other code. An unchanged policy hash cannot validate a changed wrapper, hook, import, configuration file, executable resolution, or endpoint. Recheck the execution closure and context after such changes, including branch switches and dirty working-tree edits. Missing or mismatched execution evidence blocks credential-bearing execution until that current boundary is reviewed and authorized; a successful hash calculation alone does not adopt it.

Use a dedicated or process-scoped context that exposes credentials only to the reviewed consumer. Avoid unreviewed shell startup code, repository hooks, inherited environment, or subprocesses that can read the credential. If dynamic dependencies or concurrent changes prevent establishing the relevant boundary, defer that operation or use an explicitly policy-permitted trusted integration with a verifiable identity and a controlled execution path. Do not route credentials through repository code merely because it launches an approved tool.

An already user-approved installed integration may retain authentication internally; use its supported identity/capability verification without extracting its secret. Establish that its invocation is the approved integration rather than a substituted local wrapper, and revalidate when its execution/authentication context changes. Reusing logged-in state does not exempt repository-controlled code from review.

Hashes detect drift; they do not eliminate concurrent-change races or enforce a sandbox. If the inspected code/configuration can change before or during credential use and isolation cannot preserve the reviewed boundary, stop the dependent operation. Never describe this Markdown procedure as an enforced or race-proof credential boundary.

## Keep adoption separate from setup templates

An inactive record example is available with the repository's top-level setup examples. Read it only for explicit setup or example editing. Do not install it as an active record, populate approval fields on the user's behalf without authorization, or treat placeholder hashes as accepted evidence. Do not edit `AGENTS.md`, `AGENT-REPO-CONTEXT.md`, or user memory to manufacture adoption. Return a proposed record for review when active-record writes are not authorized.
