#!/bin/bash
set -euo pipefail

# ==============================================
# Git Worktree Creation Script
# Description: Create a git worktree and feature branch
# Usage: create-worktree.sh <feature-name> [--base-branch <branch>] [--json]
# ==============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
DIM='\033[2m'

show_help() {
    cat << EOF
Usage:
  create-worktree.sh <feature-name> [--base-branch <branch>] [--json]
  create-worktree.sh --help

Arguments:
  feature-name        Name of the feature (required)

Options:
  --base-branch       Base branch for the worktree (default: auto-detect main/master/develop)
  --json              Output result in JSON format
  --help, -h          Show this help message

Examples:
  create-worktree.sh user-auth
  create-worktree.sh auth --base-branch develop
  create-worktree.sh feature-login --json

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
EOF
    exit 0
}

# Parse arguments
FEATURE_NAME=""
BASE_BRANCH=""
JSON_OUTPUT=false

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            show_help
            ;;
        --base-branch)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: --base-branch requires an argument${NC}" >&2
                exit 1
            fi
            BASE_BRANCH="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        -*)
            echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
            echo "Use 'create-worktree.sh --help' for usage" >&2
            exit 1
            ;;
        *)
            if [ -z "$FEATURE_NAME" ]; then
                FEATURE_NAME="$1"
            else
                echo -e "${RED}Error: Feature name already specified as '$FEATURE_NAME', cannot specify '$1'${NC}" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Check required arguments
if [ -z "$FEATURE_NAME" ]; then
    echo -e "${RED}Error: Missing feature name argument${NC}" >&2
    echo "Use 'create-worktree.sh --help' for usage" >&2
    exit 1
fi

# Validate feature name (sanitize)
SANITIZED_NAME=$(echo "$FEATURE_NAME" | sed 's/[^a-zA-Z0-9_-]//g')
if [ -z "$SANITIZED_NAME" ]; then
    echo -e "${RED}Error: Invalid feature name '$FEATURE_NAME'${NC}" >&2
    exit 1
fi

if [ "$SANITIZED_NAME" != "$FEATURE_NAME" ]; then
    echo -e "${YELLOW}Warning: Feature name sanitized to '$SANITIZED_NAME'${NC}" >&2
fi
FEATURE_NAME="$SANITIZED_NAME"

# Check if in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}" >&2
    exit 1
fi

# Get repository root
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

NEW_BRANCH="feature/$FEATURE_NAME"
WORKTREE_DIR=".wt/$FEATURE_NAME"

# Only print progress messages if not in JSON mode
if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}Creating worktree${NC}"
    echo -e "  Feature name: ${GREEN}$FEATURE_NAME${NC}"
    echo -e "  Target branch: ${GREEN}$NEW_BRANCH${NC}"
    echo -e "  Worktree directory: ${GREEN}$WORKTREE_DIR${NC}"
fi

# 1. Auto-detect or validate base branch
if [ -z "$BASE_BRANCH" ]; then
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "\n${BLUE}Detecting base branch...${NC}"
    fi

    # Priority: main > master > develop
    for branch in "main" "master" "develop"; do
        if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null || \
           git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
            BASE_BRANCH="$branch"
            if [ "$JSON_OUTPUT" = false ]; then
                echo -e "${GREEN}Detected base branch: $BASE_BRANCH${NC}"
            fi
            break
        fi
    done

    if [ -z "$BASE_BRANCH" ]; then
        ERROR_MSG="Unable to detect base branch. Please specify --base-branch"
        if [ "$JSON_OUTPUT" = true ]; then
            echo -e "{\"error\": \"$ERROR_MSG\"}" >&2
        else
            echo -e "${RED}Error: $ERROR_MSG${NC}" >&2
        fi
        exit 1
    fi
else
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "\n${BLUE}Validating base branch...${NC}"
    fi
    # Validate specified branch exists
    if ! git show-ref --verify --quiet "refs/heads/$BASE_BRANCH" 2>/dev/null && \
       ! git show-ref --verify --quiet "refs/remotes/origin/$BASE_BRANCH" 2>/dev/null; then
        ERROR_MSG="Base branch '$BASE_BRANCH' not found"
        if [ "$JSON_OUTPUT" = true ]; then
            echo -e "{\"error\": \"$ERROR_MSG\"}" >&2
        else
            echo -e "${RED}Error: $ERROR_MSG${NC}" >&2
        fi
        exit 1
    fi
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${GREEN}Using base branch: $BASE_BRANCH${NC}"
    fi
fi

# 2. Ensure .wt directory exists and add to .gitignore
mkdir -p ".wt"

if [ -f ".gitignore" ]; then
    if ! grep -q "^\.wt/$" ".gitignore" && ! grep -q "^\.wt$" ".gitignore"; then
        echo ".wt/" >> ".gitignore"
    fi
else
    echo ".wt/" > ".gitignore"
fi

# 3. Check if worktree already exists
if [ -d "$WORKTREE_DIR" ]; then
    # Check if it's a registered worktree
    if git worktree list --porcelain | grep -q "^worktree $WORKTREE_DIR"; then
        ERROR_MSG="Worktree already exists: $WORKTREE_DIR"
        if [ "$JSON_OUTPUT" = true ]; then
            echo -e "{\"error\": \"$ERROR_MSG\"}" >&2
        else
            echo -e "${RED}Error: $ERROR_MSG${NC}" >&2
            echo -e "  Use 'remove-worktree.sh $FEATURE_NAME' first" >&2
        fi
        exit 1
    else
        # Unregistered directory, remove it
        rm -rf "$WORKTREE_DIR"
    fi
fi

# 4. Create worktree and branch
if [ "$JSON_OUTPUT" = false ]; then
    echo -e "\n${BLUE}Creating worktree...${NC}"
fi

# Fetch base branch from remote if it exists
if git show-ref --verify --quiet "refs/remotes/origin/$BASE_BRANCH" 2>/dev/null; then
    git fetch origin "$BASE_BRANCH" >/dev/null 2>&1 || true
fi

# Check if feature branch already exists
if git show-ref --verify --quiet "refs/heads/$NEW_BRANCH" 2>/dev/null; then
    # Branch exists, create worktree from existing branch
    git worktree add "$WORKTREE_DIR" "$NEW_BRANCH" >/dev/null
else
    # Branch doesn't exist, create new branch with worktree
    git worktree add -b "$NEW_BRANCH" "$WORKTREE_DIR" "$BASE_BRANCH" >/dev/null
fi

# 5. Output result
if [ "$JSON_OUTPUT" = true ]; then
    cat <<EOF
{
  "worktree_path": "$WORKTREE_DIR",
  "branch": "$NEW_BRANCH",
  "base_branch": "$BASE_BRANCH",
  "feature_name": "$FEATURE_NAME"
}
EOF
else
    echo -e "\n${GREEN}Worktree created successfully!${NC}"
    echo -e "  Branch: $NEW_BRANCH"
    echo -e "  Directory: $WORKTREE_DIR"
    echo -e "  Base: $BASE_BRANCH"
    echo -e "\n${DIM}Next steps:${NC}"
    echo -e "  1. ${CYAN}cd $WORKTREE_DIR${NC}"
    echo -e "  2. Start developing your feature"
fi
