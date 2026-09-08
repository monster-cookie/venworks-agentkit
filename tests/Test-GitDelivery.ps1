#requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$repository = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $repository ('.work/git-delivery-tests-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
$logPath = Join-Path $testRoot 'commands.log'
$isolatedGlobalConfig = Join-Path $testRoot 'isolated-global.gitconfig'
$emptyHooks = Join-Path $testRoot 'empty-hooks'
$emptyTemplate = Join-Path $testRoot 'empty-template'
$script:assertionCount = 0
$script:groups = [Collections.Generic.List[string]]::new()
$savedEnvironment = @{}
$savedEnvironmentPresent = @{}

function Write-TestFile {
    param([string]$Path, [string]$Content)

    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
}

function Add-TestLog {
    param([string]$Message)

    [IO.File]::AppendAllText($logPath, $Message + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
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

function Complete-Group {
    param([string]$Name)

    $script:groups.Add($Name)
    Write-Output "PASS: $Name"
}

function Invoke-Git {
    param(
        [string]$WorkingDirectory,
        [string[]]$GitArguments,
        [switch]$AllowFailure
    )

    Add-TestLog ('git -C "{0}" {1}' -f $WorkingDirectory, ($GitArguments -join ' '))
    $outputLines = @(& git -C $WorkingDirectory @GitArguments 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
    $outputText = $outputLines -join "`n"
    if ($outputText) { Add-TestLog $outputText }
    Add-TestLog "exit=$exitCode"
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "Git command failed with exit code $exitCode in $WorkingDirectory`: git $($GitArguments -join ' ')`n$outputText"
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        OutputText = $outputText
    }
}

function Get-GitText {
    param([string]$WorkingDirectory, [string[]]$GitArguments)

    return (Invoke-Git $WorkingDirectory $GitArguments).OutputText.Trim()
}

function Get-GitLines {
    param([string]$WorkingDirectory, [string[]]$GitArguments)

    $text = Get-GitText $WorkingDirectory $GitArguments
    if (-not $text) { return @() }
    return @($text -split "`r?`n")
}

function Initialize-LocalGit {
    param([string]$Path)

    $hooksPath = $emptyHooks.Replace('\', '/')
    foreach ($entry in @(
        @('user.name', 'Git Delivery Test'),
        @('user.email', 'git-delivery-test@example.invalid'),
        @('commit.gpgSign', 'false'),
        @('tag.gpgSign', 'false'),
        @('core.autocrlf', 'false'),
        @('core.safecrlf', 'false'),
        @('core.hooksPath', $hooksPath),
        @('advice.detachedHead', 'false')
    )) {
        [void](Invoke-Git $Path @('config', '--local', $entry[0], $entry[1]))
    }
}

function New-Fixture {
    param(
        [string]$Name,
        [string]$BaseBranch = 'main',
        [Collections.IDictionary]$Files
    )

    if (-not $Files) {
        $Files = [ordered]@{
            'task.txt' = "task=old`n"
            'keep.txt' = "keep=original`n"
        }
    }
    $root = Join-Path $testRoot $Name
    $source = Join-Path $root 'source'
    $remote = Join-Path $root 'remote.git'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    [void](Invoke-Git $root @('init', '--bare', $remote))
    [void](Invoke-Git $root @('init', "--initial-branch=$BaseBranch", $source))
    Initialize-LocalGit $source
    foreach ($entry in $Files.GetEnumerator()) {
        Write-TestFile (Join-Path $source $entry.Key) $entry.Value
    }
    [void](Invoke-Git $source @('add', '--all'))
    [void](Invoke-Git $source @('commit', '-m', 'Baseline'))
    $baseOid = Get-GitText $source @('rev-parse', 'HEAD')
    [void](Invoke-Git $source @('remote', 'add', 'origin', $remote))
    [void](Invoke-Git $source @('push', '-u', 'origin', "HEAD:refs/heads/$BaseBranch"))
    [void](Invoke-Git $remote @('symbolic-ref', 'HEAD', "refs/heads/$BaseBranch"))
    return [pscustomobject]@{
        Name = $Name
        Root = $root
        Source = $source
        Remote = $remote
        BaseBranch = $BaseBranch
        BaseOid = $baseOid
    }
}

function Save-ReviewedPatch {
    param([string]$RepositoryPath, [string]$PatchPath, [string[]]$Paths = @())

    $arguments = @('diff', '--cached', '--binary', '--full-index', '--') + $Paths
    $patch = (Invoke-Git $RepositoryPath $arguments).OutputText
    Assert-True ([bool]$patch) "Reviewed patch was empty: $PatchPath"
    Write-TestFile $PatchPath ($patch.TrimEnd() + "`n")
    return $PatchPath
}

function Get-WorkingState {
    param([string]$RepositoryPath)

    $gitDirectory = [IO.Path]::GetFullPath((Join-Path $RepositoryPath '.git'))
    $files = @(Get-ChildItem -LiteralPath $RepositoryPath -Recurse -Force -File | Where-Object {
        -not [IO.Path]::GetFullPath($_.FullName).StartsWith($gitDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
    } | Sort-Object FullName | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($RepositoryPath, $_.FullName).Replace('\', '/')
        "${relative}:$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)"
    })
    return [ordered]@{
        Status = Get-GitText $RepositoryPath @('status', '--porcelain=v1', '--untracked-files=all')
        IndexTree = Get-GitText $RepositoryPath @('write-tree')
        CachedDiff = Get-GitText $RepositoryPath @('diff', '--cached', '--binary', '--full-index')
        WorktreeDiff = Get-GitText $RepositoryPath @('diff', '--binary', '--full-index')
        Files = $files -join "`n"
    } | ConvertTo-Json -Compress
}

function Get-RemoteRefOid {
    param([string]$RepositoryPath, [string]$RemoteName, [string]$Branch)

    $line = Get-GitText $RepositoryPath @('ls-remote', '--heads', $RemoteName, "refs/heads/$Branch")
    if (-not $line) { return $null }
    return ($line -split '\s+')[0]
}

function New-Candidate {
    param(
        [pscustomobject]$Fixture,
        [string]$PatchPath,
        [string]$HeadBranch,
        [string]$CandidateName = 'candidate',
        [string]$StartOid = $Fixture.BaseOid,
        [string]$PrBaseOid = $Fixture.BaseOid,
        [string]$PrBaseBranch = $Fixture.BaseBranch,
        [AllowNull()][string]$ExpectedDestinationOid = $null,
        [string[]]$AllowedPriorPrCommits = @(),
        [AllowNull()][string]$HookPath = $null
    )

    $candidatePath = Join-Path $Fixture.Root $CandidateName
    [void](Invoke-Git $Fixture.Root @('clone', '--no-checkout', $Fixture.Remote, $candidatePath))
    Initialize-LocalGit $candidatePath
    if ($HookPath) {
        [void](Invoke-Git $candidatePath @('config', '--local', 'core.hooksPath', $HookPath.Replace('\', '/')))
    }
    [void](Invoke-Git $candidatePath @('checkout', '--detach', $StartOid))
    [void](Invoke-Git $candidatePath @('switch', '-c', $HeadBranch))
    [void](Invoke-Git $candidatePath @('apply', '--index', '--whitespace=nowarn', $PatchPath))
    $expectedTree = Get-GitText $candidatePath @('write-tree')
    [void](Invoke-Git $candidatePath @('commit', '-m', 'Deliver reviewed task change'))
    $commitOid = Get-GitText $candidatePath @('rev-parse', 'HEAD')
    $expectedPrRange = @($AllowedPriorPrCommits) + $commitOid
    return [pscustomobject]@{
        Path = $candidatePath
        Remote = $Fixture.Remote
        HeadBranch = $HeadBranch
        PrBaseBranch = $PrBaseBranch
        PrBaseOid = $PrBaseOid
        ExpectedParentOid = $StartOid
        ExpectedDestinationOid = $ExpectedDestinationOid
        ExpectedTree = $expectedTree
        CommitOid = $commitOid
        ExpectedPrRange = @($expectedPrRange)
    }
}

function Inspect-Candidate {
    param([pscustomobject]$Candidate)

    [void](Invoke-Git $Candidate.Path @('fetch', '--prune', 'origin'))
    $reasons = [Collections.Generic.List[string]]::new()
    $actualBase = Get-GitText $Candidate.Path @('rev-parse', "refs/remotes/origin/$($Candidate.PrBaseBranch)")
    if ($actualBase -cne $Candidate.PrBaseOid) { $reasons.Add('PR base changed after candidate inspection.') }

    $actualDestination = Get-RemoteRefOid $Candidate.Path 'origin' $Candidate.HeadBranch
    if ($Candidate.ExpectedDestinationOid) {
        if ($actualDestination -cne $Candidate.ExpectedDestinationOid) { $reasons.Add('Destination task ref changed after candidate inspection.') }
    } elseif ($actualDestination) {
        $reasons.Add('Expected a missing destination task ref, but it now exists.')
    }

    $actualTree = Get-GitText $Candidate.Path @('rev-parse', "$($Candidate.CommitOid)^{tree}")
    if ($actualTree -cne $Candidate.ExpectedTree) { $reasons.Add('Actual committed tree differs from the reviewed candidate tree.') }
    $remainingState = Get-GitText $Candidate.Path @('status', '--porcelain=v1', '--untracked-files=all')
    if ($remainingState) { $reasons.Add('Candidate has remaining index or working-tree changes after commit hooks.') }

    $actualParent = Get-GitText $Candidate.Path @('rev-parse', "$($Candidate.CommitOid)^1")
    if ($actualParent -cne $Candidate.ExpectedParentOid) { $reasons.Add('Candidate parent changed.') }
    $ancestry = Invoke-Git $Candidate.Path @('merge-base', '--is-ancestor', $Candidate.PrBaseOid, $Candidate.CommitOid) -AllowFailure
    if ($ancestry.ExitCode -ne 0) { $reasons.Add('Candidate no longer descends from the verified PR base.') }
    if ($Candidate.ExpectedDestinationOid) {
        $destinationAncestry = Invoke-Git $Candidate.Path @('merge-base', '--is-ancestor', $Candidate.ExpectedDestinationOid, $Candidate.CommitOid) -AllowFailure
        if ($destinationAncestry.ExitCode -ne 0) { $reasons.Add('Candidate would not preserve the inspected destination history.') }
    }

    $actualPrRange = @(Get-GitLines $Candidate.Path @('rev-list', '--reverse', "$($Candidate.PrBaseOid)..$($Candidate.CommitOid)"))
    if (($actualPrRange -join "`n") -cne (@($Candidate.ExpectedPrRange) -join "`n")) {
        $reasons.Add('PR base-to-candidate history differs from the reviewed commit range.')
    }
    $actualOutgoingRange = @()
    if ($Candidate.ExpectedDestinationOid) {
        $actualOutgoingRange = @(Get-GitLines $Candidate.Path @('rev-list', '--reverse', "$($Candidate.ExpectedDestinationOid)..$($Candidate.CommitOid)"))
        if (($actualOutgoingRange -join "`n") -cne $Candidate.CommitOid) {
            $reasons.Add('Destination-to-candidate outgoing history contains more than the reviewed follow-up commit.')
        }
    }
    $diffCheck = Invoke-Git $Candidate.Path @('diff', '--check', "$($Candidate.PrBaseOid)..$($Candidate.CommitOid)") -AllowFailure
    if ($diffCheck.ExitCode -ne 0) { $reasons.Add('Final base-to-candidate diff check failed.') }

    return [pscustomobject]@{
        IsValid = $reasons.Count -eq 0
        Reasons = @($reasons)
        ActualBaseOid = $actualBase
        ActualDestinationOid = $actualDestination
        ActualTree = $actualTree
        RemainingState = $remainingState
        ActualPrRange = @($actualPrRange)
        ActualOutgoingRange = @($actualOutgoingRange)
    }
}

function Publish-Candidate {
    param([pscustomobject]$Candidate)

    $inspection = Inspect-Candidate $Candidate
    if (-not $inspection.IsValid) {
        return [pscustomobject]@{ Published = $false; Inspection = $inspection; RemoteOid = $null }
    }
    [void](Invoke-Git $Candidate.Path @('push', 'origin', "$($Candidate.CommitOid):refs/heads/$($Candidate.HeadBranch)"))
    $remoteOid = Get-RemoteRefOid $Candidate.Path 'origin' $Candidate.HeadBranch
    return [pscustomobject]@{ Published = $true; Inspection = $inspection; RemoteOid = $remoteOid }
}

function Assert-Published {
    param([pscustomobject]$Candidate, [pscustomobject]$Publication)

    Assert-True $Publication.Published "Candidate was refused: $($Publication.Inspection.Reasons -join '; ')"
    Assert-Equal $Candidate.CommitOid $Publication.RemoteOid 'Destination ref did not resolve to the inspected candidate commit.'
}

function New-FreshConsumer {
    param([pscustomobject]$Fixture, [pscustomobject]$Candidate, [string]$Name = 'consumer')

    $consumer = Join-Path $Fixture.Root $Name
    [void](Invoke-Git $Fixture.Root @('clone', '--branch', $Candidate.HeadBranch, '--single-branch', $Fixture.Remote, $consumer))
    Initialize-LocalGit $consumer
    Assert-Equal $Candidate.CommitOid (Get-GitText $consumer @('rev-parse', 'HEAD')) 'Fresh consumer did not check out the delivered commit.'
    return $consumer
}

function Add-CommitAndPush {
    param(
        [pscustomobject]$Fixture,
        [string]$CloneName,
        [string]$Branch,
        [string]$Path,
        [string]$Content,
        [string]$Message
    )

    $clone = Join-Path $Fixture.Root $CloneName
    [void](Invoke-Git $Fixture.Root @('clone', '--branch', $Branch, '--single-branch', $Fixture.Remote, $clone))
    Initialize-LocalGit $clone
    Write-TestFile (Join-Path $clone $Path) $Content
    [void](Invoke-Git $clone @('add', '--', $Path))
    [void](Invoke-Git $clone @('commit', '-m', $Message))
    $oid = Get-GitText $clone @('rev-parse', 'HEAD')
    [void](Invoke-Git $clone @('push', 'origin', "HEAD:refs/heads/$Branch"))
    return [pscustomobject]@{ Path = $clone; Oid = $oid }
}

New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
New-Item -ItemType Directory -Path $emptyHooks -Force | Out-Null
New-Item -ItemType Directory -Path $emptyTemplate -Force | Out-Null
Write-TestFile $isolatedGlobalConfig "[core]`n    longpaths = true`n"

$gitEnvironmentNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($name in @(
    'GIT_DIR', 'GIT_WORK_TREE', 'GIT_COMMON_DIR', 'GIT_INDEX_FILE', 'GIT_OBJECT_DIRECTORY', 'GIT_ALTERNATE_OBJECT_DIRECTORIES',
    'GIT_NAMESPACE', 'GIT_SHALLOW_FILE', 'GIT_REPLACE_REF_BASE', 'GIT_GRAFT_FILE', 'GIT_QUARANTINE_PATH',
    'GIT_CONFIG_COUNT', 'GIT_CONFIG_PARAMETERS', 'GIT_CONFIG_SYSTEM', 'GIT_CONFIG_NOSYSTEM', 'GIT_CONFIG_GLOBAL',
    'GIT_AUTHOR_NAME', 'GIT_AUTHOR_EMAIL', 'GIT_AUTHOR_DATE', 'GIT_COMMITTER_NAME', 'GIT_COMMITTER_EMAIL', 'GIT_COMMITTER_DATE',
    'GIT_EXTERNAL_DIFF', 'GIT_DIFF_OPTS', 'GIT_LITERAL_PATHSPECS', 'GIT_GLOB_PATHSPECS', 'GIT_NOGLOB_PATHSPECS', 'GIT_ICASE_PATHSPECS',
    'GIT_CEILING_DIRECTORIES', 'GIT_DISCOVERY_ACROSS_FILESYSTEM', 'GIT_OPTIONAL_LOCKS', 'GIT_ATTR_NOSYSTEM',
    'GIT_TERMINAL_PROMPT', 'GIT_ALLOW_PROTOCOL', 'GIT_TEMPLATE_DIR'
)) {
    [void]$gitEnvironmentNames.Add($name)
}
$inheritedConfigCount = [Environment]::GetEnvironmentVariable('GIT_CONFIG_COUNT', 'Process')
$parsedConfigCount = 0
if ([int]::TryParse($inheritedConfigCount, [ref]$parsedConfigCount) -and $parsedConfigCount -gt 0) {
    for ($index = 0; $index -lt $parsedConfigCount; $index++) {
        [void]$gitEnvironmentNames.Add("GIT_CONFIG_KEY_$index")
        [void]$gitEnvironmentNames.Add("GIT_CONFIG_VALUE_$index")
    }
}
foreach ($name in $gitEnvironmentNames) {
    $savedEnvironmentPresent[$name] = Test-Path -LiteralPath "Env:$name"
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    if (Test-Path -LiteralPath "Env:$name") { Remove-Item -LiteralPath "Env:$name" }
}
[Environment]::SetEnvironmentVariable('GIT_CONFIG_NOSYSTEM', '1', 'Process')
[Environment]::SetEnvironmentVariable('GIT_CONFIG_GLOBAL', $isolatedGlobalConfig, 'Process')
[Environment]::SetEnvironmentVariable('GIT_ATTR_NOSYSTEM', '1', 'Process')
[Environment]::SetEnvironmentVariable('GIT_TERMINAL_PROMPT', '0', 'Process')
[Environment]::SetEnvironmentVariable('GIT_ALLOW_PROTOCOL', 'file', 'Process')
[Environment]::SetEnvironmentVariable('GIT_TEMPLATE_DIR', $emptyTemplate, 'Process')

try {
    $gitVersion = (& git --version 2>&1 | ForEach-Object { $_.ToString() }) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Git is unavailable: $gitVersion" }
    Add-TestLog $gitVersion

    $clean = New-Fixture '01-clean-ordinary'
    [void](Invoke-Git $clean.Source @('switch', '-c', 'codex/clean-delivery'))
    Write-TestFile (Join-Path $clean.Source 'task.txt') "task=delivered`n"
    [void](Invoke-Git $clean.Source @('add', '--', 'task.txt'))
    $cleanExpectedTree = Get-GitText $clean.Source @('write-tree')
    [void](Invoke-Git $clean.Source @('commit', '-m', 'Deliver ordinary clean task'))
    $cleanCommit = Get-GitText $clean.Source @('rev-parse', 'HEAD')
    $cleanCandidate = [pscustomobject]@{
        Path = $clean.Source
        Remote = $clean.Remote
        HeadBranch = 'codex/clean-delivery'
        PrBaseBranch = 'main'
        PrBaseOid = $clean.BaseOid
        ExpectedParentOid = $clean.BaseOid
        ExpectedDestinationOid = $null
        ExpectedTree = $cleanExpectedTree
        CommitOid = $cleanCommit
        ExpectedPrRange = @($cleanCommit)
    }
    $cleanPublication = Publish-Candidate $cleanCandidate
    Assert-Published $cleanCandidate $cleanPublication
    $cleanConsumer = New-FreshConsumer $clean $cleanCandidate
    Assert-Equal "task=delivered`n" ([IO.File]::ReadAllText((Join-Path $cleanConsumer 'task.txt'))) 'Fresh consumer has the wrong task content.'
    Assert-Equal '1' (Get-GitText $cleanCandidate.Path @('rev-list', '--count', "$($clean.BaseOid)..$($cleanCandidate.CommitOid)")) 'Clean delivery did not contain exactly one reviewed commit.'
    Assert-Equal $cleanExpectedTree (Get-GitText $clean.Source @('rev-parse', "$cleanCommit^{tree}")) 'Ordinary clean commit tree differs from its reviewed index.'
    Complete-Group 'Ordinary clean task-branch commit, explicit destination ref, inspected tree, and fresh checkout'

    $preceding = New-Fixture '02-preceding'
    Write-TestFile (Join-Path $preceding.Source 'unrelated.txt') "unrelated history`n"
    [void](Invoke-Git $preceding.Source @('add', '--', 'unrelated.txt'))
    [void](Invoke-Git $preceding.Source @('commit', '-m', 'Unrelated preceding commit'))
    Write-TestFile (Join-Path $preceding.Source 'task.txt') "task=reviewed`n"
    [void](Invoke-Git $preceding.Source @('add', '--', 'task.txt'))
    $precedingPatch = Save-ReviewedPatch $preceding.Source (Join-Path $preceding.Root 'reviewed.patch') @('task.txt')
    [void](Invoke-Git $preceding.Source @('switch', '-c', 'codex/naive-from-contaminated-head'))
    [void](Invoke-Git $preceding.Source @('commit', '-m', 'Task on contaminated history'))
    $naiveOid = Get-GitText $preceding.Source @('rev-parse', 'HEAD')
    Assert-Equal '2' (Get-GitText $preceding.Source @('rev-list', '--count', "$($preceding.BaseOid)..$naiveOid")) 'Negative control did not retain the preceding unrelated commit.'
    Assert-True ((Get-GitLines $preceding.Source @('diff', '--name-only', "$($preceding.BaseOid)..$naiveOid")) -contains 'unrelated.txt') 'Naive branch negative control unexpectedly isolated the unrelated file.'
    $precedingCandidate = New-Candidate $preceding $precedingPatch 'codex/isolated-preceding'
    Assert-Published $precedingCandidate (Publish-Candidate $precedingCandidate)
    Assert-Equal '1' (Get-GitText $precedingCandidate.Path @('rev-list', '--count', "$($preceding.BaseOid)..$($precedingCandidate.CommitOid)")) 'Isolated candidate retained unrelated preceding history.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $precedingCandidate.Path 'unrelated.txt'))) 'Isolated candidate tree retained unrelated preceding content.'
    Complete-Group 'Unrelated preceding commit and naive-branch negative control'

    $reverted = New-Fixture '03-reverted'
    Write-TestFile (Join-Path $reverted.Source 'transient.txt') "transient`n"
    [void](Invoke-Git $reverted.Source @('add', '--', 'transient.txt'))
    [void](Invoke-Git $reverted.Source @('commit', '-m', 'Unrelated transient commit'))
    [void](Invoke-Git $reverted.Source @('revert', '--no-edit', 'HEAD'))
    $revertedHead = Get-GitText $reverted.Source @('rev-parse', 'HEAD')
    Assert-Equal (Get-GitText $reverted.Source @('rev-parse', "$($reverted.BaseOid)^{tree}")) (Get-GitText $reverted.Source @('rev-parse', "$revertedHead^{tree}")) 'Commit-and-revert fixture did not return to the base tree.'
    Assert-Equal '2' (Get-GitText $reverted.Source @('rev-list', '--count', "$($reverted.BaseOid)..$revertedHead")) 'Net-zero fixture did not retain both history entries.'
    Write-TestFile (Join-Path $reverted.Source 'task.txt') "task=after-revert`n"
    [void](Invoke-Git $reverted.Source @('add', '--', 'task.txt'))
    $revertedPatch = Save-ReviewedPatch $reverted.Source (Join-Path $reverted.Root 'reviewed.patch') @('task.txt')
    [void](Invoke-Git $reverted.Source @('commit', '-m', 'Task after reverted history'))
    $revertedNaive = Get-GitText $reverted.Source @('rev-parse', 'HEAD')
    Assert-Equal '3' (Get-GitText $reverted.Source @('rev-list', '--count', "$($reverted.BaseOid)..$revertedNaive")) 'Diff-only negative control lost contaminated history.'
    Assert-Equal 'task.txt' ((Get-GitLines $reverted.Source @('diff', '--name-only', "$($reverted.BaseOid)..$revertedNaive")) -join "`n") 'Net diff did not conceal the reverted unrelated file as expected.'
    $revertedCandidate = New-Candidate $reverted $revertedPatch 'codex/isolated-revert'
    Assert-Published $revertedCandidate (Publish-Candidate $revertedCandidate)
    Assert-Equal '1' (Get-GitText $revertedCandidate.Path @('rev-list', '--count', "$($reverted.BaseOid)..$($revertedCandidate.CommitOid)")) 'Isolated candidate retained commit-and-revert history.'
    Complete-Group 'Commit-and-revert net-zero diff negative control and full-history isolation'

    $stagedFiles = New-Fixture '04-staged-files' -Files ([ordered]@{
        'task.txt' = "task=old`n"
        'keep.txt' = "keep=original`n"
        'rename-old.txt' = "rename-content`n"
        'delete-me.txt' = "delete-content`n"
    })
    Write-TestFile (Join-Path $stagedFiles.Source 'task.txt') "task=reviewed`n"
    [void](Invoke-Git $stagedFiles.Source @('add', '--', 'task.txt'))
    $stagedPatch = Save-ReviewedPatch $stagedFiles.Source (Join-Path $stagedFiles.Root 'reviewed.patch') @('task.txt')
    Write-TestFile (Join-Path $stagedFiles.Source 'unrelated-added.txt') "unrelated add`n"
    [void](Invoke-Git $stagedFiles.Source @('add', '--', 'unrelated-added.txt'))
    [void](Invoke-Git $stagedFiles.Source @('mv', 'rename-old.txt', 'rename-new.txt'))
    [void](Invoke-Git $stagedFiles.Source @('rm', 'delete-me.txt'))
    Write-TestFile (Join-Path $stagedFiles.Source 'keep.txt') "keep=unstaged`n"
    $stagedFilesBefore = Get-WorkingState $stagedFiles.Source
    $stagedCandidate = New-Candidate $stagedFiles $stagedPatch 'codex/staged-preserved'
    Assert-Published $stagedCandidate (Publish-Candidate $stagedCandidate)
    Assert-Equal $stagedFilesBefore (Get-WorkingState $stagedFiles.Source) 'Candidate construction changed unrelated staged or unstaged files.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $stagedCandidate.Path 'unrelated-added.txt'))) 'Candidate included an unrelated staged addition.'
    Assert-True (Test-Path -LiteralPath (Join-Path $stagedCandidate.Path 'rename-old.txt')) 'Candidate included an unrelated staged rename.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $stagedCandidate.Path 'rename-new.txt'))) 'Candidate included the rename destination.'
    Assert-True (Test-Path -LiteralPath (Join-Path $stagedCandidate.Path 'delete-me.txt')) 'Candidate included an unrelated staged deletion.'
    Complete-Group 'Unrelated staged add, rename, deletion, and unstaged content remain intact in the source only'

    $sameFile = New-Fixture '05-same-file' -Files ([ordered]@{
        'shared.txt' = "one=base`ntwo=base`nthree=base`nfour=base`nfive=base`nsix=base`n"
    })
    $taskOnlyContent = "one=base`ntwo=task`nthree=base`nfour=base`nfive=base`nsix=base`n"
    Write-TestFile (Join-Path $sameFile.Source 'shared.txt') $taskOnlyContent
    [void](Invoke-Git $sameFile.Source @('add', '--', 'shared.txt'))
    $sameFilePatch = Save-ReviewedPatch $sameFile.Source (Join-Path $sameFile.Root 'reviewed-task-hunk.patch') @('shared.txt')
    Write-TestFile (Join-Path $sameFile.Source 'shared.txt') "one=base`ntwo=task`nthree=base`nfour=unrelated-staged`nfive=base`nsix=base`n"
    [void](Invoke-Git $sameFile.Source @('add', '--', 'shared.txt'))
    Write-TestFile (Join-Path $sameFile.Source 'shared.txt') "one=base`ntwo=task`nthree=base`nfour=unrelated-staged`nfive=base`nsix=unrelated-worktree`n"
    $sameFileBefore = Get-WorkingState $sameFile.Source
    $sameFileCandidate = New-Candidate $sameFile $sameFilePatch 'codex/task-hunk-only'
    Assert-Published $sameFileCandidate (Publish-Candidate $sameFileCandidate)
    Assert-Equal $sameFileBefore (Get-WorkingState $sameFile.Source) 'Task-hunk transfer changed the source index or worktree.'
    Assert-Equal $taskOnlyContent ([IO.File]::ReadAllText((Join-Path $sameFileCandidate.Path 'shared.txt'))) 'Candidate copied unrelated staged or unstaged hunks from the same file.'
    Assert-True ((Get-GitText $sameFile.Source @('diff', '--cached', '--', 'shared.txt')) -match 'unrelated-staged') 'Same-file staged negative control was not present after delivery.'
    Assert-True ((Get-GitText $sameFile.Source @('diff', '--', 'shared.txt')) -match 'unrelated-worktree') 'Same-file worktree negative control was not present after delivery.'
    Complete-Group 'Reviewed task-only hunk transfer preserves mixed staged and unstaged changes in the same source file'

    $release = New-Fixture '06-release-base'
    [void](Invoke-Git $release.Source @('switch', '-c', 'release/develop'))
    Write-TestFile (Join-Path $release.Source 'release-base.txt') "release line`n"
    [void](Invoke-Git $release.Source @('add', '--', 'release-base.txt'))
    [void](Invoke-Git $release.Source @('commit', '-m', 'Release development base'))
    $releaseBaseOid = Get-GitText $release.Source @('rev-parse', 'HEAD')
    [void](Invoke-Git $release.Source @('push', 'origin', 'HEAD:refs/heads/release/develop'))
    Write-TestFile (Join-Path $release.Source 'task.txt') "task=release`n"
    [void](Invoke-Git $release.Source @('add', '--', 'task.txt'))
    $releasePatch = Save-ReviewedPatch $release.Source (Join-Path $release.Root 'reviewed.patch') @('task.txt')
    $releaseCandidate = New-Candidate $release $releasePatch 'codex/release-task' -StartOid $releaseBaseOid -PrBaseOid $releaseBaseOid -PrBaseBranch 'release/develop'
    Assert-Published $releaseCandidate (Publish-Candidate $releaseCandidate)
    $releasePr = [pscustomobject]@{ Base = $releaseCandidate.PrBaseBranch; Head = $releaseCandidate.HeadBranch }
    Assert-Equal 'release/develop' $releasePr.Base 'Nondefault PR base metadata was lost.'
    Assert-Equal 'codex/release-task' $releasePr.Head 'Nondefault-base PR head metadata was lost.'
    Assert-Equal $releaseBaseOid (Get-GitText $releaseCandidate.Path @('rev-parse', "$($releaseCandidate.CommitOid)^1")) 'Release candidate did not start from the release/develop base.'
    Assert-Equal 'refs/heads/main' (Get-GitText $release.Remote @('symbolic-ref', 'HEAD')) 'Release fixture did not retain main as the remote default branch.'
    Assert-True ($releaseBaseOid -cne $release.BaseOid) 'Release/develop base did not differ from the default main tip.'
    Complete-Group 'Nondefault release/develop PR base differs from default main and retains explicit head mapping'

    $stacked = New-Fixture '07-stacked-base'
    [void](Invoke-Git $stacked.Source @('switch', '-c', 'feature/parent'))
    Write-TestFile (Join-Path $stacked.Source 'parent.txt') "parent change`n"
    [void](Invoke-Git $stacked.Source @('add', '--', 'parent.txt'))
    [void](Invoke-Git $stacked.Source @('commit', '-m', 'Parent task'))
    $parentOid = Get-GitText $stacked.Source @('rev-parse', 'HEAD')
    [void](Invoke-Git $stacked.Source @('push', 'origin', 'HEAD:refs/heads/feature/parent'))
    Write-TestFile (Join-Path $stacked.Source 'task.txt') "task=stacked-child`n"
    [void](Invoke-Git $stacked.Source @('add', '--', 'task.txt'))
    $stackedPatch = Save-ReviewedPatch $stacked.Source (Join-Path $stacked.Root 'reviewed.patch') @('task.txt')
    $stackedCandidate = New-Candidate $stacked $stackedPatch 'codex/stacked-child' -StartOid $parentOid -PrBaseOid $parentOid -PrBaseBranch 'feature/parent'
    Assert-Published $stackedCandidate (Publish-Candidate $stackedCandidate)
    Assert-Equal $parentOid (Get-GitText $stackedCandidate.Path @('rev-parse', "$($stackedCandidate.CommitOid)^1")) 'Stacked candidate did not descend directly from its parent-task base.'
    Assert-Equal '1' (Get-GitText $stackedCandidate.Path @('rev-list', '--count', "$parentOid..$($stackedCandidate.CommitOid)")) 'Stacked PR range included more than the child task.'
    Assert-Equal 'feature/parent' $stackedCandidate.PrBaseBranch 'Stacked PR base metadata was not retained.'
    Assert-True (Test-Path -LiteralPath (Join-Path $stackedCandidate.Path 'parent.txt')) 'Stacked candidate lost the parent-task content.'
    Complete-Group 'Stacked parent-task PR base and child-only outgoing range'

    $golden = New-Fixture '08-golden' -Files ([ordered]@{
        '.gitignore' = "/.work/`n"
        'task.txt' = "task=old`n"
    })
    Write-TestFile (Join-Path $golden.Source 'task.txt') "task=uses-golden`n"
    Write-TestFile (Join-Path $golden.Source 'tests/fixtures/delivery-golden.txt') "maintained expected result`n"
    $goldenConsumerScript = @'
#requires -Version 7.0
$fixture = Join-Path $PSScriptRoot 'fixtures/delivery-golden.txt'
if (-not (Test-Path -LiteralPath $fixture -PathType Leaf)) { throw 'Missing maintained golden fixture.' }
if ([IO.File]::ReadAllText($fixture) -cne "maintained expected result`n") { throw 'Golden fixture content mismatch.' }
Write-Output 'GOLDEN CONSUMER PASS'
'@
    Write-TestFile (Join-Path $golden.Source 'tests/Test-GoldenConsumer.ps1') ($goldenConsumerScript + "`n")
    Write-TestFile (Join-Path $golden.Source '.work/test-output.log') "disposable output`n"
    [void](Invoke-Git $golden.Source @('add', '--', 'task.txt', 'tests/fixtures/delivery-golden.txt', 'tests/Test-GoldenConsumer.ps1'))
    $goldenPatch = Save-ReviewedPatch $golden.Source (Join-Path $golden.Root 'reviewed.patch') @('task.txt', 'tests/fixtures/delivery-golden.txt', 'tests/Test-GoldenConsumer.ps1')
    $goldenCandidate = New-Candidate $golden $goldenPatch 'codex/golden-fixture'
    Assert-Published $goldenCandidate (Publish-Candidate $goldenCandidate)
    $goldenConsumer = New-FreshConsumer $golden $goldenCandidate
    Assert-Equal "maintained expected result`n" ([IO.File]::ReadAllText((Join-Path $goldenConsumer 'tests/fixtures/delivery-golden.txt'))) 'Fresh consumer is missing the maintained golden fixture.'
    Add-TestLog ('pwsh -NoProfile -File "{0}"' -f (Join-Path $goldenConsumer 'tests/Test-GoldenConsumer.ps1'))
    $goldenOutput = @(& pwsh -NoProfile -File (Join-Path $goldenConsumer 'tests/Test-GoldenConsumer.ps1') 2>&1 | ForEach-Object { $_.ToString() })
    $goldenExitCode = $LASTEXITCODE
    Add-TestLog (($goldenOutput -join "`n") + "`nexit=$goldenExitCode")
    Assert-Equal 0 $goldenExitCode 'Fresh-checkout consumer test failed against its delivered golden fixture.'
    Assert-Equal 'GOLDEN CONSUMER PASS' ($goldenOutput -join "`n") 'Fresh-checkout consumer test did not report its expected result.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $goldenCandidate.Path '.work/test-output.log'))) 'Candidate included disposable .work output.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $goldenConsumer '.work/test-output.log'))) 'Fresh consumer included disposable .work output.'
    Complete-Group 'Fresh-checkout consumer test depends on its maintained golden fixture while disposable .work output stays excluded'

    $existingIndex = New-Fixture '08b-existing-index'
    [void](Invoke-Git $existingIndex.Source @('switch', '-c', 'codex/existing-index-task'))
    Write-TestFile (Join-Path $existingIndex.Source 'prior-task.txt') "published task history`n"
    [void](Invoke-Git $existingIndex.Source @('add', '--', 'prior-task.txt'))
    [void](Invoke-Git $existingIndex.Source @('commit', '-m', 'Published task commit'))
    $publishedTaskOid = Get-GitText $existingIndex.Source @('rev-parse', 'HEAD')
    [void](Invoke-Git $existingIndex.Source @('push', 'origin', 'HEAD:refs/heads/codex/existing-index-task'))
    Write-TestFile (Join-Path $existingIndex.Source 'task.txt') "task=reviewed-follow-up`n"
    [void](Invoke-Git $existingIndex.Source @('add', '--', 'task.txt'))
    $existingIndexPatch = Save-ReviewedPatch $existingIndex.Source (Join-Path $existingIndex.Root 'reviewed.patch') @('task.txt')
    Write-TestFile (Join-Path $existingIndex.Source 'unrelated-index.txt') "unrelated staged work`n"
    [void](Invoke-Git $existingIndex.Source @('add', '--', 'unrelated-index.txt'))
    Write-TestFile (Join-Path $existingIndex.Source 'keep.txt') "unrelated unstaged work`n"
    $existingIndexBefore = Get-WorkingState $existingIndex.Source
    $existingIndexCandidate = New-Candidate $existingIndex $existingIndexPatch 'codex/existing-index-task' -StartOid $publishedTaskOid -ExpectedDestinationOid $publishedTaskOid -AllowedPriorPrCommits @($publishedTaskOid)
    $existingIndexPublication = Publish-Candidate $existingIndexCandidate
    Assert-Published $existingIndexCandidate $existingIndexPublication
    Assert-Equal $existingIndexBefore (Get-WorkingState $existingIndex.Source) 'Existing-task delivery changed the original unrelated index or worktree.'
    $publishedAncestry = Invoke-Git $existingIndexCandidate.Path @('merge-base', '--is-ancestor', $publishedTaskOid, $existingIndexPublication.RemoteOid) -AllowFailure
    Assert-Equal 0 $publishedAncestry.ExitCode 'Existing task branch was not updated as a fast-forward from its audited tip.'
    Assert-Equal '1' (Get-GitText $existingIndexCandidate.Path @('rev-list', '--count', "$publishedTaskOid..$($existingIndexPublication.RemoteOid)")) 'Existing task delivery replayed history instead of adding one follow-up commit.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $existingIndexCandidate.Path 'unrelated-index.txt'))) 'Existing task candidate included unrelated staged content.'
    Assert-Equal "published task history`n" ([IO.File]::ReadAllText((Join-Path $existingIndexCandidate.Path 'prior-task.txt'))) 'Existing task candidate lost its published task ancestry.'
    Complete-Group 'Suitable published task history is fast-forwarded from its audited tip while an unrelated source index is preserved'

    $baseRace = New-Fixture '09-base-race'
    Write-TestFile (Join-Path $baseRace.Source 'task.txt') "task=stale-base-candidate`n"
    [void](Invoke-Git $baseRace.Source @('add', '--', 'task.txt'))
    $baseRacePatch = Save-ReviewedPatch $baseRace.Source (Join-Path $baseRace.Root 'reviewed.patch') @('task.txt')
    $baseRaceCandidate = New-Candidate $baseRace $baseRacePatch 'codex/base-race'
    $baseAdvance = Add-CommitAndPush $baseRace 'base-updater' 'main' 'base-advance.txt' "new base work`n" 'Advance PR base'
    $baseRacePublication = Publish-Candidate $baseRaceCandidate
    Assert-True (-not $baseRacePublication.Published) 'Candidate was pushed after the PR base advanced.'
    Assert-True ($baseRacePublication.Inspection.Reasons -contains 'PR base changed after candidate inspection.') 'PR-base drift was not the refusal reason.'
    Assert-Equal $baseAdvance.Oid $baseRacePublication.Inspection.ActualBaseOid 'Reinspection did not observe the advanced PR base.'
    Assert-True (-not (Get-RemoteRefOid $baseRaceCandidate.Path 'origin' $baseRaceCandidate.HeadBranch)) 'Refused stale-base candidate unexpectedly created a destination ref.'
    Complete-Group 'PR base advancement triggers reinspection and refuses a stale candidate'

    $destinationRace = New-Fixture '10-destination-race'
    [void](Invoke-Git $destinationRace.Source @('switch', '-c', 'codex/existing-task'))
    Write-TestFile (Join-Path $destinationRace.Source 'prior-task.txt') "prior task`n"
    [void](Invoke-Git $destinationRace.Source @('add', '--', 'prior-task.txt'))
    [void](Invoke-Git $destinationRace.Source @('commit', '-m', 'Prior reviewed task commit'))
    $priorTaskOid = Get-GitText $destinationRace.Source @('rev-parse', 'HEAD')
    [void](Invoke-Git $destinationRace.Source @('push', 'origin', 'HEAD:refs/heads/codex/existing-task'))
    Write-TestFile (Join-Path $destinationRace.Source 'task.txt') "task=next-reviewed-change`n"
    [void](Invoke-Git $destinationRace.Source @('add', '--', 'task.txt'))
    $destinationPatch = Save-ReviewedPatch $destinationRace.Source (Join-Path $destinationRace.Root 'reviewed.patch') @('task.txt')
    $destinationCandidate = New-Candidate $destinationRace $destinationPatch 'codex/existing-task' -StartOid $priorTaskOid -ExpectedDestinationOid $priorTaskOid -AllowedPriorPrCommits @($priorTaskOid)
    $destinationAdvance = Add-CommitAndPush $destinationRace 'destination-updater' 'codex/existing-task' 'unrelated-appended.txt' "unrelated appended work`n" 'Unrelated appended destination commit'
    $destinationPublication = Publish-Candidate $destinationCandidate
    Assert-True (-not $destinationPublication.Published) 'Candidate was pushed after its destination task ref advanced.'
    Assert-True ($destinationPublication.Inspection.Reasons -contains 'Destination task ref changed after candidate inspection.') 'Destination-ref drift was not the refusal reason.'
    Assert-Equal $destinationAdvance.Oid $destinationPublication.Inspection.ActualDestinationOid 'Reinspection did not observe the unrelated appended destination commit.'
    Assert-Equal $destinationAdvance.Oid (Get-RemoteRefOid $destinationCandidate.Path 'origin' 'codex/existing-task') 'Refusal changed the advanced destination task ref.'
    Assert-True ($destinationPublication.Inspection.ActualBaseOid -ceq $destinationRace.BaseOid) 'Destination-race fixture unexpectedly changed the PR base.'
    Complete-Group 'Destination task ref advancement is distinct from a missing destination and refuses stale outgoing history'

    $hooked = New-Fixture '11-hook-mutation'
    Write-TestFile (Join-Path $hooked.Source 'task.txt') "task=reviewed-before-hook`n"
    [void](Invoke-Git $hooked.Source @('add', '--', 'task.txt'))
    $hookedPatch = Save-ReviewedPatch $hooked.Source (Join-Path $hooked.Root 'reviewed.patch') @('task.txt')
    $hookDirectory = Join-Path $hooked.Root 'mutating-hooks'
    New-Item -ItemType Directory -Path $hookDirectory -Force | Out-Null
    Write-TestFile (Join-Path $hookDirectory 'pre-commit') "#!/bin/sh`nprintf 'added by hook\\n' > hook-added.txt`ngit add hook-added.txt`nprintf 'remaining hook work\\n' >> task.txt`n"
    $hookedCandidate = New-Candidate $hooked $hookedPatch 'codex/hook-mutated' -HookPath $hookDirectory
    $hookedPublication = Publish-Candidate $hookedCandidate
    Assert-True (-not $hookedPublication.Published) 'Hook-mutated candidate was pushed without renewed review.'
    Assert-True ($hookedPublication.Inspection.Reasons -contains 'Actual committed tree differs from the reviewed candidate tree.') 'Reinspection missed the hook-mutated committed tree.'
    Assert-True ($hookedPublication.Inspection.Reasons -contains 'Candidate has remaining index or working-tree changes after commit hooks.') 'Reinspection missed remaining hook-created worktree changes.'
    Assert-True ($hookedPublication.Inspection.ActualTree -cne $hookedCandidate.ExpectedTree) 'Hook mutation did not change the actual committed tree in the fixture.'
    Assert-True ($hookedPublication.Inspection.RemainingState -match 'task.txt') 'Hook fixture did not leave the expected tracked worktree change.'
    Assert-True (Test-Path -LiteralPath (Join-Path $hookedCandidate.Path 'hook-added.txt')) 'Hook fixture did not add its committed file.'
    Assert-True (-not (Get-RemoteRefOid $hookedCandidate.Path 'origin' $hookedCandidate.HeadBranch)) 'Refused hook-mutated candidate unexpectedly created a destination ref.'
    Complete-Group 'Post-hook actual commit tree and remaining worktree reinspection refuses an unreviewed candidate'

    Write-Output "PASS: $($script:groups.Count) groups, $script:assertionCount assertions"
    Write-Output "Git: $gitVersion"
    Write-Output "Artifacts: $testRoot"
    Write-Output "Command log: $logPath"
} catch {
    Add-TestLog ("FAIL: " + $_.Exception.ToString())
    Write-Output "FAIL after $($script:groups.Count) completed groups and $script:assertionCount assertions"
    Write-Output "Artifacts: $testRoot"
    Write-Output "Command log: $logPath"
    throw
} finally {
    foreach ($name in $savedEnvironment.Keys) {
        if ($savedEnvironmentPresent[$name]) {
            Set-Item -LiteralPath "Env:$name" -Value ([string]$savedEnvironment[$name])
        } else {
            if (Test-Path -LiteralPath "Env:$name") { Remove-Item -LiteralPath "Env:$name" }
        }
    }
}
