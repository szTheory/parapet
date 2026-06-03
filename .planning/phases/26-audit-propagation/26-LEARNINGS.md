---
phase: 26-audit-propagation
authored: "2026-05-28"
status: lessons-captured
graduation_candidates:
  - LEARN-26-A → engineering DNA: "best-effort" side-effects need try/rescue, not `_ =`, especially around Ecto
  - LEARN-26-B → recovery-loop rigor: the failure path is the path that matters during an incident
---

# Phase 26 Learnings: Audit Propagation

Strategic lessons from wiring the durable audit trail into the operator Confirm path (AUD-01/02/03). Execution record is in `26-01-SUMMARY.md`; this file captures what we learned that should shape future decisions.

## LEARN-26-A: `_ = expr` discards a value, not an exception — and Ecto raises

**Observation.** The executor's failure-arm audit write carried a comment promising the original `{:error, reason}` would propagate "regardless of DB outcome," implemented as `_ = Evidence.run_operator_command(...)`. The code review (CR-01) caught that this only discards the *return value*. Ecto's Postgres adapter **raises** (e.g. `DBConnection.ConnectionError`) on connection failure rather than returning `{:error, _}`, so a raising audit write would have propagated past `ClaimService.mark_failed/2` and left the claim `"won"` for the full 5-minute lease — the exact operator-retry lockout this milestone exists to remove. Fix: wrap the best-effort write in `try/rescue _ -> :ok end`.

**Implication.** "Best-effort side-effect" is a control-flow guarantee, and in Elixir/Ecto that guarantee requires `try/rescue`, not `_ =`. Any best-effort write whose failure must not change the caller's outcome should be reviewed for *exception* isolation, not just return-value handling. Worth promoting into the engineering-DNA notes (`prompts/` research) as a recurring Ecto pitfall.

## LEARN-26-B: The recovery failure path deserves happy-path rigor

**Observation.** Both the executor and the plan invested heavily in the success `{:ok}` arm (enriched timeline + audit, well tested). The blocker lived in the `{:error, reason}` arm — the path that fires precisely when a real incident mitigation fails. The audit *contents* were correct; the *control flow* around releasing the claim was not, and that's the part an operator feels at 3am.

**Implication.** For recovery/remediation features, treat the failure arm as the primary deliverable, not an afterthought. Its job (release the claim, record why, let the operator retry) is the whole point of "Actionable Recovery." The CR-01 regression test (`preview_lifecycle_test.exs`, `:raise_on_transaction_multi` flag asserting `confirm_runbook_step/4` still returns the error) is the kind of failure-path test that should be default for capability dispatch, not a fix-time addition.

## LEARN-26-C: The code-review gate paid for itself on a 1-plan phase

**Observation.** Phase 26 was a single mechanical plan that compiled clean and passed 24 self-checked tests in the worktree. It still shipped a claim-lockout blocker. The advisory `gsd-code-review` gate caught it before phase completion; fixing it added two regression tests and a shared `build_audit/2`-derived failure-attrs path (eliminating schema-drift risk, WR-03).

**Implication.** Don't skip the code-review gate on "small/obvious" phases — Self-Check passing in isolation is exactly the Generator blind spot the gate exists to cover. Worth keeping `workflow.code_review=true` as the default for this project.
