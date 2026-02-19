Describe "Merge-AdoMetricRow" {
  BeforeAll { Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force }

  It "dedupes by definitionId+adoBuildId" {
    $a = [pscustomobject]@{ definitionId = 1; adoBuildId = 10; derivedParsed = $false; derived = @{} }
    $b = [pscustomobject]@{ definitionId = 1; adoBuildId = 10; derivedParsed = $true; derived = @{x = 1 } }

    $merged = Merge-AdoMetricRow -Store @($a) -Incoming @($b)
    $merged.Count | Should -Be 1
    ($merged[0].derivedParsed) | Should -BeTrue
    ($merged[0].derived.x) | Should -Be 1
  }

  It "dedupes when Store uses ints and Incoming uses strings (key normalization)" {
    $a = [pscustomobject]@{ definitionId = 1; adoBuildId = 10; derivedParsed = $false; derived = @{} }
    $b = [pscustomobject]@{ definitionId = '1'; adoBuildId = '10'; derivedParsed = $true; derived = @{x = 1 } }

    $merged = Merge-AdoMetricRow -Store @($a) -Incoming @($b)
    $merged.Count | Should -Be 1
    ($merged[0].derivedParsed) | Should -BeTrue
    ($merged[0].derived.x) | Should -Be 1
  }

  It "dedupes when Store uses strings and Incoming uses ints (key normalization)" {
    $a = [pscustomobject]@{ definitionId = '1'; adoBuildId = '10'; derivedParsed = $false; derived = @{} }
    $b = [pscustomobject]@{ definitionId = 1; adoBuildId = 10; derivedParsed = $true; derived = @{x = 1 } }

    $merged = Merge-AdoMetricRow -Store @($a) -Incoming @($b)
    $merged.Count | Should -Be 1
    ($merged[0].derivedParsed) | Should -BeTrue
    ($merged[0].derived.x) | Should -Be 1
  }

  It "returns incoming when Store is empty" {
    $incoming = @(
      [pscustomobject]@{ definitionId = 1; adoBuildId = 10; derivedParsed = $false; derived = @{} }
    )

    $merged = Merge-AdoMetricRow -Incoming $incoming
    $merged.Count | Should -Be 1
  }

  It "returns Store when Incoming is empty" {
    $store = @(
      [pscustomobject]@{ definitionId = 1; adoBuildId = 10; derivedParsed = $false; derived = @{} }
    )

    $merged = Merge-AdoMetricRow -Store $store
    $merged.Count | Should -Be 1
  }

  It "sanity: test is using the module function we expect" {
  $cmd = Get-Command Merge-AdoMetricRow -ErrorAction Stop
  $cmd.Source | Should -Be 'ModPosh.AdoMetrics'
  $cmd.ScriptBlock.ToString() | Should -Match 'Get-NormalizedKey'
 }

  It "returns empty array when both Store and Incoming are empty" {
    $merged = @(Merge-AdoMetricRow)
    $merged.Count | Should -Be 0
  }
}
