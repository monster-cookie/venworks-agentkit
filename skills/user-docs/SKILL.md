---
name: user-docs
description: Write clear end-user documentation for installation, usage, feature behavior, help content, changelogs, release notes, and compatibility guidance.
---

# User Documentation

Use this skill for readers who need to install, use, update, troubleshoot, or understand a product, tool, mod, or feature without knowing the codebase. Describe the observable behavior and the action the reader needs to take.

## Establish the user task

- Identify the audience, platform, version, task, prerequisite, and expected result. Read repository instructions and inspect the implementation, release data, existing help, and supported configuration before writing.
- Verify user-visible names, paths, commands, defaults, compatibility, limitations, and error behavior against current evidence. Do not infer a feature from an internal symbol alone.
- Preserve the project's established voice, terminology for UI and commands, document structure, and format conventions.

## Write the guidance

- Start with what changed or what the reader is trying to accomplish. Give actionable prerequisites, steps, expected results, and recovery paths in the order the user encounters them.
- Translate internal engineering language into observable outcomes. Explain a technical term only when the reader needs it to complete the task or understand a limitation.
- State important compatibility, platform, version, save-data, or feature limitations plainly. Do not promise behavior that is only a proposal, workaround, or unverified inference.
- Keep examples complete enough to use and check their paths, commands, links, and syntax. Preserve existing correct wording when only a format or small factual edit is requested.
- Edit only the requested documentation scope and use the repository-local `.work` directory for temporary documentation artifacts when practical. Do not create multiline files with giant shell commands.

## Troubleshooting

- Describe the symptom the reader sees, the most likely supported cause, and the smallest recovery action.
- Include a safe way to confirm the result, such as a visible status, version, file, log message, or repeatable command.
- Separate required steps from optional workarounds and label workarounds that have compatibility or persistence limits.
- Avoid asking the reader to inspect internal implementation details unless support genuinely requires it.
- Do not hide an unresolved limitation behind optimistic wording; state what the feature does not do and what the reader can do next.

## Verify and hand off

- Recheck every instruction against the actual current behavior and test the example or command when a safe, relevant check is available.
- Run proportionate documentation or format checks and inspect the final diff for internal jargon, broken links, unsupported claims, and accidental implementation detail.
- Return the changed document paths, validation performed, and any remaining user-facing uncertainty or compatibility gap.

## Format discipline

- Preserve the target document's heading, list, code, link, and line-break conventions.
- Keep commands, paths, menu labels, and filenames exact and visually distinct from explanatory prose.
- Use one clear action per step and put the expected result where it helps the reader recover from failure.
- Prefer a short example over an abstract explanation when the reader must copy or recognize a value.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
