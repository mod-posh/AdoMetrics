function Merge-AdoMetricRow {
  [CmdletBinding()]
  param(
    [Parameter()] [object[]] $Store    = @(),
    [Parameter()] [object[]] $Incoming = @()
  )

  $Store    = @($Store)    # normalize $null -> @()
  $Incoming = @($Incoming)

  $all = New-Object System.Collections.Generic.List[object]

  foreach ($r in $Store)    { $all.Add((Repair-AdoMetricRowSchema -Row $r)) }
  foreach ($r in $Incoming) { $all.Add((Repair-AdoMetricRowSchema -Row $r)) }

  $byKey = @{}

  foreach ($r in $all) {
    $defProp   = $r.PSObject.Properties['definitionId']
    $buildProp = $r.PSObject.Properties['adoBuildId']

    if (-not $defProp -or -not $buildProp) { continue }

    $key = "{0}|{1}" -f $defProp.Value, $buildProp.Value
    $byKey[$key] = $r
  }

  return @($byKey.Values)
}
