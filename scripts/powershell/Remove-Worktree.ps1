#!/usr/bin/env pwsh
# ==============================================
# Git Worktree Removal Script
# Description: Remove a git worktree and its branches
# Usage: .\Remove-Worktree.ps1 <feature-name> [-Force] [-Json]
# ==============================================

param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$FeatureName,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Json,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

# Import common functions
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptPath "Worktree-Common.ps1")

function Show-Help {
    Show-HelpHeader "Remove-Worktree.ps1" "Remove a git worktree and its branches"

    Write-Host @"
Usage:
  .\Remove-Worktree.ps1 <feature-name> [-Force] [-Json]
  .\Remove-Worktree.ps1 -Help

Arguments:
  feature-name        Name of the feature to remove (required)

Options:
  -Force, -f          Force removal without checking unmerged changes
  -Json               Output result in JSON format
  -Help               Show this help message

Examples:
  .\Remove-Worktree.ps1 user-auth
  .\Remove-Worktree.ps1 auth -Force
  .\Remove-Worktree.ps1 feature-login -Json

Description:
  - Removes the worktree directory .wt/<feature-name>/
  - Removes the feature/<feature-name> branch
  - Checks for uncommitted changes by default
  - Checks for merged branches by default
  - Non-interactive, suitable for AI agent usage
"@
    exit 0
}

if ($Help) {
    Show-Help
}

# Check required arguments
if ([string]::IsNullOrEmpty($FeatureName)) {
    Log-Error "Missing feature name argument"
    Write-Host "Use 'Remove-Worktree.ps1 -Help' for usage"
    exit 1
}

# Check if in a git repository
if (!(Test-GitRepo)) {
    Log-Error "Not in a git repository"
    exit 1
}

# Get repository root
$gitRoot = Get-RepoRoot
Set-Location $gitRoot

$featureBranch = Get-FeatureBranch $FeatureName
$worktreeDir = ".wt/$FeatureName"

# Only print progress messages if not in JSON mode
if (!$Json) {
    Write-Host "`nRemoving worktree" -ForegroundColor Blue
    Write-Host "  Feature name: " -NoNewline
    Write-Host "$FeatureName" -ForegroundColor Yellow
    Write-Host "  Target branch: " -NoNewline
    Write-Host "$featureBranch" -ForegroundColor Yellow
    Write-Host "  Worktree directory: " -NoNewline
    Write-Host "$worktreeDir" -ForegroundColor Yellow
}

# 1. Check and remove worktree
if (!$Json) {
    Write-Host "`nChecking worktree..." -ForegroundColor Blue
}

$worktreeExists = $false
if (Test-WorktreeRegistered $worktreeDir) {
    $worktreeExists = $true

    # Check for uncommitted changes
    if (!$Force) {
        if (Test-Path $worktreeDir) {
            if (Test-UncommittedChanges $worktreeDir) {
                $errorMsg = "Worktree has uncommitted changes"
                if ($Json) {
                    Write-Host "{`"error`": `"$errorMsg`"}" -ForegroundColor Red
                } else {
                    Log-Error $errorMsg
                    Write-Host "  Use -Force to remove anyway"
                }
                exit 1
            }
        }
    }

    # Remove worktree (try normal remove first, then force, then manual)
    $normalRemove = git worktree remove "$worktreeDir" 2>$null
    if ($normalRemove) {
        # Successfully removed
    } else {
        $forceRemove = git worktree remove "$worktreeDir" --force 2>$null
        if ($forceRemove) {
            # Force removed
        } else {
            # Fallback to manual removal
            Remove-Item -Recurse -Force $worktreeDir -ErrorAction SilentlyContinue
            git worktree prune 2>$null | Out-Null
        }
    }

    if (!$Json) {
        Log-Success "Worktree removed: $worktreeDir"
    }
} elseif (Test-Path $worktreeDir) {
    # Unregistered directory exists
    $worktreeExists = $true
    Remove-Item -Recurse -Force $worktreeDir
    if (!$Json) {
        Log-Warning "Unregistered worktree directory removed"
    }
}

# 2. Check and remove local branch
if (!$Json) {
    Write-Host "`nChecking local branch..." -ForegroundColor Blue
}

# Check if we're currently in the worktree being deleted
$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
if ($currentBranch -eq $featureBranch) {
    # We're in the worktree, need to switch branches first
    $errorMsg = "Cannot delete branch '$featureBranch' while in the worktree. Run: git checkout main; cd ..; Remove-Worktree.ps1 $FeatureName"
    if ($Json) {
        Write-Host "{`"error`": `"$errorMsg`"}" -ForegroundColor Red
    } else {
        Log-Error "Cannot delete branch '$featureBranch' while in the worktree"
        Write-Host "  Please run:"
        Write-Host "    " -NoNewline
        Write-Host "git checkout main" -ForegroundColor Cyan
        Write-Host "    " -NoNewline
        Write-Host "cd .." -ForegroundColor Cyan
        Write-Host "    " -NoNewline
        Write-Host "Remove-Worktree.ps1 $FeatureName" -ForegroundColor Cyan
    }
    exit 1
}

# Prune worktrees before deleting branch to clean up dangling references
git worktree prune 2>$null | Out-Null

$branchRemoved = $false
$localBranchExists = git show-ref --verify --quiet "refs/heads/$featureBranch" 2>$null
if ($localBranchExists) {
    # Check if branch is merged
    if (!$Force) {
        if (!$Json) {
            Write-Host "Checking merge status..." -ForegroundColor Blue
        }

        # Detect default branch
        $defaultBranch = Get-BaseBranch

        if ($defaultBranch) {
            $mergedBranches = git branch --merged "$defaultBranch" 2>$null
            if ($mergedBranches -match $featureBranch) {
                # Branch is merged, safe to delete
                git branch -d "$featureBranch" 2>$null | Out-Null
                $branchRemoved = $true
                if (!$Json) {
                    Log-Success "Branch merged to $defaultBranch and deleted"
                }
            } else {
                # Branch not merged
                $errorMsg = "Branch '$featureBranch' is not merged to '$defaultBranch'"
                if ($Json) {
                    Write-Host "{`"error`": `"$errorMsg`"}" -ForegroundColor Red
                } else {
                    Log-Error $errorMsg
                    Write-Host "  Use -Force to delete anyway"
                }
                exit 1
            }
        } else {
            # Cannot detect default branch, try regular delete
            $deleteResult = git branch -d "$featureBranch" 2>$null
            if (!$deleteResult) {
                $errorMsg = "Branch '$featureBranch' is not merged"
                if ($Json) {
                    Write-Host "{`"error`": `"$errorMsg`"}" -ForegroundColor Red
                } else {
                    Log-Error $errorMsg
                    Write-Host "  Use -Force to delete anyway"
                }
                exit 1
            }
            $branchRemoved = $true
        }
    } else {
        # Force delete
        git branch -D "$featureBranch" 2>$null | Out-Null
        $branchRemoved = $true
        if (!$Json) {
            Log-Success "Branch force deleted"
        }
    }
}

# 3. Check and remove remote branch
if (!$Json) {
    Write-Host "`nChecking remote branch..." -ForegroundColor Blue
}

$remoteBranchRemoved = $false
$remoteOutput = git ls-remote --heads origin "$featureBranch" 2>$null
if ($remoteOutput -match $featureBranch) {
    git push origin --delete "$featureBranch" 2>$null | Out-Null
    $remoteBranchRemoved = $true
    if (!$Json) {
        Log-Success "Remote branch deleted: origin/$featureBranch"
    }
}

# 4. Output result
if ($Json) {
    $result = @{
        feature_name = $FeatureName
        branch = $featureBranch
        worktree_removed = $worktreeExists
        branch_removed = $branchRemoved
        remote_branch_removed = $remoteBranchRemoved
    }
    Print-Json $result
} else {
    Write-Host "`nWorktree removed successfully!" -ForegroundColor Green
    Write-Host "  Feature: $FeatureName"
    Write-Host "  Branch: $featureBranch"

    if (!$worktreeExists) {
        Write-Host "`nNote: Worktree directory did not exist" -ForegroundColor Yellow
    }
}
