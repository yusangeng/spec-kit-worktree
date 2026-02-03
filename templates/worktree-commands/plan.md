---
description: Execute the implementation planning workflow using the plan template to generate design artifacts (worktree mode).
handoffs:
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
mode: worktree
allowed-tools:
  - Bash(find:*)
  - Bash(git:*)
  - Bash(cd:*)
  - Bash(cat:*)
  - Read(*)
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Auto-detect worktree and feature directory**:

   a. Find the spec file in worktrees:
      ```bash
      # Find the spec file in any worktree
      SPEC_FILE=$(find ../../.wt -name "spec.md" -type f 2>/dev/null | head -1)

      if [[ -z "$SPEC_FILE" ]]; then
        echo "Error: No spec.md found in worktrees"
        echo "Please run /speckit.specify first to create a worktree and spec"
        exit 1
      fi

      # Extract worktree directory from spec file path
      WORKTREE_DIR=$(dirname $(dirname $(dirname "$SPEC_FILE")))

      # Change to the worktree directory
      cd "$WORKTREE_DIR"

      echo "Working in worktree: $WORKTREE_DIR"
      ```

   b. Find the feature directory:
      ```bash
      # Find the feature directory (contains spec.md)
      FEATURE_DIR=$(find . -type d -name "FS-*" -exec test -f "{}/spec.md" \; -print | head -1)

      if [[ -z "$FEATURE_DIR" ]]; then
        echo "Error: No feature directory found in worktree"
        exit 1
      fi

      echo "Feature directory: $FEATURE_DIR"
      ```

   c. Set required variables:
      - FEATURE_SPEC: `$FEATURE_DIR/spec.md`
      - IMPL_PLAN: `$FEATURE_DIR/plan.md`
      - SPECS_DIR: `$FEATURE_DIR`
      - BRANCH: Current git branch name

   **IMPORTANT**:
   - This command must be run from within a worktree
   - The worktree is automatically detected by finding the spec.md file
   - If no worktree is found, the command will error

2. **Load context**: Read FEATURE_SPEC and `memory/constitution.md` from the
   main repository root (constitution is a project-level artifact, not feature-specific). Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 2 planning. Report worktree name, branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `$FEATURE_DIR/research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `$FEATURE_DIR/data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `$FEATURE_DIR/contracts/`

3. **Agent context update**:
   - Navigate to repo root: `cd "$(git rev-parse --show-toplevel)"`
   - Run the appropriate agent context update script
   - Update the agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers
   - Return to worktree: `cd "$WORKTREE_DIR"`

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

## Key rules

- Use absolute paths when referencing files outside the worktree
- ERROR on gate failures or unresolved clarifications
- All outputs are created within the worktree's feature directory
