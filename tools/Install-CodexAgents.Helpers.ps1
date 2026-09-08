# Private filesystem and transaction primitives for Install-CodexAgents.ps1.
# This file is dot-sourced by the installer and is not a standalone entry point.

function Get-LiteralItemOrNull {
    param([Parameter(Mandatory)][string] $LiteralPath)

    try {
        return Get-Item -LiteralPath $LiteralPath -Force -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        return $null
    }
}

function Test-IsFileSystemLink {
    param([Parameter(Mandatory)][System.IO.FileSystemInfo] $Item)

    # OneDrive cloud placeholders can carry ReparsePoint while PowerShell exposes no
    # link type or target. LinkType distinguishes junctions and symbolic links from
    # those ordinary hydrated/cloud-backed files and directories.
    return -not [string]::IsNullOrWhiteSpace([string]$Item.LinkType)
}

function ConvertTo-CanonicalPath {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $BasePath
    )

    $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim())
    if ($expanded -eq '~') {
        $expanded = [string]$HOME
    }
    elseif ($expanded.StartsWith('~\', [StringComparison]::Ordinal) -or $expanded.StartsWith('~/', [StringComparison]::Ordinal)) {
        $expanded = Join-Path -Path ([string]$HOME) -ChildPath $expanded.Substring(2)
    }
    elseif ($expanded.StartsWith('~', [StringComparison]::Ordinal)) {
        throw "Only '~', '~\', and '~/' home-relative paths are supported: $Path"
    }

    if (-not [System.IO.Path]::IsPathFullyQualified($expanded)) {
        $expanded = Join-Path -Path $BasePath -ChildPath $expanded
    }

    return [System.IO.Path]::GetFullPath($expanded)
}

function Test-PathWithinOrEqual {
    param(
        [Parameter(Mandatory)][string] $Candidate,
        [Parameter(Mandatory)][string] $Root
    )

    $candidateFull = [System.IO.Path]::GetFullPath($Candidate)
    $rootFull = [System.IO.Path]::GetFullPath($Root)
    if ($candidateFull.Equals($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $rootPrefix = $rootFull
    if (-not $rootPrefix.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $rootPrefix += [System.IO.Path]::DirectorySeparatorChar
    }

    return $candidateFull.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Test-PathsOverlap {
    param(
        [Parameter(Mandatory)][string] $First,
        [Parameter(Mandatory)][string] $Second
    )

    return (Test-PathWithinOrEqual -Candidate $First -Root $Second) -or (Test-PathWithinOrEqual -Candidate $Second -Root $First)
}

function Assert-NoLinkedAncestors {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $Description
    )

    $current = [System.IO.Path]::GetFullPath($Path)
    $paths = [System.Collections.Generic.List[string]]::new()
    while (-not [string]::IsNullOrEmpty($current)) {
        $paths.Add($current)
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrEmpty($parent) -or $parent.Equals($current, [StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $current = $parent
    }

    for ($index = $paths.Count - 1; $index -ge 0; $index--) {
        $item = Get-LiteralItemOrNull -LiteralPath $paths[$index]
        if ($null -ne $item -and (Test-IsFileSystemLink -Item $item)) {
            throw "$Description has a linked or redirected ancestor '$($item.FullName)'. Choose a root with ordinary directory ancestors."
        }
    }
}

function ConvertTo-RelativeManifestPath {
    param(
        [Parameter(Mandatory)][string] $BasePath,
        [Parameter(Mandatory)][string] $FullPath
    )

    return ([System.IO.Path]::GetRelativePath($BasePath, $FullPath) -replace '\\', '/')
}

function Get-FileSha256 {
    param([Parameter(Mandatory)][string] $LiteralPath)

    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
}

function Get-SafeTreeSnapshot {
    param(
        [Parameter(Mandatory)][string] $Root,
        [Parameter(Mandatory)][string] $Description
    )

    $rootItem = Get-LiteralItemOrNull -LiteralPath $Root
    if ($null -eq $rootItem -or -not $rootItem.PSIsContainer) {
        throw "$Description '$Root' is not an existing directory."
    }
    if (Test-IsFileSystemLink -Item $rootItem) {
        throw "$Description '$Root' is a link or reparse point."
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    $pending = [System.Collections.Generic.Stack[string]]::new()
    $pending.Push($rootItem.FullName)

    while ($pending.Count -gt 0) {
        $directory = $pending.Pop()
        foreach ($item in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
            if (Test-IsFileSystemLink -Item $item) {
                throw "$Description contains an unsupported link or reparse point '$($item.FullName)'."
            }

            $relative = ConvertTo-RelativeManifestPath -BasePath $rootItem.FullName -FullPath $item.FullName
            if ($item.PSIsContainer) {
                $entries.Add([pscustomobject]@{ Type = 'directory'; Path = $relative; Sha256 = $null; Length = $null })
                $pending.Push($item.FullName)
            }
            else {
                $entries.Add([pscustomobject]@{
                    Type = 'file'
                    Path = $relative
                    Sha256 = Get-FileSha256 -LiteralPath $item.FullName
                    Length = [long]$item.Length
                })
            }
        }
    }

    return @($entries | Sort-Object -Property @{ Expression = 'Path'; Ascending = $true }, @{ Expression = 'Type'; Ascending = $true })
}

function Get-TreeDigest {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]] $Snapshot)

    $lines = foreach ($entry in $Snapshot) {
        '{0}|{1}|{2}|{3}' -f $entry.Type, $entry.Path, $entry.Length, $entry.Sha256
    }
    $bytes = $script:Utf8NoBom.GetBytes(($lines -join "`n"))
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($hasher.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $hasher.Dispose()
    }
}

function Assert-TreeMatchesSnapshot {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]] $Expected,
        [Parameter(Mandatory)][string] $ActualRoot,
        [Parameter(Mandatory)][string] $Description
    )

    $actual = @(Get-SafeTreeSnapshot -Root $ActualRoot -Description $Description)
    $expectedDigest = Get-TreeDigest -Snapshot $Expected
    $actualDigest = Get-TreeDigest -Snapshot $actual
    if (-not $expectedDigest.Equals($actualDigest, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Description did not verify after copying. Expected tree digest $expectedDigest but found $actualDigest."
    }
}

function Copy-NormalDirectory {
    param(
        [Parameter(Mandatory)][string] $Source,
        [Parameter(Mandatory)][string] $Destination,
        [Parameter(Mandatory)][string] $Description
    )

    $snapshot = @(Get-SafeTreeSnapshot -Root $Source -Description $Description)
    if ($null -ne (Get-LiteralItemOrNull -LiteralPath $Destination)) {
        throw "Copy destination already exists: $Destination"
    }

    [System.IO.Directory]::CreateDirectory($Destination) | Out-Null
    foreach ($entry in $snapshot) {
        $destinationPath = Join-Path -Path $Destination -ChildPath ($entry.Path -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if ($entry.Type -eq 'directory') {
            [System.IO.Directory]::CreateDirectory($destinationPath) | Out-Null
        }
        else {
            $sourcePath = Join-Path -Path $Source -ChildPath ($entry.Path -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            $parent = [System.IO.Path]::GetDirectoryName($destinationPath)
            [System.IO.Directory]::CreateDirectory($parent) | Out-Null
            Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force -ErrorAction Stop
        }
    }

    Assert-TreeMatchesSnapshot -Expected $snapshot -ActualRoot $Destination -Description $Description
    return $snapshot
}

function Remove-NormalPath {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $AllowedRoot
    )

    if (-not (Test-PathWithinOrEqual -Candidate $Path -Root $AllowedRoot) -or [System.IO.Path]::GetFullPath($Path).Equals([System.IO.Path]::GetFullPath($AllowedRoot), [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove path outside the verified Codex root: $Path"
    }
    $item = Get-LiteralItemOrNull -LiteralPath $Path
    if ($null -eq $item) {
        return
    }
    if (Test-IsFileSystemLink -Item $item) {
        throw "Refusing generic removal of link or reparse point '$Path'."
    }
    if ($item.PSIsContainer) {
        [void](Get-SafeTreeSnapshot -Root $item.FullName -Description 'Removal target')
        [System.IO.Directory]::Delete($item.FullName, $true)
    }
    else {
        [System.IO.File]::Delete($item.FullName)
    }
}

function Copy-FileVerified {
    param(
        [Parameter(Mandatory)][string] $Source,
        [Parameter(Mandatory)][string] $Destination,
        [Parameter(Mandatory)][string] $ExpectedSha256
    )

    $parent = [System.IO.Path]::GetDirectoryName($Destination)
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    $temporary = Join-Path -Path $parent -ChildPath ('.agentkit-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        Copy-Item -LiteralPath $Source -Destination $temporary -Force -ErrorAction Stop
        $temporaryHash = Get-FileSha256 -LiteralPath $temporary
        if (-not $temporaryHash.Equals($ExpectedSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Copied file '$Source' failed SHA-256 verification."
        }
        [System.IO.File]::Move($temporary, $Destination, $true)
    }
    finally {
        if ([System.IO.File]::Exists($temporary)) {
            [System.IO.File]::Delete($temporary)
        }
    }

    $installedHash = Get-FileSha256 -LiteralPath $Destination
    if (-not $installedHash.Equals($ExpectedSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Installed file '$Destination' failed SHA-256 verification."
    }
}

function Write-JsonAtomic {
    param(
        [Parameter(Mandatory)][object] $Value,
        [Parameter(Mandatory)][string] $Path
    )

    $parent = [System.IO.Path]::GetDirectoryName($Path)
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    $temporary = Join-Path -Path $parent -ChildPath ('.agentkit-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $json = $Value | ConvertTo-Json -Depth 20
        [System.IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine, $script:Utf8NoBom)
        [System.IO.File]::Move($temporary, $Path, $true)
    }
    finally {
        if ([System.IO.File]::Exists($temporary)) {
            [System.IO.File]::Delete($temporary)
        }
    }
}

function Backup-OriginalPath {
    param(
        [Parameter(Mandatory)][object] $Candidate,
        [Parameter(Mandatory)][string] $BackupRoot
    )

    $item = Get-LiteralItemOrNull -LiteralPath $Candidate.Path
    if ($null -eq $item) {
        throw "Backup source disappeared after preflight: $($Candidate.Path)"
    }
    if (Test-IsFileSystemLink -Item $item) {
        throw "Backup source became a link after preflight: $($Candidate.Path)"
    }

    $backupPath = Join-Path -Path $BackupRoot -ChildPath ('originals\' + ($Candidate.RelativePath -replace '/', '\'))
    if ($item.PSIsContainer) {
        $snapshot = @(Copy-NormalDirectory -Source $item.FullName -Destination $backupPath -Description "Backup of '$($Candidate.Path)'")
        return [pscustomobject]@{
            Path = $Candidate.Path
            RelativePath = $Candidate.RelativePath
            Reason = $Candidate.Reason
            Kind = 'directory'
            BackupRelativePath = ConvertTo-RelativeManifestPath -BasePath $BackupRoot -FullPath $backupPath
            Sha256 = $null
            TreeDigest = Get-TreeDigest -Snapshot $snapshot
        }
    }

    $backupParent = [System.IO.Path]::GetDirectoryName($backupPath)
    [System.IO.Directory]::CreateDirectory($backupParent) | Out-Null
    $sourceHash = Get-FileSha256 -LiteralPath $item.FullName
    Copy-Item -LiteralPath $item.FullName -Destination $backupPath -Force -ErrorAction Stop
    $backupHash = Get-FileSha256 -LiteralPath $backupPath
    if (-not $sourceHash.Equals($backupHash, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Backup of '$($Candidate.Path)' failed SHA-256 verification."
    }
    return [pscustomobject]@{
        Path = $Candidate.Path
        RelativePath = $Candidate.RelativePath
        Reason = $Candidate.Reason
        Kind = 'file'
        BackupRelativePath = ConvertTo-RelativeManifestPath -BasePath $BackupRoot -FullPath $backupPath
        Sha256 = $sourceHash
        TreeDigest = $null
    }
}

function Restore-BackupRecord {
    param(
        [Parameter(Mandatory)][object] $Record,
        [Parameter(Mandatory)][string] $BackupRoot,
        [Parameter(Mandatory)][string] $DestinationRoot
    )

    Remove-NormalPath -Path $Record.Path -AllowedRoot $DestinationRoot
    $backupPath = Join-Path -Path $BackupRoot -ChildPath ($Record.BackupRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if ($Record.Kind -eq 'directory') {
        [void](Copy-NormalDirectory -Source $backupPath -Destination $Record.Path -Description "Rollback backup for '$($Record.Path)'")
    }
    else {
        $parent = [System.IO.Path]::GetDirectoryName($Record.Path)
        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
        Copy-Item -LiteralPath $backupPath -Destination $Record.Path -Force -ErrorAction Stop
        $restoredHash = Get-FileSha256 -LiteralPath $Record.Path
        if (-not $restoredHash.Equals([string]$Record.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Rollback verification failed for '$($Record.Path)'."
        }
    }
}
