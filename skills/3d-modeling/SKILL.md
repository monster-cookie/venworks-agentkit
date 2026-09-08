---
name: 3d-modeling
description: Plan, create, inspect, or modify 3D assets, Blender scenes, meshes, materials, UVs, textures, rigs, and game-ready models using available 3D tools.
---

# 3D Modeling

Use this skill for planning, creating, inspecting, or modifying Blender scenes, meshes, materials, UVs, textures, rigs, game-ready models, and related 3D assets. Determine the destination and its asset contract before making modeling or export decisions.

## Tooling and credential policies

Before selecting project tools or using an authenticated service, follow [tooling and credential policies](../agent-router/references/tooling-and-credentials.md). Resolve optional adopted shared and repository-root policies for this role, target, and operation; verify the required identity through the actual consuming tool. Missing policies retain existing workflow behavior. Existing but invalid or conflicting policies block affected operations, not unrelated work. Tool access and credentials do not independently authorize mutations. Direct invocation follows the same discovery rules as delegated work.

## Establish the destination contract

- Identify the destination engine or application, target platform, import path, coordinate system, units, scale, axis orientation, and required export format.
- Establish polygon, draw-call, texture-memory, level-of-detail, collision, and other performance budgets when the target defines them.
- Establish material, shader, texture, color-space, UV, baking, animation, rigging, skeleton, and naming requirements before editing the asset.
- Inspect existing assets and project conventions so the new model matches scale, pivots, naming, folder layout, materials, and expected runtime behavior.

## Model and prepare

- Prefer nondestructive workflows where practical and preserve an editable source scene or mesh until the output is accepted.
- Keep topology, normals, transforms, pivots, smoothing, modifiers, object hierarchy, and material assignments consistent with the destination importer.
- Build UVs and textures for the actual resolution, tiling, baking, compression, and channel requirements instead of assuming a generic game pipeline.
- Create level-of-detail and collision representations when the destination requires them, and keep their ownership and naming unambiguous.
- Use Blender or other configured 3D tools only when they are available in the current environment; do not invent tool access or silently substitute an unverified exporter.
- Use the repository-local `.work` directory for temporary meshes, exports, renders, and diagnostic artifacts when practical, and keep final assets within authorized paths.

## Export and verify

- Validate geometry, normals, transforms, pivots, scale, materials, UVs, textures, armatures, animation clips, collision, and level-of-detail before completion.
- Check export settings, coordinate conversion, unit conversion, naming, dependencies, and destination import behavior against the target platform's actual requirements.
- Inspect the exported result in the destination application or with an appropriate validator when available; distinguish an export file existing from the asset importing and rendering correctly.
- If the required 3D tool, scene, exporter, or destination runtime is unavailable, provide an implementation-ready asset specification and validation checklist rather than claiming the scene or asset was modified.
- Report the files or scene elements changed, checks performed, tool versions or settings that matter, and the remaining unverified boundary.

## Progress and recovery

For delegated work or a long-running operation, read [task progress, interruption, and recovery](../agent-router/references/task-lifecycle.md); loading it does not require further delegation. At useful milestones, report completed work, the current operation, remaining scope, actual verification, and blockers. Preserve editable scene checkpoints only within authorized paths or return them in a message when read-only.

A coordinator wait timeout is not the operation's execution deadline. Continue healthy work; honor explicit user stops and budgets. Before retrying an interrupted bake, export, or render, inspect partial outputs and any external job state. Hand back incomplete coverage and recovery state honestly; never claim a cancelled or unverified 3D operation succeeded.
