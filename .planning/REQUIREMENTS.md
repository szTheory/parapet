# Requirements

## Milestone v1.4 Trust Hardening & Host-App Compatibility

**Goal:** Close the quality-evaluation risks most likely to damage adoption trust without expanding Parapet's public product surface.

**Source artifact:** `.planning/QUALITY-EVALUATION.md`

## Archive Durability

- [ ] **ARCH-01**: Operators can run archive/export/prune maintenance knowing resolved evidence is preserved as a complete incident bundle, including incident, timeline, tool audit, and related evidence records that Parapet owns.
- [ ] **ARCH-02**: Archive maintenance fails loudly and actionably on partial persistence/export/delete failure instead of silently returning success or leaving ambiguous state.
- [ ] **ARCH-03**: Archive maintenance keeps the resolved-only retention contract explicit and test-pinned: active or investigating incidents are never pruned, and boundary retention dates are handled deterministically.
- [ ] **ARCH-04**: Archive maintenance returns or logs a structured run summary with counts, skipped records, failures, and enough context for a host app or maintainer to debug the run.

## Generated UI Host Compatibility

- [ ] **UIROUTE-01**: Generated Operator UI route helpers, links, redirects, forms, and LiveView patches respect a host-owned base path when mounted under a non-default scope such as `/ops/parapet`.
- [ ] **UIROUTE-02**: The generated template and demo app copy stay synchronized and test-pinned for both default `/parapet` and scoped route mounting.
- [ ] **UIROUTE-03**: Scoped-route support does not change Parapet's auth ownership, router ownership, public API stability tier, or dependency surface.

## Adoption And Supportability

- [ ] **ADOPT-01**: README and docs explain archive maintenance in practical production terms: when to run it, what it preserves, what failure looks like, and how to recover.
- [ ] **ADOPT-02**: README and generated UI docs explain default and scoped Operator UI mounting with copy-pasteable Phoenix router examples and known gotchas.
- [ ] **ADOPT-03**: The quality-evaluation artifact is updated or cross-referenced at milestone close so future milestone planning can see which top risks were actually closed.

## Future Requirements

- Rich archive export formats beyond the current Parapet-owned evidence model.
- Full multi-tenant/operator-per-org UI semantics.
- Hosted dashboards or external SRE platform integrations for archive observability.

## Out Of Scope

- Autonomous remediation or no-human recovery decisions.
- New runtime dependencies.
- New public stable APIs unless required to preserve host-app compatibility and explicitly reviewed.
- Auth policy changes in generated UI. The host app continues to own authentication and authorization.
- Replacing Phoenix route helpers globally or taking ownership of the host router.

## Traceability

| Requirement | Phase | Status |
|---|---:|---|
| ARCH-01 | 37 | planned |
| ARCH-02 | 37 | planned |
| ARCH-03 | 37 | planned |
| ARCH-04 | 37 | planned |
| UIROUTE-01 | 38 | planned |
| UIROUTE-02 | 38 | planned |
| UIROUTE-03 | 38 | planned |
| ADOPT-01 | 39 | planned |
| ADOPT-02 | 39 | planned |
| ADOPT-03 | 39 | planned |
