#requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$results = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param(
        [Parameter(Mandatory)][bool] $Condition,
        [Parameter(Mandatory)][string] $Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Get-UniqueStringSetting {
    param(
        [Parameter(Mandatory)][string] $Text,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $Source
    )

    $pattern = '(?m)^[ \t]*' + [regex]::Escape($Name) + '[ \t]*=[ \t]*"([^"\r\n]+)"[ \t]*(?:#.*)?\r?$'
    $matches = [regex]::Matches($Text, $pattern)
    Assert-True ($matches.Count -eq 1) "$Source must contain exactly one quoted '$Name' setting"
    return $matches[0].Groups[1].Value
}

function Get-UniqueIntegerSetting {
    param(
        [Parameter(Mandatory)][string] $Text,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $Source
    )

    $pattern = '(?m)^[ \t]*' + [regex]::Escape($Name) + '[ \t]*=[ \t]*([0-9]+)[ \t]*(?:#.*)?\r?$'
    $matches = [regex]::Matches($Text, $pattern)
    Assert-True ($matches.Count -eq 1) "$Source must contain exactly one integer '$Name' setting"
    return [int] $matches[0].Groups[1].Value
}

function Assert-UniqueLine {
    param(
        [Parameter(Mandatory)][string] $Text,
        [Parameter(Mandatory)][string] $Line,
        [Parameter(Mandatory)][string] $Source
    )

    $matches = [regex]::Matches($Text, '(?m)^' + [regex]::Escape($Line) + '\r?$')
    Assert-True ($matches.Count -eq 1) "$Source must contain exactly one expected line: $Line"
}

$expectedAgents = [ordered]@{
    '3d-modeling' = [pscustomobject]@{ Model = 'gpt-6-astra'; Effort = 'high'; Readme = '3D modeling' }
    'adversarial-review' = [pscustomobject]@{ Model = 'gpt-6-astra'; Effort = 'low'; Readme = 'Adversarial review' }
    'code-review' = [pscustomobject]@{ Model = 'gpt-5.6-sol'; Effort = 'xhigh'; Readme = 'Code review' }
    'coding' = [pscustomobject]@{ Model = 'gpt-5.6-sol'; Effort = 'xhigh'; Readme = 'Coding' }
    'graphic-design' = [pscustomobject]@{ Model = 'gpt-6-astra'; Effort = 'medium'; Readme = 'Graphic design and art' }
    'marketing-docs' = [pscustomobject]@{ Model = 'gpt-5.6-luna'; Effort = 'max'; Readme = 'Marketing documentation' }
    'research' = [pscustomobject]@{ Model = 'gpt-6-astra'; Effort = 'low'; Readme = 'Research' }
    'security-review' = [pscustomobject]@{ Model = 'gpt-5.6-sol'; Effort = 'xhigh'; Readme = 'Security review (opt-in)' }
    'software-architecture' = [pscustomobject]@{ Model = 'gpt-6-astra'; Effort = 'medium'; Readme = 'Software architecture' }
    'tech-ops' = [pscustomobject]@{ Model = 'gpt-5.6-sol'; Effort = 'xhigh'; Readme = 'Tech ops / infrastructure as code' }
    'technical-docs' = [pscustomobject]@{ Model = 'gpt-5.6-luna'; Effort = 'max'; Readme = 'Technical documentation' }
    'user-docs' = [pscustomobject]@{ Model = 'gpt-6-astra'; Effort = 'low'; Readme = 'User documentation' }
}

$allowedEfforts = @{
    'gpt-6-astra' = @('low', 'medium', 'high', 'xhigh')
    'gpt-5.6-sol' = @('none', 'low', 'medium', 'high', 'xhigh')
    'gpt-5.6-terra' = @('none', 'low', 'medium', 'high', 'xhigh')
    'gpt-5.6-luna' = @('none', 'low', 'medium', 'high', 'xhigh', 'max')
}

$agentDirectory = Join-Path $repositoryRoot 'agents'
$expectedNames = @($expectedAgents.Keys | Sort-Object)
$actualNames = @(Get-ChildItem -LiteralPath $agentDirectory -Filter '*.toml' -File | ForEach-Object BaseName | Sort-Object)
Assert-True (($actualNames -join "`n") -ceq ($expectedNames -join "`n")) 'Packaged agent set does not match the expected model matrix'

foreach ($agentName in $expectedNames) {
    $expected = $expectedAgents[$agentName]
    $agentPath = Join-Path $agentDirectory "$agentName.toml"
    $skillPath = Join-Path $repositoryRoot "skills/$agentName/SKILL.md"
    Assert-True (Test-Path -LiteralPath $skillPath -PathType Leaf) "Agent '$agentName' has no matching skill"

    $agentText = [IO.File]::ReadAllText($agentPath)
    $configuredName = Get-UniqueStringSetting -Text $agentText -Name 'name' -Source $agentPath
    $model = Get-UniqueStringSetting -Text $agentText -Name 'model' -Source $agentPath
    $effort = Get-UniqueStringSetting -Text $agentText -Name 'model_reasoning_effort' -Source $agentPath
    $serviceTier = Get-UniqueStringSetting -Text $agentText -Name 'service_tier' -Source $agentPath

    Assert-True ($configuredName -ceq $agentName) "Agent '$agentName' has mismatched name '$configuredName'"
    Assert-True ($model -ceq $expected.Model) "Agent '$agentName' model '$model' does not match '$($expected.Model)'"
    Assert-True ($effort -ceq $expected.Effort) "Agent '$agentName' effort '$effort' does not match '$($expected.Effort)'"
    Assert-True ($allowedEfforts.ContainsKey($model)) "Agent '$agentName' uses unsupported packaged model '$model'"
    Assert-True ($allowedEfforts[$model] -contains $effort) "Agent '$agentName' uses unsupported packaged effort '$effort' for '$model'"
    Assert-True ($effort -cne 'max' -or $model -ceq 'gpt-5.6-luna') "Only GPT-5.6 Luna may use max effort"
    Assert-True ($serviceTier -ceq 'default') "Agent '$agentName' must use the default service tier"
}
$results.Add('Agent files, matching skills, model matrix, effort caps, and service tiers passed.')

$configPath = Join-Path $repositoryRoot 'Config-Settings.toml.example'
$configText = [IO.File]::ReadAllText($configPath)
Assert-True ((Get-UniqueStringSetting -Text $configText -Name 'model' -Source $configPath) -ceq 'gpt-5.6-sol') 'Example root model must be GPT-5.6 Sol'
Assert-True ((Get-UniqueStringSetting -Text $configText -Name 'model_reasoning_effort' -Source $configPath) -ceq 'xhigh') 'Example root effort must be xhigh'
Assert-True ((Get-UniqueStringSetting -Text $configText -Name 'default_subagent_model' -Source $configPath) -ceq 'gpt-5.6-sol') 'Example default subagent model must be GPT-5.6 Sol'
Assert-True ((Get-UniqueStringSetting -Text $configText -Name 'default_subagent_reasoning_effort' -Source $configPath) -ceq 'xhigh') 'Example default subagent effort must be xhigh'
Assert-True ((Get-UniqueIntegerSetting -Text $configText -Name 'max_concurrent_threads_per_session' -Source $configPath) -eq 8) 'Example concurrent-thread ceiling must be eight'
Assert-True ((Get-UniqueStringSetting -Text $configText -Name 'service_tier' -Source $configPath) -ceq 'default') 'Example root must use the default service tier'
$results.Add('Example root, default subagent, concurrency, and service-tier settings passed.')

$routerPath = Join-Path $repositoryRoot 'skills/agent-router/SKILL.md'
$routerText = [IO.File]::ReadAllText($routerPath)
Assert-UniqueLine -Text $routerText -Line '- root/orchestrator: `gpt-5.6-sol` with `xhigh`' -Source $routerPath
foreach ($agentName in $expectedNames) {
    $expected = $expectedAgents[$agentName]
    Assert-UniqueLine -Text $routerText -Line "- ${agentName}: ``$($expected.Model)`` with ``$($expected.Effort)``" -Source $routerPath
}
$results.Add('Agent-router model table passed.')

$displayModels = @{
    'gpt-6-astra' = 'GPT-6 Astra'
    'gpt-5.6-sol' = 'GPT-5.6 Sol'
    'gpt-5.6-terra' = 'GPT-5.6 Terra'
    'gpt-5.6-luna' = 'GPT-5.6 Luna'
}
$readmePath = Join-Path $repositoryRoot 'README.md'
$readmeText = [IO.File]::ReadAllText($readmePath)
foreach ($agentName in $expectedNames) {
    $expected = $expectedAgents[$agentName]
    $line = "| $($expected.Readme) | $($displayModels[$expected.Model]) | $($expected.Effort) |"
    Assert-UniqueLine -Text $readmeText -Line $line -Source $readmePath
}
$results.Add('README model table passed.')

foreach ($result in $results) {
    Write-Output "PASS: $result"
}
