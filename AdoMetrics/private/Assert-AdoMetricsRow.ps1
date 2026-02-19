function Assert-AdoMetricsRow {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][object] $Row,
    [Parameter()][int] $Index = -1
  )

  function Fail([string]$Message) {
    $prefix = if ($Index -ge 0) { "Row[$Index]: " } else { "Row: " }
    throw "Assert-AdoMetricsRow: $prefix$Message"
  }

  if ($null -eq $Row) { Fail "Row is `$null." }

  $defProp   = $Row.PSObject.Properties['definitionId']
  $buildProp = $Row.PSObject.Properties['adoBuildId']

  if (-not $defProp)   { Fail "Missing required field 'definitionId'." }
  if (-not $buildProp) { Fail "Missing required field 'adoBuildId'." }

  try { [void][long]$defProp.Value }   catch { Fail "'definitionId' must be numeric/coercible. Value='$($defProp.Value)'." }
  try { [void][long]$buildProp.Value } catch { Fail "'adoBuildId' must be numeric/coercible. Value='$($buildProp.Value)'." }

  $dp = $Row.PSObject.Properties['derivedParsed']
  $d  = $Row.PSObject.Properties['derived']

  if (-not $dp) { Fail "Missing required field 'derivedParsed' (V1 schema guarantee)." }
  if (-not $d)  { Fail "Missing required field 'derived' (V1 schema guarantee)." }

  if ($dp.Value -isnot [bool]) { Fail "'derivedParsed' must be [bool]. ValueType='$($dp.Value.GetType().FullName)'." }

  # Be tolerant: 'derived' might be a PSCustomObject coming from JSON
  if (($d.Value -isnot [hashtable]) -and ($d.Value -isnot [pscustomobject])) {
    Fail "'derived' must be a hashtable/object. ValueType='$($d.Value.GetType().FullName)'."
  }

  return $Row
}
