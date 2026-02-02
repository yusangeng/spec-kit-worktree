#!/bin/bash
# ==============================================
# Git Worktree Common Functions
# Description: Shared utility functions for worktree management
# Usage: source worktree-common.sh
# ==============================================

# Colors (can be overridden)
if [ -z "${RED:-}" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

# ==============================================
# Logging Functions
# ==============================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# ==============================================
# Git Repository Functions
# ==============================================

# Check if in a git repository
# Returns: 0 if in git repo, 1 otherwise
is_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1
}

# Get repository root directory
# Echoes the repository root path
get_repo_root() {
    git rev-parse --show-toplevel
}

# Navigate to repository root
# Usage: cd_to_repo_root
cd_to_repo_root() {
    local root
    root=$(get_repo_root)
    cd "$root"
}

# ==============================================
# Branch Detection Functions
# ==============================================

# Auto-detect base branch (main/master/develop)
# Returns: The first found branch name
# Echoes: "main", "master", or "develop"
detect_base_branch() {
    for branch in "main" "master" "develop"; do
        if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null || \
           git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
            echo "$branch"
            return 0
        fi
    done
    return 1
}

# Check if a branch exists (local or remote)
# Usage: branch_exists <branch-name>
# Returns: 0 if exists, 1 otherwise
branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null || \
    git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null
}

# ==============================================
# Worktree Directory Functions
# ==============================================

# Ensure .wt directory exists and is in .gitignore
# Usage: ensure_wt_directory
ensure_wt_directory() {
    mkdir -p ".wt"

    # Add .wt/ to .gitignore
    if [ -f ".gitignore" ]; then
        if ! grep -q "^\.wt/$" ".gitignore" && ! grep -q "^\.wt$" ".gitignore"; then
            echo ".wt/" >> ".gitignore"
        fi
    else
        echo ".wt/" > ".gitignore"
    fi
}

# Get worktree directory path for a feature
# Usage: get_worktree_path <feature-name>
# Echoes: ".wt/<feature-name>"
get_worktree_path() {
    local feature_name="$1"
    echo ".wt/$feature_name"
}

# Check if a worktree is registered
# Usage: is_worktree_registered <worktree-path>
# Returns: 0 if registered, 1 otherwise
is_worktree_registered() {
    local wt_path="$1"
    git worktree list --porcelain | grep -q "^worktree $wt_path"
}

# ==============================================
# Worktree Status Functions
# ==============================================

# Get worktree status (clean/dirty)
# Usage: get_worktree_status <worktree-path>
# Echoes: "clean", "dirty", or "unknown"
get_worktree_status() {
    local wt_path="$1"

    if [ ! -d "$wt_path" ]; then
        echo "unknown"
        return 1
    fi

    if cd "$wt_path" 2>/dev/null; then
        if git diff-index --quiet HEAD -- 2>/dev/null; then
            echo "clean"
        else
            echo "dirty"
        fi
        return 0
    else
        echo "unknown"
        return 1
    fi
}

# Check if worktree has uncommitted changes
# Usage: has_uncommitted_changes <worktree-path>
# Returns: 0 if has changes, 1 if clean
has_uncommitted_changes() {
    local wt_path="$1"
    local status

    status=$(get_worktree_status "$wt_path")
    [ "$status" = "dirty" ]
}

# ==============================================
# Feature Name Functions
# ==============================================

# Sanitize feature name (remove invalid characters)
# Usage: sanitize_feature_name <name>
# Echoes: Sanitized feature name
sanitize_feature_name() {
    local name="$1"
    echo "$name" | sed 's/[^a-zA-Z0-9_-]//g'
}

# Get branch name for a feature
# Usage: get_feature_branch <feature-name>
# Echoes: "feature/<feature-name>"
get_feature_branch() {
    local feature_name="$1"
    echo "feature/$feature_name"
}

# ==============================================
# Validation Functions
# ==============================================

# Validate feature name
# Usage: validate_feature_name <name>
# Returns: 0 if valid, 1 otherwise
validate_feature_name() {
    local name="$1"
    local sanitized

    if [ -z "$name" ]; then
        log_error "Feature name is empty"
        return 1
    fi

    sanitized=$(sanitize_feature_name "$name")
    if [ -z "$sanitized" ]; then
        log_error "Invalid feature name: '$name'"
        return 1
    fi

    return 0
}

# ==============================================
# Output Functions
# ==============================================

# Print JSON output (wrapper for consistency)
# Usage: print_json <key-value pairs>
# Example: print_json "name: \"$NAME\"" "branch: \"$BRANCH\""
print_json() {
    local pairs=("$@")
    local count=${#pairs[@]}

    echo "{"
    for i in "${!pairs[@]}"; do
        local pair="${pairs[$i]}"
        if [ $i -lt $((count - 1)) ]; then
            echo -n "  $pair,"
        else
            echo "  $pair"
        fi
    done
    echo "}"
}

# ==============================================
# Help Functions
# ==============================================

# Show common help header
# Usage: show_help_header <script-name> <description>
show_help_header() {
    local script_name="$1"
    local description="$2"

    cat << EOF
$script_name - $description

EOF
}

# Show common help footer
show_help_footer() {
    cat << EOF

Options:
  --help, -h          Show this help message
  --json              Output result in JSON format

Description:
  - Non-interactive, suitable for AI agent usage
  - Works from any directory in the repository

Examples:
  $(basename "$0") <args>

EOF
}

# ==============================================
# Version Info
# ==============================================

# Show version information
# Usage: show_version <version>
show_version() {
    local version="$1"
    echo "$version"
}

# ==============================================
# Self-test Functions (for debugging)
# ==============================================

# Run self-tests
# Usage: run_self_tests
run_self_tests() {
    local failures=0

    echo "Running self-tests..."

    # Test 1: Check git repo
    if ! is_git_repo; then
        log_error "Not in a git repository"
        ((failures++))
    fi

    # Test 2: Detect base branch
    if ! BASE_BRANCH=$(detect_base_branch); then
        log_warning "Could not detect base branch"
        ((failures++))
    fi

    # Test 3: Check .wt directory
    if [ ! -d ".wt" ]; then
        log_warning ".wt directory does not exist"
    fi

    if [ $failures -eq 0 ]; then
        log_success "All self-tests passed"
    else
        log_error "$failures self-test(s) failed"
    fi

    return $failures
}
