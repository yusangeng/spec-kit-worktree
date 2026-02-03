#!/usr/bin/env pwsh
# Common PowerShell functions analogous to common.sh

function Get-RepoRoot {
    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }
    
    # Fall back to script location for non-git repos
    return (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
}

function Get-CurrentBranch {
    # First check if SPECIFY_FEATURE environment variable is set
    if ($env:SPECIFY_FEATURE) {
        return $env:SPECIFY_FEATURE
    }
    
    # Then check git if available
    try {
        $result = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }
    
    # For non-git repos, try to find the latest feature directory
    $repoRoot = Get-RepoRoot
    $specsDir = Join-Path $repoRoot "specs"
    
    if (Test-Path $specsDir) {
        $latestFeature = ""
        $highest = 0
        
        Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d{3})-') {
                $num = [int]$matches[1]
                if ($num -gt $highest) {
                    $highest = $num
                    $latestFeature = $_.Name
                }
            }
        }
        
        if ($latestFeature) {
            return $latestFeature
        }
    }
    
    # Final fallback
    return "main"
}

function Test-HasGit {
    try {
        git rev-parse --show-toplevel 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-InWorktree {
    try {
        $gitCommonDir = git rev-parse --git-common-dir 2>$null
        $currentGitDir = git rev-parse --git-dir 2>$null

        if ($LASTEXITCODE -ne 0) {
            return $false
        }

        # In worktrees, the git common dir is different from the current directory's .git
        # In main repo, they are the same
        return ($gitCommonDir -ne $currentGitDir)
    } catch {
        return $false
    }
}

function Get-EffectiveRoot {
    if (Test-InWorktree) {
        # In worktree - specs are in the worktree directory
        return (Get-Location).Path
    } elseif (Test-HasGit) {
        # In main repo - specs are in repo root
        return (git rev-parse --show-toplevel 2>$null)
    } else {
        # Non-git repo - fall back to script location
        return (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
    }
}

function Find-FeatureDirByPrefix {
    param(
        [string]$RepoRoot,
        [string]$BranchName
    )

    $specsDir = Join-Path $RepoRoot "specs"

    # Extract numeric prefix from branch (e.g., "004" from "004-whatever")
    if ($BranchName -notmatch '^(\d{3})-') {
        # If branch doesn't have numeric prefix, fall back to exact match
        return Join-Path $specsDir $BranchName
    }

    $prefix = $matches[1]

    # Search for directories in specs/ that start with this prefix
    $matchingDirs = @()
    if (Test-Path $specsDir) {
        $matchingDirs = Get-ChildItem -Path "$specsDir/$prefix-*" -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
    }

    # Handle results
    if ($matchingDirs.Count -eq 0) {
        # No match found - return the branch name path (will fail later with clear error)
        return Join-Path $specsDir $BranchName
    } elseif ($matchingDirs.Count -eq 1) {
        # Exactly one match - perfect!
        return Join-Path $specsDir $matchingDirs[0]
    } else {
        # Multiple matches - this shouldn't happen with proper naming convention
        Write-Error "ERROR: Multiple spec directories found with prefix '$prefix': $($matchingDirs -join ', ')"
        Write-Error "Please ensure only one spec directory exists per numeric prefix."
        return Join-Path $specsDir $BranchName  # Return something to avoid breaking the script
    }
}

function Test-FeatureBranch {
    param(
        [string]$Branch,
        [bool]$HasGit = $true
    )
    
    # For non-git repos, we can't enforce branch naming but still provide output
    if (-not $HasGit) {
        Write-Warning "[specify] Warning: Git repository not detected; skipped branch validation"
        return $true
    }
    
    if ($Branch -notmatch '^[0-9]{3}-') {
        Write-Output "ERROR: Not on a feature branch. Current branch: $Branch"
        Write-Output "Feature branches should be named like: 001-feature-name"
        return $false
    }
    return $true
}

function Get-FeatureDir {
    param([string]$RepoRoot, [string]$Branch)
    Join-Path $RepoRoot "specs/$Branch"
}

function Get-FeaturePathsEnv {
    $effectiveRoot = Get-EffectiveRoot
    $mainRepoRoot = ""
    $currentBranch = Get-CurrentBranch
    $hasGit = Test-HasGit
    $inWorktree = $false

    if ($hasGit) {
        # Get the actual main repository root (not worktree)
        $mainRepoRoot = git rev-parse --show-toplevel 2>$null
        if (Test-InWorktree) {
            # In worktree, show-toplevel returns the worktree path
            # We need to get the common git dir's parent to find the main repo
            $gitCommonDir = git rev-parse --git-common-dir 2>$null
            if ($gitCommonDir) {
                # The git-common-dir is typically at /path/to/repo/.git/worktrees/<worktree-name>
                # or /path/to/repo/.git for main repo
                $mainRepoRoot = Split-Path -Parent $gitCommonDir
                # Handle both .git/worktrees/<name> and .git cases
                if ((Split-Path -Leaf $mainRepoRoot) -eq "worktrees") {
                    $mainRepoRoot = Split-Path -Parent (Split-Path -Parent $mainRepoRoot)
                }
            }
            $inWorktree = $true
        }
    } else {
        $mainRepoRoot = $effectiveRoot
    }

    # Use effective root for feature path lookup
    $featureDir = Find-FeatureDirByPrefix -RepoRoot $effectiveRoot -BranchName $currentBranch

    [PSCustomObject]@{
        REPO_ROOT      = $mainRepoRoot
        EFFECTIVE_ROOT = $effectiveRoot
        CURRENT_BRANCH = $currentBranch
        HAS_GIT        = $hasGit
        IN_WORKTREE    = $inWorktree
        FEATURE_DIR    = $featureDir
        FEATURE_SPEC   = Join-Path $featureDir 'spec.md'
        IMPL_PLAN      = Join-Path $featureDir 'plan.md'
        TASKS          = Join-Path $featureDir 'tasks.md'
        RESEARCH       = Join-Path $featureDir 'research.md'
        DATA_MODEL     = Join-Path $featureDir 'data-model.md'
        QUICKSTART     = Join-Path $featureDir 'quickstart.md'
        CONTRACTS_DIR  = Join-Path $featureDir 'contracts'
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

function Test-DirHasFiles {
    param([string]$Path, [string]$Description)
    if ((Test-Path -Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1)) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

