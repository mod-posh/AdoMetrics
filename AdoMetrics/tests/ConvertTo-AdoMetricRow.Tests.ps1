Describe "ConvertTo-AdoMetricRow (no profiles)" {
  BeforeAll {
    Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force
  }

  It "produces required fields with defaults when no profiles provided" {
    $run = [pscustomobject]@{
      id = 42
      buildNumber = "20260219.1"
      status = "completed"
      result = "succeeded"
      queueTime = "2026-02-19T10:00:00Z"
      startTime = "2026-02-19T10:01:00Z"
      finishTime = "2026-02-19T10:05:00Z"
      lastChangedDate = "2026-02-19T10:05:30Z"
      definition = [pscustomobject]@{ name = "My Pipeline" }
      requestedFor = [pscustomobject]@{ displayName="Alex"; uniqueName="alex@x.com"; id="u1" }
      _links = [pscustomobject]@{ web = [pscustomobject]@{ href="https://example" } }
    }

    $row = $run | ConvertTo-AdoMetricRow -Organization "org" -Project "proj" -DefinitionId 123

    $row.definitionId | Should -Be 123
    $row.adoBuildId   | Should -Be 42
    $row.derivedParsed | Should -BeFalse
    $row.derived.Keys.Count | Should -Be 0
    $row.pipelineLabel | Should -Be "My Pipeline"
  }

  It "falls back to DEF-<id> when no definition name exists" {
    $run = [pscustomobject]@{ id = 1; _links = [pscustomobject]@{ web = [pscustomobject]@{ href="x" } } }
    $row = $run | ConvertTo-AdoMetricRow -Organization "org" -Project "proj" -DefinitionId 999
    $row.pipelineLabel | Should -Be "DEF-999"
  }
}
