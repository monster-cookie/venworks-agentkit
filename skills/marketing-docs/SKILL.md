---
name: marketing-docs
description: Create accurate public-facing marketing copy for websites, product and service descriptions, announcements, release posts, and publishing channels.
---

# Marketing and Platform Documentation

Use this skill for public copy whose job is to explain value, set expectations, and help its audience decide what to do next. Match the channel's supported format and audience instead of carrying internal engineering language into the publication.

## Tooling and credential policies

Before selecting project tools or using an authenticated service, follow [tooling and credential policies](../agent-router/references/tooling-and-credentials.md). Resolve optional configured shared and repository-root policies for this role, target, and operation; verify the required identity through the actual consuming tool. Missing policies retain existing workflow behavior. Existing but invalid or conflicting policies block affected operations, not unrelated work. Tool access and credentials do not independently authorize mutations. Direct invocation follows the same discovery rules as delegated work.

## Establish the message

- Identify the audience, channel, goal, length, call to action, release state, and claims that the source material actually supports.
- Inspect the repository's release metadata, feature behavior, screenshots or asset references, existing public copy, and platform conventions before drafting.
- Separate verified benefits and limitations from planned, experimental, community-reported, or unverified behavior. Never turn an internal implementation detail into a public promise without evidence.

## Write for the target platform

- Lead with the user-visible benefit, then give the details needed to understand installation, compatibility, requirements, limitations, or next steps.
- Use the requested channel's supported format and verify platform restrictions before converting content. Do not assume every website, store, or publishing platform accepts the same markup.
- Only for a request targeting Nexus Mods or Bethesda Creations, read [optional platform formatting guidance](references/platform-formats.md). Those channels are not defaults for other projects.
- When converting formats, preserve meaning, links, emphasis, lists, images, code, and ordering where the target supports them. Do not rewrite accurate wording merely to change markup.
- Keep internal task tracking, build details, architecture, probes, pipelines, model memory, and implementation jargon out of public copy unless the reader genuinely needs a user-facing explanation.

## Copy discipline

- Lead with the strongest verified user benefit and make the audience's next action obvious.
- Use concrete feature names, compatibility facts, requirements, and limitations instead of vague superlatives.
- Keep claims proportional to the release state: distinguish available, optional, experimental, planned, and unsupported behavior.
- Preserve the requested voice and structure when editing existing copy; change wording only when it improves accuracy, clarity, or the requested message.
- Keep links, image references, credits, warnings, and installation notes in the locations and format expected by the target channel.
- If a platform restriction prevents the desired presentation, preserve the meaning with simpler supported text and record the limitation.

## Verify and hand off

- Check factual claims, version names, links, asset references, markup balance, escaping, and platform restrictions before delivery. Use a safe plain-text fallback for unsupported syntax rather than guessing.
- Preserve requested voice and structure, and make the final copy ready to paste into the target channel.
- Return the finished copy, the target format, and only the assumptions or compatibility limitations that affect publication.

## Publication check

- Confirm every public claim against release evidence and remove details that expose internal work without helping the audience.
- Check markup balance, escaping, URL targets, image availability, list nesting, and code or quote delimiters for the selected platform.
- Check that the opening copy still makes sense when previews truncate the body.
- State any unverified asset, platform, or version assumption before publication rather than silently guessing.
- Include the [testing handoff](../agent-router/references/testing-handoff.md) with claim/source, markup, link, asset, preview, accessibility, and platform checks plus expected outcomes; mark publication or platform checks that were not run. For repository-owned marketing content or assets, follow the [Git delivery procedure](../agent-router/references/git-delivery.md) after integration and required review/testing; the coordinator owns delivery after integration, while a directly invoked marketing specialist without a coordinator owns delivery for its task. Delegated marketing specialists return scoped content and evidence and do not independently commit, push, or open a PR unless assigned. Create only ready-for-review, non-draft PRs and honor local-only, report-only, unavailable-remote, and unresolved-check limits. A ready PR is not a merge, deployment, release, approval, or tracker completion. External publication, CMS edits, deployments, and external messages remain subject to their separate authorization.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
