Describe "Export-AdoMetricsJsonl" {
  BeforeAll {
   Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force
   . (Join-Path $PSScriptRoot '..\Private\Repair-AdoMetricRowSchema.ps1')
  }

It "roundtrips repaired rows through export/import" {
  $tmp = Join-Path $TestDrive 'roundtrip.jsonl'

  $rows = @(
    [pscustomobject]@{ DefinitionId = 3; AdoBuildId = 30 } # drift input
  )

  Export-AdoMetricsJsonl -Path $tmp -Rows $rows

  $back = @(Import-AdoMetricsJsonl -Path $tmp)

  $back.Count | Should -Be 1
  $back[0].definitionId | Should -Be 3
  $back[0].adoBuildId   | Should -Be 30
  $back[0].derivedParsed | Should -BeFalse
  $back[0].derived.Keys.Count | Should -Be 0
}
}