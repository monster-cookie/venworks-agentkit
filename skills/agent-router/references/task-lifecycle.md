# Task progress, interruption, and recovery

Apply this guidance to delegated tasks and root-owned tool operations, regardless of domain or expected duration. It changes coordination decisions, not tool implementations or execution permissions. It does not require delegation when the underlying task is root-only.

## Establish a progress contract

Scale the contract to the task: a short assignment can use a single completion checkpoint. For substantial work, identify the scope or snapshot, owned paths or external targets, deliverable, completion evidence, useful milestones, authorized checkpoint location, and any explicit deadline or budget. Record worker/task IDs and process/job IDs when available. Do not invent time or token limits from a typical task duration.

At meaningful milestones, preserve completed work and report the current operation, remaining scope, actual verification, blockers, and where to resume. Prefer existing artifacts and concise messages over repeated full reports. Do not impose a fixed heartbeat or demand an early final answer just to prove liveness. While a blocking tool is running, a worker may be unable to respond to a checkpoint request until it returns.

Checkpoints do not expand write permissions. A read-only worker returns its checkpoint in a message; the coordinator may save it only to an authorized location. Do not write memory, source, temporary fixtures, or external records merely because checkpointing would be convenient. Exclude credentials and unnecessary private data.

## Maintain convergence

For coordinated work, keep a compact ledger of the critical path, current milestone, prerequisite checkpoint, active agents, cumulative assignments, ownership, follow-up count, integrated deliverables, and repeated verification. Before adding work, identify why its result is needed now and which completed prerequisite makes it executable. Available concurrency is capacity, not a task-generation target; five or six active specialists can be healthy when their work is independent and ownership-safe.

Prefer continuing a suitable existing agent over creating an equivalent replacement. One correction handoff for a finding or acceptance item is normal. If the same finding, failure, or substantially equivalent assignment returns again without a changed diagnosis or new evidence, reassess the plan before another assignment. Freeze scope expansion when agent creation does not reduce the current milestone, downstream work is advancing ahead of an unmet prerequisite, or broad checks repeat without a relevant source, input, failure, or risk change.

When the user questions agent count, sequencing, scope, looping, or progress, stop spawning new work. Inspect and report active versus cumulative agents, current ownership, completed deliverables, the unmet prerequisite, and the corrected critical path before continuing. Do not cancel healthy existing work unless the user asks or another authorized stopping reason applies.

Do not invent token, elapsed-time, context-compaction, or agent-count deadlines. Enforce explicit user budgets and platform limits, but use evidence of repeated or misordered work—not resource consumption alone—to diagnose a coordination loop.

## Observe before intervening

Separate the coordinator's wait timeout from a tool-operation timeout, an explicit worker error, and a user-imposed deadline. A wait returning without a final answer is an observation boundary, not a task failure. Tool timeouts may leave a process running or an external action completed; inspect their actual semantics and outcome.

Use the capabilities available in the current environment. Prefer compact status and existing checkpoints; use scoped logs or process/job status when available and authorized. Record which evidence was observed and its timestamp. Distinguish requested/configured models from runtime metadata actually exposed. Do not assume unavailable logs, CPU metrics, output timestamps, pending-approval APIs, or remote-host access exist.

| Evidence | Classification and next action |
|---|---|
| Recent completed steps, advancing output, or an active operation with advancing progress evidence | Running with evidence of progress; continue waiting and do independent work when useful. |
| Quiet worker or operation, with status still running | Progress may be unknown. Request one non-interrupting checkpoint if supported, and inspect available operation state. Silence or elapsed time alone does not prove a stall. |
| No visibility into the worker or tool | Progress unknown; explain the visibility gap. Do not cancel or retry solely to obtain a status response. |
| Pending user question, approval, or required external decision | Blocked on input; surface the existing request and preserve the task. Do not answer, approve, or restart it on the user's behalf. |
| Explicit recoverable tool/provider error | Preserve partial work; inspect what completed and retry only the failed step when safe, within authorization and applicable backoff. |
| Repeated identical failures with no successful step, a reported deadlock, or other concrete evidence of no forward progress | Suspected stall or execution failure, with supporting evidence; assess recovery and interruption risk. A count of waits or unanswered checkpoints is not this evidence. |
| Worker reports completion | Retrieve its actual deliverables and verify acceptance criteria; completion status alone is insufficient. |
| Explicit user stop, enforced budget/deadline, or concrete safety concern | Honor the constraint. Preserve state when safe without delaying an urgent stop, and report cancellation/partial results rather than execution success. |

Adapt polling to the operation and evidence. Back off when nothing changes; avoid busy polling or repeated unchanged user updates. Never set an implicit total execution deadline by adding up bounded waits. Lack of telemetry does not require endless blind waiting: disclose the gap and seek user direction when no useful independent work or observation remains, preserving the worker unless a separate authorized stopping reason exists.

## Interruption and replacement

Before a discretionary interruption, record the evidence, last known operation, partial artifacts, remaining scope, ownership, and recovery point. Assess whether stopping risks unsaved state, partial writes, held locks, active child processes, or an uncertain external side effect. Ask for a checkpoint without interrupting when supported; do not repeatedly send finalize requests to a worker that is still progressing. Failure to answer a checkpoint is not enough to justify cancellation.

Prefer continuing the existing worker or recovering the failed operation. When stopping is necessary and authorized, use the least disruptive supported stop mechanism, then verify whether the worker and its owned operations actually stopped. Stopping an agent does not prove its render, build, child process, or external job stopped. Do not start a replacement writer while the original writer may still own the same files or resources. If ownership or stop outcome cannot be verified, report that blocker before overlapping work.

A replacement receives the preserved snapshot, partial changes/results, completed and remaining coverage, known errors, ownership, and actual validation state. Assign the remaining scope, not a renamed version of the entire original task. Preserve independent-review boundaries: recovering a reviewer's own partial analysis is different from exposing another reviewer's conclusions. If a changed snapshot requires invalidating prior work, explain which coverage became stale and why.

Do not retry a consequential action with an unknown outcome. Check the destination or job receipt using read-only operations, use supported idempotency/recovery mechanisms when available, and request direction if the outcome remains uncertain. This applies to uploads, sends, purchases, deployments, database changes, file swaps, and other side effects; checkpointing does not grant authorization for any of them.

## Domain-specific checkpoints

| Work | Preserve and verify |
|---|---|
| Coding, scripts, configuration, data transformations | Owned paths, partial diff/output, last successful step, migrations or persistent changes, tests run and not run. Inspect actual state before replaying edits. |
| Review, research, architecture, security analysis | Findings and evidence, confidence, reviewed coverage versus remaining scope, unresolved assumptions, source/snapshot identity. Opening a file is not substantive review. |
| Documents, spreadsheets, slides, marketing copy | Editable artifact/version, completed sections or calculations, source/claim checks, remaining content and render/format validation. Draft completion is not publication. |
| Images, 3D, audio/video, CAD and other creative work | Save an editable checkpoint at a safe milestone within authorized paths; record scene/document state, operation settings, job IDs, output locations and unsaved work. Avoid unsafe saves during active operations. |
| Build, render, bake, simulation, export, download and batch processing | Process or external job identity, available progress evidence, completed outputs and integrity, resumability, and whether the operation continues after its client disconnects. Quiet output is not proof of a hang. |
| Browser, remote UI, deployment and external services | Last confirmed state, pending prompt/approval, destination and operation receipt, and whether an action took effect before retry. Do not repeat a submission to test liveness. |

These examples are not an exhaustive task list. For other work, apply the same ownership, observability, side-effect, and recovery principles without forcing an unrelated specialist workflow.

## Completion and reporting

Use evidence-based labels: running, progress unknown, blocked on input, execution failed, cancelled by the root/user, partial, or completed. Report why a task was cancelled and who initiated it; never relabel root cancellation as a model failure without separate evidence. Partial results can coexist with blocked, failed, or cancelled execution.

Retrieve original worker results and account for missing coverage before synthesis. Distinguish verified results, worker-reported claims, failed checks, unrun checks, and unconfirmed assumptions. No pending required worker may be silently omitted or terminated just to satisfy a completion gate. A user-requested handoff may leave a known worker running, with its ID, ownership, status, and next action reported; it is not completion of the underlying task.

## Applying updated guidance

Shared skill edits affect future loads; they do not prove running tasks have adopted the new text. Verify OneDrive sync and the target machine's junction/file content before claiming rollout there. For an active task, provide a concise non-interrupting instruction to load this guidance at its next safe boundary, when supported and authorized. Otherwise give the user a direct continuation prompt. Do not restart healthy workers merely to reload a skill, and do not claim adoption without acknowledgement or observed behavior.
