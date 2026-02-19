@{
    RootModule        = 'ModPosh.AdoMetrics.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '442c032e-4c89-487f-ad68-9f57747b03c8'
    Author            = 'Mod-Posh'
    CompanyName       = 'Mod-Posh'
    Copyright         = '(c) Mod-Posh'
    Description       = 'Profile-driven Azure DevOps pipeline metrics ingestion and reporting (JSONL + Markdown).'
    PowerShellVersion = '7.2'

    FunctionsToExport = @(
        'New-AdoAuthHeader',
        'Get-AdoBuildRun',
        'ConvertTo-AdoMetricRow',
        'Import-AdoMetricsJsonl',
        'Export-AdoMetricsJsonl',
        'Merge-AdoMetricRow',
        'Get-AdoPat'
    )

    PrivateData       = @{
        PSData = @{
            Tags       = @('AzureDevOps', 'Metrics', 'JSONL', 'Markdown', 'Automation', 'PlatyPS')
            ProjectUri = 'https://github.com/mod-posh/adometrics'
            LicenseUri = 'https://github.com/mod-posh/adometrics/blob/main/LICENSE'
        }
    }
}
