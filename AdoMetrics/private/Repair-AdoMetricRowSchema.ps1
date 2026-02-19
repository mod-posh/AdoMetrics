function Repair-AdoMetricRowSchema {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][object] $Row
  )

  function Ensure([string]$Name, $Value) {
    if ($null -eq $Row.PSObject.Properties[$Name]) {
      $Row | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
    }
  }

  # ---- schemaVersion contract (V1 supports schemaVersion = 1) ----
  $svProp = $Row.PSObject.Properties['schemaVersion']

  if ($null -eq $svProp) {
    # caller decides whether to warn (Import does warn-once)
    Ensure -Name 'schemaVersion' -Value 1
  }
  else {
    try { $sv = [int]$svProp.Value }
    catch { throw "Repair-AdoMetricRowSchema: 'schemaVersion' must be numeric/coercible. Value='$($svProp.Value)'." }

    if ($sv -gt 1) {
      throw "Repair-AdoMetricRowSchema: Row schemaVersion $sv is newer than supported version 1."
    }

    # normalize weird-but-valid values like "1" -> 1
    if ($svProp.Value -ne $sv) {
      $Row | Add-Member -NotePropertyName 'schemaVersion' -NotePropertyValue $sv -Force
    }
  }

  # ---- Required by milestone ----
  Ensure -Name 'derivedParsed' -Value $false
  Ensure -Name 'derived'       -Value @{}

  # ---- V1 merge key support (do NOT overwrite; only backfill from legacy names) ----
  if (-not $Row.PSObject.Properties.Match('definitionId')) {
    $legacy = $Row.PSObject.Properties['DefinitionId']
    if ($legacy) { Ensure -Name 'definitionId' -Value [int]$legacy.Value }
  }

  if (-not $Row.PSObject.Properties.Match('adoBuildId')) {
    $legacy = $Row.PSObject.Properties['AdoBuildId']
    if ($legacy) { Ensure -Name 'adoBuildId' -Value [int]$legacy.Value }
  }

  return $Row
}
