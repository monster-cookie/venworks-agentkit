# Release readiness

Replace the bracketed fields and paste the entire block.

```text
$agent-router

Assess release readiness for [requested Plane release work item] in the current project.

Read the Plane item and relevant linked context for the release candidate, target environments, acceptance criteria, and validation evidence.

Read project instructions and release conventions. Record candidate snapshot and artifact identities. This assessment authorizes reports under .work/release-readiness/ only. Do not fix source/docs, bump versions, build/install artifacts that write elsewhere, change Git state, publish, deploy, or mutate external records. Identify necessary unrun checks and their required authorization.

Use appropriate research, review, and documentation specialists, plus tech-ops when infrastructure readiness is in scope. Reuse verified prior reviews covering the exact candidate and review changed/missing coverage rather than mechanically repeating full scans. Apply adversarial review only for major new features, a newly introduced framework/library, or an explicit user request; release readiness alone does not trigger it. Skip documentation-only changes, routine fixes, and minor changes. Verify that claimed evidence is accessible and matches the candidate.

Assess outstanding supported findings, tests/builds/packages, platform coverage, version consistency, installation/upgrade/recovery instructions, technical/user docs, and end-user changelog accuracy. Check marketing claims against actual candidate capabilities. Classify blockers and nonblocking follow-ups against acceptance criteria.

Apply shared lifecycle guidance. Deliver readiness, candidate identity, evidence, coverage, blockers, follow-ups, and uncertainty. State ready only when required criteria have supporting evidence. Do not infer readiness from a clean working tree or absence of reported findings.
```
