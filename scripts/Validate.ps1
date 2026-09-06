param([string]$ExpectedVersion)
$ErrorActionPreference = 'Stop'
$arguments = @("$PSScriptRoot/validate.py")
if ($ExpectedVersion) { $arguments += @('--expected-version', $ExpectedVersion) }
& python @arguments
if ($LASTEXITCODE -ne 0) { throw 'Validation failed' }
