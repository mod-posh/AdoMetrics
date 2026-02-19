function Get-AdoDefinitionProfile
{
    <#
.SYNOPSIS
Loads ADO run parsing profiles keyed by definitionId.

.DESCRIPTION
Loads and validates one or more definition profiles from a folder. Each profile defines:
- definitionId
- pipelineLabel
- buildNumber parsing patterns (regex + mapping of capture groups to canonical fields)

These profiles allow the module to derive BAT-specific metadata (userId/accountId/embeddedBuildId)
from the pipeline buildNumber even though those fields don't exist in the ADO REST payload.

Expected folder layout:
./ado-metrics/definitions/*.json

.PARAMETER DefinitionsPath
Folder containing definition profile JSON files.

.OUTPUTS
Hashtable keyed by [int] definitionId with profile objects as values.

.EXAMPLE
$defs = Get-AdoDefinitionProfile -DefinitionsPath "./ado-metrics/definitions"
$defs[1111].pipelineLabel
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DefinitionsPath
    )

    if (-not (Test-Path $DefinitionsPath))
    {
        throw "Definitions profiles folder not found: $DefinitionsPath"
    }

    $profiles = @{}

    $files = Get-ChildItem -Path $DefinitionsPath -Filter '*.json' | Sort-Object Name
    foreach ($f in $files)
    {
        $p = Read-JsonFile -Path $f.FullName
        Assert-ProfileValid -Profile $p -ProfileType Definition -SourcePath $f.FullName

        $id = [int]$p.definitionId
        $profiles[$id] = $p
    }

    return $profiles
}
