# Testing AgentKit

Run these commands from the repository root on Windows with PowerShell 7 and Git available. The installer suite exercises packaging and installation. The Git harness exercises concrete delivery mechanics in local repositories; its isolation regression runs that harness with both a clean environment and an inherited template containing a harmless rejecting hook. These tests do not enforce the Markdown instructions or prove that every agent follows them.

```powershell
pwsh -NoProfile -File .\tests\Test-Installer.ps1
pwsh -NoProfile -File .\tests\Test-GitDeliveryIsolation.ps1
git diff --check
```

Expected: both commands exit 0 and print `PASS` for every reported check. The isolation regression must pass both complete Git harness variants without executing the inherited hook, creating its execution sentinel, or copying its active receive-hook file; the deliberate hook-mutation case in the harness must still pass. The whitespace check exits 0 without whitespace errors. Git may print informational LF/CRLF conversion notices on Windows. A nonzero exit or failed assertion is a failure, not a completed acceptance check.

Both suites create unique disposable folders and logs beneath `.work` and print their locations. The Git harness uses a local bare remote, synthetic identity, isolated Git configuration, and a known empty template directory for repository creation. It does not publish to GitHub or change a live Codex home or the user's templates. Maintained test scripts belong in Git; the generated `.work` fixtures do not. To run the Git mechanics once without the additional inherited-template variant, use `pwsh -NoProfile -File .\tests\Test-GitDelivery.ps1`.

## Git delivery regressions

The [delivery procedure](../skills/agent-router/references/git-delivery.md) requires reviewing both candidate contents and publishable history. The Git suite tests representative mechanisms for doing that, with negative controls for unsafe shortcuts.

| Case | Required observable result |
| --- | --- |
| Clean index and task-only history | Ordinary delivery succeeds and a fresh checkout contains the intended result. |
| Unrelated earlier commit, including one followed by its revert | Unrelated commit IDs are absent from delivered history even when their net diff is empty. Starting another branch from the same contaminated HEAD is insufficient. |
| Unrelated staged file, rename, or deletion | The task commit excludes them and the original index and files remain intact. |
| Task and unrelated staged/unstaged edits in one file | Only the reviewed task patch enters the candidate. Whole-file copying or path-limited commits must not consume unrelated hunks. |
| Release/development base or stacked parent PR | The branch derives from the intended base and the selected base/head metadata identifies that target. Metadata assertions are not a real hosted PR test. |
| Required maintained golden file and disposable test output | The golden file is committed, disposable output is excluded, and its consumer passes in a fresh checkout. |
| Destination or base advances after inspection | Stale comparison evidence does not authorize publication; the changed state is inspected again. |
| Commit hook changes the candidate | The actual commit is checked against the reviewed result and affected checks must be refreshed. |
| Calling process supplies a Git template with a rejecting receive hook | The isolation regression runs the same unchanged harness successfully, with no inherited hook marker, execution sentinel, or copied active receive-hook file. Deliberately configured fixture hooks still execute. |

## Fresh-agent acceptance

Use a separate disposable repository and an already-authorized test environment. Load the current delivery reference into a new agent task. Explicitly restrict remote operations to a local bare repository and replace GitHub PR creation with a local JSON record of the intended base, head branch, commit, and `draft: false`. This substitution tests local behavior and request selection, not GitHub integration or installation into a live Codex home.

1. Create and commit a baseline with a small behavior file, a maintained expected-output fixture, and a test comparing the two. Create a release branch that differs from the default branch and push those baseline branches to the local bare remote.
2. Start a task branch from the release base. Add an unrelated commit and revert it. In the behavior file, stage an unrelated edit near the beginning, then make a separate unrelated unstaged edit near the end. Record HEAD, `git ls-files --stage`, file contents, and `git status --porcelain=v1` before handing over the task.
3. Ask the new agent to change the behavior in a separate part of that file, keep regression checks passing, preserve existing user work, and deliver against the release branch. Give it the task and current shared procedure, without a repair recipe or expected Git commands.
4. Independently inspect the pushed history and tree, compare the original checkout with the recorded state, and run the regression test in a new clone of the delivered branch. Expect only intended task history above the release base, the required fixture in the commit, and unchanged unrelated staged/unstaged work. Verify the captured PR base, head, commit, and ready status.
5. Record the guidance revision or hashes, agent assignment, actual commands/results, and limitations. A successful controlled run is evidence for that case; it is not a guarantee across agents, installations, or hosted services.

## Image-selection acceptance

Read the current [image tool boundary](../skills/graphic-design/SKILL.md#image-model-and-tool-boundary). In a fresh task, supply each capability case below explicitly as synthetic input and request a dry-run decision. Do not use live credentials or generate images just to exercise these decisions.

| Synthetic capability case | Expected decision |
| --- | --- |
| Native tool has no model selector or backend identity; exact model is a preference | Use the native path when appropriate and disclose that the requested backend cannot be selected or verified. |
| Official catalog documents the requested ID but the account does not expose it | Report the account limitation; do not declare the ID nonexistent or silently substitute another model. |
| Account and endpoint support the model but the wrapper rejects a requested quality option | Report the wrapper/option limitation; do not bypass its validator, silently lower quality, or modify the installed wrapper. |
| Authorized tool, endpoint, options, and account support the selection; no execution yet | The requested selection can be prepared. Do not claim that the backend executed before a successful operation and runtime evidence. |
| Exact model execution is required but native backend is unidentified | Defer that execution and complete independent preparation within scope. |

Record original agent decisions before reconciliation. These cases test interpretation of instructions using supplied capability evidence; they do not verify live account access, image quality, SDK compatibility, or the native tool's backend identity.

## Cleanup

No cleanup is needed before rerunning the suites. Retain the printed fixture directories while investigating failures or reviewing evidence. To remove completed test output, first resolve the exact task-created directory, verify it is beneath this repository's `.work` folder, and inspect it for unsaved results or registered worktrees. Remove only that directory using native PowerShell operations, unregistering any task-created worktree through Git first. Never delete the entire `.work` folder or follow a junction into a live installation as part of test cleanup.
