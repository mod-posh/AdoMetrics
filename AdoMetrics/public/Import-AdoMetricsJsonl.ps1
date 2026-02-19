function Import-AdoMetricsJsonl
{
  <#
  .SYNOPSIS
  Imports Azure DevOps metric rows from a JSONL (JSON Lines) store file.

  .DESCRIPTION
  Reads a JSONL file representing the canonical AdoMetrics V1 store format and
  returns an array of metric row objects.

  JSONL (JSON Lines) is a newline-delimited format where each line contains a
  single, self-contained JSON object. Each line represents one metric row.

  This function guarantees the following:

  • Always returns an array (never $null)
  • Returns @() if the file does not exist
  • Normalizes output if the underlying reader returns a single array wrapper
  • By default, repairs rows to meet V1 schema guarantees (derivedParsed, derived namespace)

  Repair behavior is controlled via -Repair. In V1, Repair defaults to enabled
  to ensure the store becomes canonical at the read boundary.

  The function is intentionally tolerant of missing files to support
  idempotent workflows (e.g., first-run scenarios where the store does not
  yet exist).

  .PARAMETER Path
  The filesystem path to the JSONL file representing the metric store.

  If the file does not exist, the function returns an empty array.

  .PARAMETER Repair
  When specified (default), each imported row is passed through Repair-AdoMetricRowSchema
  to ensure minimum V1 schema guarantees.

  Use -Repair:$false to import rows without mutation (primarily for diagnostics).

  .INPUTS
  None

  .OUTPUTS
  System.Object[]

  Returns an array of metric row objects.
  Returns @() if the file does not exist.

  .EXAMPLE
  $rows = Import-AdoMetricsJsonl -Path ".\metrics\data\metrics.jsonl"

  Loads stored metric rows and repairs them to meet V1 schema guarantees.

  .EXAMPLE
  $raw = Import-AdoMetricsJsonl -Path ".\metrics\data\metrics.jsonl" -Repair:$false

  Imports rows without schema repair (diagnostic use).

  .NOTES
  Architectural Notes (ADR-001):
  - Missing store files are treated as an empty dataset.
  - The JSONL store is treated as the authoritative dataset, but V1 read boundaries
    repair rows to re-establish canonical guarantees.
  - Canonical schema guarantees are handled by Repair-AdoMetricRowSchema.

  JSONL expectations:
  - One valid JSON object per line.
  - No wrapping array.
  - No trailing commas.

  .LINK
  Export-AdoMetricsJsonl
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter()]
    [bool] $Repair = $true
  )

  if (-not (Test-Path $Path))
  {
    return @()
  }

  $items = @(Read-JsonlFile -Path $Path)

  # If Read-JsonlFile returned a single array as one item, flatten it
  if ($items.Count -eq 1 -and $items[0] -is [System.Array])
  {
    $items = @($items[0])
  }

  if ($Repair)
  {
    $items = @(
      foreach ($r in $items)
      {
        Repair-AdoMetricRowSchema -Row $r
      }
    )
  }

  return @($items)
}
