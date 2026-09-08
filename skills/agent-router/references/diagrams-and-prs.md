# Diagrams and generated pull requests

## Mermaid in Markdown

Include fenced `mermaid` diagrams in architecture analysis and technical documentation when explaining components, dependencies, data flow, interactions, or state transitions. Use flowcharts for structure, sequence diagrams for ordering, and state diagrams for lifecycle. Keep a simple prose-only explanation for changes with no meaningful relationship to diagram, such as spelling corrections.

Keep diagrams small enough to read, use real component and interface names, label important edges, and explain the takeaway in adjacent prose. Separate existing behavior, proposed behavior, and implemented changes. Include failure, retry, or recovery paths when they matter to the decision. Never invent a dependency to make a diagram look complete.

Preserve editable Mermaid source in Markdown. Check syntax with the project's available tooling and inspect rendering in the target renderer when possible; report separately when rendering was not verified. Update diagrams after implementation or review changes, and avoid unsupported renderer-specific features unless the target supports them.

## Every generated PR description

Describe the concrete problem, final behavior, and actual validation using the repository's PR template. Add a Mermaid diagram when the change affects architecture, infrastructure topology, control/data flow, lifecycle, or interactions. For a change with no useful structural or behavioral diagram, keep the description concise without a decorative diagram.

Anchor the description and diagram to the final diff and reviewed base/head. Distinguish unchanged context from added, changed, or removed behavior; rebuild visuals if the implementation changes. Include material compatibility, migration, operational, or unverified-runtime implications. A diagram is an explanation, not evidence that tests passed or a deployment succeeded.

For implemented changes, include the [testing handoff](testing-handoff.md) steps and expected results or a direct link to the finished guide. Keep recorded passes/failures separate from instructions and checks that still need to run, and update the handoff when the final diff changes.

Prepare the text and visuals within the task scope. Repository implementation requests include commit, push, and a ready-for-review PR under [Git delivery and definition of done](git-delivery.md), with one delivery owner and explicit task restrictions preserved. Create only ready-for-review PRs, never draft PRs. Standalone diagram preparation or review does not start Git delivery, and the default does not authorize unrelated comments, attachments, or external publication.

## PR Lens

[PR Lens](https://github.com/coldteadotai/pr-lens) provides architecture and data-flow visuals through a GitHub App, Action, CLI, or agent skill. Its renderer consumes a graph document and produces SVGs; it is a separate visual format from Mermaid Markdown.

When PR Lens is available and suitable for the change, follow its current installed skill or official documentation to validate and render the final diff, then include the resulting visuals with the authorized PR. Inspect component names and relationships against the code. Follow existing repository configuration and avoid duplicating a bot's output.

If it is unavailable, deliver the Mermaid diagram and report that PR Lens was not run. AgentKit does not bundle or install PR Lens, configure its GitHub App or Action, or provision provider credentials. Perform that setup only when requested. Follow the project's approved handling of source, generated assets, and external services.
