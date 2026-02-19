function Get-RowFieldValue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Row,
        [Parameter(Mandatory)][string]$Path
    )

    if ($null -eq $Row) { return $null }
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

    $parts = $Path.Split('.', [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($parts.Count -lt 1) { return $null }

    $current = $Row

    foreach ($p in $parts)
    {
        if ($null -eq $current) { return $null }

        # Support both PSCustomObject properties and hashtables/dictionaries
        if ($current -is [System.Collections.IDictionary])
        {
            if ($current.Contains($p)) { $current = $current[$p] }
            else { return $null }
            continue
        }

        $prop = $current.PSObject.Properties[$p]
        if ($null -eq $prop) { return $null }

        $current = $prop.Value
    }

    return $current
}
