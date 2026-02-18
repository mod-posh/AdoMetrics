function ConvertFrom-AdoRunMetadata {
<#
.SYNOPSIS
Converts an Azure DevOps build number into structured metadata using definition profiles.

.DESCRIPTION
Azure DevOps build payloads do not contain certain BAT-specific fields (userId, accountId,
embeddedBuildId GUID). Those values are embedded in buildNumber by naming conventions.

This function applies the parsing rules from the definition profile for the given definitionId.
If no profile exists or no patterns match, it returns parsed = $false and all derived fields empty.

.PARAMETER DefinitionId
Build definition ID (pipeline definition id).

.PARAMETER BuildNumber
The Azure DevOps build number string.

.PARAMETER DefinitionProfiles
Hashtable keyed by definitionId with profile objects as values.

.OUTPUTS
PSCustomObject representing derived metadata.

.EXAMPLE
$defs = Get-AdoDefinitionProfiles -DefinitionsPath "./ado-metrics/definitions"
ConvertFrom-AdoRunMetadata -DefinitionId 1111 -BuildNumber $b.buildNumber -DefinitionProfiles $defs
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$DefinitionId,
        [Parameter(Mandatory)][string]$BuildNumber,
        [Parameter(Mandatory)][hashtable]$DefinitionProfiles
    )

    $out = @{
        parsed               = $false
        pipelineNameFragment = $null
        userId               = $null
        embeddedBuildId      = $null
        accountName          = $null
        accountId            = $null
        cloudProvider        = $null
        runDateYmd           = $null
        runRev               = $null
    }

    if (-not $DefinitionProfiles.ContainsKey($DefinitionId)) {
        return [pscustomobject]$out
    }

    $profile = $DefinitionProfiles[$DefinitionId]

    foreach ($pat in $profile.patterns) {
        $rx = [string]$pat.regex
        $m = [regex]::Match($BuildNumber, $rx)
        if (-not $m.Success) { continue }

        foreach ($kv in $pat.fields.PSObject.Properties) {
            $dest = $kv.Name
            $srcGroup = [string]$kv.Value

            if ($m.Groups[$srcGroup] -and $m.Groups[$srcGroup].Success) {
                $out[$dest] = $m.Groups[$srcGroup].Value
            }
        }

        $out.parsed = $true
        break
    }

    return [pscustomobject]$out
}
