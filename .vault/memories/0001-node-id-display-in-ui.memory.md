---
type: memory
title: "Node ID display in ComfyUI UI is a built-in frontend setting"
createdAt: "2026-10-15T15:57:23Z"
updatedAt: "2026-10-15T15:57:23Z"
tags: [ui, frontend, settings, node-id, gotcha]
see_also: []
deprecated:
  date: null
  reason: null
  superseded_by: null
---

# Memory: Node ID display in ComfyUI UI is a built-in frontend setting

## Fact

Showing node ids on nodes does NOT require a custom node. The ComfyUI frontend (pinned here as
`comfyui-frontend-package==1.53.6`) has a built-in setting `Comfy.NodeBadge.NodeIdBadgeMode`
("Node ID badge mode", options None / Show All). UI path: Settings (gear, Ctrl+,) → LiteGraph →
Node → NodeIdBadgeMode → Show All. Verified in Comfy-Org/ComfyUI_frontend source
(coreSettings.ts, useNodeBadge.ts, badgeSystem.ts).

## Context

Investigation 2026-10-15: asked whether a custom-node exists to show node ids in the UI of this
fork. custom_nodes/ contains no such node. A community option exists — qzw881130/ComfyUI-ShowNodeID
(pure frontend JS, prepends `#<id>` to node titles) — but it is a 0-star hobby repo; the built-in
badge is the maintained path.

## Impact

No install needed to show node ids; enable the built-in badge setting instead of adding a custom
node. Use ComfyUI-ShowNodeID only if ids must appear inside the title text (copy/paste, JSON id
matching).
