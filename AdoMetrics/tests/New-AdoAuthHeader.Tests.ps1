Describe "New-AdoAuthHeader" {
 BeforeAll { Import-Module "$PSScriptRoot/../ModPosh.AdoMetrics.psd1" -Force }

 It "encodes raw PAT as base64 of ':PAT'" {
  $pat = "abc123"
  $h = New-AdoAuthHeader -Pat $pat

  $h.Authorization | Should -Match '^Basic '
  $b64 = $h.Authorization -replace '^Basic\s+', ''
  $decoded = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($b64))

  $decoded | Should -Be ":$pat"
  $h.Accept | Should -Be "application/json"
 }

 It "uses already-encoded base64(':PAT') as-is" {
  $pat = "abc123"
  $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))

  $h = New-AdoAuthHeader -Pat $b64
  ($h.Authorization -replace '^Basic\s+', '') | Should -Be $b64
 }

 It "treats base64 that decodes to non-: prefix as raw PAT" {
  $decoded = "notColonPrefixed"
  $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($decoded))

  $h = New-AdoAuthHeader -Pat $b64
  $outB64 = $h.Authorization -replace '^Basic\s+', ''
  $outDecoded = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($outB64))

  # since it treats input as raw PAT, it encodes ":<original input string>"
  $outDecoded | Should -Be ":$b64"
 }

 It "treats non-base64 input as raw PAT" {
  $pat = "not base64 !!!"
  $h = New-AdoAuthHeader -Pat $pat

  $b64 = $h.Authorization -replace '^Basic\s+', ''
  $decoded = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($b64))

  $decoded | Should -Be ":$pat"
 }

}
