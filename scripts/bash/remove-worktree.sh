#!/bin/bash
set -euo pipefail

# ==============================================
# Git Worktree Removal Script
# Description: Remove a git worktree and its branches
# Usage: remove-worktree.sh <feature-name> [--force] [--json]
# ==============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << EOF
Usage:
  remove-worktree.sh <feature-name> [--force] [--json]
  remove-worktree.sh --help

Arguments:
  feature-name        Name of the feature to remove (required)

Options:
  --force, -f         Force removal without checking unmerged changes
  --json              Output result in JSON format
  --help, -h          Show this help message

Examples:
  remove-worktree.sh user-auth
  remove-worktree.sh auth --force
  remove-worktree.sh feature-login --json

Description:
  - Removes the worktree directory .wt/<feature-name>/
  - Removes the feature/<feature-name> branch
  - Checks for uncommitted changes by default
  - Checks for merged branches by default
  - Non-interactive, suitable for AI agent usage
EOF
    exit 0
}

# Parse arguments
FEATURE_NAME=""
FORCE_DELETE=false
JSON_OUTPUT=false

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            show_help
            ;;
        --force|-f)
            FORCE_DELETE=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        -*)
            echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
            echo "Use 'remove-worktree.sh --help' for usage" >&2
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
    echo "Use 'remove-worktree.sh --help' for usage" >&2
    exit 1
fi

# Check if in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}" >&2
    exit 1
fi

# Get repository root
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

FEATURE_BRANCH="feature/$FEATURE_NAME"
WORKTREE_DIR=".wt/$FEATURE_NAME"

# Only print progress messages if not in JSON mode
if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}Removing worktree${NC}"
    echo -e "  Feature name: ${YELLOW}$FEATURE_NAME${NC}"
    echo -e "  Target branch: ${YELLOW}$FEATURE_BRANCH${NC}"
    echo -e "  Worktree directory: ${YELLOW}$WORKTREE_DIR${NC}"
fi

# 1. Check and remove worktree
if [ "$JSON_OUTPUT" = false ]; then
    echo -e "\n${BLUE}Checking worktree...${NC}"
fi

WORKTREE_EXISTS=false
if git worktree list --porcelain | grep -q "^worktree $WORKTREE_DIR"; then
    WORKTREE_EXISTS=true

    # Check for uncommitted changes
    if [ "$FORCE_DELETE" = false ]; then
        if cd "$WORKTREE_DIR" 2>/dev/null; then
            if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                ERROR_MSG="Worktree has uncommitted changes"
                if [ "$JSON_OUTPUT" = true ]; then
                    echo -e "{\"error\": \"$ERROR_MSG\"}" >&2
                else
                    echo -e "${RED}Error: $ERROR_MSG${NC}" >&2
                    echo -e "  Use --force to remove anyway" >&2
                fi
                exit 1
            fi
            cd "$GIT_ROOT"
        fi
    fi

    # Remove worktree (try normal remove first, then force, then manual)
    if git worktree remove "$WORKTREE_DIR" 2>/dev/null; then
        # Successfully removed
        :
    elif git worktree remove "$WORKTREE_DIR" --force 2>/dev/null; then
        # Force removed
        :
    else
        # Fallback to manual removal
        rm -rf "$WORKTREE_DIR"
        git worktree prune >/dev/null 2>&1 || true
    fi

    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${GREEN}Worktree removed: $WORKTREE_DIR${NC}"
    fi
elif [ -d "$WORKTREE_DIR" ]; then
    # Unregistered directory exists
    WORKTREE_EXISTS=true
    rm -rf "$WORKTREE_DIR"
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${YELLOW}Unregistered worktree directory removed${NC}"
    fi
fi

# 2. Check and remove local branch
if [ "$JSON_OUTPUT" = false ]; then
    echo -e "\n${BLUE}Checking local branch...${NC}"
fi

# Check if we're currently in the worktree being deleted
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$CURRENT_BRANCH" = "$FEATURE_BRANCH" ]; then
    # We're in the worktree, need to switch branches first
    if [ "$JSON_OUTPUT" = true ]; then
        echo -e "{\"error\": \"Cannot delete branch '$FEATURE_BRANCH' while checked out in the worktree. Run: git checkout main && cd .. && remove-worktree.sh $FEATURE_NAME\"}" >&2
    else
        echo -e "${RED}Error: Cannot delete branch '$FEATURE_BRANCH' while in the worktree${NC}" >&2
        echo -e "  Please run:" >&2
        echo -e "    ${cyan}git checkout main${NC}" >&2
        echo -e "    ${cyan}cd ..${NC}" >&2
        echo -e "    ${cyan}remove-worktree.sh $FEATURE_NAME${NC}" >&2
    fi
    exit 1
fi

# Prune worktrees before deleting branch to clean up dangling references
git worktree prune >/dev/null 2>&1 || true

BRANCH_REMOVED=false
if git show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH" 2>/dev/null; then
    # Check if branch is merged
    if [ "$FORCE_DELETE" = false ]; then
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "${BLUE}Checking merge status...${NC}"
        fi

        # Detect default branch
        DEFAULT_BRANCH=""
        for branch in "main" "master" "develop"; do
            if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null || \
               git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
                DEFAULT_BRANCH="$branch"
                break
            fi
        done

        if [ -n "$DEFAULT_BRANCH" ]; then
            if git branch --merged "$DEFAULT_BRANCH" 2>/dev/null | grep -q "$FEATURE_BRANCH"; then
                # Branch is merged, safe to delete
                git branch -d "$FEATURE_BRANCH" >/dev/null
                BRANCH_REMOVED=true
                if [ "$JSON_OUTPUT" = false ]; then
                    echo -e "${GREEN}Branch merged to $DEFAULT_BRANCH and deleted${NC}"
                fi
            else
                # Branch not merged
                ERROR_MSG="Branch '$FEATURE_BRANCH' is not merged to '$DEFAULT_BRANCH'"
                if [ "$JSON_OUTPUT" = true ]; then
                    echo -e "{\"error\": \"$ERROR_MSG\"}" >&2
                else
                    echo -e "${RED}Error: $ERROR_MSG${NC}" >&2
                    echo -e "  Use --force to delete anyway" >&2
                fi
                exit 1
            fi
        else
            # Cannot detect default branch, try regular delete
            if ! git branch -d "$FEATURE_BRANCH" 2>/dev/null; then
                ERROR_MSG="Branch '$FEATURE_BRANCH' is not merged"
                if [ "$JSON_OUTPUT" = true ]; then
                    echo -e "{\"error\": \"$ERROR_MSG\"}" >&2
                else
                    echo -e "${RED}Error: $ERROR_MSG${NC}" >&2
                    echo -e "  Use --force to delete anyway" >&2
                fi
                exit 1
            fi
            BRANCH_REMOVED=true
        fi
    else
        # Force delete
        git branch -D "$FEATURE_BRANCH" >/dev/null
        BRANCH_REMOVED=true
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "${GREEN}Branch force deleted${NC}"
        fi
    fi
fi

# 3. Check and remove remote branch
if [ "$JSON_OUTPUT" = false ]; then
    echo -e "\n${BLUE}Checking remote branch...${NC}"
fi

REMOTE_BRANCH_REMOVED=false
if git ls-remote --heads origin "$FEATURE_BRANCH" 2>/dev/null | grep -q "$FEATURE_BRANCH"; then
    git push origin --delete "$FEATURE_BRANCH" >/dev/null 2>&1 || true
    REMOTE_BRANCH_REMOVED=true
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${GREEN}Remote branch deleted: origin/$FEATURE_BRANCH${NC}"
    fi
fi

# 4. Output result
if [ "$JSON_OUTPUT" = true ]; then
    cat <<EOF
{
  "feature_name": "$FEATURE_NAME",
  "branch": "$FEATURE_BRANCH",
  "worktree_removed": $WORKTREE_EXISTS,
  "branch_removed": $BRANCH_REMOVED,
  "remote_branch_removed": $REMOTE_BRANCH_REMOVED
}
EOF
else
    echo -e "\n${GREEN}Worktree removed successfully!${NC}"
    echo -e "  Feature: $FEATURE_NAME"
    echo -e "  Branch: $FEATURE_BRANCH"

    if [ "$WORKTREE_EXISTS" = false ]; then
        echo -e "\n${YELLOW}Note: Worktree directory did not exist${NC}"
    fi
fi
