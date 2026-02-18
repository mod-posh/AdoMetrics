function Read-Jsonl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path $Path)) { return @() }

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($line in (Get-Content -Path $Path)) {
        $t = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($t)) { continue }
        $items.Add(($t | ConvertFrom-Json))
    }

    return ,$items.ToArray()
}
