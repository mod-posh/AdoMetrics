function Get-AdoBuildRun {
<#
.SYNOPSIS
Fetches Azure DevOps build runs for one or more definition IDs.

.DESCRIPTION
Calls the ADO Builds List REST API and handles continuation token paging.
Returns the raw build objects (as returned by ADO).

.PARAMETER Organization
ADO organization (e.g. rseng)

.PARAMETER Project
ADO project (e.g. GlobalBuildAutomation)

.PARAMETER DefinitionIds
One or more pipeline definition IDs.

.PARAMETER Headers
Authorization headers (use New-AdoAuthHeader).

.PARAMETER MinTimeUtc
Optional minimum time (UTC). Only runs after this time are returned.

.OUTPUTS
Array of raw ADO build objects.

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Organization,
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][int[]]$DefinitionIds,
        [Parameter(Mandatory)][hashtable]$Headers,
        [Parameter()][datetime]$MinTimeUtc
    )

    $all = New-Object System.Collections.Generic.List[object]

    foreach ($defId in $DefinitionIds) {
        $runs = Get-AdoBuildsPaged -Headers $Headers -Organization $Organization -Project $Project -DefinitionId $defId @(
            if ($PSBoundParameters.ContainsKey('MinTimeUtc')) { @{ MinTimeUtc = $MinTimeUtc } }
        )
        foreach ($r in $runs) { $all.Add($r) }
    }

    return ,$all.ToArray()
}
