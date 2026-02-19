function ConvertTo-AdoMetricRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Build,
        [Parameter(Mandatory)][string]$Organization,
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][hashtable]$DefinitionProfiles
    )

    $defId = [int]$Build.definition.id

    $pipelineLabel = "DEF-$defId"
    $pipelineName  = $null

    if ($Build.definition -and $Build.definition.name) {
        $pipelineName = [string]$Build.definition.name
    }

    if ($DefinitionProfiles.ContainsKey($defId)) {
        $pipelineLabel = [string]$DefinitionProfiles[$defId].pipelineLabel
    }

    $buildNumber = [string]$Build.buildNumber

    # Derived fields are profile-driven and project-specific
    $meta = ConvertFrom-AdoRunMetadata -DefinitionId $defId -BuildNumber $buildNumber -DefinitionProfiles $DefinitionProfiles
    $derived = @{}
    foreach ($k in $meta.Values.Keys) { $derived[$k] = $meta.Values[$k] }

    $requestedForDisplay = $null
    if ($Build.requestedFor -and $Build.requestedFor.displayName) {
        $requestedForDisplay = [string]$Build.requestedFor.displayName
    }

    $durationSeconds = Get-DurationSeconds -StartTimeUtc $Build.startTime -FinishTimeUtc $Build.finishTime

    # Canonical base row schema + derived bag
    [pscustomobject]@{
        organization    = $Organization
        project         = $Project

        definitionId    = $defId
        pipeline        = $pipelineLabel
        pipelineName    = $pipelineName

        adoBuildId      = $Build.id
        adoBuildNumber  = $buildNumber

        status          = $Build.status
        result          = $Build.result

        queueTimeUtc    = $Build.queueTime
        startTimeUtc    = $Build.startTime
        finishTimeUtc   = $Build.finishTime
        durationSeconds = $durationSeconds

        requestedFor    = $requestedForDisplay

        # generic derived
        derivedParsed   = [bool]$meta.Parsed
        derived         = [pscustomobject]$derived
    }
}
