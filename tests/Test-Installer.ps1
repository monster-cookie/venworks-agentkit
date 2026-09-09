#requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$repository = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $repository ('.work/installer-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$results = [Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function New-Package {
    param([string]$Name)
    $destination = Join-Path $testRoot $Name
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    foreach ($name in @('agents', 'skills', 'prompts', 'tools', 'example', 'Config-Settings.toml.example', 'VERSION')) {
        $source = Join-Path $repository $name
        if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination (Join-Path $destination $name) -Recurse }
    }
    return $destination
}

function Invoke-Install {
    param([string]$Package, [string]$Target, [string[]]$Options = @(), [switch]$ExpectFailure)
    $installer = Join-Path $Package 'tools\Install-CodexAgents.ps1'
    $log = @(& pwsh -NoProfile -File $installer -CodexRoot $Target @Options 2>&1)
    $exitCode = $LASTEXITCODE
    $log | Set-Content -LiteralPath (Join-Path $testRoot ('run-' + [guid]::NewGuid().ToString('N') + '.log'))
    if ($ExpectFailure) { Assert-True ($exitCode -ne 0) "Expected failure: $($log -join [Environment]::NewLine)" }
    else { Assert-True ($exitCode -eq 0) "Installer failed: $($log -join [Environment]::NewLine)" }
}

function Get-TreeState {
    param([string]$Root)
    $state = @(if (Test-Path -LiteralPath $Root) {
        Get-ChildItem -LiteralPath $Root -Recurse -Force -File | Sort-Object FullName | ForEach-Object {
            [IO.Path]::GetRelativePath($Root, $_.FullName) + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash
        }
    })
    return $state -join "`n"
}

function Assert-Payload {
    param([string]$Package, [string]$Target)
    foreach ($area in @('agents', 'skills', 'prompts')) {
        foreach ($file in Get-ChildItem -LiteralPath (Join-Path $Package $area) -File -Recurse) {
            $installed = Join-Path $Target ([IO.Path]::GetRelativePath($Package, $file.FullName))
            Assert-True (Test-Path -LiteralPath $installed -PathType Leaf) "Missing installed file: $installed"
            Assert-True ((Get-FileHash -LiteralPath $file.FullName).Hash -eq (Get-FileHash -LiteralPath $installed).Hash) "Payload mismatch: $installed"
        }
    }
}

function Assert-BackupContains {
    param([string]$Target, [string]$Content)
    $matching = @(Get-ChildItem -LiteralPath (Join-Path $Target '.venworks-agentkit/backups') -File -Recurse | Where-Object {
        [IO.File]::ReadAllText($_.FullName) -ceq $Content
    })
    Assert-True ($matching.Count -gt 0) 'Expected original bytes in backup'
}

$package = New-Package 'package'
$fresh = Join-Path $testRoot 'fresh'
Invoke-Install $package $fresh -Options @('-WhatIf')
Assert-True (-not (Test-Path -LiteralPath $fresh)) 'WhatIf created the home'
Invoke-Install $package $fresh
Assert-Payload $package $fresh
Assert-True (-not (Test-Path -LiteralPath (Join-Path $fresh 'config.toml'))) 'Default install created config'
$before = Get-TreeState $fresh
Invoke-Install $package $fresh
Assert-True ($before -ceq (Get-TreeState $fresh)) 'Identical install changed state or backups'
$results.Add('Fresh install, all payload hashes, no default config creation, WhatIf and no-op repeat passed.')

$initialized = Join-Path $testRoot 'initialized'
Invoke-Install $package $initialized -Options @('-InitializeConfig')
Assert-True ((Get-FileHash (Join-Path $package 'Config-Settings.toml.example')).Hash -eq (Get-FileHash (Join-Path $initialized 'config.toml')).Hash) 'Starter config mismatch'
$config = "# Synthetic local configuration`r`nmodel = 'local-model'`r`n[features]`r`ncontext_management.experimental_mode = true`r`n[agents]`r`nmax_concurrent_threads_per_session = 12`r`ndefault_subagent_reasoning_effort = 'xhigh'`r`n[mcp_servers.'example']`r`nargs = [`r`n'one',`r`n]`r`n"
[IO.File]::WriteAllText((Join-Path $initialized 'config.toml'), $config)
$before = Get-TreeState $initialized
Invoke-Install $package $initialized -Options @('-InitializeConfig', '-Force')
Assert-True ($before -ceq (Get-TreeState $initialized)) 'Existing config or state changed on forced repeat'
$results.Add('Explicit initialization and byte-for-byte preservation of complex existing config passed.')

$newPrompt = Join-Path $package 'prompts/new-template.md'
[IO.File]::WriteAllText($newPrompt, 'New template')
Invoke-Install $package $initialized
Assert-Payload $package $initialized
Assert-True ([IO.File]::ReadAllText((Join-Path $initialized 'config.toml')) -ceq $config) 'Upgrade changed config'
$manifest = Get-Content (Join-Path $initialized '.venworks-agentkit/manifest.json') -Raw | ConvertFrom-Json
Assert-True ($manifest.packageVersion -eq ([IO.File]::ReadAllText((Join-Path $package 'VERSION')).Trim())) 'Missing package version'
$results.Add('Same-version content upgrade, managed manifest and config preservation passed.')

$edited = Join-Path $initialized 'prompts/new-template.md'
[IO.File]::WriteAllText($edited, 'Local customization')
[IO.File]::WriteAllText($newPrompt, 'Updated template')
$before = Get-TreeState $initialized
Invoke-Install $package $initialized -ExpectFailure
Assert-True ($before -ceq (Get-TreeState $initialized)) 'Conflict detection wrote files'
Invoke-Install $package $initialized -Options @('-Force')
Assert-True ([IO.File]::ReadAllText($edited) -ceq 'Updated template') 'Force did not update'
Assert-BackupContains $initialized 'Local customization'
$results.Add('Local-edit conflict refusal and explicit Force with original backup passed.')

Remove-Item -LiteralPath $newPrompt
Invoke-Install $package $initialized
Assert-True (-not (Test-Path -LiteralPath $edited)) 'Unchanged retired managed file remains'
Assert-BackupContains $initialized 'Updated template'
[IO.File]::WriteAllText($newPrompt, 'Temporary managed file')
Invoke-Install $package $initialized
[IO.File]::WriteAllText($edited, 'Retired but locally customized')
Remove-Item -LiteralPath $newPrompt
$before = Get-TreeState $initialized
Invoke-Install $package $initialized -ExpectFailure
Assert-True ($before -ceq (Get-TreeState $initialized)) 'Retired-file conflict wrote files'
Invoke-Install $package $initialized -Options @('-Force')
Assert-True ([IO.File]::ReadAllText($edited) -ceq 'Retired but locally customized') 'Customized retired file was deleted'
$manifest = Get-Content (Join-Path $initialized '.venworks-agentkit/manifest.json') -Raw | ConvertFrom-Json
Assert-True (@($manifest.files | Where-Object path -eq 'prompts/new-template.md').Count -eq 0) 'Retired customized file remains managed'
$results.Add('Unchanged retirement backup/removal and preservation of modified retired files passed.')

$collision = Join-Path $testRoot 'collision'
New-Item -ItemType Directory -Path (Join-Path $collision 'agents') -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $collision 'agents/coding.toml'), 'Existing independent role')
[IO.File]::WriteAllText((Join-Path $collision 'agents/unrelated.toml'), 'Keep unrelated')
$before = Get-TreeState $collision
Invoke-Install $package $collision -ExpectFailure
Assert-True ($before -ceq (Get-TreeState $collision)) 'Unmanaged collision wrote files'
Invoke-Install $package $collision -Options @('-Force')
Assert-BackupContains $collision 'Existing independent role'
Assert-True ([IO.File]::ReadAllText((Join-Path $collision 'agents/unrelated.toml')) -ceq 'Keep unrelated') 'Unrelated role changed'
$results.Add('Unmanaged collision refusal, backed-up Force, and unrelated-file preservation passed.')

$migration = Join-Path $testRoot 'migration'
$shared = Join-Path $testRoot 'shared'
New-Item -ItemType Directory -Path (Join-Path $migration 'skills') -Force | Out-Null
New-Item -ItemType Directory -Path $shared -Force | Out-Null
foreach ($area in @('agents', 'skills', 'prompts')) { Copy-Item -LiteralPath (Join-Path $package $area) -Destination (Join-Path $shared $area) -Recurse }
[IO.File]::WriteAllText((Join-Path $shared 'agents/extra.toml'), 'Extra shared role')
[IO.File]::WriteAllText((Join-Path $shared 'prompts/extra.md'), 'Extra shared prompt')
foreach ($area in @('agents', 'prompts')) { New-Item -ItemType Junction -Path (Join-Path $migration $area) -Target (Join-Path $shared $area) | Out-Null }
foreach ($folder in Get-ChildItem -LiteralPath (Join-Path $shared 'skills') -Directory) {
    New-Item -ItemType Junction -Path (Join-Path $migration ('skills/' + $folder.Name)) -Target $folder.FullName | Out-Null
}
$sharedBefore = Get-TreeState $shared
Invoke-Install $package $migration -ExpectFailure
Invoke-Install $package $migration -Options @('-MigrateJunctions', '-WhatIf')
Assert-True ((Get-Item (Join-Path $migration 'prompts')).LinkType -eq 'Junction') 'Migration WhatIf removed a junction'
Invoke-Install $package $migration -Options @('-MigrateJunctions')
Assert-Payload $package $migration
Assert-True (-not (Get-Item (Join-Path $migration 'agents')).LinkType) 'Agents still linked'
Assert-True (-not (Get-Item (Join-Path $migration 'prompts')).LinkType) 'Prompts still linked'
foreach ($folder in Get-ChildItem (Join-Path $migration 'skills') -Directory) { Assert-True (-not $folder.LinkType) 'Skill still linked' }
Assert-True ((Get-TreeState $shared) -ceq $sharedBefore) 'Migration changed the shared source'
Assert-True ([IO.File]::ReadAllText((Join-Path $migration 'agents/extra.toml')) -ceq 'Extra shared role') 'Migration lost unowned role'
Assert-True ([IO.File]::ReadAllText((Join-Path $migration 'prompts/extra.md')) -ceq 'Extra shared prompt') 'Migration lost unowned prompt'
$before = Get-TreeState $migration
Invoke-Install $package $migration -Options @('-MigrateJunctions')
Assert-True ((Get-TreeState $migration) -ceq $before) 'Repeated migration changed files'
$results.Add('Explicit migration, WhatIf, target preservation, extra-file retention and migration idempotency passed.')

$overlapBefore = Get-TreeState $package
Invoke-Install $package (Join-Path $package 'skills') -ExpectFailure
Assert-True ((Get-TreeState $package) -ceq $overlapBefore) 'Overlapping home changed package'
$corrupt = Join-Path $testRoot 'corrupt'
Invoke-Install $package $corrupt
[IO.File]::WriteAllText((Join-Path $corrupt '.venworks-agentkit/manifest.json'), '{invalid')
$before = Get-TreeState $corrupt
Invoke-Install $package $corrupt -ExpectFailure
Assert-True ((Get-TreeState $corrupt) -ceq $before) 'Corrupt manifest caused writes'
$results.Add('Overlapping source/target and corrupted manifest refusal passed.')

$tampered = Join-Path $testRoot 'tampered'
Invoke-Install $package $tampered
$outside = Join-Path $testRoot 'outside.txt'
[IO.File]::WriteAllText($outside, 'Outside sentinel')
$manifestPath = Join-Path $tampered '.venworks-agentkit/manifest.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$manifest.files += [pscustomobject]@{ path = '../outside.txt'; sha256 = (Get-FileHash $outside).Hash }
$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath
$before = Get-TreeState $tampered
Invoke-Install $package $tampered -ExpectFailure
Assert-True ((Get-TreeState $tampered) -ceq $before) 'Unsafe manifest caused home writes'
Assert-True ([IO.File]::ReadAllText($outside) -ceq 'Outside sentinel') 'Unsafe manifest modified outside file'
$redirectedParent = Join-Path $testRoot 'redirected-parent'
$redirectedTarget = Join-Path $testRoot 'redirected-target'
New-Item -ItemType Directory -Path $redirectedTarget | Out-Null
New-Item -ItemType Junction -Path $redirectedParent -Target $redirectedTarget | Out-Null
Invoke-Install $package (Join-Path $redirectedParent 'home') -Options @('-MigrateJunctions') -ExpectFailure
Assert-True (-not (Test-Path (Join-Path $redirectedTarget 'home'))) 'Redirected ancestor was written'
$results.Add('Unsafe managed-manifest path and redirected ancestor refusal passed.')

$redirectedBackupHome = Join-Path $testRoot 'redirected-backups-home'
Invoke-Install $package $redirectedBackupHome
$externalBackups = Join-Path $testRoot 'external-backups'
New-Item -ItemType Directory -Path $externalBackups | Out-Null
$backupRoot = Join-Path $redirectedBackupHome '.venworks-agentkit/backups'
Assert-True ([IO.Path]::GetFullPath($backupRoot).StartsWith([IO.Path]::GetFullPath($testRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) 'Test move escaped fixture root'
if (Test-Path -LiteralPath $backupRoot) { Move-Item -LiteralPath $backupRoot -Destination (Join-Path $testRoot 'saved-original-backups') }
New-Item -ItemType Junction -Path $backupRoot -Target $externalBackups | Out-Null
$redirectedPackage = New-Package 'redirected-backups-package'
Set-Content -LiteralPath (Join-Path $redirectedPackage 'VERSION') -Value '0.1.2'
$externalBefore = Get-TreeState $externalBackups
$redirectedManifest = Join-Path $redirectedBackupHome '.venworks-agentkit/manifest.json'
$manifestBefore = [IO.File]::ReadAllText($redirectedManifest)
Invoke-Install $redirectedPackage $redirectedBackupHome -ExpectFailure
Assert-True ((Get-TreeState $externalBackups) -ceq $externalBefore) 'Redirected backup target was modified'
Assert-True ([IO.File]::ReadAllText($redirectedManifest) -ceq $manifestBefore) 'Refused redirected backup changed manifest'
$results.Add('Redirected backup storage with existing manifest is refused without external writes.')

$transitionPackage = New-Package 'directory-transition-package'
$transitionDirectory = Join-Path $transitionPackage 'prompts/topic'
New-Item -ItemType Directory -Path $transitionDirectory | Out-Null
Set-Content -LiteralPath (Join-Path $transitionDirectory 'old.md') -Value 'Original managed topic'
$transitionHome = Join-Path $testRoot 'directory-transition-home'
Invoke-Install $transitionPackage $transitionHome
$customizedChild = Join-Path $transitionHome 'prompts/topic/old.md'
Set-Content -LiteralPath $customizedChild -Value 'Locally customized retired topic'
Assert-True ([IO.Path]::GetFullPath($transitionDirectory).StartsWith([IO.Path]::GetFullPath($testRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) 'Test removal escaped fixture root'
Remove-Item -LiteralPath $transitionDirectory -Recurse
Set-Content -LiteralPath $transitionDirectory -Value 'New file replaces former directory'
$transitionBefore = Get-TreeState $transitionHome
Invoke-Install $transitionPackage $transitionHome -Options @('-Force') -ExpectFailure
Assert-True ((Get-TreeState $transitionHome) -ceq $transitionBefore) 'Directory replacement removed preserved retired content or changed state'
$results.Add('Forced directory-to-file replacement refuses to remove a modified retired child.')

$migrationRollback = Join-Path $testRoot 'migration-rollback'
Invoke-Install $package $migrationRollback
$savedAgents = Join-Path $testRoot 'rollback-shared-agents'
$agentRoot = Join-Path $migrationRollback 'agents'
foreach ($path in @($agentRoot, $savedAgents)) {
    Assert-True ([IO.Path]::GetFullPath($path).StartsWith([IO.Path]::GetFullPath($testRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) 'Test move escaped fixture root'
}
Move-Item -LiteralPath $agentRoot -Destination $savedAgents
New-Item -ItemType Junction -Path $agentRoot -Target $savedAgents | Out-Null
$sourceBefore = Get-TreeState $savedAgents
$statePath = Join-Path $migrationRollback '.venworks-agentkit/manifest.json'
$stateBefore = [IO.File]::ReadAllText($statePath)
$migrationPackage = New-Package 'migration-upgrade-package'
Set-Content -LiteralPath (Join-Path $migrationPackage 'VERSION') -Value '0.1.1'
$stateLock = [IO.File]::Open($statePath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
try {
    Invoke-Install $migrationPackage $migrationRollback -Options @('-MigrateJunctions') -ExpectFailure
    Assert-True ((Get-Item $agentRoot).LinkType -eq 'Junction') 'Failed migration did not restore original junction'
    Assert-True ([IO.File]::ReadAllText($statePath) -ceq $stateBefore) 'Failed migration changed manifest'
    Assert-True ((Get-TreeState $savedAgents) -ceq $sourceBefore) 'Failed migration changed shared target'
} finally { $stateLock.Dispose() }
$results.Add('Failure at migration manifest commit restored the original junction and preserved its target.')

$locked = Join-Path $testRoot 'locked'
Invoke-Install $package $locked
$lockPath = Join-Path $locked 'skills/user-docs/SKILL.md'
$stream = [IO.File]::Open($lockPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
try {
    Add-Content -LiteralPath (Join-Path $package 'agents/coding.toml') -Value '# Synthetic upgrade'
    Add-Content -LiteralPath (Join-Path $package 'skills/user-docs/SKILL.md') -Value 'Synthetic upgrade'
    $before = Get-TreeState $locked
    Invoke-Install $package $locked -ExpectFailure
    $afterPayload = @(Get-ChildItem -LiteralPath $locked -File -Recurse | Where-Object FullName -notlike '*\.venworks-agentkit\*' | ForEach-Object {
        [IO.Path]::GetRelativePath($locked, $_.FullName) + ':' + (Get-FileHash $_.FullName).Hash
    } | Sort-Object) -join "`n"
    $beforePayload = @($before -split "`n" | Where-Object { $_ -notlike '.venworks-agentkit\*' } | Sort-Object) -join "`n"
    Assert-True ($afterPayload -ceq $beforePayload) 'Write failure did not restore previous payload'
} finally { $stream.Dispose() }
$results.Add('Locked-file write failure preserved/restored previous payload.')

$policyPackage = New-Package 'policy-package'
$legacyPolicyPackage = New-Package 'legacy-policy-package'
$legacyAdoptionGuide = 'skills/agent-router/references/policy-adoption.md'
[IO.File]::WriteAllText((Join-Path $legacyPolicyPackage $legacyAdoptionGuide), 'Legacy managed adoption-record procedure.')
$legacyExamples = Join-Path $legacyPolicyPackage 'skills/agent-router/references/policies'
New-Item -ItemType Directory -Path $legacyExamples -Force | Out-Null
foreach ($example in Get-ChildItem -LiteralPath (Join-Path $legacyPolicyPackage 'example') -Filter '*.example.md' -File) {
    Copy-Item -LiteralPath $example.FullName -Destination (Join-Path $legacyExamples $example.Name)
}
Assert-True (-not (Test-Path -LiteralPath (Join-Path $fresh 'example'))) 'Default install copied the example directory'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $fresh 'skills/agent-router/references/policies'))) 'Default install copied policy templates into skill references'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $fresh $legacyAdoptionGuide))) 'Default install included the retired adoption-record procedure'
# Legacy user-owned records remain untouched even though the policy workflow no longer uses them.
foreach ($policyName in @('tooling-policy.md', 'credential-policy.md', 'policy-adoptions.json')) {
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $fresh $policyName))) 'Default install activated a policy example'
}
$policyHomes = @((Join-Path $testRoot 'policy-shared-home'), (Join-Path $testRoot 'policy-project/.codex'))
foreach ($policyHome in $policyHomes) {
    New-Item -ItemType Directory -Path $policyHome -Force | Out-Null
    foreach ($policyName in @('tooling-policy.md', 'credential-policy.md', 'policy-adoptions.json')) {
        [IO.File]::WriteAllText((Join-Path $policyHome $policyName), "User-owned policy: $policyName`r`nPreserve these exact bytes.")
    }
    $policyBefore = Get-TreeState $policyHome
    Invoke-Install $legacyPolicyPackage $policyHome
    Assert-Payload $legacyPolicyPackage $policyHome
    Assert-True (Test-Path -LiteralPath (Join-Path $policyHome $legacyAdoptionGuide)) 'Legacy fixture did not install the adoption-record procedure'
    $policyAfter = @(Get-ChildItem -LiteralPath $policyHome -File | Sort-Object FullName | ForEach-Object { $_.Name + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash }) -join "`n"
    Assert-True ($policyBefore -ceq $policyAfter) 'Fresh install changed active policies'
}
$policyExample = Join-Path $policyPackage 'example/shared-tooling-policy.example.md'
Assert-True (Test-Path -LiteralPath $policyExample) 'Missing policy example in package'
Add-Content -LiteralPath $policyExample -Value 'Synthetic example upgrade'
foreach ($policyHome in $policyHomes) {
    $policyBefore = @(Get-ChildItem -LiteralPath $policyHome -File | Sort-Object FullName | ForEach-Object { $_.Name + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash }) -join "`n"
    Invoke-Install $policyPackage $policyHome -Options @('-Force')
    Assert-Payload $policyPackage $policyHome
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $policyHome 'example'))) 'Update copied setup examples into Codex'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $policyHome $legacyAdoptionGuide))) 'Update retained the obsolete managed adoption-record procedure'
    foreach ($example in Get-ChildItem -LiteralPath (Join-Path $policyPackage 'example') -Filter '*.example.md' -File) {
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $policyHome ('skills/agent-router/references/policies/' + $example.Name)))) 'Update retained an unchanged formerly managed template'
    }
    $policyAfter = @(Get-ChildItem -LiteralPath $policyHome -File | Sort-Object FullName | ForEach-Object { $_.Name + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash }) -join "`n"
    Assert-True ($policyBefore -ceq $policyAfter) 'Example upgrade changed active policies'
    $installedManifest = Get-Content -LiteralPath (Join-Path $policyHome '.venworks-agentkit/manifest.json') -Raw | ConvertFrom-Json
    Assert-True (@($installedManifest.files | Where-Object { $_.path -in @('tooling-policy.md', 'credential-policy.md', 'policy-adoptions.json') }).Count -eq 0) 'Installer took ownership of active policies'
    $policyState = Get-TreeState $policyHome
    Invoke-Install $policyPackage $policyHome
    Assert-True ($policyState -ceq (Get-TreeState $policyHome)) 'Policy fixture repeat was not a no-op'
}
$results.Add('Setup examples stay uninstalled, obsolete managed policy guidance retires, user-owned policies and legacy records remain unchanged, and repeat is a no-op.')

$results | ForEach-Object { Write-Output "PASS: $_" }
Write-Output "Artifacts: $testRoot"
