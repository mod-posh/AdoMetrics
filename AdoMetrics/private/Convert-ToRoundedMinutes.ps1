function Convert-ToRoundedMinutes
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][double]$Seconds
    )

    if ($Seconds -lt 0) { $Seconds = 0 }

    # Round down if remainder <= 31 seconds, otherwise round up
    $mins = [math]::Floor($Seconds / 60)
    $rem = $Seconds - ($mins * 60)

    if ($rem -gt 31) { $mins++ }
    return [int]$mins
}
