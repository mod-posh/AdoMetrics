function Read-JsonFile
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path $Path))
    {
        throw "JSON file not found: $Path"
    }

    $raw = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw))
    {
        throw "JSON file is empty: $Path"
    }

    try
    {
        return ($raw | ConvertFrom-Json)
    }
    catch
    {
        throw "Failed to parse JSON file '$Path': $($_.Exception.Message)"
    }
}
