# Phase 1 Validation Criteria

This document defines the Nyquist compliance validation criteria for Phase 1. Each requirement is verified via an automated test command.

## SPINE-01: Incident Schema
* **Criteria:** Incident schema can be loaded and validates open/investigating/resolved states.
* **Nyquist Verification:** 
  ```xml
  <automated>mix test test/parapet/spine/incident_test.exs</automated>
  ```

## SPINE-02: TimelineEntry Schema
* **Criteria:** TimelineEntry schema can be loaded and linked to an Incident.
* **Nyquist Verification:**
  ```xml
  <automated>mix test test/parapet/spine/timeline_entry_test.exs</automated>
  ```

## SPINE-03: ToolAudit Schema
* **Criteria:** ToolAudit schema can be loaded and validates JSON map payloads.
* **Nyquist Verification:**
  ```xml
  <automated>mix test test/parapet/spine/tool_audit_test.exs</automated>
  ```

## SPINE-04: Evidence API and Generator
* **Criteria:** Application can insert incidents via Evidence context and generate host application migrations.
* **Nyquist Verification:**
  ```xml
  <automated>mix test test/parapet/evidence_test.exs && mix test test/mix/tasks/parapet.gen.spine_test.exs</automated>
  ```