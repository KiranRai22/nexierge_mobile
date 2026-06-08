#!/usr/bin/env bash
# Fails if lib/ contains hardcoded colors outside lib/core/theme/.
#
# Rule (docs/THEME_CONSOLIDATION_PLAN.md §5):
#   All color must come from `context.appColors.<token>`.
#   Adding new shades means adding tokens to lib/core/theme/app_colors.dart
#   first (light + dark), then consuming. Never `Color(0xFF…)`, never
#   `Colors.<x>` (except `Colors.transparent`), never `ColorPalette.<x>`
#   in widget code.
#
# Wire into pre-commit and CI.
#
# Usage:
#   scripts/check_no_hardcoded_colors.sh            # check whole tree
#   scripts/check_no_hardcoded_colors.sh path/...   # check specific files
#
# Exits 0 on clean, 1 on violations.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Files we treat as the single source of truth — they are ALLOWED to define
# hex colors and may reference `Colors.*` for transparent / scrim defaults.
EXEMPT_PATHS=(
  'lib/core/theme/'
)

# Build a grep exclude pattern for the canonical paths.
EXCLUDE_ARGS=()
for p in "${EXEMPT_PATHS[@]}"; do
  EXCLUDE_ARGS+=(--exclude-dir="${p#lib/}")
done

if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  TARGETS=(lib)
fi

# Limit the scan to files outside the theme directory. Use a POSIX read
# loop instead of `mapfile` so the script works on stock macOS bash 3.x.
FILES=()
while IFS= read -r f; do
  FILES+=("$f")
done < <(
  find "${TARGETS[@]}" -type f -name '*.dart' \
    ! -path 'lib/core/theme/*'
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No dart files to scan."
  exit 0
fi

violations=0
report() {
  local pattern="$1" label="$2" allow_regex="${3:-}"
  echo
  echo "→ ${label}"
  local hits
  if [[ -n "$allow_regex" ]]; then
    hits=$(grep -nE "$pattern" "${FILES[@]}" 2>/dev/null | grep -vE "$allow_regex" || true)
  else
    hits=$(grep -nE "$pattern" "${FILES[@]}" 2>/dev/null || true)
  fi
  if [[ -n "$hits" ]]; then
    echo "$hits"
    local count
    count=$(echo "$hits" | wc -l | tr -d ' ')
    violations=$((violations + count))
  else
    echo "  (clean)"
  fi
}

echo "Scanning ${#FILES[@]} dart files (excluding lib/core/theme/)..."

# 1. Hex color literals.
report 'Color\(0x[0-9A-Fa-f]{6,8}\)' \
  'Hardcoded Color(0x…) literals'

# 2. Material `Colors.<name>` — allow Colors.transparent only.
report '\bColors\.[A-Za-z]' \
  'Material `Colors.<x>` constants (only Colors.transparent allowed)' \
  '\bColors\.transparent\b'

# 3. Legacy ColorPalette references.
report '\bColorPalette\.' \
  'Legacy `ColorPalette.<x>` references'

echo
if (( violations == 0 )); then
  echo "✓ No hardcoded color usage found."
  exit 0
fi

echo "✗ Found $violations violation(s)."
echo "  Fix: register the color in lib/core/theme/app_colors.dart"
echo "  (light + dark variants) and read it via context.appColors.<token>."
exit 1
