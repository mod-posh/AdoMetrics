function Get-AadAccessToken
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret,
        [Parameter(Mandatory)][string]$Scope
    )

    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
        scope         = $Scope
    }

    try
    {
        $resp = Invoke-RestMethod -Method Post -Uri $tokenUri -Body $body -ContentType "application/x-www-form-urlencoded"
    }
    catch
    {
        throw "Failed to acquire AAD token: $($_.Exception.Message)"
    }

    if (-not $resp.access_token)
    {
        throw "Failed to acquire AAD token: response did not contain access_token."
    }

    return [string]$resp.access_token
}
