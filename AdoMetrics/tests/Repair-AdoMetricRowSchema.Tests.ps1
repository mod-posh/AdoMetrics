Describe "Repair-AdoMetricRowSchema" {
  BeforeAll {
   Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force
   . (Join-Path $PSScriptRoot '..\Private\Repair-AdoMetricRowSchema.ps1')
  }

  It "is idempotent and does not overwrite existing members" {
    $row = [pscustomobject]@{
      derivedParsed = $true
      derived = @{ a = 1 }
    }

    { Repair-AdoMetricRowSchema -Row $row | Out-Null } | Should -Not -Throw
    { Repair-AdoMetricRowSchema -Row $row | Out-Null } | Should -Not -Throw

    $row.derivedParsed | Should -BeTrue
    $row.derived.a | Should -Be 1
  }

  It "adds missing fields without throwing" {
    $row = [pscustomobject]@{ definitionId=1; adoBuildId=2 }
    $fixed = Repair-AdoMetricRowSchema -Row $row
    $fixed.derivedParsed | Should -BeFalse
    $fixed.derived.Keys.Count | Should -Be 0
  }
}
