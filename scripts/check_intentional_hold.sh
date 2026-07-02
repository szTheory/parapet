#!/usr/bin/env bash
# D-17 guard: enforce the three-primitive sleep vocabulary in test/.
#
# Every Process.sleep( in test/ must be immediately preceded (within 2 lines)
# by a comment containing the token "INTENTIONAL HOLD:", OR be part of the
# bounded SELECT 1 readiness barrier in executor_cluster_smoke_test.exs
# (which is a synchronous readiness probe, not a hold).
#
# On clean: exits 0 (silent).
# On violations: prints each violating file:line with a remediation hint,
# then exits 1.
#
# NOT wired into mix test, CI, or .credo.exs in this phase.
# Promotion to a Credo.Check.Warning.SleepInTest is deferred to Phase 58/59.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="${REPO_ROOT}/test"

# Files exempt because their sleep is a bounded readiness probe (not a hold).
# The SELECT 1 barrier in executor_cluster_smoke_test.exs is inside a rescue
# block and is bounded by a 5_000ms deadline — it is structurally a
# synchronous start-barrier, not a timing hack.
EXEMPT_PATTERN="executor_cluster_smoke_test.exs"

violations=()

while IFS= read -r filepath; do
  # Skip exempt files
  if [[ "$filepath" == *"$EXEMPT_PATTERN"* ]]; then
    continue
  fi

  # Scan line-by-line; keep a rolling window of the previous 2 lines
  prev2=""
  prev1=""
  lineno=0

  while IFS= read -r line; do
    lineno=$((lineno + 1))

    if echo "$line" | grep -q 'Process\.sleep('; then
      # Check if either of the preceding 2 lines contains "INTENTIONAL HOLD:"
      if ! echo "$prev1$prev2" | grep -q 'INTENTIONAL HOLD:'; then
        violations+=("${filepath}:${lineno}")
      fi
    fi

    prev2="$prev1"
    prev1="$line"
  done < "$filepath"
done < <(find "$TEST_DIR" -name "*.exs" -type f)

if [ ${#violations[@]} -eq 0 ]; then
  exit 0
fi

echo "check_intentional_hold: bare Process.sleep found in test/ without INTENTIONAL HOLD: annotation"
echo ""
for v in "${violations[@]}"; do
  echo "  $v"
  echo "    Remediation: precede this Process.sleep with a two-line comment:"
  echo "    # INTENTIONAL HOLD: <why the race window must stay open>"
  echo "    # NOT a lazy wait — do not replace with assert_eventually/the start-barrier."
  echo "    Or replace with assert_eventually/2 (for async-settle waits) or the SELECT 1"
  echo "    readiness barrier (for startup probes)."
  echo ""
done

exit 1
