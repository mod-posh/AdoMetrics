Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe "Export-AdoMetricsJsonl" {
  BeforeAll {
    Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force
  }

  It "roundtrips repaired rows through export/import" {
    $tmp = Join-Path $TestDrive 'roundtrip.jsonl'

    $rows = @(
      [pscustomobject]@{ DefinitionId = 3; AdoBuildId = 30 } # drift input
    )

    Export-AdoMetricsJsonl -Path $tmp -Rows $rows
    $back = @(Import-AdoMetricsJsonl -Path $tmp)

    $back.Count | Should -Be 1
    $back[0].definitionId   | Should -Be 3
    $back[0].adoBuildId     | Should -Be 30
    $back[0].derivedParsed  | Should -BeFalse
    $back[0].derived.Keys.Count | Should -Be 0
  }

  It "throws when a row cannot be made valid (missing keys)" {
    $tmp = Join-Path $TestDrive 'bad.jsonl'
    $rows = @([pscustomobject]@{ foo = 1 })

    { Export-AdoMetricsJsonl -Path $tmp -Rows $rows } | Should -Throw
  }

  It "throws when Validate is enabled and a row is not repairable (missing keys)" {
    $tmp = Join-Path $TestDrive 'bad.jsonl'

    $rows = @(
      [pscustomobject]@{ foo = 1 }  # cannot be repaired into a valid key row
    )

    { Export-AdoMetricsJsonl -Path $tmp -Rows $rows -Repair:$true -Validate:$true } | Should -Throw
  }

  It "does not throw when Validate is disabled (diagnostic export)" {
    $tmp = Join-Path $TestDrive 'novalidate.jsonl'

    $rows = @(
      [pscustomobject]@{ foo = 1 }
    )

    { Export-AdoMetricsJsonl -Path $tmp -Rows $rows -Repair:$false -Validate:$false } | Should -Not -Throw

    (Get-Content -Path $tmp -ErrorAction Stop).Count | Should -Be 1
  }

}
