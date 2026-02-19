function Get-AdoBuildRun {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string] $Organization,
    [Parameter(Mandatory)] [string] $Project,
    [Parameter(Mandatory)] [int] $DefinitionId,
    [Parameter(Mandatory)] [datetime] $MinTimeUtc,
    [Parameter(Mandatory)] [hashtable] $Headers
  )

  $min = $MinTimeUtc.ToUniversalTime().ToString("o")
  $uri = "https://dev.azure.com/$Organization/$Project/_apis/build/builds?definitions=$DefinitionId&minTime=$min&`$top=100&queryOrder=finishTimeDescending&api-version=7.1"

  # Make sure we always request JSON
  $reqHeaders = @{}
  foreach ($k in $Headers.Keys) { $reqHeaders[$k] = $Headers[$k] }
  if (-not $reqHeaders.ContainsKey('Accept')) { $reqHeaders['Accept'] = 'application/json' }

  try {
    # IMPORTANT: assign to $null first so the response object never hits the pipeline
    $resp = $null
    $resp = Invoke-WebRequest -Method Get -Uri $uri -Headers $reqHeaders -ErrorAction Stop

    $body = $resp.Content
    $trim = if ($null -ne $body) { $body.TrimStart() } else { "" }

    if (-not ($trim.StartsWith('{') -or $trim.StartsWith('['))) {
      $snippet = if ($body) { $body.Substring(0, [Math]::Min(200, $body.Length)) } else { "<empty>" }
      throw "ADO returned non-JSON content. Status=$($resp.StatusCode). ContentType=$($resp.Headers['Content-Type']). Snippet=$snippet"
    }

    $json = $body | ConvertFrom-Json -Depth 50

    if ($null -ne $json -and ($json.PSObject.Properties.Name -contains 'value')) {
      return ,@($json.value)
    }

    if ($json -is [System.Array]) {
      return ,@($json)
    }

    $props = if ($null -ne $json) { ($json.PSObject.Properties.Name -join ', ') } else { '<null>' }
    throw "Unexpected JSON shape from ADO. Missing 'value'. JsonProperties=[$props]"
  }
  catch {
    throw "Get-AdoBuildRun failed. Uri=$uri. $($_.Exception.Message)"
  }
}
