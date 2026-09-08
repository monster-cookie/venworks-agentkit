---
name: adversarial-review
description: Challenge major new features or newly introduced frameworks/libraries, or perform an explicitly requested adversarial review. Not a default review for documentation, routine fixes, or minor changes.
---

# Adversarial Review

Use this skill only for major new features, introduction of a new framework or library, or an explicit user request. Skip documentation-only changes, routine fixes, and minor changes unless explicitly requested; size, statefulness, or perceived risk alone does not qualify. If delegated outside this scope, report that adversarial review is unnecessary rather than performing it. For qualifying work, this review complements normal review by searching for hidden failure sequences.

Follow-up review should address corrections affecting the qualifying feature or integration. Later documentation/changelog edits or unrelated routine changes do not restart this stage.

## Define what should hold

- Read the request, applicable repository instructions, changed code, adjacent consumers, and existing tests.
- State the important invariants, preconditions, postconditions, ownership rules, and state transitions implied by the implementation.
- Identify assumptions about timing, ordering, retries, persistence, cleanup, input shape, platform behavior, and backward compatibility.
- Separate evidence from hypotheses. A plausible concern becomes a finding only when the code or a focused probe supports a concrete failure path.

## Try to break it

- Walk sequences that include first use, repeated use, cancellation, retry, partial completion, restart, stale state, failure during cleanup, and recovery after interruption where relevant.
- Challenge empty, missing, malformed, duplicate, boundary, oversized, reordered, delayed, and unexpected inputs. Check off-by-one conditions and transitions at limits.
- Examine concurrency and reentrancy: races, lock or ownership gaps, duplicate callbacks, interleaved updates, and assumptions that an operation is serialized.
- Compare old and new behavior for compatibility, migration, version skew, and callers that were not updated with the change.
- Check whether tests exercise the invariant and failure mode or merely reproduce the implementation's current shape.
- Keep security findings in scope only when the failure crosses a genuine trust boundary; route a security-specific concern to security review when needed.

## Scenario matrix

- Check the first invocation, the second invocation, and repeated invocation after a successful result.
- Check interruption before, during, and after each externally visible side effect.
- Check retries after timeout, partial completion, stale state, and a changed dependency or version.
- Check empty, duplicate, reordered, truncated, maximum, and one-past-maximum inputs.
- Check concurrent callers, duplicate callbacks, reentrancy, and cleanup racing with use when applicable.
- Check rollback, restart, recovery, and migration from the previous representation.
- Prefer a short executable or inspectable scenario when a sequence is too subtle to establish from reading alone.

## Report and hand off

- For each credible finding, provide severity, affected file/symbol/component, triggering sequence, expected versus actual behavior, evidence, impact, and correction direction.
- Rank findings by practical consequence and confidence. Label a useful unanswered question as uncertainty rather than overstating it as a defect.
- Do not edit production files. Use the repository-local `.work` directory for temporary scenarios or probes when practical.
- If the implementation survives the challenge, say what failure classes were covered and state the remaining validation limits.

## Confidence

- Label a result as confirmed when code, tests, or a focused probe demonstrates the failure.
- Label it as likely when the path follows directly from code but depends on an unverified environment condition.
- Label it as open when the available evidence cannot establish reachability or expected behavior.
- Keep the parent orchestrator's handoff actionable: explain the smallest correction direction and the check that would prove it fixed.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not your task's execution deadline. Continue healthy work; do not force an early final answer merely to satisfy a wait. Honor explicit user stops and budgets. Before retrying an interrupted operation, inspect partial artifacts and any external outcome. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified step succeeded.
