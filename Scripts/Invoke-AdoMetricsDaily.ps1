function Invoke-AdoMetricsDaily {
<#
.SYNOPSIS
Fetches ADO runs from the last 24 hours (inclusive), merges into the cumulative JSONL store, and updates README.

.DESCRIPTION
- Loads project/definition/metrics profiles.
- Retrieves PAT from Key Vault via REST (SPN client credentials).
- Pulls builds for all definitionIds from the last 24 hours (+ small safety buffer).
- Normalizes builds into canonical metric rows (base + derived bag).
- Merges into metrics/data/ado-build-metrics.all.jsonl (dedupes by definitionId + adoBuildId).
- Regenerates metrics/README.md.

.PARAMETER ConfigRoot
Folder containing project.profile.json, metrics.profile.json, and definitions/.

.PARAMETER OutDir
Output folder (default: metrics).

.PARAMETER KeyVaultName
Key Vault name (no URL).

.PARAMETER TenantId
Azure tenant id for SPN.

.PARAMETER ClientId
Azure client id for SPN.

.PARAMETER ClientSecret
Azure client secret for SPN.

.PARAMETER SecretName
Key Vault secret name that contains the PAT (default: DEVOPSTOKEN).

.PARAMETER HoursBack
How far back to pull. Default 24.

.EXAMPLE
Invoke-AdoMetricsDaily -ConfigRoot "./ado-metrics" -OutDir "metrics" `
  -KeyVaultName $env:azure_keyvault_name `
  -TenantId $env:azure_tenant_id `
  -ClientId $env:azure_client_id `
  -ClientSecret $env:azure_client_secret
#>
    [CmdletBinding()]
    param(
        [Parameter()][string]$ConfigRoot = "./ado-metrics",
        [Parameter()][string]$OutDir = "metrics",

        [Parameter(Mandatory)][string]$KeyVaultName,
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret,
        [Parameter()][string]$SecretName = "DEVOPSTOKEN",

        [Parameter()][int]$HoursBack = 24
    )

    $cfg     = Resolve-AdoMetricsConfig -ConfigRoot $ConfigRoot
    $project = Get-AdoProjectProfile -Path $cfg.ProjectProfilePath
    $defs    = Get-AdoDefinitionProfiles -DefinitionsPath $cfg.DefinitionsPath

    $pat = Get-AdoPat -KeyVaultName $KeyVaultName -SecretName $SecretName -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
    $headers = New-AdoAuthHeader -Pat $pat

    $win = Get-TimeWindowDaily -HoursBack $HoursBack
    $minUtc = $win.MinTimeUtc

    $allBuilds = New-Object System.Collections.Generic.List[object]

    foreach ($defId in @($project.definitionIds)) {
        Write-Host "Fetching builds for definitionId=$defId since $($minUtc.ToString('o')) (UTC)"
        $builds = Get-AdoBuildsPaged -Headers $headers -Organization $project.organization -Project $project.project -DefinitionId ([int]$defId) -MinTimeUtc $minUtc
        foreach ($b in $builds) { $allBuilds.Add($b) }
    }

    $rows = foreach ($b in $allBuilds) {
        ConvertTo-AdoMetricRow -Build $b -Organization $project.organization -Project $project.project -DefinitionProfiles $defs
    }

    # Keep only builds in window by queueTimeUtc if present (server minTime is usually enough, this is extra safety)
    $rows = @($rows | Where-Object {
        $qt = $null
        try { $qt = ([datetime]$_.queueTimeUtc).ToUniversalTime() } catch {}
        if ($null -eq $qt) { $true } else { $qt -ge $minUtc }
    })

    $dataDir = Join-Path $OutDir "data"
    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
    $allJsonlPath = Join-Path $dataDir "ado-build-metrics.all.jsonl"

    $merge = Merge-AdoMetricsStoreJsonl -AllJsonlPath $allJsonlPath -NewRows $rows
    Write-Host "Merged store: existing=$($merge.existingCount) new=$($merge.newCount) merged=$($merge.mergedCount)"

    Update-AdoMetricsReadme -ConfigRoot $ConfigRoot -OutDir $OutDir

    return [pscustomobject]@{
        windowMinUtc   = $minUtc.ToString('o')
        newRows        = @($rows).Count
        mergedCount    = $merge.mergedCount
        allJsonlPath   = $allJsonlPath
        readmePath     = (Join-Path $OutDir "README.md")
    }
}
