function Import-AdoMetricsJsonl {
<#
.SYNOPSIS
Reads metric rows from a JSONL file.

.DESCRIPTION
Reads JSONL (one JSON object per line). If the file does not exist, returns an empty array.

.PARAMETER Path
Input JSONL path.

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    return @(Read-JsonlFile -Path $Path | ForEach-Object { Repair-AdoMetricRowSchema -Row $_ })
}
