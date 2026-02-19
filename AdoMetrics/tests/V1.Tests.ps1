Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
  Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force
}

Describe "AdoMetrics V1" {

  It "ConvertTo-AdoMetricRow without profiles produces required fields" {
    $mockRun = [pscustomobject]@{
      id = 12345
      buildNumber = "20260219.1"
      status = "completed"
      result = "succeeded"
      queueTime = (Get-Date).ToUniversalTime()
      definition = [pscustomobject]@{ name = "MyDef" }
    }

    $row = $mockRun | ConvertTo-AdoMetricRow -Organization "org" -Project "proj" -DefinitionId 1111

    $row.definitionId   | Should -Be 1111
    $row.adoBuildId     | Should -Be 12345
    $row.pipelineLabel  | Should -Be "MyDef"
    $row.derivedParsed  | Should -BeFalse
    $row.PSObject.Properties.Name | Should -Contain 'derived'
  }

  It "Merge dedupes by definitionId+adoBuildId" {
    $r1 = [pscustomobject]@{ definitionId = 1; adoBuildId = 10 }
    $r2 = [pscustomobject]@{ definitionId = 1; adoBuildId = 10 }

    $merged = Merge-AdoMetricRow -Store @($r1) -Incoming @($r2)
    $merged.Count | Should -Be 1
  }

  It "Schema repair is idempotent" {
    InModuleScope ModPosh.AdoMetrics {
      $row = [pscustomobject]@{ definitionId = 1; adoBuildId = 100 }

      $r1 = Repair-AdoMetricRowSchema -Row $row
      $r2 = Repair-AdoMetricRowSchema -Row $r1

      $r2.PSObject.Properties.Name | Should -Contain 'derivedParsed'
      $r2.PSObject.Properties.Name | Should -Contain 'derived'
    }
  }
}
