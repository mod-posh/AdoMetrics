function Get-AdoBuildsPaged {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Headers,
        [Parameter(Mandatory)][string]$Organization,
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][int]$DefinitionId,

        # Windowing
        [Parameter()][datetime]$MinTimeUtc,

        # API behavior
        [Parameter()][int]$Top = 200,
        [Parameter()][ValidateSet('finishTimeDescending','finishTimeAscending','queueTimeDescending','queueTimeAscending','startTimeDescending','startTimeAscending')]
        [string]$QueryOrder = 'finishTimeDescending',

        [Parameter()][string]$ApiVersion = '7.1'
    )

    $base = "https://dev.azure.com/$Organization/$Project/_apis/build/builds"

    $all = New-Object System.Collections.Generic.List[object]
    $continuationToken = $null

    while ($true) {

        $qs = @(
            "api-version=$ApiVersion"
            "definitions=$DefinitionId"
            "`$top=$Top"
            "queryOrder=$QueryOrder"
        )

        if ($PSBoundParameters.ContainsKey('MinTimeUtc')) {
            $minIso = $MinTimeUtc.ToUniversalTime().ToString('o')
            $qs += "minTime=$([Uri]::EscapeDataString($minIso))"
        }

        if ($continuationToken) {
            $qs += "continuationToken=$([Uri]::EscapeDataString($continuationToken))"
        }

        $url = "$($base)?$($qs -join '&')"

        $resp = Invoke-WebRequest -Method Get -Uri $url -Headers $Headers -ErrorAction Stop
        $json = $resp.Content | ConvertFrom-Json

        if ($json -and $json.value) {
            foreach ($b in $json.value) { $all.Add($b) }
        }

        # Continuation token header name can vary in casing
        $ct = $null
        foreach ($name in @("x-ms-continuationtoken", "X-MS-ContinuationToken", "x-ms-continuationToken")) {
            if ($resp.Headers[$name]) { $ct = $resp.Headers[$name]; break }
        }

        if ([string]::IsNullOrWhiteSpace($ct)) { break }
        $continuationToken = $ct
    }

    return ,$all.ToArray()
}
