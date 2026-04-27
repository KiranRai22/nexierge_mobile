---
name: Required Output Format for Code Changes
description: Mandatory response format and documentation protocol for every code change or feature task
type: feedback
---

For every task that involves writing or changing code, always follow this exact structure.

## Part A — Response format (in this order)

1. **File structure** — show the planned/affected file tree before writing any code
2. **Code** — full code file by file
3. **Explanation** — why this structure and approach was chosen
4. **Trade-offs** — what was gained, what was sacrificed, alternatives considered

## Part B — After completion

1. **Summary block** with:
   - Title
   - Description of what was done
   - Files affected (listed)

2. **Changelog documentation** — maintain a `docs/changelog/` folder at the project root. Each task gets an entry. Never delete old entries.

3. **Labels and emphasis** — mark important changes in **bold** and tag them with labels:
   - `(Critical)` — breaking changes, security, core architecture
   - `(Medium)` — meaningful logic or structure changes
   - `(UI)` — visual/layout changes
   - `(Logic)` — business logic, state, provider changes

**Why:** The user wants every change to be auditable, documented, and easy to review at a glance. This format makes work reviewable, prevents undocumented changes from accumulating, and keeps the project history queryable.

**How to apply:** Apply to every response that creates, edits, or deletes code files — no exceptions. Even small bug fixes get a summary and changelog entry.
