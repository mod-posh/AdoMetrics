# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [[1.0.0]](https://github.com/mod-posh/AdoMetrics/releases/tag/v1.0.0) - 2026-02-19

### Architectural Reset — Canonical Ingestion Baseline (ADR-001)

This release establishes the V1 canonical ingestion model for Azure DevOps metrics.

The module has been intentionally simplified to provide a deterministic ingestion and storage substrate with no profile or orchestration dependencies.

---

### Added

* Canonical metric row schema (`schemaVersion = 1`)
* Deterministic merge semantics (`definitionId + adoBuildId`)
* JSONL-based storage contract
* Idempotent schema repair (`Repair-AdoMetricRowSchema`)
* StrictMode-safe ingestion pipeline
* Pester v5 test coverage for:

  * Canonical row generation without profiles
  * Merge deduplication
  * Schema repair idempotency
  * V1 contract integrity
* `/scripts/quickstart-v1.ps1` reference implementation
* `/tests` test suite
* `/docs/architecture` ADR structure

---

### Changed

* `ConvertTo-AdoMetricRow`

  * No longer requires profiles
  * Guarantees `derivedParsed` and `derived`
  * Implements deterministic pipeline label fallback
* `Get-AdoBuildRun`

  * Normalized ADO response handling
  * Explicit error handling for non-JSON responses
* `Import-AdoMetricsJsonl`

  * Treats missing or empty file as empty store
* `Export-AdoMetricsJsonl`

  * Auto-creates parent directories
* `Merge-AdoMetricRow`

  * Strict deduplication by canonical merge key
* `Repair-AdoMetricRowSchema`

  * Idempotent
  * Non-destructive
  * Legacy casing backfill support

---

### Removed

The following profile and orchestration features were intentionally removed:

* Project profiles
* Definition profiles
* Metrics profiles
* Profile validation helpers
* Daily time-window orchestration
* README generation engine
* Derived duration helpers
* Metric block writers
* Paged build retrieval helper
* Legacy JSON file helpers
* Daily invocation script
* Orchestration cmdlets from public surface

Public surface reduced to:

* `New-AdoAuthHeader`
* `Get-AdoBuildRun`
* `ConvertTo-AdoMetricRow`
* `Import-AdoMetricsJsonl`
* `Export-AdoMetricsJsonl`
* `Merge-AdoMetricRow`
* `Get-AdoPat` (optional convenience)

---

### Breaking Changes

* All profile-based ingestion removed.
* README generation removed.
* Derived metric parsing removed.
* Orchestration logic removed from module surface.
* JSON (non-JSONL) store support removed.
* Internal helper surface restructured.

Consumers relying on profile-driven behavior must migrate to V1 canonical ingestion patterns.

---

### Design Intent

This milestone establishes:

* A stable schema contract
* Idempotent merge guarantees
* A minimal ingestion substrate
* Clear separation between primitives and orchestration
* Explicit architectural boundaries

Future milestones will layer enrichment, classification, and reporting on top of this baseline.
