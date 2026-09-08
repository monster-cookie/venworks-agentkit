---
name: security-review
description: Perform an explicitly requested local security review of project code. Not an automatic workflow stage or a Codex Security scan.
---

# Security Review

Use this skill only when the user explicitly requests a security review. It is available for any project. Skip it during ordinary workflow stages that do not explicitly request security review. A trust boundary, serious finding, or request for general code review does not activate this skill.

AgentKit's `security-review` is a local, read-only specialist using its matching skill. Do not load `codex-security:*` skills, call Codex Security access/preflight/scan tools, or launch a Codex Security scan as part of this assignment. A request for a security review does not request that separate product. Only an explicit user request for a Codex Security product scan starts that separate workflow, which must follow its own access requirements. Do not treat Daybreak, Cyber, TAC access, or scan preflight as prerequisites for this local review, and do not automatically escalate findings to that product.

For an eligible requested review, evaluate whether an attacker or genuinely untrusted input can obtain capabilities, data, or access they should not have; do not label every crash or malformed local input a vulnerability.

## Tooling and credential policies

Before selecting project tools or using an authenticated service, follow [tooling and credential policies](../agent-router/references/tooling-and-credentials.md). Resolve optional adopted shared and repository-root policies for this role, target, and operation; verify the required identity through the actual consuming tool. Missing policies retain existing workflow behavior. Existing but invalid or conflicting policies block affected operations, not unrelated work. Tool access and credentials do not independently authorize mutations. Direct invocation follows the same discovery rules as delegated work.

## Establish the threat model

- Read applicable repository instructions and identify assets, trust boundaries, principals, attacker capabilities, deployment context, and security-relevant assumptions.
- Trace untrusted data from its source through parsing, validation, authorization, transformations, storage, logging, and security-sensitive sinks.
- Check authentication and authorization decisions, secret handling, command or process execution, filesystem paths, deserialization, plugin or executable content, network interfaces, and sensitive information exposure when present.
- Verify whether an input is actually attacker-controlled in the real workflow. Distinguish trusted local configuration and installed extensions from attacker-controlled input using the actual deployment and distribution model.

## Validate findings

- Prefer a concrete attack path over a keyword match. Describe the prerequisite, controllable input, missing or bypassed control, reachable capability, and impact.
- Consider canonicalization, encoding, path resolution, privilege changes, confused deputy behavior, secret lifetime, error disclosure, and cross-component assumptions where they affect exploitability.
- Calibrate severity to realistic reachability and impact. Distinguish a security issue from a reliability defect, denial of service without an attacker-controlled boundary, or theoretical concern.
- Do not manufacture findings to make the review comprehensive. Record meaningful uncertainty and the evidence needed to resolve it.

## Boundary checklist

- Identify where data enters from a user, network, file, plugin, dependency, process, or another privilege level.
- Verify validation occurs before parsing assumptions, authorization decisions, sensitive writes, or execution.
- Check whether canonical paths, identities, encodings, and permissions remain stable across trust boundaries.
- Check secrets in source, logs, errors, temporary files, process arguments, caches, and telemetry.
- Check least privilege and whether a component can act as a confused deputy for another principal.
- Check failure and recovery paths for bypassed authorization, stale credentials, partial writes, or unsafe defaults.
- Treat mitigations as effective only when the code path actually reaches them under the attack sequence.

## Report and hand off

- For every real finding, provide severity, attacker prerequisites, concrete attack path, affected component, impact, evidence, and remediation direction.
- Keep the review read-only and use the repository-local `.work` directory for temporary analysis or safe probes when practical.
- If no reportable vulnerability is supported, say so clearly and list the security-relevant surfaces examined plus any validation limits.

## Severity and evidence

- Tie severity to the affected asset, attacker reach, required privileges, exploit reliability, and practical impact.
- Explain what an attacker gains and what prerequisite prevents broader exploitation.
- Cite the source-to-sink path and the missing or ineffective control precisely enough to reproduce the reasoning.
- Recommend a remediation direction that closes the boundary without hiding the issue behind unrelated hardening.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
