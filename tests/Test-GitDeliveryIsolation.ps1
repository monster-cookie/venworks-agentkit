#requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$repository = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $repository ('.work/gdi-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
$packageRoot = Join-Path $testRoot 'p'
$packageTests = Join-Path $packageRoot 'tests'
$sourceHarness = Join-Path $PSScriptRoot 'Test-GitDelivery.ps1'
$copiedHarness = Join-Path $packageTests 'Test-GitDelivery.ps1'
$inheritedTemplate = Join-Path $testRoot 't'
$resultPath = Join-Path $testRoot 'isolation-result.json'
$marker = 'GIT_DELIVERY_ISOLATION_INHERITED_HOOK_RAN'
$sentinelVariable = 'GIT_DELIVERY_ISOLATION_SENTINEL'
$script:assertionCount = 0

function Write-TestFile {
    param([string]$Path, [string]$Content)

    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
}

function Assert-True {
    param([bool]$Condition, [string]$Message)

    $script:assertionCount++
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param([AllowNull()]$Expected, [AllowNull()]$Actual, [string]$Message)

    $script:assertionCount++
    if ($Expected -cne $Actual) {
        throw "$Message`nExpected: <$Expected>`nActual:   <$Actual>"
    }
}

function Remove-ProcessEnvironmentValue {
    param([string]$Name)

    if (Test-Path -LiteralPath "Env:$Name") { Remove-Item -LiteralPath "Env:$Name" }
}

function Get-ProcessEnvironmentState {
    param([string]$Name)

    return [pscustomobject]@{
        Present = Test-Path -LiteralPath "Env:$Name"
        Value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    }
}

function Restore-ProcessEnvironmentValue {
    param([string]$Name, [pscustomobject]$State)

    if ($State.Present) {
        Set-Item -LiteralPath "Env:$Name" -Value ([string]$State.Value)
    } else {
        Remove-ProcessEnvironmentValue $Name
    }
}

function Invoke-HarnessVariant {
    param(
        [string]$Name,
        [AllowNull()][string]$TemplatePath,
        [string]$SentinelPath
    )

    if ($TemplatePath) {
        [Environment]::SetEnvironmentVariable('GIT_TEMPLATE_DIR', $TemplatePath, 'Process')
    } else {
        Remove-ProcessEnvironmentValue 'GIT_TEMPLATE_DIR'
    }
    [Environment]::SetEnvironmentVariable($sentinelVariable, $SentinelPath.Replace('\', '/'), 'Process')
    $output = @(& pwsh -NoProfile -File $copiedHarness 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
    $logPath = Join-Path $testRoot "$Name.log"
    Write-TestFile $logPath (($output -join "`n") + "`nexit=$exitCode`n")
    $artifactRoots = @($output | Where-Object { $_ -match '^Artifacts: ' } | ForEach-Object { $_.Substring('Artifacts: '.Length) })
    $activePreReceiveHooks = @($artifactRoots | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | ForEach-Object {
        Get-ChildItem -LiteralPath $_ -Recurse -Force -File -Filter 'pre-receive' | ForEach-Object { $_.FullName }
    })
    return [pscustomobject]@{
        Name = $Name
        ExitCode = $exitCode
        Summary = @($output | Where-Object { $_ -match '^PASS: [0-9]+ groups, [0-9]+ assertions$' })
        IntentionalHookPass = @($output | Where-Object { $_ -ceq 'PASS: Post-hook actual commit tree and remaining worktree reinspection refuses an unreviewed candidate' })
        MarkerObserved = [bool](($output -join "`n") -match [regex]::Escape($marker))
        SentinelExists = Test-Path -LiteralPath $SentinelPath
        ArtifactRoots = $artifactRoots
        ActivePreReceiveHooks = $activePreReceiveHooks
        LogPath = $logPath
    }
}

function Assert-Variant {
    param([pscustomobject]$Run)

    Assert-Equal 0 $Run.ExitCode "$($Run.Name) harness run failed; inspect $($Run.LogPath)."
    Assert-Equal 'PASS: 12 groups, 87 assertions' ($Run.Summary -join "`n") "$($Run.Name) did not complete the full mechanics suite."
    Assert-Equal 1 $Run.IntentionalHookPass.Count "$($Run.Name) lost the deliberate hook-mutation scenario."
    Assert-True (-not $Run.MarkerObserved) "$($Run.Name) executed the inherited template hook marker."
    Assert-True (-not $Run.SentinelExists) "$($Run.Name) created the inherited template hook sentinel."
    Assert-Equal 1 $Run.ArtifactRoots.Count "$($Run.Name) did not report exactly one fixture root."
    $expectedArtifactParent = [IO.Path]::GetFullPath((Join-Path $packageRoot '.work')) + [IO.Path]::DirectorySeparatorChar
    Assert-True ([IO.Path]::GetFullPath($Run.ArtifactRoots[0]).StartsWith($expectedArtifactParent, [StringComparison]::OrdinalIgnoreCase)) "$($Run.Name) fixture escaped the copied package .work directory."
    Assert-Equal 0 $Run.ActivePreReceiveHooks.Count "$($Run.Name) copied an inherited active pre-receive hook into a fixture."
}

$savedTemplate = Get-ProcessEnvironmentState 'GIT_TEMPLATE_DIR'
$savedSentinel = Get-ProcessEnvironmentState $sentinelVariable
$runError = $null
$control = $null
$inherited = $null

try {
    try {
        New-Item -ItemType Directory -Path $packageTests -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $inheritedTemplate 'hooks') -Force | Out-Null
        Copy-Item -LiteralPath $sourceHarness -Destination $copiedHarness
        $sourceHash = (Get-FileHash -LiteralPath $sourceHarness -Algorithm SHA256).Hash
        $copyHash = (Get-FileHash -LiteralPath $copiedHarness -Algorithm SHA256).Hash
        Assert-Equal $sourceHash $copyHash 'Copied Git mechanics harness changed before execution.'

        $hook = @'
#!/bin/sh
printf 'GIT_DELIVERY_ISOLATION_INHERITED_HOOK_RAN\n' >&2
printf 'inherited hook executed\n' > "$GIT_DELIVERY_ISOLATION_SENTINEL"
exit 1
'@
        Write-TestFile (Join-Path $inheritedTemplate 'hooks/pre-receive') ($hook + "`n")

        $controlSentinel = Join-Path $testRoot 'control-inherited-hook.sentinel'
        $inheritedSentinel = Join-Path $testRoot 'inherited-template-hook.sentinel'
        $control = Invoke-HarnessVariant 'control' $null $controlSentinel
        $inherited = Invoke-HarnessVariant 'inherited-template' $inheritedTemplate $inheritedSentinel

        $structuredResult = [ordered]@{
            HarnessSHA256 = $sourceHash
            CopySHA256 = $copyHash
            Control = $control
            InheritedTemplate = $inherited
        }
        Write-TestFile $resultPath (($structuredResult | ConvertTo-Json -Depth 6) + "`n")

        Assert-Variant $control
        Assert-Variant $inherited
        Assert-Equal $sourceHash ((Get-FileHash -LiteralPath $copiedHarness -Algorithm SHA256).Hash) 'Copied harness bytes changed during isolation runs.'
    } catch {
        $runError = $_
    } finally {
        Restore-ProcessEnvironmentValue 'GIT_TEMPLATE_DIR' $savedTemplate
        Restore-ProcessEnvironmentValue $sentinelVariable $savedSentinel
    }

    Assert-Equal ($savedTemplate | ConvertTo-Json -Compress) ((Get-ProcessEnvironmentState 'GIT_TEMPLATE_DIR') | ConvertTo-Json -Compress) 'GIT_TEMPLATE_DIR was not restored for the caller.'
    Assert-Equal ($savedSentinel | ConvertTo-Json -Compress) ((Get-ProcessEnvironmentState $sentinelVariable) | ConvertTo-Json -Compress) "$sentinelVariable was not restored for the caller."
    if ($runError) { throw $runError }

    Write-Output 'PASS: Control harness run ignored ambient templates.'
    Write-Output 'PASS: Inherited rejecting receive hook was isolated while the intentional hook-mutation scenario remained active.'
    Write-Output "PASS: 2 variants, $script:assertionCount assertions"
    Write-Output "Harness SHA256: $sourceHash"
    Write-Output "Artifacts: $testRoot"
    Write-Output "Structured result: $resultPath"
} catch {
    Write-TestFile (Join-Path $testRoot 'failure.log') ($_.Exception.ToString() + "`n")
    Write-Output "FAIL after $script:assertionCount assertions"
    Write-Output "Artifacts: $testRoot"
    if (Test-Path -LiteralPath $resultPath) { Write-Output "Structured result: $resultPath" }
    throw
}
