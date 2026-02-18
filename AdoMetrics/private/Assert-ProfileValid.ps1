function Assert-ProfileValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Profile,
        [Parameter(Mandatory)][ValidateSet('Project','Metrics','Definition')] [string]$ProfileType,
        [Parameter()][string]$SourcePath = ''
    )

    $where = if ($SourcePath) { " ($SourcePath)" } else { "" }

    switch ($ProfileType) {
        'Project' {
            if (-not $Profile.organization) { throw "Project profile missing 'organization'$where" }
            if (-not $Profile.project)      { throw "Project profile missing 'project'$where" }
            if (-not $Profile.timezone)     { throw "Project profile missing 'timezone'$where" }
            if (-not $Profile.definitionIds -or $Profile.definitionIds.Count -lt 1) {
                throw "Project profile missing 'definitionIds' (non-empty array)$where"
            }
            if (-not $Profile.titles) { throw "Project profile missing 'titles'$where" }
            foreach ($k in @('readme','weekly','monthly','yearly')) {
                if (-not $Profile.titles.$k) { throw "Project profile missing titles.$k$where" }
            }
        }

        'Metrics' {
            if (-not $Profile.reports) { throw "Metrics profile missing 'reports'$where" }
            foreach ($k in @('readme','weekly','monthly','yearly')) {
                if (-not $Profile.reports.$k) { throw "Metrics profile missing reports.$k$where" }
                if (-not $Profile.reports.$k.sections -or $Profile.reports.$k.sections.Count -lt 1) {
                    throw "Metrics profile missing reports.$k.sections (non-empty array)$where"
                }
            }
        }

        'Definition' {
            if (-not $Profile.definitionId)  { throw "Definition profile missing 'definitionId'$where" }
            if (-not $Profile.pipelineLabel) { throw "Definition profile missing 'pipelineLabel'$where" }
            if (-not $Profile.patterns -or $Profile.patterns.Count -lt 1) {
                throw "Definition profile missing 'patterns' (non-empty array)$where"
            }

            foreach ($pat in $Profile.patterns) {
                if (-not $pat.regex) { throw "Definition profile pattern missing 'regex'$where" }
                if (-not $pat.fields) { throw "Definition profile pattern missing 'fields'$where" }
            }
        }
    }
}
