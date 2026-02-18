function Get-KeyVaultSecretValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$KeyVaultName,
        [Parameter(Mandatory)][string]$SecretName
    )

    # Note: This assumes the caller already authenticated to Azure (e.g., via azure/login in GitHub Actions
    # and optionally Set-AzContext). We keep this function small and deterministic.
    try {
        # Prefer -AsPlainText when available (Az.KeyVault supports it in modern versions).
        $value = $null

        try {
            $value = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText
        }
        catch {
            # Fallback for older Az.KeyVault versions: SecretValue is a SecureString
            $secret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName
            if ($null -eq $secret -or $null -eq $secret.SecretValue) {
                throw
            }

            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
            try {
                $value = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
            }
            finally {
                if ($bstr -ne [IntPtr]::Zero) {
                    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                }
            }
        }

        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "Key Vault secret '$SecretName' returned empty."
        }

        return $value
    }
    catch {
        throw "Failed to read secret '$SecretName' from Key Vault '$KeyVaultName': $($_.Exception.Message)"
    }
}
