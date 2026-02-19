function Merge-AdoMetricsStoreJsonl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$AllJsonlPath,
        [Parameter(Mandatory)][object[]]$NewRows
    )

    $existing = @(Read-Jsonl -Path $AllJsonlPath)
    $existing = @($existing | ForEach-Object { Ensure-AdoMetricRowSchema -Row $_ })

    $index = @{}

    foreach ($e in $existing) {
        $k = "{0}:{1}" -f $e.definitionId, $e.adoBuildId
        $index[$k] = $e
    }

    foreach ($n in @($NewRows)) {
        $k = "{0}:{1}" -f $n.definitionId, $n.adoBuildId
        $index[$k] = $n
    }

    $merged = @($index.Values | Sort-Object { $_.queueTimeUtc } -Descending)
    Write-Jsonl -Path $AllJsonlPath -Items $merged

    return [pscustomobject]@{
        existingCount = $existing.Count
        newCount      = @($NewRows).Count
        mergedCount   = $merged.Count
    }
}
