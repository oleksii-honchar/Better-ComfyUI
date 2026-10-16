---
type: runbook
title: "Fork Update Cycle (rebase patches onto a new upstream release)"
createdAt: "2026-10-16T19:32:00Z"
updatedAt: "2026-10-16T19:32:00Z"
tags: [operations, rebase, git, docker, deployment]
see_also:
  - "[[0002-build-docker-latest-not-retagged.memory]]"
  - "[[0003-nvcc-segfault-llama-cpp-transient.memory]]"
deprecated:
  date: null
  reason: null
  superseded_by: null
---

# Runbook: Fork Update Cycle (rebase patches onto a new upstream release)

Procedure validated on 2026-10-16 (v0.38.0 → v0.41.2, branch `patched/master-0-41-0`); same shape as the v0.37.0 and v0.38.0 cycles.

## Prerequisites

- Local clone `/Volumes/Data/www/misc/Better-ComfyUI` with remotes `origin` (fork) + `upstream` (ComfyUI).
- Fork patch set is **purely additive** (new files only: Dockerfile, entrypoint, MCP wrapper, build scripts, `custom_node_requirements.txt`, `.vault/`) — verify before starting: `git diff --stat <prev-base-tag>..<current-branch>` must show 0 deletions of upstream files.
- User confirmation for any behemoth.lan remote operation (ssh) per house rules.

## Steps

1. **Fetch upstream tags**: `git fetch upstream --tags`; pick the target tag (prefer the actual latest, not the assumed one).
2. **Save local changes on the current branch first** — commit any uncommitted files (esp. `.vault/` edits) so they cherry-pick along and don't collide.
3. **Create the new branch from the tag**: `git checkout -b patched/master-<x-y-z> <tag>` (branch guard in `scripts/build-docker.sh` accepts `patched/master-*`).
4. **Cherry-pick the whole old stack**: `git cherry-pick <prev-base-tag>..<old-branch>` — expected clean while the patch set stays additive. Then re-apply any step-2 commits.
5. **Verify footprint**: `git diff --stat <tag>..HEAD` shows only fork-owned files, 0 upstream deletions; fix stale version comments in fork files (comment-only commit).
6. **Push**: `git push -u origin patched/master-<x-y-z>`.
7. **Build on behemoth.lan** (amd64 — never on the Mac): in `/home/tuiteraz/Better-ComfyUI`, checkout the branch, run `scripts/build-docker.sh` (background + log; the llama-cpp-python CUDA wheel step takes ~5 min). If nvcc segfaults, see [[0003-nvcc-segfault-llama-cpp-transient.memory]].
8. **Verify `:latest` actually moved** — compare the pushed digest with the built image ID (see [[0002-build-docker-latest-not-retagged.memory]]).
9. **Stage the deployment** (restart is a separate, user-owned step): in `~/behemoth-lan` use `git fetch && git merge --ff-only origin/main` (the repo there carries live user data — never stash/discard), then `cd comfyui && docker compose pull`.

## Verification

- `git describe --tags` on the new branch = `<tag>-N-<sha>`.
- `docker images tuiteraz/better-comfyui` shows `latest` = the new image ID.
- Container untouched until the user runs `./restart.sh`; after restart, ComfyUI reports the new version on :8015.

## Rollback

- Git: the old branch remains untouched; new branch can be deleted/force-replaced.
- Deploy: compose can pin the previous `:<old-sha>` tag instead of `:latest` to roll back.
