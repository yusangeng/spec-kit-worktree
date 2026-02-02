# ==============================================
# Git Worktree Common Functions
# Description: Shared utility functions for worktree management
# Usage: . .\Worktree-Common.ps1
# ==============================================

# ==============================================
# Logging Functions
# ==============================================

function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Log-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Log-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ==============================================
# Git Repository Functions
# ==============================================

# Check if in a git repository
# Returns: $true if in git repo, $false otherwise
function Test-GitRepo {
    $null = git rev-parse --git-dir 2>$null
    return $?
}

# Get repository root directory
# Returns: The repository root path
function Get-RepoRoot {
    return git rev-parse --show-toplevel 2>$null
}

# Navigate to repository root
function Set-RepoRoot {
    $root = Get-RepoRoot
    if ($root) {
        Set-Location $root
    }
}

# ==============================================
# Branch Detection Functions
# ==============================================

# Auto-detect base branch (main/master/develop)
# Returns: The first found branch name
function Get-BaseBranch {
    $branches = @("main", "master", "develop")

    foreach ($branch in $branches) {
        $localExists = git show-ref --verify --quiet "refs/heads/$branch" 2>$null
        $remoteExists = git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>$null

        if ($localExists -or $remoteExists) {
            return $branch
        }
    }

    return $null
}

# Check if a branch exists (local or remote)
# Returns: $true if exists, $false otherwise
function Test-BranchExists {
    param([string]$Branch)

    $localExists = git show-ref --verify --quiet "refs/heads/$Branch" 2>$null
    $remoteExists = git show-ref --verify --quiet "refs/remotes/origin/$Branch" 2>$null

    return ($localExists -or $remoteExists)
}

# ==============================================
# Worktree Directory Functions
# ==============================================

# Ensure .wt directory exists and is in .gitignore
function Initialize-WtDirectory {
    if (!(Test-Path ".wt")) {
        New-Item -ItemType Directory -Path ".wt" | Out-Null
    }

    # Add .wt/ to .gitignore
    if (Test-Path ".gitignore") {
        $gitignore = Get-Content ".gitignore"
        if ($gitignore -notmatch "^\.wt/$" -and $gitignore -notmatch "^\.wt$") {
            Add-Content ".gitignore" ".wt/"
        }
    } else {
        Set-Content ".gitignore" ".wt/"
    }
}

# Get worktree directory path for a feature
# Returns: ".wt/<feature-name>"
function Get-WorktreePath {
    param([string]$FeatureName)
    return ".wt/$FeatureName"
}

# Check if a worktree is registered
# Returns: $true if registered, $false otherwise
function Test-WorktreeRegistered {
    param([string]$WtPath)

    $output = git worktree list --porcelain 2>$null
    return $output -match "^worktree $WtPath"
}

# ==============================================
# Worktree Status Functions
# ==============================================

# Get worktree status (clean/dirty)
# Returns: "clean", "dirty", or "unknown"
function Get-WorktreeStatus {
    param([string]$WtPath)

    if (!(Test-Path $WtPath)) {
        return "unknown"
    }

    $originalLocation = Get-Location
    try {
        Set-Location $WtPath
        $status = git diff-index --quiet HEAD -- 2>$null

        if ($status) {
            return "clean"
        } else {
            return "dirty"
        }
    } catch {
        return "unknown"
    } finally {
        Set-Location $originalLocation
    }
}

# Check if worktree has uncommitted changes
# Returns: $true if has changes, $false if clean
function Test-UncommittedChanges {
    param([string]$WtPath)

    $status = Get-WorktreeStatus $WtPath
    return ($status -eq "dirty")
}

# ==============================================
# Feature Name Functions
# ==============================================

# Sanitize feature name (remove invalid characters)
# Returns: Sanitized feature name
function Sanitize-FeatureName {
    param([string]$Name)

    # Remove invalid characters (keep only alphanumeric, underscore, hyphen)
    return $Name -replace '[^a-zA-Z0-9_-]', ''
}

# Get branch name for a feature
# Returns: "feature/<feature-name>"
function Get-FeatureBranch {
    param([string]$FeatureName)
    return "feature/$FeatureName"
}

# ==============================================
# Validation Functions
# ==============================================

# Validate feature name
# Returns: $true if valid, $false otherwise
function Test-FeatureName {
    param([string]$Name)

    if ([string]::IsNullOrEmpty($Name)) {
        Log-Error "Feature name is empty"
        return $false
    }

    $sanitized = Sanitize-FeatureName $Name
    if ([string]::IsNullOrEmpty($sanitized)) {
        Log-Error "Invalid feature name: '$Name'"
        return $false
    }

    return $true
}

# ==============================================
# Output Functions
# ==============================================

# Print JSON output (wrapper for consistency)
function Print-Json {
    param([hashtable]$Data)

    $json = $Data | ConvertTo-Json -Compress:$false
    Write-Output $json
}

# ==============================================
# Help Functions
# ==============================================

# Show common help header
function Show-HelpHeader {
    param([string]$ScriptName, [string]$Description)

    Write-Host "$ScriptName - $Description`n"
}

# Show common help footer
function Show-HelpFooter {
    Write-Host @"

Options:
  --help, -h          Show this help message
  --json              Output result in JSON format

Description:
  - Non-interactive, suitable for AI agent usage
  - Works from any directory in the repository

Examples:
  $($MyInvocation.ScriptName) <args>
"@
}

# ==============================================
# Version Info
# ==============================================

# Show version information
function Show-Version {
    param([string]$Version)
    Write-Output $Version
}

# ==============================================
# Self-test Functions (for debugging)
# ==============================================

# Run self-tests
function Invoke-SelfTest {
    $failures = 0

    Write-Host "Running self-tests..."

    # Test 1: Check git repo
    if (!(Test-GitRepo)) {
        Log-Error "Not in a git repository"
        $failures++
    }

    # Test 2: Detect base branch
    $baseBranch = Get-BaseBranch
    if (!$baseBranch) {
        Log-Warning "Could not detect base branch"
        $failures++
    }

    # Test 3: Check .wt directory
    if (!(Test-Path ".wt")) {
        Log-Warning ".wt directory does not exist"
    }

    if ($failures -eq 0) {
        Log-Success "All self-tests passed"
    } else {
        Log-Error "$failures self-test(s) failed"
    }

    return $failures
}

# Export functions
Export-ModuleMember -Function @(
    'Log-Info',
    'Log-Success',
    'Log-Warning',
    'Log-Error',
    'Test-GitRepo',
    'Get-RepoRoot',
    'Set-RepoRoot',
    'Get-BaseBranch',
    'Test-BranchExists',
    'Initialize-WtDirectory',
    'Get-WorktreePath',
    'Test-WorktreeRegistered',
    'Get-WorktreeStatus',
    'Test-UncommittedChanges',
    'Sanitize-FeatureName',
    'Get-FeatureBranch',
    'Test-FeatureName',
    'Print-Json',
    'Show-HelpHeader',
    'Show-HelpFooter',
    'Show-Version',
    'Invoke-SelfTest'
)
