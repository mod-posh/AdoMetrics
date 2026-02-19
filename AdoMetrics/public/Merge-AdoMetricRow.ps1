function Merge-AdoMetricRow
{
  <#
  .SYNOPSIS
  Merges two collections of Azure DevOps metric rows, deduplicating by definitionId + adoBuildId.

  .DESCRIPTION
  Combines Store and Incoming metric row collections into a single set, deduplicated using a composite key
  of (definitionId, adoBuildId). Each row is first passed through Repair-AdoMetricRowSchema to ensure the
  minimum schema guarantees (e.g., derivedParsed and derived).

  For deduplication stability, definitionId and adoBuildId are normalized to numeric values before keying.
  If a row is missing required fields or they are not numeric/coercible, the function throws to avoid
  silently dropping data.

  When duplicate keys exist, the last processed row wins (Incoming overrides Store).

  .PARAMETER Store
  Existing metric rows (the current store). Defaults to an empty array.

  .PARAMETER Incoming
  New metric rows to merge into the store. Defaults to an empty array.

  .OUTPUTS
  System.Object[]
  Returns an array of deduplicated metric row objects.

  .EXAMPLE
  $existingMetrics = @(
    @{ definitionId = 123; adoBuildId = 456; result = 'succeeded' },
    @{ definitionId = 789; adoBuildId = 101; result = 'failed' }
  )

  $newMetrics = @(
    @{ definitionId = 123; adoBuildId = 999; result = 'succeeded' },
    @{ definitionId = '123'; adoBuildId = '456'; result = 'succeeded' }  # Duplicate key (string IDs)
  )

  $merged = Merge-AdoMetricRow -Store $existingMetrics -Incoming $newMetrics

  Merges existing metrics with new metrics and deduplicates correctly even if IDs are strings vs ints.

  .EXAMPLE
  $merged = Merge-AdoMetricRow -Incoming $newlyFetchedMetrics

  Merges newly fetched metrics into an empty store.

  .NOTES
  - Each row is repaired via Repair-AdoMetricRowSchema before merging
  - Deduplication key is based on (definitionId, adoBuildId) after numeric normalization
  - Incoming rows override Store rows on key collisions
  - The function throws if a row is missing required key fields or they are not numeric/coercible
  #>
  [CmdletBinding()]
  param(
    [Parameter()] [object[]] $Store = @(),
    [Parameter()] [object[]] $Incoming = @()
  )

  $Store    = @($Store)     # normalize $null -> @()
  $Incoming = @($Incoming)

  # Explicit empty/empty behavior (V1-friendly no-op)
  if ($Store.Count -eq 0 -and $Incoming.Count -eq 0) {
    return @()
  }
  
  function Get-NormalizedKey {
    param([Parameter(Mandatory)][object] $Row)

    $defProp   = $Row.PSObject.Properties['definitionId']
    $buildProp = $Row.PSObject.Properties['adoBuildId']

    if (-not $defProp)   { throw "Merge-AdoMetricRow: Row missing required field 'definitionId'." }
    if (-not $buildProp) { throw "Merge-AdoMetricRow: Row missing required field 'adoBuildId'." }

    try   { $defId = [long]$defProp.Value }
    catch { throw "Merge-AdoMetricRow: 'definitionId' must be numeric/coercible. Value='$($defProp.Value)'." }

    try   { $buildId = [long]$buildProp.Value }
    catch { throw "Merge-AdoMetricRow: 'adoBuildId' must be numeric/coercible. Value='$($buildProp.Value)'." }

    # stable key string
    return "{0}:{1}" -f $defId, $buildId
  }

  $byKey = @{}

  foreach ($r in $Store) {
    $r = Repair-AdoMetricRowSchema -Row $r
    $byKey[(Get-NormalizedKey -Row $r)] = $r
  }

  foreach ($r in $Incoming) {
    $r = Repair-AdoMetricRowSchema -Row $r
    $byKey[(Get-NormalizedKey -Row $r)] = $r
  }

  # Stable output ordering (helps tests + diffs + deterministic exports)
  return @(
    $byKey.GetEnumerator() |
      Sort-Object Name |
      ForEach-Object { $_.Value }
  )
}
