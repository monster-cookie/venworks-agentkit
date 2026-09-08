#requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $CodexRoot,

    [Parameter()]
    [switch] $InitializeConfig,

    [Parameter()]
    [switch] $Force,

    [Parameter()]
    [switch] $MigrateJunctions
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ManifestSchemaVersion = 1
$script:ManagedDirectoryNames = @('agents', 'skills', 'prompts')
$script:StateDirectoryName = '.venworks-agentkit'
$script:ManifestFileName = 'manifest.json'
$script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$script:PathComparer = [System.StringComparer]::OrdinalIgnoreCase

$helperPath = Join-Path -Path $PSScriptRoot -ChildPath 'Install-CodexAgents.Helpers.ps1'
try {
    $helperItem = Get-Item -LiteralPath $helperPath -Force -ErrorAction Stop
}
catch {
    throw "Required installer helper is missing: $helperPath"
}
if ($helperItem.PSIsContainer -or -not [string]::IsNullOrWhiteSpace([string]$helperItem.LinkType)) {
    throw "Required installer helper is not an ordinary file: $helperPath"
}
. $helperItem.FullName

function Assert-ValidManifestPath {
    param([Parameter(Mandatory)][string] $RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or $RelativePath.Contains('\')) {
        throw "The install manifest contains an invalid managed path '$RelativePath'."
    }

    $segments = $RelativePath.Split('/')
    if ($segments.Count -lt 2 -or $segments[0] -notin $script:ManagedDirectoryNames) {
        throw "The install manifest path '$RelativePath' is outside agents, skills, and prompts."
    }

    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment) -or $segment -eq '.' -or $segment -eq '..' -or $segment.Contains(':')) {
            throw "The install manifest contains an unsafe managed path '$RelativePath'."
        }
    }

    $roundTrip = [System.IO.Path]::GetFullPath(($segments -join [System.IO.Path]::DirectorySeparatorChar), 'C:\')
    if (-not (Test-PathWithinOrEqual -Candidate $roundTrip -Root 'C:\')) {
        throw "The install manifest contains an unsafe managed path '$RelativePath'."
    }
}

function Get-PackageFiles {
    param([Parameter(Mandatory)][string] $PackageRoot)

    $files = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new($script:PathComparer)

    foreach ($directoryName in $script:ManagedDirectoryNames) {
        $directoryPath = Join-Path -Path $PackageRoot -ChildPath $directoryName
        $snapshot = @(Get-SafeTreeSnapshot -Root $directoryPath -Description "Package directory '$directoryName'")
        foreach ($entry in $snapshot) {
            if ($entry.Type -ne 'file') {
                continue
            }

            $relativePath = "$directoryName/$($entry.Path)"
            Assert-ValidManifestPath -RelativePath $relativePath
            if (-not $seen.Add($relativePath)) {
                throw "The package contains duplicate managed path '$relativePath'."
            }

            $files.Add([pscustomobject]@{
                Path = $relativePath
                SourcePath = Join-Path -Path $PackageRoot -ChildPath ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                Sha256 = $entry.Sha256
            })
        }
    }

    return @($files | Sort-Object -Property Path)
}

function Assert-SafeStateWithoutManifest {
    param([Parameter(Mandatory)][string] $StateRoot)

    $stateItem = Get-LiteralItemOrNull -LiteralPath $StateRoot
    if ($null -eq $stateItem) {
        return
    }
    if (-not $stateItem.PSIsContainer -or (Test-IsFileSystemLink -Item $stateItem)) {
        throw "Installer state path '$StateRoot' is not an ordinary directory."
    }

    $stateChildren = @(Get-ChildItem -LiteralPath $StateRoot -Force -ErrorAction Stop)
    if ($stateChildren.Count -eq 0) {
        return
    }
    if ($stateChildren.Count -ne 1 -or $stateChildren[0].Name -ne 'backups' -or -not $stateChildren[0].PSIsContainer -or (Test-IsFileSystemLink -Item $stateChildren[0])) {
        throw "Installer state exists without a manifest at '$StateRoot'. Inspect it before retrying; the installer will not assume that state is safe."
    }

    foreach ($transactionDirectory in @(Get-ChildItem -LiteralPath $stateChildren[0].FullName -Directory -Force -ErrorAction Stop)) {
        if (Test-IsFileSystemLink -Item $transactionDirectory) {
            throw "Installer backup state contains an unsupported link '$($transactionDirectory.FullName)'."
        }
        $transactionPath = Join-Path -Path $transactionDirectory.FullName -ChildPath 'transaction.json'
        $transactionItem = Get-LiteralItemOrNull -LiteralPath $transactionPath
        if ($null -eq $transactionItem -or $transactionItem.PSIsContainer -or (Test-IsFileSystemLink -Item $transactionItem)) {
            throw "Installer state contains an incomplete transaction at '$($transactionDirectory.FullName)'. Recover or remove it manually before retrying."
        }
        try {
            $transaction = Get-Content -LiteralPath $transactionPath -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 20 -ErrorAction Stop
        }
        catch {
            throw "Installer transaction '$transactionPath' is unreadable: $($_.Exception.Message)"
        }
        if ([string]$transaction.status -ne 'RolledBack') {
            throw "Installer transaction '$transactionPath' has status '$($transaction.status)'. Complete manual recovery before retrying."
        }
    }
}

function Read-InstallManifest {
    param(
        [Parameter(Mandatory)][string] $ManifestPath,
        [Parameter(Mandatory)][string] $StateRoot
    )

    $manifestItem = Get-LiteralItemOrNull -LiteralPath $ManifestPath
    if ($null -eq $manifestItem) {
        Assert-SafeStateWithoutManifest -StateRoot $StateRoot
        return $null
    }
    if ($manifestItem.PSIsContainer -or (Test-IsFileSystemLink -Item $manifestItem)) {
        throw "Install manifest '$ManifestPath' is not an ordinary file."
    }

    try {
        $manifest = Get-Content -LiteralPath $ManifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 20 -ErrorAction Stop
    }
    catch {
        throw "Install manifest '$ManifestPath' is corrupt or unreadable: $($_.Exception.Message)"
    }

    if ($null -eq $manifest.schemaVersion -or [int]$manifest.schemaVersion -ne $script:ManifestSchemaVersion) {
        throw "Install manifest '$ManifestPath' uses an unsupported or missing schema version."
    }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.packageVersion)) {
        throw "Install manifest '$ManifestPath' has no package version."
    }
    if ($null -eq $manifest.files) {
        throw "Install manifest '$ManifestPath' has no managed file list."
    }

    $filesByPath = [System.Collections.Generic.Dictionary[string, object]]::new($script:PathComparer)
    foreach ($file in @($manifest.files)) {
        $relativePath = [string]$file.path
        $sha256 = [string]$file.sha256
        Assert-ValidManifestPath -RelativePath $relativePath
        if ($sha256 -notmatch '^[0-9a-fA-F]{64}$') {
            throw "Install manifest '$ManifestPath' has an invalid SHA-256 for '$relativePath'."
        }
        if ($filesByPath.ContainsKey($relativePath)) {
            throw "Install manifest '$ManifestPath' contains duplicate managed path '$relativePath'."
        }
        $filesByPath.Add($relativePath, [pscustomobject]@{ Path = $relativePath; Sha256 = $sha256.ToLowerInvariant() })
    }

    return [pscustomobject]@{
        PackageVersion = [string]$manifest.packageVersion
        InstalledAtUtc = [string]$manifest.installedAtUtc
        FilesByPath = $filesByPath
    }
}

function Get-JunctionTargetPath {
    param([Parameter(Mandatory)][System.IO.FileSystemInfo] $Item)

    if (-not $Item.PSIsContainer -or -not (Test-IsFileSystemLink -Item $Item) -or [string]$Item.LinkType -ne 'Junction') {
        throw "'$($Item.FullName)' is not a supported directory junction."
    }

    $targets = @($Item.Target)
    if ($targets.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$targets[0])) {
        throw "Directory junction '$($Item.FullName)' does not expose exactly one target."
    }

    $target = [string]$targets[0]
    if ($target.StartsWith('\??\', [StringComparison]::Ordinal)) {
        $target = $target.Substring(4)
    }
    if (-not [System.IO.Path]::IsPathFullyQualified($target)) {
        $target = Join-Path -Path $Item.Parent.FullName -ChildPath $target
    }
    return [System.IO.Path]::GetFullPath($target)
}

function Add-MigrationIfNeeded {
    param(
        [Parameter(Mandatory)][string] $LinkPath,
        [Parameter(Mandatory)][string] $RelativePath,
        [Parameter(Mandatory)][bool] $AllowedShape,
        [Parameter(Mandatory)][bool] $MigrationEnabled,
        [Parameter(Mandatory)][System.Collections.Generic.Dictionary[string, object]] $Migrations
    )

    $item = Get-LiteralItemOrNull -LiteralPath $LinkPath
    if ($null -eq $item -or -not (Test-IsFileSystemLink -Item $item)) {
        return $false
    }
    if (-not $AllowedShape -or -not $item.PSIsContainer -or [string]$item.LinkType -ne 'Junction') {
        throw "Unsupported link or reparse point at '$LinkPath'. The installer never follows or retargets it."
    }
    if (-not $MigrationEnabled) {
        throw "Managed destination '$LinkPath' is a directory junction. Rerun with -MigrateJunctions to copy its target into an ordinary local directory, or choose another Codex root."
    }
    if ($Migrations.ContainsKey($LinkPath)) {
        return $true
    }

    $targetPath = Get-JunctionTargetPath -Item $item
    Assert-NoLinkedAncestors -Path $targetPath -Description "Junction target"
    $snapshot = @(Get-SafeTreeSnapshot -Root $targetPath -Description "Junction target for '$LinkPath'")
    $Migrations.Add($LinkPath, [pscustomobject]@{
        LinkPath = $LinkPath
        RelativePath = $RelativePath
        TargetPath = $targetPath
        TargetSnapshot = $snapshot
        TargetDigest = Get-TreeDigest -Snapshot $snapshot
        LinkAttributes = [string]$item.Attributes
    })
    return $true
}

function Get-PlannedMigrations {
    param(
        [Parameter(Mandatory)][string] $DestinationRoot,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $RelevantPaths,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $PackagedSkillNames,
        [Parameter(Mandatory)][bool] $MigrationEnabled,
        [Parameter(Mandatory)][string] $PackageRoot,
        [Parameter(Mandatory)][string] $StateRoot
    )

    $migrations = [System.Collections.Generic.Dictionary[string, object]]::new($script:PathComparer)
    $packagedSkills = [System.Collections.Generic.HashSet[string]]::new($PackagedSkillNames, $script:PathComparer)

    foreach ($directoryName in $script:ManagedDirectoryNames) {
        $managedRoot = Join-Path -Path $DestinationRoot -ChildPath $directoryName
        $rootItem = Get-LiteralItemOrNull -LiteralPath $managedRoot
        if ($null -ne $rootItem -and (Test-IsFileSystemLink -Item $rootItem)) {
            $allowed = $directoryName -in @('agents', 'prompts')
            [void](Add-MigrationIfNeeded -LinkPath $managedRoot -RelativePath $directoryName -AllowedShape $allowed -MigrationEnabled $MigrationEnabled -Migrations $migrations)
        }
        elseif ($null -ne $rootItem -and -not $rootItem.PSIsContainer) {
            throw "Managed root '$managedRoot' exists but is not a directory."
        }
    }

    foreach ($relativePath in $RelevantPaths) {
        $segments = $relativePath.Split('/')
        $categoryRoot = Join-Path -Path $DestinationRoot -ChildPath $segments[0]
        if ($migrations.ContainsKey($categoryRoot)) {
            continue
        }

        $current = $categoryRoot
        for ($index = 1; $index -lt $segments.Count; $index++) {
            $current = Join-Path -Path $current -ChildPath $segments[$index]
            $item = Get-LiteralItemOrNull -LiteralPath $current
            if ($null -eq $item) {
                continue
            }
            if (Test-IsFileSystemLink -Item $item) {
                $isPackagedSkillJunction = $segments[0] -eq 'skills' -and $index -eq 1 -and $packagedSkills.Contains($segments[1])
                $wasAdded = Add-MigrationIfNeeded -LinkPath $current -RelativePath "skills/$($segments[1])" -AllowedShape $isPackagedSkillJunction -MigrationEnabled $MigrationEnabled -Migrations $migrations
                if ($wasAdded) {
                    break
                }
            }
            if ($index -lt $segments.Count - 1 -and -not $item.PSIsContainer) {
                throw "File '$current' blocks a required managed directory. Resolve this structural collision before installing."
            }
        }
    }

    $migrationList = @($migrations.Values | Sort-Object -Property LinkPath)
    for ($index = 0; $index -lt $migrationList.Count; $index++) {
        $migration = $migrationList[$index]
        if ((Test-PathsOverlap -First $migration.TargetPath -Second $DestinationRoot) -or
            (Test-PathsOverlap -First $migration.TargetPath -Second $PackageRoot) -or
            (Test-PathsOverlap -First $migration.TargetPath -Second $StateRoot)) {
            throw "Junction target '$($migration.TargetPath)' overlaps the package, Codex root, or installer state. Migration is unsafe."
        }
        for ($otherIndex = $index + 1; $otherIndex -lt $migrationList.Count; $otherIndex++) {
            if (Test-PathsOverlap -First $migration.TargetPath -Second $migrationList[$otherIndex].TargetPath) {
                throw "Junction targets '$($migration.TargetPath)' and '$($migrationList[$otherIndex].TargetPath)' overlap. Migration is unsafe."
            }
        }
    }

    return $migrationList
}

function Test-IsUnderMigration {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]] $Migrations
    )

    foreach ($migration in $Migrations) {
        if (Test-PathWithinOrEqual -Candidate $Path -Root $migration.LinkPath) {
            return $true
        }
    }
    return $false
}

function Add-BackupCandidate {
    param(
        [Parameter(Mandatory)][System.Collections.Generic.Dictionary[string, object]] $Candidates,
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $RelativePath,
        [Parameter(Mandatory)][string] $Reason,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]] $Migrations
    )

    if (Test-IsUnderMigration -Path $Path -Migrations $Migrations) {
        return
    }
    if (-not $Candidates.ContainsKey($Path)) {
        $Candidates.Add($Path, [pscustomobject]@{ Path = $Path; RelativePath = $RelativePath; Reason = $Reason })
    }
}

function Add-PlanError {
    param(
        [Parameter(Mandatory)][System.Collections.Generic.List[string]] $Errors,
        [Parameter(Mandatory)][string] $Message
    )
    $Errors.Add($Message)
}

function New-InstallPlan {
    param(
        [Parameter(Mandatory)][string] $DestinationRoot,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]] $PackageFiles,
        [AllowNull()][object] $PreviousManifest,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]] $Migrations,
        [Parameter(Mandatory)][bool] $ForceEnabled,
        [Parameter(Mandatory)][bool] $InitializeConfigEnabled,
        [Parameter(Mandatory)][string] $ConfigExamplePath,
        [Parameter(Mandatory)][string] $PackageVersion
    )

    $writes = [System.Collections.Generic.List[object]]::new()
    $deletes = [System.Collections.Generic.List[object]]::new()
    $preservedRetired = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $backupCandidates = [System.Collections.Generic.Dictionary[string, object]]::new($script:PathComparer)
    $packageByPath = [System.Collections.Generic.Dictionary[string, object]]::new($script:PathComparer)
    foreach ($file in $PackageFiles) {
        $packageByPath.Add($file.Path, $file)
        $destinationPath = Join-Path -Path $DestinationRoot -ChildPath ($file.Path -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $destinationItem = Get-LiteralItemOrNull -LiteralPath $destinationPath
        $previous = $null
        if ($null -ne $PreviousManifest -and $PreviousManifest.FilesByPath.ContainsKey($file.Path)) {
            $previous = $PreviousManifest.FilesByPath[$file.Path]
        }

        if ($null -eq $destinationItem) {
            if ($null -ne $previous -and -not $ForceEnabled) {
                Add-PlanError -Errors $errors -Message "Managed file '$($file.Path)' was removed locally. Use -Force to restore it from the package."
            }
            else {
                $writes.Add([pscustomobject]@{ File = $file; DestinationPath = $destinationPath; ExistingKind = 'missing' })
            }
            continue
        }

        if (Test-IsFileSystemLink -Item $destinationItem) {
            Add-PlanError -Errors $errors -Message "Managed path '$destinationPath' is an unsupported link or reparse point."
            continue
        }

        if ($destinationItem.PSIsContainer) {
            if (-not $ForceEnabled) {
                $collisionType = if ($null -eq $previous) { 'unknown same-name collision' } else { 'locally modified managed path' }
                Add-PlanError -Errors $errors -Message "Directory '$destinationPath' is a $collisionType where the package requires a file. Use -Force to back it up and replace it."
            }
            else {
                [void](Get-SafeTreeSnapshot -Root $destinationPath -Description "Collision directory")
                Add-BackupCandidate -Candidates $backupCandidates -Path $destinationPath -RelativePath $file.Path -Reason 'replace-directory-collision' -Migrations $Migrations
                $writes.Add([pscustomobject]@{ File = $file; DestinationPath = $destinationPath; ExistingKind = 'directory' })
            }
            continue
        }

        $currentHash = Get-FileSha256 -LiteralPath $destinationPath
        if ($null -eq $previous) {
            if ($currentHash.Equals($file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
            if (-not $ForceEnabled) {
                Add-PlanError -Errors $errors -Message "Unknown file collision at '$destinationPath'. Use -Force to back it up and install the packaged file."
            }
            else {
                Add-BackupCandidate -Candidates $backupCandidates -Path $destinationPath -RelativePath $file.Path -Reason 'replace-unknown-collision' -Migrations $Migrations
                $writes.Add([pscustomobject]@{ File = $file; DestinationPath = $destinationPath; ExistingKind = 'file' })
            }
            continue
        }

        if (-not $currentHash.Equals($previous.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            if (-not $ForceEnabled) {
                Add-PlanError -Errors $errors -Message "Managed file '$destinationPath' was modified locally. Use -Force to back it up and continue."
            }
            else {
                Add-BackupCandidate -Candidates $backupCandidates -Path $destinationPath -RelativePath $file.Path -Reason 'locally-modified-managed-file' -Migrations $Migrations
                if (-not $currentHash.Equals($file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                    $writes.Add([pscustomobject]@{ File = $file; DestinationPath = $destinationPath; ExistingKind = 'file' })
                }
            }
            continue
        }

        if (-not $currentHash.Equals($file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            Add-BackupCandidate -Candidates $backupCandidates -Path $destinationPath -RelativePath $file.Path -Reason 'upgrade-managed-file' -Migrations $Migrations
            $writes.Add([pscustomobject]@{ File = $file; DestinationPath = $destinationPath; ExistingKind = 'file' })
        }
    }

    if ($null -ne $PreviousManifest) {
        foreach ($previous in $PreviousManifest.FilesByPath.Values) {
            if ($packageByPath.ContainsKey($previous.Path)) {
                continue
            }

            $destinationPath = Join-Path -Path $DestinationRoot -ChildPath ($previous.Path -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            $destinationItem = Get-LiteralItemOrNull -LiteralPath $destinationPath
            if ($null -eq $destinationItem) {
                continue
            }
            if (Test-IsFileSystemLink -Item $destinationItem) {
                Add-PlanError -Errors $errors -Message "Retired managed path '$destinationPath' is an unsupported link or reparse point."
                continue
            }

            $unchanged = -not $destinationItem.PSIsContainer -and (Get-FileSha256 -LiteralPath $destinationPath).Equals($previous.Sha256, [StringComparison]::OrdinalIgnoreCase)
            if ($unchanged) {
                Add-BackupCandidate -Candidates $backupCandidates -Path $destinationPath -RelativePath $previous.Path -Reason 'remove-unchanged-retired-file' -Migrations $Migrations
                $deletes.Add([pscustomobject]@{ Path = $destinationPath; RelativePath = $previous.Path })
            }
            elseif (-not $ForceEnabled) {
                Add-PlanError -Errors $errors -Message "Retired managed file '$destinationPath' was modified locally. It will not be deleted; use -Force to preserve it and continue the upgrade."
            }
            else {
                if ($destinationItem.PSIsContainer) {
                    [void](Get-SafeTreeSnapshot -Root $destinationPath -Description "Modified retired directory")
                }
                Add-BackupCandidate -Candidates $backupCandidates -Path $destinationPath -RelativePath $previous.Path -Reason 'preserve-modified-retired-path' -Migrations $Migrations
                $preservedRetired.Add($previous.Path)
            }
        }
    }

    foreach ($retiredPath in $preservedRetired) {
        foreach ($write in $writes) {
            $replacementPrefix = $write.File.Path.TrimEnd('/') + '/'
            if ($retiredPath.StartsWith($replacementPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                Add-PlanError -Errors $errors -Message "Package path '$($write.File.Path)' would replace the directory containing modified retired file '$retiredPath'. The installer cannot preserve that file in place, so this path transition must be resolved manually."
            }
        }
    }

    if ($errors.Count -gt 0) {
        throw "Installer preflight failed:`n - $($errors -join "`n - ")"
    }

    $configPath = Join-Path -Path $DestinationRoot -ChildPath 'config.toml'
    $createConfig = $false
    if ($InitializeConfigEnabled) {
        $configItem = Get-LiteralItemOrNull -LiteralPath $configPath
        if ($null -eq $configItem) {
            $createConfig = $true
        }
    }

    $manifestNeedsWrite = $true
    if ($null -ne $PreviousManifest -and $PreviousManifest.PackageVersion -eq $PackageVersion -and $PreviousManifest.FilesByPath.Count -eq $packageByPath.Count) {
        $manifestNeedsWrite = $false
        foreach ($file in $PackageFiles) {
            if (-not $PreviousManifest.FilesByPath.ContainsKey($file.Path) -or
                -not $PreviousManifest.FilesByPath[$file.Path].Sha256.Equals($file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                $manifestNeedsWrite = $true
                break
            }
        }
    }
    return [pscustomobject]@{
        Writes = @($writes)
        Deletes = @($deletes)
        PreservedRetired = @($preservedRetired)
        BackupCandidates = @($backupCandidates.Values | Sort-Object -Property Path)
        CreateConfig = $createConfig
        ConfigPath = $configPath
        ConfigExamplePath = $ConfigExamplePath
        ManifestNeedsWrite = $manifestNeedsWrite
        HasChanges = $writes.Count -gt 0 -or $deletes.Count -gt 0 -or $migrations.Count -gt 0 -or $createConfig -or $manifestNeedsWrite -or $backupCandidates.Count -gt 0
    }
}

function New-ManifestValue {
    param(
        [Parameter(Mandatory)][string] $PackageVersion,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]] $PackageFiles
    )

    return [ordered]@{
        schemaVersion = $script:ManifestSchemaVersion
        packageVersion = $PackageVersion
        installedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        files = @($PackageFiles | Sort-Object -Property Path | ForEach-Object {
            [ordered]@{ path = $_.Path; sha256 = $_.Sha256 }
        })
    }
}

if (-not $IsWindows) {
    throw 'Install-CodexAgents.ps1 supports Windows PowerShell 7 or later.'
}

$packageRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if ([string]::IsNullOrWhiteSpace($CodexRoot)) {
    $environmentRoot = [Environment]::GetEnvironmentVariable('CODEX_HOME')
    if ([string]::IsNullOrWhiteSpace($environmentRoot)) {
        $environmentRoot = Join-Path -Path ([string]$HOME) -ChildPath '.codex'
    }
    $CodexRoot = $environmentRoot
}
$destinationRoot = ConvertTo-CanonicalPath -Path $CodexRoot -BasePath (Get-Location).ProviderPath

if (Test-PathsOverlap -First $packageRoot -Second $destinationRoot) {
    throw "Package root '$packageRoot' and Codex root '$destinationRoot' overlap. Install from a separate checkout."
}
Assert-NoLinkedAncestors -Path $packageRoot -Description 'Package root'
Assert-NoLinkedAncestors -Path $destinationRoot -Description 'Codex root'

$versionPath = Join-Path -Path $packageRoot -ChildPath 'VERSION'
$versionItem = Get-LiteralItemOrNull -LiteralPath $versionPath
if ($null -eq $versionItem -or $versionItem.PSIsContainer -or (Test-IsFileSystemLink -Item $versionItem)) {
    throw "Package VERSION file is missing or unsafe: $versionPath"
}
$packageVersion = (Get-Content -LiteralPath $versionPath -Raw -ErrorAction Stop).Trim()
if ([string]::IsNullOrWhiteSpace($packageVersion) -or $packageVersion -notmatch '^[0-9A-Za-z][0-9A-Za-z._+-]*$') {
    throw "Package VERSION contains an invalid value: '$packageVersion'"
}

$configExamplePath = Join-Path -Path $packageRoot -ChildPath 'Config-Settings.toml.example'
if ($InitializeConfig) {
    $configExampleItem = Get-LiteralItemOrNull -LiteralPath $configExamplePath
    if ($null -eq $configExampleItem -or $configExampleItem.PSIsContainer -or (Test-IsFileSystemLink -Item $configExampleItem)) {
        throw "Configuration example is missing or unsafe: $configExamplePath"
    }
}

$stateRoot = Join-Path -Path $destinationRoot -ChildPath $script:StateDirectoryName
$manifestPath = Join-Path -Path $stateRoot -ChildPath $script:ManifestFileName
$backupsRoot = Join-Path -Path $stateRoot -ChildPath 'backups'
Assert-NoLinkedAncestors -Path $stateRoot -Description 'Installer state path'
Assert-NoLinkedAncestors -Path $backupsRoot -Description 'Installer backup path'
$previousManifest = Read-InstallManifest -ManifestPath $manifestPath -StateRoot $stateRoot
$packageFiles = @(Get-PackageFiles -PackageRoot $packageRoot)

$relevantPaths = [System.Collections.Generic.HashSet[string]]::new($script:PathComparer)
foreach ($file in $packageFiles) {
    [void]$relevantPaths.Add($file.Path)
}
if ($null -ne $previousManifest) {
    foreach ($path in $previousManifest.FilesByPath.Keys) {
        [void]$relevantPaths.Add($path)
    }
}
$packagedSkillNames = @($packageFiles | Where-Object { $_.Path.StartsWith('skills/', [StringComparison]::OrdinalIgnoreCase) } | ForEach-Object { $_.Path.Split('/')[1] } | Sort-Object -Unique)
$migrations = @(Get-PlannedMigrations -DestinationRoot $destinationRoot -RelevantPaths @($relevantPaths) -PackagedSkillNames $packagedSkillNames -MigrationEnabled ([bool]$MigrateJunctions) -PackageRoot $packageRoot -StateRoot $stateRoot)
$plan = New-InstallPlan -DestinationRoot $destinationRoot -PackageFiles $packageFiles -PreviousManifest $previousManifest -Migrations $migrations -ForceEnabled ([bool]$Force) -InitializeConfigEnabled ([bool]$InitializeConfig) -ConfigExamplePath $configExamplePath -PackageVersion $packageVersion

Write-Host "Preflight passed for package $packageVersion -> $destinationRoot"
foreach ($migration in $migrations) {
    Write-Host "Migrate junction: $($migration.LinkPath) -> $($migration.TargetPath)"
}
foreach ($retiredPath in $plan.PreservedRetired) {
    Write-Warning "Preserving locally modified retired managed path '$retiredPath'; it will no longer be tracked."
}
if ($InitializeConfig -and -not $plan.CreateConfig) {
    Write-Host "Preserve existing config.toml without reading or modifying it."
}

if (-not $plan.HasChanges) {
    Write-Host 'Installation is already current; no files or backups were written.'
    [pscustomobject]@{
        Status = 'Current'
        PackageVersion = $packageVersion
        CodexRoot = $destinationRoot
        ManifestPath = $manifestPath
        BackupPath = $null
    }
    return
}

$operationSummary = "install package $packageVersion ($($plan.Writes.Count) writes, $($plan.Deletes.Count) retired removals, $($migrations.Count) junction migrations)"
if (-not $PSCmdlet.ShouldProcess($destinationRoot, $operationSummary)) {
    return
}

$transactionName = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ') + '_' + [Guid]::NewGuid().ToString('N')
$backupRoot = Join-Path -Path $backupsRoot -ChildPath $transactionName
$transactionPath = Join-Path -Path $backupRoot -ChildPath 'transaction.json'
$backupRecords = [System.Collections.Generic.List[object]]::new()
$appliedNormalPaths = [System.Collections.Generic.List[object]]::new()
$appliedMigrations = [System.Collections.Generic.List[object]]::new()
$createdDirectories = [System.Collections.Generic.HashSet[string]]::new($script:PathComparer)
$configCreated = $false
$manifestTouched = $false
$previousManifestBackup = $null

$transaction = [ordered]@{
    schemaVersion = 1
    packageVersion = $packageVersion
    createdAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    codexRoot = $destinationRoot
    status = 'Preparing'
    previousManifest = $null
    originals = @()
    migrations = @($migrations | ForEach-Object {
        [ordered]@{
            linkPath = $_.RelativePath
            targetPath = $_.TargetPath
            linkType = 'Junction'
            linkAttributes = $_.LinkAttributes
            targetTreeSha256 = $_.TargetDigest
            backupRelativePath = $null
        }
    })
    intendedWrites = @($plan.Writes | ForEach-Object { $_.File.Path })
    intendedDeletes = @($plan.Deletes | ForEach-Object { $_.RelativePath })
    preservedRetired = @($plan.PreservedRetired)
}

try {
    [System.IO.Directory]::CreateDirectory($backupRoot) | Out-Null
    Write-JsonAtomic -Value $transaction -Path $transactionPath

    foreach ($candidate in $plan.BackupCandidates) {
        $record = Backup-OriginalPath -Candidate $candidate -BackupRoot $backupRoot
        $backupRecords.Add($record)
    }

    $manifestItem = Get-LiteralItemOrNull -LiteralPath $manifestPath
    if ($plan.ManifestNeedsWrite -and $null -ne $manifestItem) {
        $previousManifestBackup = Join-Path -Path $backupRoot -ChildPath 'previous-manifest.json'
        $manifestHash = Get-FileSha256 -LiteralPath $manifestPath
        Copy-Item -LiteralPath $manifestPath -Destination $previousManifestBackup -Force -ErrorAction Stop
        if (-not (Get-FileSha256 -LiteralPath $previousManifestBackup).Equals($manifestHash, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'The previous install manifest backup failed SHA-256 verification.'
        }
        $transaction.previousManifest = [ordered]@{ existed = $true; backupRelativePath = 'previous-manifest.json'; sha256 = $manifestHash }
    }
    elseif ($plan.ManifestNeedsWrite) {
        $transaction.previousManifest = [ordered]@{ existed = $false; backupRelativePath = $null; sha256 = $null }
    }

    for ($index = 0; $index -lt $migrations.Count; $index++) {
        $migration = $migrations[$index]
        $migrationBackupPath = Join-Path -Path $backupRoot -ChildPath ('migrations\{0:D3}\content' -f $index)
        [void](Copy-NormalDirectory -Source $migration.TargetPath -Destination $migrationBackupPath -Description "Junction target backup for '$($migration.LinkPath)'")
        $transaction.migrations[$index].backupRelativePath = ConvertTo-RelativeManifestPath -BasePath $backupRoot -FullPath $migrationBackupPath
    }

    $transaction.originals = @($backupRecords | ForEach-Object {
        [ordered]@{
            path = $_.RelativePath
            reason = $_.Reason
            kind = $_.Kind
            backupRelativePath = $_.BackupRelativePath
            sha256 = $_.Sha256
            treeSha256 = $_.TreeDigest
        }
    })
    $transaction.status = 'BackupComplete'
    Write-JsonAtomic -Value $transaction -Path $transactionPath

    foreach ($migration in $migrations) {
        $linkItem = Get-LiteralItemOrNull -LiteralPath $migration.LinkPath
        if ($null -eq $linkItem -or [string]$linkItem.LinkType -ne 'Junction' -or -not (Get-JunctionTargetPath -Item $linkItem).Equals($migration.TargetPath, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Junction '$($migration.LinkPath)' changed after preflight."
        }
        Assert-TreeMatchesSnapshot -Expected $migration.TargetSnapshot -ActualRoot $migration.TargetPath -Description "Junction target for '$($migration.LinkPath)'"

        [System.IO.Directory]::Delete($migration.LinkPath)
        $appliedMigrations.Add($migration)
        [void](Copy-NormalDirectory -Source $migration.TargetPath -Destination $migration.LinkPath -Description "Migrated local copy for '$($migration.LinkPath)'")
        Assert-TreeMatchesSnapshot -Expected $migration.TargetSnapshot -ActualRoot $migration.TargetPath -Description "Unchanged junction target for '$($migration.LinkPath)'"
    }

    foreach ($delete in $plan.Deletes) {
        if (-not (Test-IsUnderMigration -Path $delete.Path -Migrations $migrations)) {
            $record = $backupRecords | Where-Object { $_.Path.Equals($delete.Path, [StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
            $appliedNormalPaths.Add([pscustomobject]@{ Path = $delete.Path; BackupRecord = $record })
        }
        Remove-NormalPath -Path $delete.Path -AllowedRoot $destinationRoot
    }

    foreach ($write in $plan.Writes) {
        if (-not (Test-IsUnderMigration -Path $write.DestinationPath -Migrations $migrations)) {
            $record = $backupRecords | Where-Object { $_.Path.Equals($write.DestinationPath, [StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
            $appliedNormalPaths.Add([pscustomobject]@{ Path = $write.DestinationPath; BackupRecord = $record })
        }
        if ($write.ExistingKind -eq 'directory') {
            Remove-NormalPath -Path $write.DestinationPath -AllowedRoot $destinationRoot
        }
        $parent = [System.IO.Path]::GetDirectoryName($write.DestinationPath)
        if ($null -eq (Get-LiteralItemOrNull -LiteralPath $parent)) {
            [void]$createdDirectories.Add($parent)
        }
        Copy-FileVerified -Source $write.File.SourcePath -Destination $write.DestinationPath -ExpectedSha256 $write.File.Sha256
    }

    if ($plan.CreateConfig) {
        $configHash = Get-FileSha256 -LiteralPath $plan.ConfigExamplePath
        Copy-FileVerified -Source $plan.ConfigExamplePath -Destination $plan.ConfigPath -ExpectedSha256 $configHash
        $configCreated = $true
    }

    foreach ($migration in $migrations) {
        Assert-TreeMatchesSnapshot -Expected $migration.TargetSnapshot -ActualRoot $migration.TargetPath -Description "Unchanged junction target for '$($migration.LinkPath)'"
    }

    if ($plan.ManifestNeedsWrite) {
        $manifestTouched = $true
        Write-JsonAtomic -Value (New-ManifestValue -PackageVersion $packageVersion -PackageFiles $packageFiles) -Path $manifestPath
    }

    $transaction.status = 'Committed'
    $transaction.completedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    Write-JsonAtomic -Value $transaction -Path $transactionPath
}
catch {
    $installError = $_
    $rollbackErrors = [System.Collections.Generic.List[string]]::new()

    for ($index = $appliedNormalPaths.Count - 1; $index -ge 0; $index--) {
        $applied = $appliedNormalPaths[$index]
        try {
            if ($null -ne $applied.BackupRecord) {
                Restore-BackupRecord -Record $applied.BackupRecord -BackupRoot $backupRoot -DestinationRoot $destinationRoot
            }
            else {
                Remove-NormalPath -Path $applied.Path -AllowedRoot $destinationRoot
            }
        }
        catch {
            $rollbackErrors.Add("$($applied.Path): $($_.Exception.Message)")
        }
    }

    if ($configCreated) {
        try {
            Remove-NormalPath -Path $plan.ConfigPath -AllowedRoot $destinationRoot
        }
        catch {
            $rollbackErrors.Add("$($plan.ConfigPath): $($_.Exception.Message)")
        }
    }

    for ($index = $appliedMigrations.Count - 1; $index -ge 0; $index--) {
        $migration = $appliedMigrations[$index]
        try {
            Remove-NormalPath -Path $migration.LinkPath -AllowedRoot $destinationRoot
            $parent = [System.IO.Path]::GetDirectoryName($migration.LinkPath)
            [System.IO.Directory]::CreateDirectory($parent) | Out-Null
            New-Item -ItemType Junction -Path $migration.LinkPath -Target $migration.TargetPath -ErrorAction Stop | Out-Null
            $restoredJunction = Get-LiteralItemOrNull -LiteralPath $migration.LinkPath
            if ($null -eq $restoredJunction -or [string]$restoredJunction.LinkType -ne 'Junction' -or -not (Get-JunctionTargetPath -Item $restoredJunction).Equals($migration.TargetPath, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Restored junction did not verify.'
            }
            Assert-TreeMatchesSnapshot -Expected $migration.TargetSnapshot -ActualRoot $migration.TargetPath -Description "Restored junction target for '$($migration.LinkPath)'"
        }
        catch {
            $rollbackErrors.Add("$($migration.LinkPath): $($_.Exception.Message)")
        }
    }

    if ($manifestTouched) {
        try {
            if ($null -ne $previousManifestBackup) {
                Copy-Item -LiteralPath $previousManifestBackup -Destination $manifestPath -Force -ErrorAction Stop
                $expectedManifestHash = [string]$transaction.previousManifest.sha256
                if (-not (Get-FileSha256 -LiteralPath $manifestPath).Equals($expectedManifestHash, [StringComparison]::OrdinalIgnoreCase)) {
                    throw 'Restored manifest failed SHA-256 verification.'
                }
            }
            else {
                Remove-NormalPath -Path $manifestPath -AllowedRoot $destinationRoot
            }
        }
        catch {
            $rollbackErrors.Add("${manifestPath}: $($_.Exception.Message)")
        }
    }

    foreach ($directory in @($createdDirectories | Sort-Object -Descending)) {
        try {
            $directoryItem = Get-LiteralItemOrNull -LiteralPath $directory
            if ($null -ne $directoryItem -and $directoryItem.PSIsContainer -and -not (Test-IsFileSystemLink -Item $directoryItem) -and @(Get-ChildItem -LiteralPath $directory -Force).Count -eq 0) {
                [System.IO.Directory]::Delete($directory)
            }
        }
        catch {
            $rollbackErrors.Add("${directory}: $($_.Exception.Message)")
        }
    }

    try {
        $transaction.status = if ($rollbackErrors.Count -eq 0) { 'RolledBack' } else { 'RollbackFailed' }
        $transaction.failure = $installError.Exception.Message
        $transaction.rollbackErrors = @($rollbackErrors)
        $transaction.completedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        Write-JsonAtomic -Value $transaction -Path $transactionPath
    }
    catch {
        $rollbackErrors.Add("Transaction record: $($_.Exception.Message)")
    }

    if ($rollbackErrors.Count -gt 0) {
        throw "Installation failed: $($installError.Exception.Message)`nRollback was incomplete. Use '$transactionPath' and its verified backups for manual recovery:`n - $($rollbackErrors -join "`n - ")"
    }
    throw "Installation failed and original files and junctions were restored. Recovery record: '$transactionPath'. Cause: $($installError.Exception.Message)"
}

Write-Host "Installed package $packageVersion. Manifest: $manifestPath"
[pscustomobject]@{
    Status = 'Installed'
    PackageVersion = $packageVersion
    CodexRoot = $destinationRoot
    ManifestPath = $manifestPath
    BackupPath = $backupRoot
    FilesWritten = $plan.Writes.Count
    RetiredFilesRemoved = $plan.Deletes.Count
    JunctionsMigrated = $migrations.Count
    ConfigInitialized = $plan.CreateConfig
    PreservedRetiredFiles = @($plan.PreservedRetired)
}
