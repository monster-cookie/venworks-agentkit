---
name: graphic-design
description: Design visual assets, UI visual direction, branding, icons, logos, graphics, layouts, and image-generation concepts using available design tools.
---

# Graphic Design

Use this skill for visual asset creation, adaptation, review, art direction, UI visual design, branding, icons, logos, layouts, or image-generation concepts. The result should be a usable asset or an implementation-ready specification whose visual and technical constraints are explicit.

## Tooling and credential policies

Before selecting project tools or using an authenticated service, follow [tooling and credential policies](../agent-router/references/tooling-and-credentials.md). Resolve optional adopted shared and repository-root policies for this role, target, and operation; verify the required identity through the actual consuming tool. Missing policies retain existing workflow behavior. Existing but invalid or conflicting policies block affected operations, not unrelated work. Tool access and credentials do not independently authorize mutations. Direct invocation follows the same discovery rules as delegated work.

## Establish the visual objective

- Determine the audience, purpose, usage context, destination surface, dimensions, aspect ratio, color mode, transparency, and required output format.
- Identify whether the request is to create, revise, extend, compare, or specify an asset, and preserve the requested scope.
- Inspect existing brand guidance, visual assets, UI patterns, typography, color tokens, and neighboring artwork before introducing a new direction.
- Identify required variants, responsive or multi-size behavior, localization space, accessibility needs, and protected areas when the destination requires them.

## Design the direction

- Maintain visual consistency when extending an existing product, service, or brand. Reuse established visual language before introducing a new style.
- Consider hierarchy, typography, spacing, contrast, composition, balance, legibility, accessibility, and recognition at the smallest required size.
- Choose shapes, color, type, imagery, and effects that support the audience and usage context rather than decoration alone.
- For application or game assets, account for the actual platform constraints: supported dimensions, file format, alpha behavior, scaling, performance, and integration surface.
- When a design decision is uncertain, state the assumption and provide the smallest useful alternative rather than inventing an undocumented platform rule.

## Produce or specify

- Use image-generation, SVG, graphics, or other configured design tools when they are available and appropriate for the requested output.
- Preserve editable source structure and source assets when the workflow supports them; keep layers, naming, dimensions, and export settings understandable to the maintainer.
- If direct visual generation or editing is unavailable, produce an implementation-ready design specification with dimensions, layout, colors, typography, asset references, variants, and acceptance criteria.
- Do not claim to have generated, edited, rendered, or exported a binary visual asset unless an appropriate tool actually completed that operation.
- Use the repository-local `.work` directory for temporary visual references and intermediate artifacts when practical, and keep final assets within the authorized target paths.

## Image model and tool boundary

The reasoning model for this specialist is separate from the image-generation backend. When available, prefer the native `image_gen.imagegen` tool for raster work, and preserve SVG or other vector-native editing when that is the better fit for the requested output. Select an image backend only when the active tool exposes model selection, and identify the backend only when runtime metadata verifies it; if neither is exposed, report that limitation rather than setting up an API, credentials, or a fallback solely to choose a model.

When an already-authorized image tool or API exposes model selection, verify the requested ID against the current official model catalog and establish support in that endpoint, the active tool/SDK and its accepted options, and the configured account. A model's public documentation establishes that it exists; it does not establish access through every account or wrapper. Bundled references and wrapper validators can lag the catalog, so do not treat an older list as proof that a newer documented ID is invalid, or bypass a wrapper's unsupported options.

When those checks establish support, prefer [`gpt-image-2.5-flare`](https://developers.openai.com/api/docs/models/gpt-image-2.5-flare) for fast, high-quality everyday generation and [`gpt-image-2.5-sunburst`](https://developers.openai.com/api/docs/models/gpt-image-2.5-sunburst) when editing precision matters most, following the current [image-generation guidance](https://developers.openai.com/api/docs/guides/image-generation). If the requested selection or options are unavailable or cannot be verified, state the specific limitation; do not silently substitute another model or claim the requested backend ran. Use the native tool when appropriate under the existing tool boundary, reporting an unverified backend when it exposes no selector or identity. If verified execution on an exact model is a task requirement, an unidentified native backend cannot satisfy it; defer that execution and complete independent preparation within scope. Distinguish a supported/requested selection from runtime metadata confirming which model actually executed. This guidance does not authorize API setup, credential changes, or changes to an installed wrapper solely to choose a model.

## Verify the result

- Inspect the final composition at the target size and at a representative smaller size when scaling or responsive use matters.
- Check contrast, text legibility, alignment, protected regions, transparency, crop behavior, file format, dimensions, and naming against the destination requirements.
- Confirm that referenced fonts, images, icons, and source files exist or clearly mark them as required inputs.
- Report what was visually or technically checked, what tool produced the result, and which visual or platform behaviors remain unverified.
- Return the [testing handoff](../agent-router/references/testing-handoff.md) with steps to inspect the editable source and export at the target and representative sizes, expected visual or technical outcomes, cleanup for temporary assets, and explicit checks run or not run. For repository-owned asset changes, follow the [Git delivery procedure](../agent-router/references/git-delivery.md) after integration and required review/testing; the coordinator owns delivery after integration, while a directly invoked designer without a coordinator owns delivery for its task. Delegated designers return scoped assets and evidence and do not independently commit, push, or open a PR unless assigned. Create only ready-for-review, non-draft PRs and honor local-only, report-only, unavailable-remote, and unresolved-check limits. A ready PR is not a merge, deployment, release, approval, or tracker completion.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve editable checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not the operation's execution deadline. Continue healthy work; honor explicit user stops and budgets. Before retrying an interrupted render or generation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified visual operation succeeded.
