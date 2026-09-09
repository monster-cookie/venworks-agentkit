#requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$repository = Split-Path -Parent $PSScriptRoot
$referencePath = Join-Path $repository 'skills/agent-router/references/proton-pass.md'
$testRoot = Join-Path $repository ('.work/proton-example-tests-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
$probePath = Join-Path $testRoot 'Test-ChildEnvironment.ps1'
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

function Assert-Throws {
    param([scriptblock]$Operation, [string]$Message)

    $script:assertionCount++
    try {
        & $Operation
    } catch {
        return $_
    }
    throw $Message
}

function Get-ProcessEnvironmentState {
    param([string]$Name)

    $environment = [Environment]::GetEnvironmentVariables('Process')
    return [pscustomobject]@{
        Present = $environment.Contains($Name)
        Value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    }
}

function Restore-ProcessEnvironmentValue {
    param([string]$Name, [pscustomobject]$State)

    if ($State.Present) {
        Set-Item -LiteralPath "Env:$Name" -Value ([string]$State.Value)
    } else {
        if (Test-Path -LiteralPath "Env:$Name") { Remove-Item -LiteralPath "Env:$Name" }
    }
}

function Get-DocumentedExample {
    $markdown = [IO.File]::ReadAllText($referencePath)
    $blocks = @([regex]::Matches($markdown, '(?ms)^```powershell[^\S\r\n]*\r?\n(?<code>.*?)^```[^\S\r\n]*(?:\r?\n|$)'))
    $matches = @($blocks | Where-Object { $_.Groups['code'].Value.Contains('[Diagnostics.ProcessStartInfo]::new') })
    Assert-True ($matches.Count -eq 1) 'Expected exactly one documented PowerShell ProcessStartInfo example.'

    $code = $matches[0].Groups['code'].Value
    $startMarker = '$process = [Diagnostics.Process]::Start($startInfo)'
    $startIndex = $code.IndexOf($startMarker, [StringComparison]::Ordinal)
    Assert-True ($startIndex -ge 0) 'The documented example has no Process.Start seam.'

    return [pscustomobject]@{
        Setup = $code.Substring(0, $startIndex)
        Tail = $code.Substring($startIndex)
    }
}

function Invoke-DocumentedSetup {
    param(
        [string]$Code,
        [string]$PowerShellPath
    )

    $lookups = [Collections.Generic.List[object]]::new()
    function Get-Command {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position = 0)]
            [string]$Name,
            [Management.Automation.CommandTypes]$CommandType
        )

        if ($Name -cnotin @('pass-cli', 'gh')) { throw "Unexpected executable lookup: $Name" }
        $lookups.Add([pscustomobject]@{ Name = $Name; CommandType = $CommandType })
        return [pscustomobject]@{ Source = $PowerShellPath }
    }

    Invoke-Expression $Code
    return [pscustomobject]@{
        StartInfo = $startInfo
        Lookups = @($lookups)
    }
}

function Assert-DocumentedInvocation {
    param(
        [pscustomobject]$Setup,
        [string]$PowerShellPath
    )

    $expectedArguments = @('run', '--', $PowerShellPath, 'api', 'user', '--jq', '.login')
    $actualArguments = @($Setup.StartInfo.ArgumentList)
    Assert-True ($Setup.Lookups.Count -eq 2) 'The example did not resolve exactly two executables.'
    Assert-True (([string]::Join(',', [string[]]$Setup.Lookups.Name)) -ceq 'pass-cli,gh') 'The example resolved unexpected executables.'
    Assert-True (@($Setup.Lookups | Where-Object CommandType -ne ([Management.Automation.CommandTypes]::Application)).Count -eq 0) 'The example did not restrict executable resolution to applications.'
    Assert-True ($Setup.StartInfo.FileName -ceq $PowerShellPath) 'The example did not use the resolved pass-cli path.'
    Assert-True (-not $Setup.StartInfo.UseShellExecute) 'The example enabled shell execution.'
    Assert-True ($Setup.StartInfo.CreateNoWindow) 'The example did not suppress a child console window.'
    Assert-True ($actualArguments.Count -eq $expectedArguments.Count) 'The documented run argument count changed.'
    for ($index = 0; $index -lt $expectedArguments.Count; $index++) {
        Assert-True ($actualArguments[$index] -ceq $expectedArguments[$index]) "The documented run argument at index $index changed."
    }
}

function Assert-IsolatedConstruction {
    param(
        [Diagnostics.ProcessStartInfo]$StartInfo,
        [string[]]$ForbiddenNames
    )

    foreach ($name in $ForbiddenNames) {
        Assert-True (-not $StartInfo.Environment.ContainsKey($name)) "The child environment retained forbidden variable $name."
    }
}

function Write-EnvironmentExpectation {
    param(
        [Diagnostics.ProcessStartInfo]$StartInfo,
        [string[]]$ForbiddenNames,
        [hashtable]$ExpectedValues,
        [string]$Path
    )

    $expectation = [ordered]@{
        ExpectedNames = @($StartInfo.Environment.Keys | Sort-Object)
        ExpectedValues = $ExpectedValues
        ForbiddenNames = $ForbiddenNames
    }
    Write-TestFile $Path (($expectation | ConvertTo-Json -Depth 4) + "`n")
}

function Invoke-DocumentedTailWithProbe {
    param(
        [pscustomobject]$Example,
        [Diagnostics.ProcessStartInfo]$StartInfo,
        [string]$ExpectationPath,
        [int]$RequestedExitCode
    )

    $StartInfo.ArgumentList.Clear()
    foreach ($argument in @('-NoProfile', '-File', $probePath, '-ExpectationPath', $ExpectationPath, '-RequestedExitCode', [string]$RequestedExitCode)) {
        $StartInfo.ArgumentList.Add($argument)
    }
    $startInfo = $StartInfo
    Invoke-Expression $Example.Tail
}

$probe = @'
#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ExpectationPath,
    [int]$RequestedExitCode = 0
)

$expectation = Get-Content -LiteralPath $ExpectationPath -Raw | ConvertFrom-Json
foreach ($name in $expectation.ExpectedNames) {
    if ($null -eq [Environment]::GetEnvironmentVariable([string]$name, 'Process')) { exit 10 }
}
foreach ($property in $expectation.ExpectedValues.PSObject.Properties) {
    $actual = [Environment]::GetEnvironmentVariable($property.Name, 'Process')
    if ($actual -cne [string]$property.Value) { exit 11 }
}
foreach ($name in $expectation.ForbiddenNames) {
    if ($null -ne [Environment]::GetEnvironmentVariable([string]$name, 'Process')) { exit 12 }
}
exit $RequestedExitCode
'@

$managedNames = @(
    'PROTON_PASS_SESSION_DIR',
    'PROTON_PASS_AGENT_REASON',
    'PROTON_PASS_PERSONAL_ACCESS_TOKEN',
    'PROTON_PASS_UNRELATED_REFERENCE',
    'UNRELATED_SERVICE_CREDENTIAL',
    'UNRELATED_PASS_REFERENCE',
    'GH_TOKEN'
)
$savedEnvironment = @{}
foreach ($name in $managedNames) { $savedEnvironment[$name] = Get-ProcessEnvironmentState $name }
$forbiddenNames = @(
    'PROTON_PASS_PERSONAL_ACCESS_TOKEN',
    'PROTON_PASS_UNRELATED_REFERENCE',
    'UNRELATED_SERVICE_CREDENTIAL',
    'UNRELATED_PASS_REFERENCE'
)
$sessionValue = 'synthetic-session-directory'
$reasonValue = 'Synthetic reason for the offline Proton Pass example test.'
$approvedReference = 'pass://replace-with-share-id/replace-with-item-id/replace-with-field'
$expectedValues = @{
    GH_TOKEN = $approvedReference
    PROTON_PASS_SESSION_DIR = $sessionValue
    PROTON_PASS_AGENT_REASON = $reasonValue
}
$runError = $null

try {
    try {
        New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
        Write-TestFile $probePath ($probe + "`n")
        Assert-True $IsWindows 'This regression exercises the documented Windows process-launch example.'
        $powerShellPath = @(Microsoft.PowerShell.Core\Get-Command pwsh -CommandType Application -ErrorAction Stop)[0].Source
        $example = Get-DocumentedExample

        [Environment]::SetEnvironmentVariable('PROTON_PASS_SESSION_DIR', $sessionValue, 'Process')
        [Environment]::SetEnvironmentVariable('PROTON_PASS_AGENT_REASON', $reasonValue, 'Process')
        [Environment]::SetEnvironmentVariable('PROTON_PASS_PERSONAL_ACCESS_TOKEN', 'synthetic-parent-pat', 'Process')
        [Environment]::SetEnvironmentVariable('PROTON_PASS_UNRELATED_REFERENCE', 'pass://unrelated/share/field', 'Process')
        [Environment]::SetEnvironmentVariable('UNRELATED_SERVICE_CREDENTIAL', 'synthetic-unrelated-credential', 'Process')
        [Environment]::SetEnvironmentVariable('UNRELATED_PASS_REFERENCE', 'pass://another/unrelated/field', 'Process')
        [Environment]::SetEnvironmentVariable('GH_TOKEN', 'synthetic-ambient-gh-token', 'Process')

        $setup = Invoke-DocumentedSetup $example.Setup $powerShellPath
        Assert-DocumentedInvocation $setup $powerShellPath
        Assert-IsolatedConstruction $setup.StartInfo $forbiddenNames
        Assert-True ($setup.StartInfo.Environment['GH_TOKEN'] -ceq $approvedReference) 'The child did not receive only the approved GH_TOKEN reference.'
        Assert-True ($setup.StartInfo.Environment['PROTON_PASS_SESSION_DIR'] -ceq $sessionValue) 'The child did not receive the selected session metadata.'
        Assert-True ($setup.StartInfo.Environment['PROTON_PASS_AGENT_REASON'] -ceq $reasonValue) 'The child did not receive the access reason.'
        Assert-True ($setup.StartInfo.Environment.ContainsKey('SystemRoot')) 'The child did not receive the Windows system path.'
        Assert-True ($setup.StartInfo.Environment.ContainsKey('TEMP')) 'The child did not receive the temporary path.'
        $expectationPath = Join-Path $testRoot 'happy-path-expectation.json'
        Write-EnvironmentExpectation $setup.StartInfo $forbiddenNames $expectedValues $expectationPath
        Invoke-DocumentedTailWithProbe $example $setup.StartInfo $expectationPath 0
        Write-Output 'PASS: The documented child environment excludes the parent PAT, unrelated credentials, and unrelated pass references.'
        Write-Output 'PASS: The documented child receives its approved reference, session metadata, reason, and selected platform paths.'

        [Environment]::SetEnvironmentVariable('PROTON_PASS_AGENT_REASON', 'pass://unexpected/metadata/reference', 'Process')
        $null = Assert-Throws { Invoke-DocumentedSetup $example.Setup $powerShellPath } 'The example accepted a pass reference in allowlisted metadata.'
        [Environment]::SetEnvironmentVariable('PROTON_PASS_AGENT_REASON', $reasonValue, 'Process')

        [Environment]::SetEnvironmentVariable('PROTON_PASS_SESSION_DIR', $null, 'Process')
        $null = Assert-Throws { Invoke-DocumentedSetup $example.Setup $powerShellPath } 'The example accepted a missing session directory.'
        [Environment]::SetEnvironmentVariable('PROTON_PASS_SESSION_DIR', $sessionValue, 'Process')
        [Environment]::SetEnvironmentVariable('PROTON_PASS_AGENT_REASON', $null, 'Process')
        $null = Assert-Throws { Invoke-DocumentedSetup $example.Setup $powerShellPath } 'The example accepted a missing access reason.'
        [Environment]::SetEnvironmentVariable('PROTON_PASS_AGENT_REASON', $reasonValue, 'Process')
        Write-Output 'PASS: Invalid or missing required metadata is rejected before launch.'

        $nonzeroSetup = Invoke-DocumentedSetup $example.Setup $powerShellPath
        $nonzeroExpectationPath = Join-Path $testRoot 'nonzero-expectation.json'
        Write-EnvironmentExpectation $nonzeroSetup.StartInfo $forbiddenNames $expectedValues $nonzeroExpectationPath
        $null = Assert-Throws {
            Invoke-DocumentedTailWithProbe $example $nonzeroSetup.StartInfo $nonzeroExpectationPath 23
        } 'The documented tail accepted a nonzero consumer exit.'
        Write-Output 'PASS: The documented process tail rejects a nonzero consumer exit.'

        $unsafeSetupCode = $example.Setup.Replace('$startInfo.Environment.Clear()', '')
        Assert-True ($unsafeSetupCode -cne $example.Setup) 'The Environment.Clear negative control did not alter the example setup.'
        $unsafeSetup = Invoke-DocumentedSetup $unsafeSetupCode $powerShellPath
        $null = Assert-Throws {
            Assert-IsolatedConstruction $unsafeSetup.StartInfo $forbiddenNames
        } 'The isolation invariant did not detect the removed Environment.Clear call.'
        Write-Output 'PASS: Removing Environment.Clear fails the isolation invariant before any child is launched.'
    } catch {
        $runError = $_
    } finally {
        foreach ($name in $managedNames) { Restore-ProcessEnvironmentValue $name $savedEnvironment[$name] }
    }

    foreach ($name in $managedNames) {
        $restored = Get-ProcessEnvironmentState $name
        $saved = $savedEnvironment[$name]
        Assert-True ($restored.Present -eq $saved.Present -and $restored.Value -ceq $saved.Value) "Process environment variable $name was not restored."
    }
    if ($runError) { throw $runError }

    Write-Output "PASS: $script:assertionCount assertions"
    Write-Output "Artifacts: $testRoot"
} catch {
    if (Test-Path -LiteralPath $testRoot -PathType Container) {
        Write-TestFile (Join-Path $testRoot 'failure.log') ($_.Exception.ToString() + "`n")
    }
    Write-Output "FAIL after $script:assertionCount assertions"
    Write-Output "Artifacts: $testRoot"
    throw
}
