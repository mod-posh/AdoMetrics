function Merge-AdoMetricRow
{
    <#
.SYNOPSIS
Merges two sets of metric rows, deduping by definitionId + adoBuildId.

.PARAMETER Existing
Existing rows.

.PARAMETER New
New rows.

.OUTPUTS
Merged rows, newest-first.
#>
    [CmdletBinding()]
    param(
        [Parameter()][object[]]$Existing = @(),
        [Parameter()][object[]]$New = @()
    )

    $index = @{}

    foreach ($e in @($Existing))
    {
        $e = Repair-AdoMetricRowSchema -Row $e
        $k = "{0}:{1}" -f $e.definitionId, $e.adoBuildId
        $index[$k] = $e
    }

    foreach ($n in @($New))
    {
        $n = Repair-AdoMetricRowSchema -Row $n
        $k = "{0}:{1}" -f $n.definitionId, $n.adoBuildId
        $index[$k] = $n
    }

    return @($index.Values | Sort-Object { $_.queueTimeUtc } -Descending)
}
