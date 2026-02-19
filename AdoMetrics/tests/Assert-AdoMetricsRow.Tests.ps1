Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IMPORTANT: load at discovery time so InModuleScope can resolve the module
Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force

Describe "Assert-AdoMetricsRow" {

 InModuleScope ModPosh.AdoMetrics {

  It "does not throw for a canonical row" {
   $row = [pscustomobject]@{
    definitionId  = 1
    adoBuildId    = 10
    derivedParsed = $false
    derived       = @{}
   }

   { Assert-AdoMetricsRow -Row $row | Out-Null } | Should -Not -Throw
  }

  It "throws when definitionId is missing" {
   $row = [pscustomobject]@{
    adoBuildId    = 10
    derivedParsed = $false
    derived       = @{}
   }

   { Assert-AdoMetricsRow -Row $row | Out-Null } | Should -Throw
  }

  It "throws when adoBuildId is missing" {
   $row = [pscustomobject]@{
    definitionId  = 1
    derivedParsed = $false
    derived       = @{}
   }

   { Assert-AdoMetricsRow -Row $row | Out-Null } | Should -Throw
  }

  It "throws when ids are not coercible to numbers" {
   $row = [pscustomobject]@{
    definitionId  = "nope"
    adoBuildId    = "alsoNope"
    derivedParsed = $false
    derived       = @{}
   }

   { Assert-AdoMetricsRow -Row $row | Out-Null } | Should -Throw
  }

  It "throws when derivedParsed is missing" {
   $row = [pscustomobject]@{
    definitionId = 1
    adoBuildId   = 10
    derived      = @{}
   }

   { Assert-AdoMetricsRow -Row $row | Out-Null } | Should -Throw
  }

  It "throws when derived is missing" {
   $row = [pscustomobject]@{
    definitionId  = 1
    adoBuildId    = 10
    derivedParsed = $false
   }

   { Assert-AdoMetricsRow -Row $row | Out-Null } | Should -Throw
  }
 }
}
