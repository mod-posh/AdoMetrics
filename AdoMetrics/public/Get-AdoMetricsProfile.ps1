function Get-AdoMetricsProfile
{
    <#
.SYNOPSIS
Loads the ADO Metrics metrics profile.

.DESCRIPTION
Loads and validates a metrics profile JSON document that defines:
- Which sections/metrics are included for each report type:
  - readme
  - weekly
  - monthly
  - yearly
- Default options like topN, latestRunsN, correlationTopN

This profile is intended to live in the consuming repo under:
./ado-metrics/metrics.profile.json

.PARAMETER Path
Path to the metrics.profile.json file.

.OUTPUTS
A PSCustomObject representing the validated metrics profile.

.EXAMPLE
$metrics = Get-AdoMetricsProfile -Path "./ado-metrics/metrics.profile.json"
$metrics.reports.weekly.sections
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $profile = Read-JsonFile -Path $Path
    Assert-ProfileValid -Profile $profile -ProfileType Metrics -SourcePath $Path

    return $profile
}
