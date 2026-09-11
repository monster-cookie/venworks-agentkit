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

function Get-UniqueMultilineStringSetting {
    param(
        [Parameter(Mandatory)][string] $Text,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $Source
    )

    $pattern = '(?ms)^[ \t]*' + [regex]::Escape($Name) + '[ \t]*=[ \t]*"""[ \t]*\r?\n(.*?)^[ \t]*"""[ \t]*(?:#.*)?\r?$'
    $matches = [regex]::Matches($Text, $pattern)
    Assert-True ($matches.Count -eq 1) "$Source must contain exactly one multiline '$Name' setting"
    return $matches[0].Groups[1].Value
}

$agentDirectory = Join-Path $repositoryRoot 'agents'
$agentFiles = @(Get-ChildItem -LiteralPath $agentDirectory -Filter '*.toml' -File | Sort-Object Name)
Assert-True ($agentFiles.Count -gt 0) 'At least one packaged agent definition is required'
$agentNames = @($agentFiles | ForEach-Object BaseName | Sort-Object)
$skillNames = @(
    Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'skills') -Directory |
        Where-Object Name -cne 'agent-router' |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf } |
        ForEach-Object Name |
        Sort-Object
)
Assert-True (($agentNames -join "`n") -ceq ($skillNames -join "`n")) 'Packaged agent definitions and specialist skills must have a one-to-one name match'
$configuredNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$validReasoningEfforts = @('none', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max', 'ultra')

foreach ($agentFile in $agentFiles) {
    $agentName = $agentFile.BaseName
    $agentPath = $agentFile.FullName
    $skillPath = Join-Path $repositoryRoot "skills/$agentName/SKILL.md"
    Assert-True (Test-Path -LiteralPath $skillPath -PathType Leaf) "Agent '$agentName' has no matching skill"

    $agentText = [IO.File]::ReadAllText($agentPath)
    $configuredName = Get-UniqueStringSetting -Text $agentText -Name 'name' -Source $agentPath
    $description = Get-UniqueStringSetting -Text $agentText -Name 'description' -Source $agentPath
    $model = Get-UniqueStringSetting -Text $agentText -Name 'model' -Source $agentPath
    $effort = Get-UniqueStringSetting -Text $agentText -Name 'model_reasoning_effort' -Source $agentPath
    $serviceTier = Get-UniqueStringSetting -Text $agentText -Name 'service_tier' -Source $agentPath
    $sandboxMode = Get-UniqueStringSetting -Text $agentText -Name 'sandbox_mode' -Source $agentPath
    $developerInstructions = Get-UniqueMultilineStringSetting -Text $agentText -Name 'developer_instructions' -Source $agentPath

    Assert-True ($configuredName -ceq $agentName) "Agent '$agentName' has mismatched name '$configuredName'"
    Assert-True ($configuredNames.Add($configuredName)) "Agent name '$configuredName' is duplicated"
    Assert-True (-not [string]::IsNullOrWhiteSpace($description)) "Agent '$agentName' must have a description"
    Assert-True (-not [string]::IsNullOrWhiteSpace($model)) "Agent '$agentName' must select a model in its definition"
    Assert-True (-not [string]::IsNullOrWhiteSpace($effort)) "Agent '$agentName' must select a reasoning effort in its definition"
    Assert-True ($validReasoningEfforts -ccontains $effort) "Agent '$agentName' has unrecognized reasoning effort '$effort'"
    Assert-True ($serviceTier -ceq 'default') "Agent '$agentName' must use the default service tier"
    Assert-True ($sandboxMode -cin @('read-only', 'workspace-write')) "Agent '$agentName' has unsupported sandbox mode '$sandboxMode'"
    Assert-True (-not [string]::IsNullOrWhiteSpace($developerInstructions)) "Agent '$agentName' must have developer instructions"

    $skillText = [IO.File]::ReadAllText($skillPath)
    $skillNameMatches = [regex]::Matches($skillText, '(?m)^name:[ \t]*' + [regex]::Escape($agentName) + '[ \t]*\r?$')
    Assert-True ($skillNameMatches.Count -eq 1) "Skill for agent '$agentName' must declare the same name"
}
$results.Add('Discovered agent definitions, unique role names, matching skills, and required runtime fields passed.')

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
$modelIdPattern = '(?i)\bgpt-[a-z0-9][a-z0-9.-]*\b'
Assert-True ($routerText -cnotmatch $modelIdPattern) 'Agent router must not duplicate concrete model IDs from agent definitions'
Assert-True ($routerText -cnotmatch '(?m)^Packaged starting defaults') 'Agent router must not contain a packaged role-model matrix'
Assert-True ($routerText -cmatch 'Treat the matching agent TOML as the authoritative source') 'Agent router must identify agent TOMLs as the runtime-setting source of truth'
$results.Add('Agent-router model-source boundary passed.')

$readmePath = Join-Path $repositoryRoot 'README.md'
$readmeText = [IO.File]::ReadAllText($readmePath)
$modelSettingsMatch = [regex]::Match($readmeText, '(?ms)^## Model settings\r?\n(?<Body>.*?)(?=^### )')
Assert-True $modelSettingsMatch.Success 'README must contain a Model settings section'
$modelSettingsText = $modelSettingsMatch.Groups['Body'].Value
Assert-True ($modelSettingsText -cnotmatch '(?m)^\|[ \t]*Specialist[ \t]*\|') 'README Model settings must not contain a duplicated specialist model table'
Assert-True ($modelSettingsText -cnotmatch $modelIdPattern) 'README Model settings must not duplicate concrete model IDs from agent definitions'
Assert-True ($modelSettingsText -cmatch 'agent definitions are the authoritative source') 'README must identify agent definitions as the runtime-setting source of truth'
Assert-True ($readmeText -cmatch 'eight-thread session ceiling') 'README must document the configured eight-thread session ceiling'
Assert-True ($readmeText -cnotmatch '(?i)\b(?:12|twelve)[ -]+(?:assistants?|threads?)\b') 'README must not retain the stale 12-assistant concurrency claim'
$results.Add('README model-source and concurrency documentation passed.')

foreach ($result in $results) {
    Write-Output "PASS: $result"
}
