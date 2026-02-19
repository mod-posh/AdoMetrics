# Version 1.0.0 Release

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

## CREATE, ADR-001

* issue-17: Add auth regression tests for raw vs encoded PAT
* issue-10: Create Pester tests
* issue-9: Create scripts\quickstart-v1.ps1

## ENHANCEMENT, ADR-001

* issue-18: Enforce schemaVersion contract in V1 (warn-if-missing, throw-if-newer)
* issue-16: Harden `Export-AdoMetricsJsonl` to validate rows before write
* issue-14: Apply schema repair at merge boundary (store + incoming)
* issue-13: Apply schema repair during JSONL import
* issue-12: Normalize merge keys in Merge-AdoMetricRow

## MODIFY, ADR-001

* issue-8: Modify public\New-AdoMetricsReadme.ps1
* issue-7: Modify ModPosh.AdoMetrics.psd1
* issue-6: Modify public\Get-AdoBuildRun.ps1
* issue-5: Modify public\Export-AdoMetricsJsonl.ps1
* issue-4: Modify public\Import-AdoMetricsJsonl.ps1
* issue-3: Modify private\Repair-AdoMetricRowSchema.ps1
* issue-2: Modify public\ConvertTo-AdoMetricRow.ps1

## ENHANCEMENT, CREATE, ADR-001

* issue-15: Add private `Assert-AdoMetricRow` for boundary validation

## DELETE, ADR-001

* issue-1: Delete (or move out of module entirely)

