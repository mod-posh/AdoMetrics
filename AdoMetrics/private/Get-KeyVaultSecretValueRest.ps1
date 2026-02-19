function Get-KeyVaultSecretValueRest
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$KeyVaultName,
        [Parameter(Mandatory)][string]$SecretName,
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter()][string]$ApiVersion = "7.4"
    )

    # Secret identifier format:
    # https://{vault-name}.vault.azure.net/secrets/{secret-name}?api-version=7.4
    $uri = "https://$KeyVaultName.vault.azure.net/secrets/$($SecretName)?api-version=$ApiVersion"

    $headers = @{
        Authorization = "Bearer $AccessToken"
        Accept        = "application/json"
    }

    try
    {
        $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    }
    catch
    {
        # Surface Key Vault REST failure cleanly
        throw "Failed to read Key Vault secret '$SecretName' from '$KeyVaultName': $($_.Exception.Message)"
    }

    if (-not $resp.value)
    {
        throw "Key Vault secret '$SecretName' returned empty 'value'."
    }

    return [string]$resp.value
}
