Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe "Import-AdoMetricsJsonl schema repair" {
  BeforeAll {
    Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force
  }

  It "repairs missing derived fields and legacy key casing" {
    $tmp = Join-Path $TestDrive 'drift.jsonl'

    @(
      @{ definitionId = 1; adoBuildId = 10 } | ConvertTo-Json -Compress
      @{ DefinitionId = 2; AdoBuildId = 20 } | ConvertTo-Json -Compress
    ) | Set-Content -Path $tmp -Encoding UTF8

    $rows = @(Import-AdoMetricsJsonl -Path $tmp)

    $rows.Count | Should -Be 2

    $rows[0].PSObject.Properties.Name | Should -Contain 'derivedParsed'
    $rows[0].derivedParsed | Should -BeFalse
    $rows[0].PSObject.Properties.Name | Should -Contain 'derived'

    $rows[1].definitionId  | Should -Be 2
    $rows[1].adoBuildId    | Should -Be 20
    $rows[1].derivedParsed | Should -BeFalse
    $rows[1].derived.Keys.Count | Should -Be 0
  }

  It "warns once and defaults missing schemaVersion to 1" {
    Mock -CommandName Write-Warning -ModuleName 'ModPosh.AdoMetrics' -MockWith { }

    $tmp = Join-Path $TestDrive 'schema-missing.jsonl'
    @(
      @{ definitionId = 1; adoBuildId = 10 } | ConvertTo-Json -Compress
      @{ definitionId = 2; adoBuildId = 20 } | ConvertTo-Json -Compress
    ) | Set-Content -Path $tmp -Encoding UTF8

    $rows = @(Import-AdoMetricsJsonl -Path $tmp)

    $rows[0].schemaVersion | Should -Be 1
    $rows[1].schemaVersion | Should -Be 1

    Should -Invoke -CommandName Write-Warning -ModuleName 'ModPosh.AdoMetrics' -Times 1 -Exactly
  }

  It "throws if any row has schemaVersion > 1" {
    $tmp = Join-Path $TestDrive 'schema-newer.jsonl'
    @(
      @{ schemaVersion = 2; definitionId = 1; adoBuildId = 10 } | ConvertTo-Json -Compress
    ) | Set-Content -Path $tmp -Encoding UTF8

    { Import-AdoMetricsJsonl -Path $tmp | Out-Null } | Should -Throw
  }
}
