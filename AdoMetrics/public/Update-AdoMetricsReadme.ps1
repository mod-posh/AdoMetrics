function Update-AdoMetricsReadme {
<#
.SYNOPSIS
Regenerates metrics/README.md from the cumulative JSONL store and profile configuration.

.DESCRIPTION
Reads:
- project.profile.json (org/project/titles/definitionIds)
- metrics.profile.json (which sections to render)
- metrics/data/ado-build-metrics.all.jsonl (cumulative store)

Then writes:
- metrics/README.md

This is intended to run daily after ingest merges new ADO runs into the cumulative store.

.PARAMETER ConfigRoot
Root folder containing profiles (default: ./ado-metrics).

.PARAMETER OutDir
Metrics output directory (default: metrics).

.PARAMETER AllJsonlRelativePath
Relative path under OutDir where the cumulative JSONL store lives.
Default: data/ado-build-metrics.all.jsonl

.EXAMPLE
Update-AdoMetricsReadme -ConfigRoot "./ado-metrics" -OutDir "metrics"
#>
    [CmdletBinding()]
    param(
        [Parameter()][string]$ConfigRoot = "./ado-metrics",
        [Parameter()][string]$OutDir = "metrics",
        [Parameter()][string]$AllJsonlRelativePath = "data/ado-build-metrics.all.jsonl"
    )

    $cfg = Resolve-AdoMetricsConfig -ConfigRoot $ConfigRoot
    $project = Get-AdoProjectProfile -Path $cfg.ProjectProfilePath
    $metrics  = Get-AdoMetricsProfile -Path $cfg.MetricsProfilePath

    $allJsonlPath = Join-Path $OutDir $AllJsonlRelativePath
    $rows = @(Read-Jsonl -Path $allJsonlPath)

    # Basic sort newest-first for consistency
    $rows = @($rows | Sort-Object { $_.queueTimeUtc } -Descending)

    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $readmePath = Join-Path $OutDir "README.md"

    $b = New-Object System.Text.StringBuilder

    $title = [string]$project.titles.readme
    if ([string]::IsNullOrWhiteSpace($title)) { $title = "Azure DevOps Metrics" }

    $null = $b.AppendLine("# $title")
    $null = $b.AppendLine()
    $null = $b.AppendLine("- Organization: **$($project.organization)**")
    $null = $b.AppendLine("- Project: **$($project.project)**")
    $null = $b.AppendLine("- DefinitionIds: **$($project.definitionIds -join ', ')**")
    $null = $b.AppendLine()

    Write-AdoMetricsSections -Builder $b -Rows $rows -ProjectProfile $project -MetricsProfile $metrics -ReportKind "readme"

    [System.IO.File]::WriteAllText($readmePath, $b.ToString())
}
