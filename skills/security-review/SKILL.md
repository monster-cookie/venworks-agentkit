---
name: security-review
description: Assess realistic attack paths across untrusted input, authentication, authorization, secrets, privilege boundaries, execution, filesystem access, and sensitive data flows.
---

# Security Review

Use this skill only when the application has a meaningful security or trust boundary. Evaluate whether an attacker or genuinely untrusted input can obtain capabilities, data, or access they should not have; do not label every crash or malformed local input a vulnerability.

## Establish the threat model

- Read applicable repository instructions and identify assets, trust boundaries, principals, attacker capabilities, deployment context, and security-relevant assumptions.
- Trace untrusted data from its source through parsing, validation, authorization, transformations, storage, logging, and security-sensitive sinks.
- Check authentication and authorization decisions, secret handling, command or process execution, filesystem paths, deserialization, plugin or executable content, network interfaces, and sensitive information exposure when present.
- Verify whether an input is actually attacker-controlled in the real workflow. For local game or modding code, ordinary installed content is not a remote hostile actor unless the deployment or distribution path makes it externally controlled.

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
