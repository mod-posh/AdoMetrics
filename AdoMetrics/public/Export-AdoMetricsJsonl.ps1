function Export-AdoMetricsJsonl
{
  <#
  .SYNOPSIS
  Writes Azure DevOps metric rows to a JSONL (JSON Lines) store file.

  .DESCRIPTION
  Serializes an array of metric row objects to a JSONL file where each
  object is written as a single compressed JSON line.

  This function guarantees:

  • Deterministic overwrite behavior (existing file is replaced)
  • Directory creation if needed
  • UTF-8 encoding
  • One JSON object per line (no wrapping array)
  • Empty input produces an empty file (no blank lines)

  JSON output is compressed and written using a depth of 50 to support
  nested structures such as the `.derived` namespace.

  In V1, this function repairs rows by default prior to export to ensure
  the JSONL store remains canonical even if callers provide partial rows.
  Repair behavior can be disabled via -Repair:$false (diagnostic use).

  .PARAMETER Path
  The filesystem path where the JSONL store will be written.
  If the directory does not exist, it is created automatically.

  .PARAMETER Rows
  The metric row objects to write to the store.
  Defaults to an empty array.

  .PARAMETER Repair
  When specified (default), each exported row is passed through Repair-AdoMetricRowSchema
  to ensure minimum V1 schema guarantees before writing.

  Use -Repair:$false to export rows exactly as provided (diagnostic use).

  .INPUTS
  None

  .OUTPUTS
  None

  Writes directly to the specified file.

  .EXAMPLE
  Export-AdoMetricsJsonl -Path ".\metrics\data\metrics.jsonl" -Rows $rows

  Writes the provided rows to the store file, repairing rows by default.

  .EXAMPLE
  Export-AdoMetricsJsonl -Path "metrics.jsonl"

  Initializes or overwrites the store with an empty dataset.

  .EXAMPLE
  Export-AdoMetricsJsonl -Path "metrics.jsonl" -Rows $rows -Repair:$false

  Exports rows without schema repair (diagnostic use).

  .NOTES
  Architectural Notes (ADR-001):
  - The JSONL file is the authoritative canonical store.
  - V1 export boundaries repair rows by default to enforce schema guarantees.
  - This function does not perform deduplication; Merge-AdoMetricRow is responsible
    for merge semantics.
  - Repairs schemaVersion if missing; throws if schemaVersion > 1

  JSONL format:
  - One compressed JSON object per line
  - No outer array
  - No blank lines

  .LINK
  Import-AdoMetricsJsonl
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string] $Path,
    [Parameter()][object[]] $Rows = @(),
    [Parameter()][bool] $Repair = $true,
    [Parameter()][bool] $Validate = $true
  )

  $Rows = @($Rows)

  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir))
  {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  $toWrite = $Rows

  if ($Repair)
  {
    $toWrite = @(
      foreach ($r in $Rows)
      {
        Repair-AdoMetricRowSchema -Row $r
      }
    )
  }

  if ($Validate) {
    for ($i = 0; $i -lt $toWrite.Count; $i++) {
      Assert-AdoMetricsRow -Row $toWrite[$i] -Index $i | Out-Null
    }
  }

  # Overwrite file with rows only (no leading blank line)
  $lines = @(
    foreach ($r in $toWrite) {
      $r | ConvertTo-Json -Depth 50 -Compress
    }
  )
  Set-Content -Path $Path -Value $lines -Encoding UTF8
}
