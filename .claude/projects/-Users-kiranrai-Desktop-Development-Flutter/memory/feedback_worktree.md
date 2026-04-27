---
name: Work in Main Project Directory
description: Always write files to the main project at /Users/kiranrai/Desktop/Development/Flutter/nexierge/, not the worktree path
type: feedback
---

Always write code changes directly to the main project directory `/Users/kiranrai/Desktop/Development/Flutter/nexierge/`, not to any `.claude/worktrees/` path.

**Why:** The user works on `feature/dev` and expects changes to appear immediately in the real project, not in an isolated worktree branch.

**How to apply:** Before writing any file, confirm the target path starts with `/Users/kiranrai/Desktop/Development/Flutter/nexierge/lib/` (or `docs/`, etc.), never with `/Users/kiranrai/Desktop/Development/Flutter/nexierge/.claude/worktrees/`.
