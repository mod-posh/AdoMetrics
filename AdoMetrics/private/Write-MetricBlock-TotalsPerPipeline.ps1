function Write-MetricBlock-TotalsPerPipeline
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory)][object[]]$Rows,
        [Parameter()][switch]$IncludeTotalPipelines
    )

    $groups = @($Rows | Group-Object pipeline | Sort-Object Name)
    $pipelineCount = $groups.Count

    $title = "## Totals Per Pipeline"
    if ($IncludeTotalPipelines)
    {
        $title = "## Totals Per Pipeline (Pipelines: $pipelineCount)"
    }

    $null = $Builder.AppendLine($title)
    $null = $Builder.AppendLine()
    $null = $Builder.AppendLine("| Pipeline | Runs | Completed | Succeeded | Failed | Canceled | Avg Duration (min) |")
    $null = $Builder.AppendLine("|---|---:|---:|---:|---:|---:|---:|")

    foreach ($g in $groups)
    {
        $pipeRows = @($g.Group)

        $runs = $pipeRows.Count
        $completed = @($pipeRows | Where-Object { $_.status -eq "completed" }).Count
        $succeeded = @($pipeRows | Where-Object { $_.result -eq "succeeded" }).Count
        $failed = @($pipeRows | Where-Object { $_.result -eq "failed" }).Count
        $canceled = @($pipeRows | Where-Object { $_.result -eq "canceled" -or $_.result -eq "cancelling" }).Count

        $durSecs = @(
            foreach ($r in $pipeRows)
            {
                if ($null -ne $r.PSObject.Properties["durationSeconds"] -and $null -ne $r.durationSeconds)
                {
                    [double]$r.durationSeconds
                }
            }
        )

        $avgMin = ""
        if ($durSecs.Count -gt 0)
        {
            $avgSec = ($durSecs | Measure-Object -Average).Average
            # simple rounding to minutes
            $avgMin = [int][math]::Round($avgSec / 60.0, 0)
        }

        $null = $Builder.AppendLine("| $($g.Name) | $runs | $completed | $succeeded | $failed | $canceled | $avgMin |")
    }

    $null = $Builder.AppendLine()
}
