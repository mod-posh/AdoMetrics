function Get-PSPropValue {
  [CmdletBinding()]
  param(
    # Must allow $null
    [Parameter()]
    [object] $Object,

    [Parameter(Mandatory)]
    [string] $Name,

    [Parameter()]
    $Default = $null
  )

  if ($null -eq $Object) { return $Default }

  $p = $Object.PSObject.Properties[$Name]
  if ($null -ne $p) { return $p.Value }

  return $Default
}
