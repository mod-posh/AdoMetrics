function Export-AdoMetricsJsonl
{
    <#
.SYNOPSIS
Writes metric rows to a JSONL file.

.PARAMETER Path
Output file path.

.PARAMETER Rows
Objects to write as JSONL.

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object[]]$Rows
    )

    Write-Jsonl -Path $Path -Items $Rows
}
