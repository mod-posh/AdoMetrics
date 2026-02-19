function Write-AdoMetricsSections
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory)][object[]]$Rows,
        [Parameter(Mandatory)][object]$ProjectProfile,
        [Parameter(Mandatory)][object]$MetricsProfile,
        [Parameter(Mandatory)][string]$ReportKind  # readme | weekly | monthly | yearly
    )

    $sections = $MetricsProfile.reports.$ReportKind.sections
    if (-not $sections -or $sections.Count -lt 1)
    {
        throw "Metrics profile has no sections for report '$ReportKind'."
    }

    foreach ($s in $sections)
    {
        switch ([string]$s.type)
        {

            'overallTotals'
            {
                Write-MetricBlock-OverallTotals -Builder $Builder -Rows $Rows
                continue
            }

            'totalsPerPipeline'
            {
                Write-MetricBlock-TotalsPerPipeline -Builder $Builder -Rows $Rows -IncludeTotalPipelines:$true
                continue
            }

            'indexWeekly'
            {
                # Placeholder for now (we’ll wire it once weekly reports exist)
                $null = $Builder.AppendLine("## Weekly Metrics")
                $null = $Builder.AppendLine()
                $null = $Builder.AppendLine("> Weekly index will populate once weekly jobs are generating files.")
                $null = $Builder.AppendLine()
                continue
            }

            default
            {
                # Don’t silently ignore: it’s config-driven; missing handler should be visible.
                throw "Unsupported metrics section type '$($s.type)' for report '$ReportKind'."
            }
        }
    }
}
