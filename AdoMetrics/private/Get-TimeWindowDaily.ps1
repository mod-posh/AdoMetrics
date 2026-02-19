function Get-TimeWindowDaily {
    [CmdletBinding()]
    param(
        [Parameter()][int]$HoursBack = 24
    )

    $nowUtc = (Get-Date).ToUniversalTime()

    # inclusive window: subtract HoursBack and then a small buffer
    # (buffer avoids missing runs if clocks drift or queueTime is near boundary)
    $minUtc = $nowUtc.AddHours(-1 * $HoursBack).AddMinutes(-5)

    return [pscustomobject]@{
        MinTimeUtc = $minUtc
        MaxTimeUtc = $nowUtc
    }
}
