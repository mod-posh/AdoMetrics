function ConvertTo-AdoMetricRow {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [object] $AdoBuildRun,

    [Parameter(Mandatory)]
    [string] $Organization,

    [Parameter(Mandatory)]
    [string] $Project,

    [Parameter(Mandatory)]
    [int] $DefinitionId,

    [Parameter()]
    [object] $DefinitionProfile
  )

  process {
    # --- definition name (optional) ---
    $defObj = Get-PSPropValue -Object $AdoBuildRun -Name 'definition'
    $adoDefinitionName = Get-PSPropValue -Object $defObj -Name 'name'

    # --- label fallback ---
    $profileLabel = $null
    if ($null -ne $DefinitionProfile) {
      if ($DefinitionProfile -is [string]) { $profileLabel = $DefinitionProfile }
      else {
        $profileLabel = Get-PSPropValue -Object $DefinitionProfile -Name 'label'
        if (-not $profileLabel) { $profileLabel = Get-PSPropValue -Object $DefinitionProfile -Name 'Label' }
      }
    }

    $pipelineLabel =
      if ($profileLabel) { $profileLabel }
      elseif ($adoDefinitionName) { $adoDefinitionName }
      else { "DEF-$DefinitionId" }

    # --- requester (optional) ---
    $rf = Get-PSPropValue -Object $AdoBuildRun -Name 'requestedFor'
    $requestedFor = $null
    if ($null -ne $rf) {
      $requestedFor = [pscustomobject]@{
        displayName = Get-PSPropValue -Object $rf -Name 'displayName'
        uniqueName  = Get-PSPropValue -Object $rf -Name 'uniqueName'
        id          = Get-PSPropValue -Object $rf -Name 'id'
      }
    }

    # --- links (optional) ---
    $links = Get-PSPropValue -Object $AdoBuildRun -Name '_links'
    $web   = Get-PSPropValue -Object $links -Name 'web'
    $url   = Get-PSPropValue -Object $web -Name 'href'

    # --- canonical row ---
    $row = [pscustomobject]@{
      schemaVersion = 1

      organization  = $Organization
      project       = $Project

      definitionId  = $DefinitionId
      pipelineLabel = $pipelineLabel

      adoBuildId    = [int](Get-PSPropValue -Object $AdoBuildRun -Name 'id' -Default 0)
      buildNumber   = Get-PSPropValue -Object $AdoBuildRun -Name 'buildNumber'

      status        = Get-PSPropValue -Object $AdoBuildRun -Name 'status'
      result        = Get-PSPropValue -Object $AdoBuildRun -Name 'result'

      queueTime       = Get-PSPropValue -Object $AdoBuildRun -Name 'queueTime'
      startTime       = Get-PSPropValue -Object $AdoBuildRun -Name 'startTime'
      finishTime      = Get-PSPropValue -Object $AdoBuildRun -Name 'finishTime'
      lastChangedDate = Get-PSPropValue -Object $AdoBuildRun -Name 'lastChangedDate'

      requestedFor   = $requestedFor

      sourceBranch   = Get-PSPropValue -Object $AdoBuildRun -Name 'sourceBranch'
      sourceVersion  = Get-PSPropValue -Object $AdoBuildRun -Name 'sourceVersion'

      url            = $url

      # required by milestone
      derivedParsed  = $false
      derived        = @{}
    }

    Repair-AdoMetricRowSchema -Row $row
  }
}
