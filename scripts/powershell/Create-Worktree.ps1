#!/usr/bin/env pwsh
# ==============================================
# Git Worktree Creation Script
# Description: Create a git worktree and feature branch
# Usage: .\Create-Worktree.ps1 <feature-name> [-BaseBranch <branch>] [-Json]
# ==============================================

param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$FeatureName,

    [Parameter(Mandatory = $false)]
    [string]$BaseBranch,

    [Parameter(Mandatory = $false)]
    [switch]$Json,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

# Import common functions
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptPath "Worktree-Common.ps1")

function Show-Help {
    Show-HelpHeader "Create-Worktree.ps1" "Create a git worktree and feature branch"

    Write-Host @"
Usage:
  .\Create-Worktree.ps1 <feature-name> [-BaseBranch <branch>] [-Json]
  .\Create-Worktree.ps1 -Help

Arguments:
  feature-name        Name of the feature (required)

Options:
  -BaseBranch         Base branch for the worktree (default: auto-detect main/master/develop)
  -Json               Output result in JSON format
  -Help               Show this help message

Examples:
  .\Create-Worktree.ps1 user-auth
  .\Create-Worktree.ps1 auth -BaseBranch develop
  .\Create-Worktree.ps1 feature-login -Json

Description:
  - Creates a worktree in .wt/<feature-name> directory
  - Creates a feature/<feature-name> branch
  - Automatically adds .wt/ to .gitignore
  - Non-interactive, suitable for AI agent usage

JSON Output Format:
  {
    "worktree_path": ".wt/feature-name",
    "branch": "feature/feature-name",
    "base_branch": "main"
  }
"@
    exit 0
}

if ($Help) {
    Show-Help
}

# Check required arguments
if ([string]::IsNullOrEmpty($FeatureName)) {
    Log-Error "Missing feature name argument"
    Write-Host "Use 'Create-Worktree.ps1 -Help' for usage"
    exit 1
}

# Validate feature name (sanitize)
$sanitizedName = Sanitize-FeatureName $FeatureName
if ([string]::IsNullOrEmpty($sanitizedName)) {
    Log-Error "Invalid feature name '$FeatureName'"
    exit 1
}

if ($sanitizedName -ne $FeatureName) {
    Log-Warning "Feature name sanitized to '$sanitizedName'"
}
$FeatureName = $sanitizedName

# Check if in a git repository
if (!(Test-GitRepo)) {
    Log-Error "Not in a git repository"
    exit 1
}

# Get repository root
$gitRoot = Get-RepoRoot
Set-Location $gitRoot

$newBranch = Get-FeatureBranch $FeatureName
$worktreeDir = ".wt/$FeatureName"

# Only print progress messages if not in JSON mode
if (!$Json) {
    Write-Host "`nCreating worktree" -ForegroundColor Blue
    Write-Host "  Feature name: " -NoNewline
    Write-Host "$FeatureName" -ForegroundColor Green
    Write-Host "  Target branch: " -NoNewline
    Write-Host "$newBranch" -ForegroundColor Green
    Write-Host "  Worktree directory: " -NoNewline
    Write-Host "$worktreeDir" -ForegroundColor Green
}

# 1. Auto-detect or validate base branch
if ([string]::IsNullOrEmpty($BaseBranch)) {
    if (!$Json) {
        Write-Host "`nDetecting base branch..." -ForegroundColor Blue
    }

    $BaseBranch = Get-BaseBranch

    if ([string]::IsNullOrEmpty($BaseBranch)) {
        $errorMsg = "Unable to detect base branch. Please specify -BaseBranch"
        if ($Json) {
            Write-Host "{`"error`": `"$errorMsg`"}" -ForegroundColor Red
        } else {
            Log-Error $errorMsg
        }
        exit 1
    }

    if (!$Json) {
        Log-Success "Detected base branch: $BaseBranch"
    }
} else {
    if (!$Json) {
        Write-Host "`nValidating base branch..." -ForegroundColor Blue
    }
    # Validate specified branch exists
    if (!(Test-BranchExists $BaseBranch)) {
        $errorMsg = "Base branch '$BaseBranch' not found"
        if ($Json) {
            Write-Host "{`"error`": `"$errorMsg`"}" -ForegroundColor Red
        } else {
            Log-Error $errorMsg
        }
        exit 1
    }
    if (!$Json) {
        Log-Success "Using base branch: $BaseBranch"
    }
}

# 2. Ensure .wt directory exists and add to .gitignore
Initialize-WtDirectory

# 3. Check if worktree already exists
if (Test-Path $worktreeDir) {
    # Check if it's a registered worktree
    if (Test-WorktreeRegistered $worktreeDir) {
        $errorMsg = "Worktree already exists: $worktreeDir"
        if ($Json) {
            Write-Host "{`"error`": `"$errorMsg`"}" -ForegroundColor Red
        } else {
            Log-Error $errorMsg
            Write-Host "  Use 'Remove-Worktree.ps1 $FeatureName' first"
        }
        exit 1
    } else {
        # Unregistered directory, remove it
        Remove-Item -Recurse -Force $worktreeDir
    }
}

# 4. Create worktree and branch
if (!$Json) {
    Write-Host "`nCreating worktree..." -ForegroundColor Blue
}

# Fetch base branch from remote if it exists
$remoteExists = git show-ref --verify --quiet "refs/remotes/origin/$BaseBranch" 2>$null
if ($remoteExists) {
    git fetch origin "$BaseBranch" 2>$null | Out-Null
}

# Check if feature branch already exists
$localBranchExists = git show-ref --verify --quiet "refs/heads/$newBranch" 2>$null
if ($localBranchExists) {
    # Branch exists, create worktree from existing branch
    git worktree add "$worktreeDir" "$newBranch" 2>$null | Out-Null
} else {
    # Branch doesn't exist, create new branch with worktree
    git worktree add -b "$newBranch" "$worktreeDir" "$BaseBranch" 2>$null | Out-Null
}

# 5. Output result
if ($Json) {
    $result = @{
        worktree_path = $worktreeDir
        branch = $newBranch
        base_branch = $BaseBranch
        feature_name = $FeatureName
    }
    Print-Json $result
} else {
    Write-Host "`nWorktree created successfully!" -ForegroundColor Green
    Write-Host "  Branch: $newBranch"
    Write-Host "  Directory: $worktreeDir"
    Write-Host "  Base: $BaseBranch"
    Write-Host "`nNext steps:"
    Write-Host "  1. " -NoNewline
    Write-Host "cd $worktreeDir" -ForegroundColor Cyan
    Write-Host "  2. Start developing your feature"
}
