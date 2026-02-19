# ModPosh.AdoMetrics

**Azure DevOps Metrics Collection — Canonical V1 Baseline.**

---

## Purpose

`ModPosh.AdoMetrics` establishes a deterministic, profile-independent metrics ingestion layer for Azure DevOps build pipelines.

The objective of V1 is architectural clarity:

* Normalize Azure DevOps build runs into a canonical schema
* Persist rows in a JSONL store
* Guarantee idempotent merges
* Eliminate hidden orchestration and implicit behaviors

This milestone intentionally avoids:

* Profile systems
* Derived parsing logic
* Aggregation layers
* Reporting engines
* Opinionated pipeline classification

V1 is the stable substrate.

---

## Architectural Principles

### 1. Deterministic Canonical Schema

All Azure DevOps build runs are converted into a fixed schema (schemaVersion = 1).

There are no conditional fields.
There is no profile dependency.
There is no runtime mutation of structure.

### 2. Idempotent Store Semantics

The JSONL store guarantees:

* Safe re-execution
* Deduplication by stable merge key
* Schema repair without mutation of existing values

Merge Key:

```bash
definitionId + adoBuildId
```

### 3. Explicit Boundaries

The module surface contains only ingestion and storage primitives.

No orchestration.
No scheduling.
No reporting.
No derived enrichment logic.

Execution orchestration lives in `/scripts`.

### 4. Schema Repair is Non-Destructive

`Repair-AdoMetricRowSchema`:

* Adds missing required fields
* Never overwrites existing values
* Is safe to execute multiple times
* Supports legacy casing backfill

This enables forward compatibility without store corruption.

---

## V1 Public Contract

### Authentication

* `New-AdoAuthHeader`

Creates a valid Azure DevOps Basic authentication header.

Accepts:

* Raw PAT
* Base64 encoded `":PAT"`

Automatically normalizes to the required format.

---

### Azure DevOps Ingestion

* `Get-AdoBuildRun`

Fetches build runs for:

* Organization
* Project
* DefinitionId
* Time window

Returns normalized build objects suitable for canonical conversion.

---

### Canonical Conversion

* `ConvertTo-AdoMetricRow`

Transforms an Azure DevOps build run into a canonical metric row.

Profile dependency: **None**

Pipeline label fallback order:

1. Definition profile label (future support)
2. ADO `definition.name`
3. `"DEF-$definitionId"`

Guaranteed Fields:

* `derivedParsed` (default: `$false`)
* `derived` (default: `{}`)

---

### Store Management (JSONL Only)

* `Import-AdoMetricsJsonl`
* `Export-AdoMetricsJsonl`
* `Merge-AdoMetricRow`

Storage format: **JSON Lines**

Behavior:

* Missing file → treated as empty store
* Empty file → treated as empty store
* Parent directories auto-created on export
* Merge is idempotent

---

## Canonical Schema (V1)

Each row conforms to:

```json
{
  "schemaVersion": 1,
  "organization": "string",
  "project": "string",
  "definitionId": 1111,
  "pipelineLabel": "string",
  "adoBuildId": 16838,
  "buildNumber": "string",
  "status": "completed|inProgress|...",
  "result": "succeeded|failed|canceled|...",
  "queueTime": "datetime",
  "startTime": "datetime",
  "finishTime": "datetime",
  "lastChangedDate": "datetime",
  "requestedFor": {},
  "sourceBranch": "string",
  "sourceVersion": "string",
  "url": "string",
  "derivedParsed": false,
  "derived": {}
}
```

### Invariants

* `derivedParsed` always exists
* `derived` always exists
* `schemaVersion` always present
* Merge key fields always present
* No field mutation during schema repair

---

## Quickstart (Reference Implementation)

Located in:

```bash
/scripts/quickstart-v1.ps1
```

Example:

```powershell
.\scripts\quickstart-v1.ps1 `
  -Organization "rseng" `
  -Project "GlobalBuildAutomation" `
  -DefinitionId 1111 `
  -MinTimeUtc "2026-02-01T00:00:00Z" `
  -Pat "<PAT>"
```

Execution flow:

1. Normalize authentication header
2. Fetch build runs
3. Convert to canonical rows
4. Import JSONL store
5. Merge (idempotent)
6. Export updated store

Safe to re-run without duplication.

---

## Testing

Pester v5 coverage validates:

* Canonical row generation without profiles
* DEF fallback behavior
* Merge deduplication semantics
* Schema repair idempotency
* V1 contract integrity

Run:

```powershell
Invoke-Pester -Path .\tests\ -Output Detailed
```

All tests must pass under:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
```

---

## Design Scope (Intentional Constraints)

V1 does **not** include:

* Profile-driven labeling
* Derived metric parsing
* Time-window helpers
* Reporting (Markdown, README generation)
* Aggregations
* Multi-definition orchestration
* Data warehouse integration

Those belong to later milestones.

---

## Architectural Positioning

This module is:

* A canonical ingestion layer
* A stable schema contract
* A merge-safe JSONL persistence layer

It is not:

* A reporting engine
* A scheduling system
* A classification framework
* A metrics analytics platform

V1 exists to establish structural integrity before introducing enrichment layers.

---

## Roadmap (Post-V1)

Future milestones may introduce:

* Definition profiles
* Derived metric extraction (duration, environment, etc.)
* Aggregation helpers
* Markdown reporting
* Multi-project ingestion
* Store compaction strategies
* Structured storage backends

All future expansion will preserve:

* Canonical schema stability
* Idempotent merge semantics
* Explicit contracts
