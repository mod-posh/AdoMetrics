# ModPosh.AdoMetrics Roadmap & Migration Plan

## Purpose of this plan

This document describes how we will evolve **ModPosh.AdoMetrics** from the current working implementation into a clean, durable module with a stable public contract.

The plan is organized into three milestones (V1/V2/V3) that map to architecture decisions captured in ADRs:

* **ADR-001**: Canonical metrics row + JSONL store as the core contract
* **ADR-002**: Profiles are optional; derived fields are namespaced under `.derived`
* **ADR-003**: Projection layer for selection/rename/custom metrics; canonical store stays canonical

---

## Current state (what we have today)

### Working capabilities

* We can authenticate to ADO and pull build runs.
* We can normalize runs into a canonical “metric row” shape.
* We can persist rows into a JSONL cumulative store with merge/dedupe.
* We have profile files (`project.profile.json`, definition profiles, metrics profile).
* We have a README formatter, and a local smoke script that drives the end-to-end flow.

### Current repo structure (module)

Public functions include:

* acquisition (`Get-AdoBuildRun`, `New-AdoAuthHeader`, `Get-AdoPat`)
* canonical conversion (`ConvertTo-AdoMetricRow`, `ConvertFrom-AdoRunMetadata`)
* persistence (`Import-AdoMetricsJsonl`, `Export-AdoMetricsJsonl`, `Merge-AdoMetricRow`)
* profile loaders (`Resolve-AdoMetricsConfig`, `Get-Ado*Profile`)
* formatter (`New-AdoMetricsReadme`)
* orchestration-ish function (`Update-AdoMetricsReadme`) — likely to move out of module

Private functions include:

* REST paging, schema repair, JSON helpers, utilities
* formatter block helpers (metric blocks)

### Known pain points / drift risks

* Some code paths assume profiles exist (module must work without them).
* Some functions are orchestration-focused and belong in consumer scripts/actions.
* The README formatter must be StrictMode-safe and title-driven from the project profile.

---

## Target state (where we are going)

We will have three user experiences:

1. **Default (V1)**: No profiles required. Pull runs, create canonical rows, persist JSONL.
2. **Enhanced (V2)**: Profiles add defaults + pipeline labels + derived parsing under `.derived`.
3. **Custom (V3)**: Projection layer enables select/rename/lift/custom metrics without mutating canonical store.

---

# Milestone 1 — V1 Default (ADR-001 + “profiles optional” baseline)

## V1 goal

A typical user can run this with **no profiles**:

* Provide org/project/definitionIds
* Provide PAT (or headers)
* Provide a time window (`MinTimeUtc`)
* Create canonical metric rows
* Merge into a JSONL store

## V1 public contract (minimum)

Required:

* `New-AdoAuthHeader`
* `Get-AdoBuildRun`
* `ConvertTo-AdoMetricRow`
* `Import-AdoMetricsJsonl`
* `Export-AdoMetricsJsonl`
* `Merge-AdoMetricRow`

Optional convenience:

* `Get-AdoPat` (Key Vault path is optional; PAT can be passed directly)

## V1 implementation work

### 1) Canonical row must not require profiles

Update `ConvertTo-AdoMetricRow` so it works with:

* no project profile
* no definition profiles
* no derived parsing rules

Rules:

* Always populate standard ADO fields (definition id, name, status/result, timestamps, requestedFor, etc.)
* Always include:

  * `derivedParsed` (default `$false`)
  * `derived` (default `{}`)

Pipeline label fallback order:

1. definition profile label if present
2. ADO `definition.name` if present
3. `"DEF-$definitionId"`

### 2) Import + schema repair must be idempotent

Update `Repair-AdoMetricRowSchema` to:

* only add missing fields
* never overwrite an existing member (no `Add-Member` collisions)

Minimum repair guarantees:

* `derivedParsed` exists
* `derived` exists

### 3) JSONL import/export is the only supported store API

* Ensure `Import-AdoMetricsJsonl` reads JSONL line-by-line (`Read-JsonlFile`)
* Ensure `Export-AdoMetricsJsonl` creates parent directories before writing

### 4) Remove orchestration from module public surface

Move any “job runner” behavior to scripts/examples:

* `Update-AdoMetricsReadme` should move to `/scripts` (or be removed)
* module formatters are allowed, but must be pure (return strings)

### 5) Add V1 quickstart script

Add `/scripts/quickstart-v1.ps1` that demonstrates:

* PAT → header → Get-AdoBuildRun → ConvertTo rows → Import store → Merge → Export store

## V1 definition of done

* ✅ No-profiles quickstart runs successfully under StrictMode
* ✅ Store can be created from scratch and re-run without duplicating entries
* ✅ Import/export work with an empty or missing JSONL file
* ✅ Core Pester tests exist:

  * ConvertTo-AdoMetricRow without profiles produces required fields
  * Merge dedupes by definitionId+adoBuildId
  * Schema repair is idempotent (doesn’t throw on already-repaired rows)

---

# Milestone 2 — V2 Enhanced (ADR-002 full)

## V2 goal

Profiles enhance the experience but are never required.

Profiles provide:

* project defaults (org/project/timezone/definitionIds)
* per-definition labeling (friendly pipeline names)
* optional derived parsing rules

Derived data must remain namespaced:

* `.derivedParsed`
* `.derived.<field>`

## V2 implementation work

* Validate profiles (schema/versioning)
* Definition profile loading supports “no derived fields” profiles
* Derived parsing is optional per definition:

  * if parsing rules exist → attempt parse
  * if parse fails → still emit canonical row with derivedParsed=false

## V2 definition of done

* ✅ Works with mixed profiles (some defs have derived parsing, others don’t)
* ✅ Derived fields never leak into canonical top-level fields
* ✅ Additional tests for definition profiles:

  * label-only profile works
  * derived parsing fills `.derived` when present

---

# Milestone 3 — V3 Custom (ADR-003)

## V3 goal

Users can tailor outputs without changing the canonical store.

Capabilities:

* select fields
* rename fields (aliases)
* lift selected `.derived.*` fields into projected outputs
* define additional custom derived metrics from sources beyond buildNumber

## V3 implementation work

* Introduce projection config in metrics profile:

  * `fields.include`
  * `fields.rename`
  * `fields.liftDerived`
* Add a projector function, e.g. `Select-AdoMetricRowProjection` (public)
* Formatters consume projected rows when desired

## V3 definition of done

* ✅ Canonical store format unchanged
* ✅ Projection is a view (opt-in export)
* ✅ Tests cover selection/rename/lift behavior

---

## What we are intentionally not doing in this module

* Scheduling daily/weekly/monthly/yearly runs
* Git operations (commit/push)
* SharePoint uploads
* Spreadsheet generation (Excel)
* UI orchestration
  These belong in consuming repos / GitHub Actions.

---

## Notes on consumer automation

Consumer repos (GitHub Actions) can implement:

* daily ingestion (update JSONL + README)
* weekly/monthly/yearly reports (filter JSONL store by time window, format, publish artifacts)

The module provides primitives; consumers wire them together.
