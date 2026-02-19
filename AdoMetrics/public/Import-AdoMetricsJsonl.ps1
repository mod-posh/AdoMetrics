function Import-AdoMetricsJsonl {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $Path
  )

  if (-not (Test-Path $Path)) {
    return @()
  }

  $items = @(Read-JsonlFile -Path $Path)

  # If Read-JsonlFile returned a single array as one item, flatten it
  if ($items.Count -eq 1 -and $items[0] -is [System.Array]) {
    return @($items[0])
  }

  return @($items)
}
