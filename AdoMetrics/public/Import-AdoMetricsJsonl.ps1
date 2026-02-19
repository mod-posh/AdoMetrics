function Import-AdoMetricsJsonl {
<#
.SYNOPSIS
Reads metric rows from a JSONL file.

.PARAMETER Path
Input JSONL path.

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    return @(Read-Jsonl -Path $Path | ForEach-Object { Repair-AdoMetricRow -Row $_ })
}
