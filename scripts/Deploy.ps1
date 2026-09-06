param([string]$WowRoot, [switch]$Watch)
$ErrorActionPreference = 'Stop'
if (-not $WowRoot) { $WowRoot = $env:WOW_RETAIL_PATH }
if (-not $WowRoot -and (Test-Path "$PSScriptRoot/../.deploy.local.ps1")) {
  . "$PSScriptRoot/../.deploy.local.ps1"
  $WowRoot = $WhatToBuyWowRoot
}
$arguments = @("$PSScriptRoot/deploy.py")
if ($WowRoot) { $arguments += @('--wow-root', $WowRoot) }
if ($Watch) { $arguments += '--watch' }
& python @arguments
if ($LASTEXITCODE -ne 0) { throw 'Deployment failed' }
