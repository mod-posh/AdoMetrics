function Test-IsBase64 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Value
    )

    try {
        if ($Value.Length -lt 4) { return $false }
        if ($Value.Length % 4 -ne 0) { return $false }

        # Will throw if not base64
        [Convert]::FromBase64String($Value) | Out-Null
        return $true
    }
    catch {
        return $false
    }
}
