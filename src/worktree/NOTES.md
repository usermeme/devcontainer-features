## Requirements

This feature is for worktree layouts where the shared `.git` is in the parent folder of the workspace (`repo/.git` + `repo/<worktree>/`). The parent `.git` must exist on the host, otherwise the container fails to start.

## What it changes

- The worktree's `.git` file (your host file) is rewritten from an absolute host path to the relative `gitdir: ../.git/worktrees/<name>`, which works on the host and in the container. Pointers written by 1.0.0 (`/workspaces/.git/...`, which broke git on the host) are healed the same way.
- `safe.directory` trusts `/workspaces/*` (git >= 2.46) or the exact workspace paths, in the container's system config. It no longer uses `*`.
- `gc.worktreePruneExpire=never` is set in the container's system config.

## Caveats

- The shared `.git` is mounted read-write. Running `git worktree prune` **inside the container** treats every sibling worktree as stale (their recorded paths are host paths) and deletes their metadata on the host. Prune from the host only.
- Anything in the container can write `.git/hooks`, and those hooks run on the host at your next commit in any worktree.
