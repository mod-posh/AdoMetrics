Describe "Merge-AdoMetricRow" {
  BeforeAll { Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force }

  It "dedupes by definitionId+adoBuildId" {
    $a = [pscustomobject]@{ definitionId=1; adoBuildId=10; derivedParsed=$false; derived=@{} }
    $b = [pscustomobject]@{ definitionId=1; adoBuildId=10; derivedParsed=$true;  derived=@{x=1} }

    $merged = Merge-AdoMetricRow -Store @($a) -Incoming @($b)
    $merged.Count | Should -Be 1
    ($merged[0].derivedParsed) | Should -BeTrue
    ($merged[0].derived.x) | Should -Be 1
  }
}
