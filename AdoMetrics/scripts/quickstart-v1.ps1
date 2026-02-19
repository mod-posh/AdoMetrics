[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $Organization,
  [Parameter(Mandatory)] [string] $Project,

  # Accept either one or many
  [Parameter(ParameterSetName='Single', Mandatory)]
  [int] $DefinitionId,

  [Parameter(ParameterSetName='Many', Mandatory)]
  [int[]] $DefinitionIds,

  [Parameter(Mandatory)] [datetime] $MinTimeUtc,

  [Parameter(Mandatory)] [string] $Pat,

  [Parameter()] [string] $StorePath = (Join-Path $PSScriptRoot '..\..\metrics\data\metrics.jsonl')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Canonicalize: always use $DefinitionIds in the rest of the script
if ($PSCmdlet.ParameterSetName -eq 'Single') {
  $DefinitionIds = @($DefinitionId)
} else {
  $DefinitionIds = @($DefinitionIds)
}


Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force

# --- PAT resolution ---
if (-not $Pat) {
  $Pat = $env:ADO_PAT
}

if ([string]::IsNullOrWhiteSpace($Pat)) {
  throw "PAT must be provided via -Pat parameter or ADO_PAT environment variable."
}

# Normalize MinTimeUtc
$MinTimeUtc = $MinTimeUtc.ToUniversalTime()

Write-Host "Organization  : $Organization"
Write-Host "Project       : $Project"
Write-Host "DefinitionIds : $($DefinitionId -join ', ')"
Write-Host "MinTimeUtc    : $MinTimeUtc"
Write-Host "StorePath     : $StorePath"
Write-Host ""

# --- Build header ---
$headers = New-AdoAuthHeader -Pat $Pat

# --- Load existing store (safe if missing) ---
$store = @(Import-AdoMetricsJsonl -Path $StorePath)
Write-Host "Existing rows in store: $($store.Count)"

# collect incoming
$incoming = @()
foreach ($defId in $DefinitionIds) {
  Write-Host "Fetching builds for DefinitionId $defId ..."
  $runs = @(Get-AdoBuildRun -Organization $Organization -Project $Project -DefinitionId $defId -MinTimeUtc $MinTimeUtc -Headers $headers)

  foreach ($run in $runs) {
    $incoming += ($run | ConvertTo-AdoMetricRow -Organization $Organization -Project $Project -DefinitionId $defId)
  }
}

Write-Host "Incoming rows collected: $($incoming.Count)"

$merged = Merge-AdoMetricRow -Store $store -Incoming $incoming
Write-Host "Merged rows total: $($merged.Count)"

Export-AdoMetricsJsonl -Path $StorePath -Rows $merged
Write-Host "Wrote store: $StorePath"
