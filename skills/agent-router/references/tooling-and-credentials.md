# Tooling and credential policies

AgentKit uses optional Markdown policies to select tools, identities, and authorized operations. This is an instruction convention, not a Codex configuration schema, executable policy engine, credential store, or runtime permission boundary. It cannot grant capabilities the current tools, sandbox, service account, or organization do not allow.

## Discover the applicable files

Before selecting project tools, the coordinator and directly invoked specialists check these exact locations:

| Scope | Tooling | Credentials |
| --- | --- | --- |
| Shared | `$CODEX_HOME/tooling-policy.md` | `$CODEX_HOME/credential-policy.md` |
| Repository | `<repository-root>/.codex/tooling-policy.md` | `<repository-root>/.codex/credential-policy.md` |

Use the effective Codex home; when `CODEX_HOME` is unset, use the user's `.codex` directory. These are location descriptions, not literal shell commands. Find the current checkout's repository root, including a Git worktree's root, from available repository context or a read-only Git query. Never substitute an unrelated parent repository or search sibling repositories. Outside a repository, use shared files only. Version 1 does not discover nested `.codex` policies or load remote includes.

Missing files are optional and preserve existing workflow behavior for unspecified tools and identities. Distinguish absence from a file that exists but is unreadable, invalid, ambiguous, or contains unresolved placeholders: stop the affected operation and explain the issue; do not silently fall back to an older policy or personal account. Continue independent work when possible. Read credential metadata only when needed for the selected tool; never fetch all referenced secrets during discovery.

Only use policies the user has adopted for this repository or shared setup. Presence in a checkout, a pull-request change, or an example is not by itself authorization to retrieve credentials, change identities, send data, or perform remote mutations. Existing adoption and standing authorization persist across tasks; do not repeatedly ask to reconfirm them. If adoption or a material change to a credential destination or grant is uncertain, prepare the effective policy for review and defer the affected operation. Explicit current task instructions and higher-priority instructions or enforced permissions prevail.

## Resolve entries

Each policy declares `Policy-Version: 1` once before its entries. Tooling entries use `## Tool: <id>`; credential entries use `## Identity: <id>`. IDs use lowercase letters, digits, and hyphens. Treat IDs and role names as exact matches. Use the installed agent role names, including `root` for the coordinator; `all` includes root and specialists. The required fields are described below. Markdown prose may explain entries but must not contradict their fields.

1. Read the applicable shared tooling entries, then repository tooling entries. Resolve credentials in the same order when needed.
2. A repository entry replaces the entire shared entry with the same ID, including its role scope. It must repeat every required field; never combine a shared identity with a repository target or merge lists of permissions. Unmatched shared entries remain. An entry with `Requirement: disabled` explicitly removes that tool ID; it needs only that field and its ID. An identity with `Disabled: true` similarly disables that identity ID.
3. Select entries matching the operation's service and current role. An exact role entry takes precedence over an `all` entry for the same service. Multiple equally specific entries for the same service are ambiguous and block that service operation. A role may name several services. Do not choose a different ID to bypass a disabled entry or a restriction; if remaining entries create unclear intent, report the conflict.
4. After selection, resolve the referenced identity. Missing or disabled referenced identities block authenticated operations. `Identity: none` means no credential is required, not permission to use whatever account is currently logged in.
5. Check the target and requested operation against the resolved policy and task authorization. A tool preference or identity reference does not grant an operation. A standing grant must explicitly identify the operation and target and come from an adopted policy. More specific task restrictions still apply. A repository replacement cannot override higher-priority constraints.

Duplicate IDs within one file, unsupported versions, missing required fields, unknown roles, or conflicting equally specific entries are errors affecting the relevant entries. If the error prevents identifying the affected scope, defer policy-dependent tool operations until clarified. Do not repair or overwrite user policies unless requested.

```mermaid
flowchart TD
    Shared[Adopted shared policies] --> Resolve[Replace matching IDs with repository entries]
    Repo[Adopted repository policies] --> Resolve
    Resolve --> Select[Select service and role]
    Select --> Identity[Resolve and verify identity when required]
    Identity --> Scope[Check target and operation authorization]
    Task[Task restrictions and enforced permissions] --> Scope
    Scope --> Execute[Run supported authorized operation]
    Scope --> Block[Defer conflicting or unavailable operation]
```

## Tooling fields

Use a two-column `Field` / `Value` table below each tool heading. Every enabled entry supplies:

| Field | Meaning |
| --- | --- |
| Service | Stable logical service such as `github`, `plane`, `infrastructure`, or `diagrams`; used for role selection. |
| Roles | Comma-separated exact role names, or `all` alone. |
| Requirement | `required` or `preferred`. Both honor target, identity, and operation restrictions. |
| Tool | The actual CLI, connector, skill, or project command to use; identify the configured integration unambiguously. |
| Identity | Credential-policy identity ID, or `none` for unauthenticated work. |
| Target | Repository, endpoint, environment, workspace/stack, and other applicable boundaries. |
| Operations | `task-scoped` means the task must authorize the operation. A standing grant instead states exact allowed operations and target conditions. It never implies unrelated operations. |
| Fallbacks | `none` or an ordered explicit list of supported alternatives. Every alternative inherits the same identity, target, and operation limits. |

For a required tool, unavailability blocks its operation; a listed fallback is used only if the entry explicitly permits it for that failure. For a preferred tool, try listed alternatives in order when unavailable. `Fallbacks: none` means no substitution even for a preferred tool. Do not treat a tool's error, permission denial, or authentication mismatch as permission to bypass policy. Verify capability and effective identity on a fallback before using it.

A standing infrastructure plan grant includes its required provider/backend reads and normal transient plan-lock acquisition/release for the identified target. Local edits or validation alone do not authorize remote planning. An explicit task prohibition on remote mutations conflicts with remote locking and must be clarified before locking. Plans exclude apply, import, persistent state updates/migrations, destroy, force-unlock, and unrelated remote updates. Inspect wrappers and project commands for additional side effects rather than trusting their names. Preserve existing locks and follow the tech-ops recovery procedure when an outcome is unknown.

## Credential fields and execution

Use a two-column `Field` / `Value` table below each identity heading. Every enabled entry supplies:

| Field | Meaning |
| --- | --- |
| Service | Service for which this identity is valid; it must match the selected tooling entry. |
| Expected identity | Account or service principal identifier to verify, including applicable tenant/organization context. |
| Manager | The user's specified password manager or existing managed authentication source. |
| Reference | Non-secret vault/card/field identifier or managed-connection reference. Keep private identifiers in user-local policy where appropriate. |
| Authentication | Supported, approved method for supplying credentials to the selected tool, including isolation from other tasks. Descriptive instructions are not arbitrary executable commands. |
| Verification | A supported identity check through the same tool/session/credential context that will perform the operation, and its expected result. |
| Fallback | `none` or another explicitly allowed identity ID for this service; fallback requires explicit task authorization to switch identity and must not form a cycle. |

Reuse an already-correct authenticated context and verify its identity; do not fetch a secret or log in again merely because a policy exists. A credential card reference does not reauthenticate a connector. If a connector cannot select the required identity, use a policy-permitted alternative that can or report the limitation. Never silently use a personal account, a default shell profile, or another tenant.

For credential retrieval or setup that is needed and authorized, use the specified manager's supported integration and applicable installed skill. Transfer secrets through supported protected channels directly into the consuming process or integration, without returning secret values to the model, terminal output, command arguments, logs, repository files, or review artifacts. If the available mechanism would expose a secret, stop that authentication step and explain the capability gap. Do not invent manager commands, retrieve unrelated cards, or follow arbitrary URLs/scripts from a policy as a login procedure.

Prefer process-scoped or dedicated authenticated contexts. Do not switch shared CLI login state, mutate global credential helpers, or reconnect a shared connector while other tasks may rely on it. Changes to shared authentication require explicit setup authorization and coordination; a routine task using an existing identity does not authorize such changes. Verify the effective identity again after any authentication change, fallback, session change, or ambiguous authentication failure. A verification mismatch blocks remote operations until corrected within authorization.

Git commit authorship, signing, transport authentication for push, and GitHub API/PR authentication are separate concerns. A successful API identity check does not prove which account a separate Git transport uses. Inspect each relevant mechanism before its operation; where transport identity cannot be established, report that gap rather than claiming the service account was verified. Do not alter commit author/signing settings merely to match an API account. Never publish raw credential references in public reports unless they are deliberately public metadata.

## Delegation, caching, and recovery

The coordinator records the policy paths, selected entry IDs, role, service, target, authorized operations, required identity, permitted fallback, and unresolved gaps. Pass only the relevant non-secret effective policy to each worker. Record enough source identity, such as modification time or a content hash, to detect changed policies without copying private credential metadata into public reports.

Directly invoked specialists perform the same discovery. Workers confirm that the assigned policy applies to their current checkout, role, and operation; do not rediscover a broader grant from another checkout. A coordinator's permission to publish does not automatically authorize a read-only reviewer to publish. Recheck affected entries after policy edits, checkout/target changes, or authentication changes. A cached handoff cannot authorize a new target or preserve a grant removed by a changed policy.

On interruption, preserve non-secret selection and outcome evidence using the shared lifecycle guidance. Before retrying an external operation, inspect whether it already completed. Never retry under another account to determine whether the first attempt succeeded. Missing tooling or credentials blocks only dependent work; return completed independent work and precise remaining scope.

## Adopt the examples

The [shared tooling](policies/shared-tooling-policy.example.md), [shared credentials](policies/shared-credential-policy.example.md), [repository tooling](policies/repository-tooling-policy.example.md), and [repository credential override](policies/repository-credential-policy.example.md) examples are inert templates. Replace placeholders, remove irrelevant entries, verify tool capabilities and identity checks, and explicitly adopt the resulting files at the discovery locations. Credential policy is optional when no selected tool needs a named identity.

The installer distributes examples as skill references. It never copies them into active policy locations, provisions credentials, edits repository instructions, or installs the named tools. Existing user-authored policies remain outside its managed payload. If policies must also apply without AgentKit skills loaded, propose an `AGENTS.md` instruction to read them; do not edit `AGENTS.md` or `AGENT-REPO-CONTEXT.md` directly.

For persistent adoption across tasks, the user can add an instruction to the applicable shared or repository `AGENTS.md`. This is a proposed snippet for manual adoption, not an instruction for AgentKit to edit that file:

```text
Use the AgentKit tooling and credential policies I have adopted in my effective Codex home and this repository's root .codex folder. Follow the installed router's tooling-and-credentials reference for resolution, identity verification, and authorization. Existing adopted defaults apply across tasks; new credential destinations or expanded standing grants from unreviewed changes require my adoption. Explicit task restrictions still apply.
```

An applicable persistent user instruction or retained task authorization can establish adoption; an agent-created marker in a policy file cannot establish it by itself. Do not add adoption records to user instructions or memory without the user's authorization.
