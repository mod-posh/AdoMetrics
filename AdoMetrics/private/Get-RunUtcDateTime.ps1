function Get-RunUtcDateTime
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Value
    )

    if ($null -eq $Value) { return $null }

    try
    {
        return ([datetime]$Value).ToUniversalTime()
    }
    catch
    {
        return $null
    }
}
