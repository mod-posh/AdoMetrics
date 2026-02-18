function Get-AdoProjectProfile {
<#
.SYNOPSIS
Loads the ADO Metrics project profile.

.DESCRIPTION
Loads and validates a project profile JSON document that defines:
- Azure DevOps organization and project
- Definition IDs to track
- Timezone (for period window calculations)
- Titles for README/weekly/monthly/yearly reports

This profile is intended to live in the consuming repo under:
./ado-metrics/project.profile.json

.PARAMETER Path
Path to the project.profile.json file.

.OUTPUTS
A PSCustomObject representing the validated project profile.

.EXAMPLE
$project = Get-AdoProjectProfile -Path "./ado-metrics/project.profile.json"
$project.organization
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $profile = Read-JsonFile -Path $Path
    Assert-ProfileValid -Profile $profile -ProfileType Project -SourcePath $Path

    return $profile
}
