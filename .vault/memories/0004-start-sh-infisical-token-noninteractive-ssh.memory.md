---
type: memory
title: "start.sh fails over non-interactive ssh — INFISICAL_TOKEN lives in .zshrc"
createdAt: "2026-10-16T20:55:00Z"
updatedAt: "2026-10-16T20:55:00Z"
tags: [deployment, infisical, ssh, gotcha, behemoth]
see_also:
  - "[[0001-fork-update-cycle.runbook]]"
deprecated:
  date: null
  reason: null
  superseded_by: null
---

# Memory: start.sh fails over non-interactive ssh — INFISICAL_TOKEN lives in .zshrc

## Fact

`./start.sh` (and `./restart.sh`) on behemoth.lan fail over plain `ssh behemoth.lan "…"` with `infisical-run.sh: line 9: INFISICAL_TOKEN: unbound variable` — the script runs `set -u` and `INFISICAL_TOKEN` is exported only in `~/.zshrc`, which non-interactive shells do not source. Working invocation: `ssh behemoth.lan "zsh -ic 'cd /home/tuiteraz/behemoth-lan/comfyui && ./start.sh'"`.

## Context

Hit 2026-10-16 during the v0.41.2 deploy restart: `restart.sh` stopped the container, then the start half failed (stop.sh itself does not need Infisical). The container was left stopped until started via `zsh -ic`.

## Impact

Any scripted/agent-driven start of ComfyUI on behemoth.lan must run through an interactive zsh (or export `INFISICAL_TOKEN` explicitly). Note the asymmetry: `stop.sh` works non-interactively, `start.sh` does not.
