function ConvertTo-AdoMetricRow
{
    <#
.SYNOPSIS
Converts a raw Azure DevOps build run object into a canonical metrics row.

.DESCRIPTION
ConvertTo-AdoMetricRow normalizes an Azure DevOps build run (as returned by the Builds - List REST API)
into a stable, schema-controlled object suitable for JSONL storage and report generation.

The canonical row is composed of:
- Base fields (top-level properties) that are universal across projects
- A derived field bag stored under `.derived` which is populated using definition profiles

Derived fields are extracted from the run's build number (or other configured source field) using
ConvertFrom-AdoRunMetadata and the provided definition profiles. This keeps the module generic and allows
project-specific metadata to be defined outside the module.

The derived bag is intentionally FLAT (no nested objects) to keep JSONL stable and easy to query.

.PARAMETER Build
A single raw build run object returned by the Azure DevOps Builds - List API
(Invoke-WebRequest/Invoke-RestMethod response content items).

.PARAMETER Organization
Azure DevOps organization name (e.g. 'rseng').

.PARAMETER Project
Azure DevOps project name.

.PARAMETER DefinitionProfiles
Definition profile map keyed by definitionId (int). Each definition profile contains parsing patterns used
to extract derived fields for that definitionId. Typically returned by Get-AdoDefinitionProfile.

.OUTPUTS
PSCustomObject representing a single canonical metric row.

.OUTPUT SCHEMA
Top-level fields (universal):
- organization        (string)
- project             (string)
- definitionId        (int)
- pipeline            (string)   # pipeline label from definition profile, else "DEF-<id>"
- pipelineName        (string)   # ADO definition name (if present)
- adoBuildId          (int)
- adoBuildNumber      (string)
- status              (string)
- result              (string)
- queueTimeUtc        (string/datetime) # preserved from ADO payload
- startTimeUtc        (string/datetime) # preserved from ADO payload
- finishTimeUtc       (string/datetime) # preserved from ADO payload
- durationSeconds     (int)      # computed from start/finish when available
- requestedFor        (string)   # display name if present
- derivedParsed       (bool)     # true if a definition profile pattern matched

Derived fields (project-specific):
- derived             (object)   # flat object; keys defined by the definition profile(s)

.EXAMPLE
# Convert raw builds to canonical metric rows
$defs = Get-AdoDefinitionProfile -DefinitionsPath ./ado-metrics/definitions
$rows = foreach ($b in $builds) {
    ConvertTo-AdoMetricRow -Build $b -Organization "rseng" -Project "GlobalBuildAutomation" -DefinitionProfiles $defs
}

.EXAMPLE
# Access derived fields (example)
$row.derived.accountId
$row.derived.embeddedBuildId
$row.derived.cloudProvider

.NOTES
- This function does not perform any I/O (no file reads/writes).
- This function does not perform any report rendering.
- The canonical schema is intended to be stable across time; project-specific additions should be implemented
  as derived fields via definition profiles rather than adding new top-level fields.

.LINK
Azure DevOps REST API: Builds - List
https://learn.microsoft.com/en-us/rest/api/azure/devops/build/builds/list?view=azure-devops-rest-7.1
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Build,
        [Parameter(Mandatory)][string]$Organization,
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][hashtable]$DefinitionProfiles
    )

    $defId = [int]$Build.definition.id

    $pipelineLabel = "DEF-$defId"
    $pipelineName = $null

    if ($Build.definition -and $Build.definition.name)
    {
        $pipelineName = [string]$Build.definition.name
    }

    if ($DefinitionProfiles.ContainsKey($defId))
    {
        $pipelineLabel = [string]$DefinitionProfiles[$defId].pipelineLabel
    }

    $buildNumber = [string]$Build.buildNumber

    # Derived fields are profile-driven and project-specific
    $meta = ConvertFrom-AdoRunMetadata -DefinitionId $defId -BuildNumber $buildNumber -DefinitionProfiles $DefinitionProfiles
    $derived = @{}
    foreach ($k in $meta.Values.Keys) { $derived[$k] = $meta.Values[$k] }

    $requestedForDisplay = $null
    if ($Build.requestedFor -and $Build.requestedFor.displayName)
    {
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
