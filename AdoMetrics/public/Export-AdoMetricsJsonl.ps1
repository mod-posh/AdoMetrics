function Export-AdoMetricsJsonl {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string] $Path,
    [Parameter()][object[]] $Rows = @()
  )

  $Rows = @($Rows)

  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  # Overwrite file with rows only (no leading blank line)
  $Rows | ForEach-Object {
    $_ | ConvertTo-Json -Depth 50 -Compress
  } | Set-Content -Path $Path -Encoding UTF8
}
