function Write-MetricBlock-OverallTotals
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory)][object[]]$Rows
    )

    $totalRuns = @($Rows).Count
    $completed = @($Rows | Where-Object { $_.status -eq "completed" }).Count
    $succeeded = @($Rows | Where-Object { $_.result -eq "succeeded" }).Count
    $failed = @($Rows | Where-Object { $_.result -eq "failed" }).Count
    $canceled = @($Rows | Where-Object { $_.result -eq "canceled" -or $_.result -eq "cancelling" }).Count

    $null = $Builder.AppendLine("## Totals (All Time)")
    $null = $Builder.AppendLine()
    $null = $Builder.AppendLine("- Total runs: **$totalRuns**")
    $null = $Builder.AppendLine("- Completed: **$completed**")
    $null = $Builder.AppendLine("- Succeeded: **$succeeded**")
    $null = $Builder.AppendLine("- Failed: **$failed**")
    $null = $Builder.AppendLine("- Canceled: **$canceled**")
    $null = $Builder.AppendLine()
}
