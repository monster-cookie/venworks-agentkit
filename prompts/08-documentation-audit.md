# Documentation audit

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Audit and update documentation for [requested Plane work item] in the current project.

Read the Plane item and relevant linked context for the implementation baseline, document scope, audiences, priorities, and acceptance criteria.

Read project instructions and inventory selected documentation and implementation contracts. Distinguish shipped from unreleased/planned behavior. Plan before edits. This authorizes named documentation, previews/check outputs in project-authorized locations, and reports. After the scoped documentation edits and required checks are complete, follow the `git-delivery.md` procedure from the loaded `$agent-router` skill: by default, commit the scoped changes, push to the intended origin or delivery remote, and open or update a ready-for-review, non-draft pull request. Explicit local-only, report-only, review-only, unavailable remote, or unresolved required-check limits prevail and stop that delivery step when applicable. Do not change production code or configuration. Other publication, merge, deployment, release, and external-record updates still require authorization unless already granted.

Use technical-docs for engineering material and user-docs for end-user instructions. Use research/technical review to resolve implementation questions. Have specialists load matching skills and lifecycle guidance. Assign separate ownership if parallel and maintain consistent terminology.

Compare commands, APIs, defaults, examples, compatibility, installation/upgrade procedures, and troubleshooting against evidence. Correct drift and omissions while preserving accurate detail and style. Execute examples only when safe and authorized; distinguish inspected examples from executed ones. Check links/references and preview affected formats where tooling permits.

For documentation changes, provide testing instructions following the `testing-handoff.md` reference from the loaded `$agent-router` skill, with copyable example, link, format, and render checks, expected reader-visible outcomes, and explicit executed versus not-run evidence; refresh them after the final documentation edits.

Obtain an independent accuracy pass against implementation and resolve supported documentation findings. Report implementation defects separately instead of changing code to fit prose. Update the existing changelog only when conventions call for noting documentation corrections; do not invent behavior changes or release status.

Do not run adversarial review for this documentation-only assignment unless the user explicitly requests it. Use a proportionate accuracy/editorial check.

Deliver document paths, coverage/gaps, important corrected claims, actual example/link/render checks, review findings/disposition, and unresolved source behavior.
```
