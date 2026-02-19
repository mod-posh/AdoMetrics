function Repair-AdoMetricRowSchema {
  [CmdletBinding()]
  param([Parameter(Mandatory)][object] $Row)

  # helper to add only if missing
  function Ensure([string]$Name, $Value) {
    if ($null -eq $Row.PSObject.Properties[$Name]) {
      $Row | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
  }

  # Required by milestone
  Ensure -Name 'derivedParsed' -Value $false
  Ensure -Name 'derived'       -Value @{}

  # V1 merge key support (do NOT overwrite; only backfill from legacy names)
  if (-not $Row.PSObject.Properties.Match('definitionId')) {
    $legacy = $Row.PSObject.Properties['DefinitionId']
    if ($legacy) { Ensure -Name 'definitionId' -Value ([int]$legacy.Value) }
  }

  if (-not $Row.PSObject.Properties.Match('adoBuildId')) {
    $legacy = $Row.PSObject.Properties['AdoBuildId']
    if ($legacy) { Ensure -Name 'adoBuildId' -Value ([int]$legacy.Value) }
  }

  if ($null -eq $Row.PSObject.Properties['derivedParsed']) { throw "Repair-AdoMetricRowSchema failed to add derivedParsed" }

  return $Row
}
