function New-AdoAuthHeader {
<#
.SYNOPSIS
Creates an Azure DevOps REST API Authorization header for a PAT.

.DESCRIPTION
Azure DevOps REST API supports HTTP Basic authentication for Personal Access Tokens (PATs).
The expected format is base64 encoding of the string ":PAT" (username blank, PAT as password).

This function accepts either:
- A raw PAT value
- A base64-encoded value that already represents ":PAT"

It returns a hashtable suitable for Invoke-RestMethod / Invoke-WebRequest -Headers.

.PARAMETER Pat
A raw Azure DevOps PAT OR a pre-encoded base64 value for ":PAT".

.OUTPUTS
System.Collections.Hashtable. Keys: Authorization, Accept.

.EXAMPLE
$pat = Get-AdoPat -KeyVaultName $env:AZURE_KEYVAULT_NAME
$headers = New-AdoAuthHeader -Pat $pat
Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

.EXAMPLE
# If you already have base64(":PAT"), you can pass it directly.
$headers = New-AdoAuthHeader -Pat $env:ADO_PAT_B64

.NOTES
- If Pat is base64 but decodes to something other than a string starting with ':',
  the function treats it as a raw PAT and encodes it correctly.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Pat
    )

    # Accept either:
    # - Raw PAT => encode ":PAT"
    # - Already base64-encoded ":PAT" => use as-is
    $encoded = $null

    if (Test-IsBase64 -Value $Pat) {
        try {
            $decoded = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($Pat))

            if ($decoded.StartsWith(":") -and $decoded.Length -gt 1) {
                $encoded = $Pat
            }
            else {
                $bytes = [Text.Encoding]::ASCII.GetBytes(":$Pat")
                $encoded = [Convert]::ToBase64String($bytes)
            }
        }
        catch {
            $bytes = [Text.Encoding]::ASCII.GetBytes(":$Pat")
            $encoded = [Convert]::ToBase64String($bytes)
        }
    }
    else {
        $bytes = [Text.Encoding]::ASCII.GetBytes(":$Pat")
        $encoded = [Convert]::ToBase64String($bytes)
    }

    return @{
        Authorization = "Basic $encoded"
        Accept        = "application/json"
    }
}
