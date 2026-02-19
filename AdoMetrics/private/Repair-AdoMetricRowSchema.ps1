function Repair-AdoMetricRowSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Row
    )

    if ($null -eq $Row.PSObject.Properties["derivedParsed"]) {
        $Row | Add-Member -NotePropertyName derivedParsed -NotePropertyValue $false
    }

    if ($null -eq $Row.PSObject.Properties["derived"]) {
        $Row | Add-Member -NotePropertyName derived -NotePropertyValue ([pscustomobject]@{})
    }

    return $Row
}
