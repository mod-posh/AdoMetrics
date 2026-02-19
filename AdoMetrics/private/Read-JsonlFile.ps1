function Read-JsonlFile
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path -Path $Path))
    {
        return @()
    }

    $items = New-Object System.Collections.Generic.List[object]

    foreach ($line in (Get-Content -Path $Path -ErrorAction Stop))
    {
        $t = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($t)) { continue }

        try
        {
            $items.Add(($t | ConvertFrom-Json -ErrorAction Stop))
        }
        catch
        {
            throw "Failed to parse JSONL line in '$Path': $($_.Exception.Message)`nLine: $t"
        }
    }

    return , $items.ToArray()
}
