---
type: memory
title: "build-docker.sh pushed :latest without re-tagging it to the new build"
createdAt: "2026-10-16T19:30:00Z"
updatedAt: "2026-10-16T19:30:00Z"
tags: [docker, build, deployment, gotcha, latest-tag]
see_also:
  - "[[0001-fork-update-cycle.runbook]]"
deprecated:
  date: null
  reason: null
  superseded_by: null
---

# Memory: build-docker.sh pushed :latest without re-tagging it to the new build

## Fact

`scripts/build-docker.sh` builds and tags only `tuiteraz/better-comfyui:<short-HEAD-sha>`, then pushed `:latest` — **without ever re-tagging `:latest` to the new build**. The push therefore re-published whatever `:latest` pointed at locally (the previous image). Fixed 2026-10-16 in commit `0a681d4d` (adds `docker tag <image>:$TAG <image>:latest` before the push).

## Context

Discovered during the v0.41.2 fork update (2026-10-16): the build succeeded and pushed, but `docker images` on behemoth.lan still showed `latest` = the old image ID, and `docker compose pull` fetched the old digest. Earlier promotions must have been done with a manual `docker tag` + push.

## Impact

`:latest` is the deployment trigger for behemoth.lan — a silently stale `:latest` means a restart would NOT pick up the new build. After any `build-docker.sh` run, verify the registry digest of `:latest` matches the built SHA (e.g. compare `docker images --digests` or the push output digest with the image ID).
