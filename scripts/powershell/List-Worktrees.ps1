#!/usr/bin/env pwsh
# ==============================================
# Git Worktree List Script
# Description: List all worktrees in the .wt directory
# Usage: .\List-Worktrees.ps1 [-Verbose] [-Json]
# ==============================================

param(
    [Parameter(Mandatory = $false)]
    [switch]$Verbose,

    [Parameter(Mandatory = $false)]
    [switch]$Json,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

# Import common functions
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptPath "Worktree-Common.ps1")

function Show-Help {
    Show-HelpHeader "List-Worktrees.ps1" "List all worktrees in the .wt directory"

    Write-Host @"
Usage:
  .\List-Worktrees.ps1 [-Verbose] [-Json]
  .\List-Worktrees.ps1 -Help

Options:
  -Verbose, -v         Show detailed information (commit SHA, status)
  -Json                Output result in JSON format
  -Help                Show this help message

Description:
  - Lists all worktrees in the .wt directory
  - Shows feature name, path, branch, and status
  - Non-interactive, suitable for AI agent usage

JSON Output Format:
  {
    "worktrees": [
      {
        "name": "user-auth",
        "path": ".wt/user-auth",
        "branch": "feature/user-auth",
        "commit": "abc123",
        "status": "clean"
      }
    ]
  }
"@
    exit 0
}

if ($Help) {
    Show-Help
}

# Check if in a git repository
if (!(Test-GitRepo)) {
    $errorMsg = "Not in a git repository"
    if ($Json) {
        Write-Host "{`"error`": `"$errorMsg`"}" -ForegroundColor Red
    } else {
        Log-Error $errorMsg
    }
    exit 1
}

# Get repository root
$gitRoot = Get-RepoRoot
Set-Location $gitRoot

# Get all worktrees (porcelain format)
$worktreeOutput = git worktree list --porcelain 2>$null

# Parse worktrees and filter for .wt directory
$worktrees = @()
$currentBlock = @{}

foreach ($line in $worktreeOutput) {
    if ($line -match "^worktree (.+)") {
        $wtPath = $matches[1].TrimEnd('/')

        # Only include worktrees under .wt directory
        if ($wtPath -match "/\.wt/") {
            $name = Split-Path $wtPath -Leaf

            $currentBlock = @{
                name = $name
                path = $wtPath
                branch = ""
                commit = ""
                status = ""
            }
        }
    } elseif ($line -match "^branch (.+)") {
        $branch = $matches[1]
        $branch = $branch -replace "^refs/heads/", ""
        if ($currentBlock.Count -gt 0) {
            $currentBlock.branch = $branch
        }
    } elseif ($line -match "^HEAD (.+)") {
        $commit = $matches[1]
        if ($currentBlock.Count -gt 0) {
            $currentBlock.commit = $commit
        }
    } elseif ([string]::IsNullOrEmpty($line)) {
        # End of worktree block
        if ($currentBlock.Count -gt 0) {
            # Check worktree status if verbose or JSON mode
            if ($Verbose -or $Json) {
                $wtPath = $currentBlock.path
                if (Test-Path $wtPath) {
                    $currentBlock.status = Get-WorktreeStatus $wtPath
                } else {
                    $currentBlock.status = "unknown"
                }
            }

            $worktrees += [PSCustomObject]$currentBlock
            $currentBlock = @{}
        }
    }
}

# Handle case where output doesn't end with empty line
if ($currentBlock.Count -gt 0) {
    if ($Verbose -or $Json) {
        $wtPath = $currentBlock.path
        if (Test-Path $wtPath) {
            $currentBlock.status = Get-WorktreeStatus $wtPath
        } else {
            $currentBlock.status = "unknown"
        }
    }

    $worktrees += [PSCustomObject]$currentBlock
}

# Output results
if ($Json) {
    # JSON output
    $result = @{
        worktrees = @($worktrees | ForEach-Object {
            $wt = @{
                name = $_.name
                path = $_.path
                branch = $_.branch
            }

            if ($Verbose) {
                wt.commit = $_.commit
                wt.status = $_.status
            }

            [PSCustomObject]$wt
        })
    }

    Print-Json $result
} else {
    # Table output
    if ($worktrees.Count -eq 0) {
        Write-Host "No worktrees found" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Use 'Create-Worktree.ps1 <feature-name>' to create a worktree" -ForegroundColor DarkGray
        exit 0
    }

    # Print header
    Write-Host "`nWorktrees" -ForegroundColor Blue -Bold
    Write-Host ""
    Write-Host ("─" * 50) -ForegroundColor Cyan

    foreach ($wt in $worktrees) {
        # Make relative path if possible
        if ($wt.path -match "^$gitRoot/") {
            $relPath = $wt.path -replace "^$gitRoot/", ""
        } else {
            $relPath = $wt.path
        }

        Write-Host "  " -NoNewline
        Write-Host "Feature:" -Bold -NoNewline
        Write-Host "    $($wt.name)"
        Write-Host "  " -NoNewline
        Write-Host "Branch:" -Bold -NoNewline
        Write-Host "    $($wt.branch)"
        Write-Host "  " -NoNewline
        Write-Host "Path:" -Bold -NoNewline
        Write-Host "      $relPath"

        if ($Verbose) {
            Write-Host "  " -NoNewline
            Write-Host "Commit:" -Bold -NoNewline
            Write-Host "   $($wt.commit)"

            if ($wt.status -eq "clean") {
                Write-Host "  " -NoNewline
                Write-Host "Status:" -Bold -NoNewline
                Write-Host "   " -NoNewline
                Write-Host "clean" -ForegroundColor Green
            } elseif ($wt.status -eq "dirty") {
                Write-Host "  " -NoNewline
                Write-Host "Status:" -Bold -NoNewline
                Write-Host "   " -NoNewline
                Write-Host "dirty (uncommitted changes)" -ForegroundColor Yellow
            } else {
                Write-Host "  " -NoNewline
                Write-Host "Status:" -Bold -NoNewline
                Write-Host "   " -NoNewline
                Write-Host "unknown" -ForegroundColor DarkGray
            }
        }

        Write-Host ""
    }

    # Print summary
    $count = $worktrees.Count
    Write-Host "Total: $count worktree(s)" -ForegroundColor DarkGray

    # Get current worktree name
    $currentWorktreePath = git worktree list --porcelain 2>$null | Select-String "^worktree " | Select-Object -First 1
    if ($currentWorktreePath) {
        $currentPath = ($currentWorktreePath -replace "^worktree ", "").TrimEnd('/')
        if ($currentPath -match "/\.wt/") {
            $currentName = Split-Path $currentPath -Leaf
            Write-Host "Current: $currentName" -ForegroundColor DarkGray
        }
    }
}
