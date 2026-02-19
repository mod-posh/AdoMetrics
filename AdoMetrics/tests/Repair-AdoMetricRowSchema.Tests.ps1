Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IMPORTANT: load at discovery time so InModuleScope can resolve the module
Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force

Describe "Repair-AdoMetricRowSchema" {

  InModuleScope ModPosh.AdoMetrics {

    It "is idempotent and does not overwrite existing members" {
      $row = [pscustomobject]@{
        derivedParsed = $true
        derived       = @{ a = 1 }
      }

      { Repair-AdoMetricRowSchema -Row $row | Out-Null } | Should -Not -Throw
      { Repair-AdoMetricRowSchema -Row $row | Out-Null } | Should -Not -Throw

      $row.derivedParsed | Should -BeTrue
      $row.derived.a | Should -Be 1
    }

    It "adds missing fields without throwing" {
      $row = [pscustomobject]@{ definitionId = 1; adoBuildId = 2 }

      $fixed = Repair-AdoMetricRowSchema -Row $row

      $fixed.derivedParsed | Should -BeFalse
      $fixed.derived.Keys.Count | Should -Be 0
    }

    It "defaults schemaVersion to 1 when missing" {
      $row = [pscustomobject]@{ definitionId = 1; adoBuildId = 2 }
      $fixed = Repair-AdoMetricRowSchema -Row $row
      $fixed.schemaVersion | Should -Be 1
    }

    It "accepts schemaVersion 1 (including coercible string)" {
      $row = [pscustomobject]@{ schemaVersion = '1'; definitionId = 1; adoBuildId = 2 }
      $fixed = Repair-AdoMetricRowSchema -Row $row
      $fixed.schemaVersion | Should -Be 1
    }

    It "throws if schemaVersion is greater than 1" {
      $row = [pscustomobject]@{ schemaVersion = 2; definitionId = 1; adoBuildId = 2 }
      { Repair-AdoMetricRowSchema -Row $row | Out-Null } | Should -Throw
    }
  }
}
