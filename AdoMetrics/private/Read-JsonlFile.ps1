function Read-JsonlFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $Path
  )

  if (-not (Test-Path -LiteralPath $Path)) { return @() }

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($line in [System.IO.File]::ReadLines($Path)) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $items.Add(($line | ConvertFrom-Json -Depth 50))
  }
  return ,$items.ToArray()
}
