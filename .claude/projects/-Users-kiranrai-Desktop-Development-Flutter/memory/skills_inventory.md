---
name: Skills Inventory
description: Complete list of active Claude Code skills for this Flutter/Riverpod project — both pre-installed and custom-created
type: project
---

# Skills Inventory

## Pre-installed via anthropic-skills plugin (system-wide)

| Skill ID | Maps to | Purpose |
|----------|---------|---------|
| `anthropic-skills:project-principles` | docs/00 | Core philosophy — trigger before any implementation |
| `anthropic-skills:architecture-rules` | docs/01 | Layer structure and dependency flow |
| `anthropic-skills:riverpod-guidelines` | docs/02 | Provider selection, naming, state rules |
| `anthropic-skills:code-style-guidelines` | docs/03 | Code formatting, naming conventions |
| `anthropic-skills:base-layer-rules` | docs/04 | Centralized managers, no hardcoded values |
| `anthropic-skills:ui-implementation-rules` | docs/05 | Figma → Flutter, responsiveness, spacing scale |
| `anthropic-skills:api-and-realtime-rules` | docs/06 | Repository pattern, WebSocket, Firebase, push |
| `anthropic-skills:state-and-lifecycle-rules` | docs/07 | AsyncValue, autoDispose, streams |
| `anthropic-skills:gent-workflow-rules` | docs/09 | Agent step-by-step workflow |
| `anthropic-skills:dos-and-donts` | docs/10 | Quick anti-pattern reference |

## Custom project-level skills (created 2026-04-25)
Location: `.claude/skills/` in the project worktree

| Skill | Maps to | Trigger |
|-------|---------|---------|
| `testing-and-review` | docs/08 | Writing tests, reviewing code, pre-commit checks |
| `flutter-pr-checklist` | ai_prompts/pr_checklist.md | Creating/reviewing PRs, /review command |
| `flutter-feature-generation` | ai_prompts/feature_generation.md | Implementing new features or screens |
| `flutter-bug-fix` | ai_prompts/bug_fix.md | Debugging, fixing errors, stack traces |

## Note on docs/08 gap
`docs/08_TESTING_AND_REVIEW.md` had no pre-installed anthropic-skills counterpart. The `testing-and-review` skill fills this gap.
