# Testing instructions and handoff

Every implemented change must ship with instructions that let another person verify the delivered result. Apply this to application code, configuration, infrastructure, assets, documentation, and small fixes, including direct specialist and root-only work. Scale the instructions to the change: a small edit can use a few steps in the final response; a larger change can use the project's existing testing guide or an authorized task artifact linked from the final response. Do not create a permanent file or new test suite merely to satisfy this phase.

## Ownership and timing

The implementing specialist drafts the checks from the requirements and actual final behavior. The coordinator ensures all changed areas are covered and consolidates overlapping steps. Use `technical-docs` for substantial developer/operator instructions or `user-docs` for end-user acceptance steps when useful; the implementer remains responsible for technical accuracy. Required reviewers check meaningful verification gaps within their existing scope. A separate testing agent is not required.

Prepare checks while implementing, then refresh the handoff after the final fixes, documentation changes, or relevant snapshot changes. Tie any recorded result to the revision, dirty working-tree state, artifact, or environment actually checked. If recovery or subsequent changes make a result stale, label it and rerun only the affected checks when authorized.

## Required content

Include enough concrete detail for a reader who did not follow the task:

1. **Scope and prerequisites:** Identify the change and candidate being tested, working directory, required tools/versions, build or installation steps, configuration, representative inputs, and target platform/environment where relevant. Reference required credentials without exposing their values. Distinguish disposable fixtures from persistent or shared data.
2. **Steps and expected results:** Give ordered commands or UI/manual actions using the project's actual shell and tools. State the observable result or pass/fail criterion for each check. Include the changed behavior and proportionate nearby regression, negative, or boundary checks where applicable. For a bug fix, show how to exercise the original failure and the corrected outcome. Do not substitute “run tests” or “verify it works” for runnable instructions.
3. **Cleanup and recovery:** When a check changes state, explain how to remove task-created fixtures or restore the specific prior state safely. Identify consequential steps that still need authorization. Do not provide broad destructive cleanup commands or treat a test procedure as permission to deploy, apply infrastructure, publish, or mutate external records.
4. **Execution evidence and remaining checks:** Separately label checks actually run as passed or failed, with the command/action, relevant output or evidence, and environment. Mark unrun checks as not run and explain the missing tool, access, platform, or other constraint. Distinguish static/source checks, automated tests, builds/packages, runtime checks, and target-platform acceptance. Instructions alone are never proof of a pass.

Omit inapplicable detail instead of manufacturing setup or edge cases. For a wording-only change, concrete proofreading, link, or rendering steps and expected results can be sufficient. For creative assets, include opening the delivered source/export and relevant dimensions, scale, appearance, or consumer integration checks. For infrastructure, distinguish local validation from an authorized remote plan and from apply or runtime verification.

Use verified command names and paths. If an environment-specific value is unavailable, identify the exact input the reader must supply and label the procedure unverified; do not invent credentials, commands, test names, selectors, or a successful result. Keep instructions within the task's authorization and tooling/credential policies. Continue to execute authorized, available checks that the task requires; writing a guide does not replace that work.

## Compact handoff format

Adapt this shape to the project's existing documentation rather than forcing a new report:

```markdown
Testing instructions for <change and candidate>

Prerequisites: <working directory, tools, setup, inputs, target>

1. <Command or manual action>. Expected: <observable result>.
2. <Relevant regression or failure-path check>. Expected: <observable result>.

Cleanup: <specific task-created state to remove or restore, if needed>.

Executed: <check, environment, passed/failed, evidence>.
Not run: <remaining check, reason, and how to run it>.
```

The final response includes these instructions or a direct link to the finished guide, plus material unverified checks. Include the steps or guide link alongside actual validation evidence in the PR required by [default Git delivery](git-delivery.md), unless the task explicitly restricts that delivery or it does not apply. Use a guide accessible to PR readers; a local-only scratch path is insufficient. Read-only reviews and release-readiness assessments evaluate existing instructions and can recommend missing checks in their report; they do not gain implementation or execution permission from this reference.
