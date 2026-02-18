function Get-AdoPat {
<#
.SYNOPSIS
Retrieves the Azure DevOps PAT from Azure Key Vault using REST (no Az PowerShell / no azcli).

.DESCRIPTION
Fetches a secret from Azure Key Vault using an Azure AD application (service principal)
and client credentials OAuth flow, then calls the Key Vault REST API.

This is designed for GitHub Actions and other automation where you already have:
- azure_tenant_id
- azure_client_id
- azure_client_secret
- azure_keyvault_name

Optionally supports fallback to an environment variable for local development.

.PARAMETER KeyVaultName
Azure Key Vault name (e.g. "my-keyvault").

.PARAMETER SecretName
Key Vault secret name containing the PAT. Default: DEVOPSTOKEN.

.PARAMETER TenantId
Azure AD tenant ID.

.PARAMETER ClientId
Service Principal client ID (Application/Client ID).

.PARAMETER ClientSecret
Service Principal client secret.

.PARAMETER AllowEnvFallback
If specified, and Key Vault retrieval fails, falls back to reading from an environment variable.

.PARAMETER EnvVarName
Environment variable name to use when AllowEnvFallback is set. Default: DEVOPSTOKEN.

.PARAMETER KeyVaultApiVersion
Key Vault REST api-version parameter. Default: 7.4.

.OUTPUTS
System.String. The raw PAT value.

.EXAMPLE
$pat = Get-AdoPat `
  -KeyVaultName $env:azure_keyvault_name `
  -TenantId $env:azure_tenant_id `
  -ClientId $env:azure_client_id `
  -ClientSecret $env:azure_client_secret

.EXAMPLE
# Local dev fallback
$pat = Get-AdoPat -KeyVaultName "mykv" -TenantId $t -ClientId $c -ClientSecret $s -AllowEnvFallback

.NOTES
Permissions:
- The SPN must have permission to read secrets in the Key Vault (e.g., "Get" on secrets).
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$KeyVaultName,
        [Parameter()][string]$SecretName = "DEVOPSTOKEN",

        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret,

        [Parameter()][switch]$AllowEnvFallback,
        [Parameter()][string]$EnvVarName = "DEVOPSTOKEN",

        [Parameter()][string]$KeyVaultApiVersion = "7.4"
    )

    try {
        # Key Vault uses the resource scope "https://vault.azure.net/.default"
        $token = Get-AadAccessToken `
            -TenantId $TenantId `
            -ClientId $ClientId `
            -ClientSecret $ClientSecret `
            -Scope "https://vault.azure.net/.default"

        return Get-KeyVaultSecretValueRest `
            -KeyVaultName $KeyVaultName `
            -SecretName $SecretName `
            -AccessToken $token `
            -ApiVersion $KeyVaultApiVersion
    }
    catch {
        if ($AllowEnvFallback) {
            $fallback = [Environment]::GetEnvironmentVariable($EnvVarName)
            if (-not [string]::IsNullOrWhiteSpace($fallback)) {
                return $fallback
            }
        }

        throw
    }
}
