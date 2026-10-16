---
type: index
title: "Memories"
createdAt: "2026-10-04T19:40:35Z"
updatedAt: "2026-10-16T19:33:00Z"
tags: []
---

# Memories

Atomic durable facts: deployment gotchas, dependency quirks, incident learnings.

## Nodes

- [[0001-node-id-display-in-ui|Node ID display in ComfyUI UI is a built-in frontend setting]] — built-in `Comfy.NodeBadge.NodeIdBadgeMode`; custom-node alternative qzw881130/ComfyUI-ShowNodeID
- [[0002-build-docker-latest-not-retagged|build-docker.sh pushed :latest without re-tagging it]] — latent bug (fixed 0a681d4d); always verify the pushed :latest digest matches the built SHA
- [[0003-nvcc-segfault-llama-cpp-transient|nvcc segfault on llama-cpp-python CUDA templates is transient]] — retry the build once before chasing pins; -arch=native fallback warning is expected
