function Repair-AdoMetricRowSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Row
    )

    # Ensure derivedParsed exists
    if (-not $Row.PSObject.Properties.Match('derivedParsed')) {
        $Row | Add-Member -NotePropertyName derivedParsed -NotePropertyValue $false
    }

    # Ensure derived exists
    if (-not $Row.PSObject.Properties.Match('derived')) {
        $Row | Add-Member -NotePropertyName derived -NotePropertyValue ([pscustomobject]@{})
    }

    return $Row
}
