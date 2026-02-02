#!/bin/bash
set -eo pipefail

# ==============================================
# Git Worktree List Script
# Description: List all worktrees in the .wt directory
# Usage: list-worktrees.sh [--verbose] [--json]
# ==============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
DIM='\033[2m'

show_help() {
    cat << EOF
Usage:
  list-worktrees.sh [--verbose] [--json]
  list-worktrees.sh --help

Options:
  --verbose, -v       Show detailed information (commit SHA, status)
  --json              Output result in JSON format
  --help, -h          Show this help message

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
EOF
    exit 0
}

# Parse arguments
VERBOSE=false
JSON_OUTPUT=false

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            show_help
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        -*)
            echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
            echo "Use 'list-worktrees.sh --help' for usage" >&2
            exit 1
            ;;
        *)
            echo -e "${RED}Error: Unexpected argument '$1'${NC}" >&2
            exit 1
            ;;
    esac
done

# Check if in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    if [ "$JSON_OUTPUT" = true ]; then
        echo -e "{\"error\": \"Not in a git repository\"}" >&2
    else
        echo -e "${RED}Error: Not in a git repository${NC}" >&2
    fi
    exit 1
fi

# Get repository root
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

# Get all worktrees (porcelain format)
WORKTREE_OUTPUT=$(git worktree list --porcelain)

# Parse worktrees and filter for .wt directory
WORKTREES=()
CURRENT_WORKTREE=""
NAME=""
WT_PATH=""
BRANCH=""
COMMIT=""
STATUS=""

while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.+) ]]; then
        WT_PATH="${BASH_REMATCH[1]}"
        WT_PATH="${WT_PATH%/}"  # Remove trailing slash

        # Only include worktrees under .wt directory
        if [[ "$WT_PATH" == */.wt/* ]]; then
            NAME=$(basename "$WT_PATH")
            BRANCH=""
            COMMIT=""
            STATUS=""

            # Check if it's the current worktree
            if [[ "$WT_PATH" == "$GIT_ROOT" ]]; then
                CURRENT_WORKTREE="$NAME"
            fi
        fi
    elif [[ "$line" =~ ^branch\ (.+) ]]; then
        BRANCH="${BASH_REMATCH[1]}"
        BRANCH="${BRANCH#refs/heads/}"  # Remove refs/heads/ prefix
    elif [[ "$line" =~ ^HEAD\ (.+) ]]; then
        COMMIT="${BASH_REMATCH[1]}"
    fi

    # End of worktree block (empty line or end of input)
    if [[ -z "$line" ]]; then
        if [[ -n "$NAME" ]]; then
            # Check worktree status if verbose or JSON mode
            if [ "$VERBOSE" = true ] || [ "$JSON_OUTPUT" = true ]; then
                if [ -d "$WT_PATH" ]; then
                    # Check if worktree has uncommitted changes
                    if cd "$WT_PATH" 2>/dev/null; then
                        if git diff-index --quiet HEAD -- 2>/dev/null; then
                            STATUS="clean"
                        else
                            STATUS="dirty"
                        fi
                        cd "$GIT_ROOT" >/dev/null
                    else
                        STATUS="unknown"
                    fi
                fi
            fi

            WORKTREES+=("$NAME|$WT_PATH|$BRANCH|$COMMIT|$STATUS")
        fi
        # Reset for next worktree
        NAME=""
        WT_PATH=""
        BRANCH=""
        COMMIT=""
        STATUS=""
    fi
done <<< "$WORKTREE_OUTPUT"

# Handle case where output doesn't end with empty line
if [[ -n "$NAME" ]]; then
    # Add the last worktree that wasn't added
    if [ "$VERBOSE" = true ] || [ "$JSON_OUTPUT" = true ]; then
        if [ -d "$WT_PATH" ]; then
            if cd "$WT_PATH" 2>/dev/null; then
                if git diff-index --quiet HEAD -- 2>/dev/null; then
                    STATUS="clean"
                else
                    STATUS="dirty"
                fi
                cd "$GIT_ROOT" >/dev/null
            else
                STATUS="unknown"
            fi
        fi
    fi

    WORKTREES+=("$NAME|$WT_PATH|$BRANCH|$COMMIT|$STATUS")
fi

# Output results
if [ "$JSON_OUTPUT" = true ]; then
    # JSON output
    echo "{"
    echo "  \"worktrees\": ["

    FIRST=true
    for WT in "${WORKTREES[@]}"; do
        IFS='|' read -r NAME WT_PATH BRANCH COMMIT STATUS <<< "$WT"

        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo ","
        fi

        echo -n "    {"
        echo -n "\"name\": \"$NAME\", "
        echo -n "\"path\": \"$WT_PATH\", "
        echo -n "\"branch\": \"$BRANCH\""

        if [ "$VERBOSE" = true ]; then
            echo -n ", \"commit\": \"$COMMIT\", \"status\": \"$STATUS\""
        fi

        echo -n "}"
    done

    if [ ${#WORKTREES[@]} -gt 0 ]; then
        echo ""
    fi

    echo "  ]"
    echo "}"
else
    # Table output
    if [ ${#WORKTREES[@]} -eq 0 ]; then
        echo -e "${YELLOW}No worktrees found${NC}"
        echo ""
        echo -e "${DIM}Use 'create-worktree.sh <feature-name>' to create a worktree${NC}"
        exit 0
    fi

    # Print header
    echo -e "${BOLD}${BLUE}Worktrees${NC}"
    echo ""
    echo -e "${CYAN}$( printf '━%.0s' 50 )${NC}"

    for WT in "${WORKTREES[@]}"; do
        IFS='|' read -r NAME WT_PATH BRANCH COMMIT STATUS <<< "$WT"

        # Make relative path if possible
        if [[ "$WT_PATH" == "$GIT_ROOT"/* ]]; then
            REL_PATH="${WT_PATH#$GIT_ROOT/}"
        else
            REL_PATH="$WT_PATH"
        fi

        echo -e "  ${BOLD}Feature:${NC}    $NAME"
        echo -e "  ${BOLD}Branch:${NC}    $BRANCH"
        echo -e "  ${BOLD}Path:${NC}      $REL_PATH"

        if [ "$VERBOSE" = true ]; then
            echo -e "  ${BOLD}Commit:${NC}   $COMMIT"
            if [ "$STATUS" = "clean" ]; then
                echo -e "  ${BOLD}Status:${NC}   ${GREEN}clean${NC}"
            elif [ "$STATUS" = "dirty" ]; then
                echo -e "  ${BOLD}Status:${NC}   ${YELLOW}dirty${NC} (uncommitted changes)"
            else
                echo -e "  ${BOLD}Status:${NC}   ${DIM}unknown${NC}"
            fi
        fi

        echo ""
    done

    # Print summary
    COUNT=${#WORKTREES[@]}
    echo -e "${DIM}Total: $COUNT worktree(s)${NC}"

    if [ -n "$CURRENT_WORKTREE" ]; then
        echo -e "${DIM}Current: $CURRENT_WORKTREE${NC}"
    fi
fi
