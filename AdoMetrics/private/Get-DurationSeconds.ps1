function Get-DurationSeconds {
    [CmdletBinding()]
    param(
        [Parameter()][object]$StartTimeUtc,
        [Parameter()][object]$FinishTimeUtc
    )

    $start  = if ($StartTimeUtc)  { Get-RunUtcDateTime -Value $StartTimeUtc } else { $null }
    $finish = if ($FinishTimeUtc) { Get-RunUtcDateTime -Value $FinishTimeUtc } else { $null }

    if (-not $start -or -not $finish) { return $null }

    $sec = ($finish - $start).TotalSeconds
    if ($sec -lt 0) { $sec = 0 }

    return [int][math]::Round($sec)
}
