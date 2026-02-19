function Write-Jsonl
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object[]]$Items
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir))
    {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $sb = New-Object System.Text.StringBuilder
    foreach ($i in @($Items))
    {
        $null = $sb.AppendLine(($i | ConvertTo-Json -Depth 20 -Compress))
    }

    [System.IO.File]::WriteAllText($Path, $sb.ToString())
}
