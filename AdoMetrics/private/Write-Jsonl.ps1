function Write-JsonlFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter(Mandatory)]
    [object[]] $Items
  )

  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  $sb = New-Object System.Text.StringBuilder
  foreach ($item in $Items) {
    # ensure minimum schema before writing
    $null = Repair-AdoMetricRowSchema -Row $item
    [void]$sb.AppendLine(($item | ConvertTo-Json -Depth 50 -Compress))
  }

  [System.IO.File]::WriteAllText($Path, $sb.ToString(), [System.Text.Encoding]::UTF8)
}
