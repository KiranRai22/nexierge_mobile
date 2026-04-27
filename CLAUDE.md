# Project memory — read every session

## Package & font policy (HARD RULE)

Every package and every font added to this project MUST satisfy ALL of the following — no exceptions:

1. **Free for commercial use.** No GPL, no AGPL, no "personal/non-commercial only" clauses, no "free for evaluation" trial licenses. Acceptable licenses: MIT, BSD-2/3-Clause, Apache-2.0, MPL-2.0, ISC, SIL OFL-1.1 (fonts).
2. **Cross-platform support for ALL currently-supported Android & iOS versions** the app targets. If a package drops a platform we support, do NOT use it.
3. **Active maintenance.** Recent releases (within ~12 months), responsive issue tracker, healthy contributor base. Reject abandoned packages even if they technically still compile.
4. **Documented in `docs/PACKAGES_DETAILS.md`** in the SAME commit that adds the dependency. The entry must follow this exact format:

   - **Package name**
   - **Version**
   - **Owner**
   - **License**
   - **Description** (what it does + license stance)
   - **Why we use it**

5. **No silent additions via transitive deps.** If a transitive dep surfaces a license risk (GPL/LGPL etc.), pin or replace.

If you're about to add a package, FIRST verify all five points above, THEN edit `pubspec.yaml`, THEN update `docs/PACKAGES_DETAILS.md` in the same change set. Never the other way around.

## Other persistent rules

- **i18n is mandatory.** Every user-visible string (UI, snackbars, toasts, dialogs, errors, push & local notifications) must come from the localization layer — no hardcoded user-visible strings in widgets, services, repos, or notification handlers. See `docs/I18N_PLAN.md`.
- **Locale persistence:** the user's chosen locale must survive cold-start and logout. Stored via `shared_preferences` under key `app.locale`.
- **Theme persistence:** same rule, key `app.themeMode`.
- See `docs/00_PROJECT_PRINCIPLES.md` through `docs/10_DOS_AND_DONTS.md` for the full architecture rule set; do not deviate.
