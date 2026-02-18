function ConvertFrom-AdoRunMetadata {
<#
.SYNOPSIS
Converts an Azure DevOps build number into derived metadata using a definition profile.

.DESCRIPTION
Uses regex patterns defined in a definition profile (keyed by definitionId) to extract
derived fields from an Azure DevOps build number.

The returned object contains:
- Parsed: indicates whether any pattern matched
- Values: hashtable of derived field values (keys defined by the profile)

.PARAMETER DefinitionId
Build definition id.

.PARAMETER BuildNumber
Azure DevOps build number.

.PARAMETER DefinitionProfiles
Hashtable keyed by definitionId containing definition profile objects.

.OUTPUTS
PSCustomObject with:
- Parsed (bool)
- Values (hashtable)

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$DefinitionId,
        [Parameter(Mandatory)][string]$BuildNumber,
        [Parameter(Mandatory)][hashtable]$DefinitionProfiles
    )

    $values = @{}
    $parsed = $false

    if (-not $DefinitionProfiles.ContainsKey($DefinitionId)) {
        return [pscustomobject]@{ Parsed = $false; Values = $values }
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
                $values[$dest] = $m.Groups[$srcGroup].Value
            }
        }

        $parsed = $true
        break
    }

    return [pscustomobject]@{
        Parsed = $parsed
        Values = $values
    }
}
