function Resolve-AdoMetricsConfig {
<#
.SYNOPSIS
Resolves the standard ado-metrics configuration paths.

.DESCRIPTION
Given a root configuration folder (default: ./ado-metrics), this function resolves the
expected files and folders:
- project.profile.json
- metrics.profile.json
- definitions/ (folder)

This is a DX helper to keep workflows and scripts clean. Downstream functions can accept
the returned object rather than multiple individual paths.

.PARAMETER ConfigRoot
Root folder containing ado-metrics configuration files.

.OUTPUTS
PSCustomObject with:
- ConfigRoot
- ProjectProfilePath
- MetricsProfilePath
- DefinitionsPath

.EXAMPLE
$cfg = Resolve-AdoMetricsConfig -ConfigRoot "./ado-metrics"
$cfg.ProjectProfilePath

#>
    [CmdletBinding()]
    param(
        [Parameter()][string]$ConfigRoot = "./ado-metrics"
    )

    $root = (Resolve-Path $ConfigRoot).Path

    $projectProfile = Join-Path $root "project.profile.json"
    $metricsProfile = Join-Path $root "metrics.profile.json"
    $definitionsDir = Join-Path $root "definitions"

    if (-not (Test-Path $projectProfile)) { throw "Missing project profile: $projectProfile" }
    if (-not (Test-Path $metricsProfile)) { throw "Missing metrics profile: $metricsProfile" }
    if (-not (Test-Path $definitionsDir)) { throw "Missing definitions folder: $definitionsDir" }

    [pscustomobject]@{
        ConfigRoot         = $root
        ProjectProfilePath = $projectProfile
        MetricsProfilePath = $metricsProfile
        DefinitionsPath    = $definitionsDir
    }
}
