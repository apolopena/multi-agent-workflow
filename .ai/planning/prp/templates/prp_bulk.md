# Bulk PRP Template - Comprehensive Implementation Guide

## Purpose
Template for AI agents to implement features during initial project build with sufficient context and self-validation capabilities to achieve working code through iterative refinement.

## Core Principles
1. **Context is King**: Include ALL necessary documentation, examples, and caveats
2. **Validation Loops**: Provide executable tests/lints the AI can run and fix
3. **Information Dense**: Use keywords and patterns from the codebase
4. **Progressive Success**: Start simple, validate, then enhance
5. **Global Rules**: Follow all rules in CLAUDE.md

---

## Goal
[What needs to be built - be specific about the end state and desired outcome]

## Why
- [Business value and user impact]
- [Integration with existing features]
- [Problems this solves and for whom]

## What
[User-visible behavior and technical requirements]

## Bulk Generation Mode
If the input is `PLANNING.md` and it contains a "Work Table", generate **one PRP per row** using this template.

File names: `.ai/prp/instances/<ID>_<kebab-title>.md`

Skip rows where:
- A PRP instance already exists at `.ai/planning/prp/instances/<ID>_*.md` (already generated)

Mapping:
- Goal  ← row Title (+ brief expansion from row description)
- Why   ← value/impact inferred from PLANNING.md
- What  ← user-visible behavior from the row
- Success Criteria ← 3–6 checks derived from the row

Do not merge rows. If a file exists, create `…-v2.md` (don't overwrite).

### Success Criteria
- [ ] Feature works as described in PLANNING.md
- [ ] Unit tests for new/changed code pass (see Validation Loop)
- [ ] No regressions to existing features
- [ ] Code follows project style guide (CLAUDE.md)
- [ ] Implementation matches Detailed Specifications

---

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Include these in your context window
# Add project-specific documentation URLs, style guides, API docs
- url: [PROJECT_DOCS_URL]
  why: [Why this documentation is essential]
```

### Current Codebase Tree
```bash
# Run tree/ls command to show current structure
[SHOW_CURRENT_STRUCTURE]
```

### Desired Codebase Tree
```bash
# Show new files and structure to be created
[SHOW_DESIRED_STRUCTURE]
```

### Known Gotchas
```text
# Project-specific gotchas and constraints
[LIST_PROJECT_CONSTRAINTS]
```

---

## Dependencies & Tooling

List all dependencies that must be used at their **latest supported version**:

```yaml
# Core dependencies for this project
- [DEPENDENCY_1]: [description and purpose]
- [DEPENDENCY_2]: [description and purpose]
```

---

## Implementation Blueprint

### Data Models and Structure
[Define data models, database schemas, API contracts, types]

### List of Tasks to Fulfill the PRP
```yaml
Task 1:
[ACTION] [FILE_PATH]:
  - FOLLOW pattern in [REFERENCE_FILE]
  - KEEP [consistency requirement]
  - ADD [testing requirement]

Task 2:
[Next task...]
```

### Per Task Pseudocode
```
// Task 1 pseudocode
[FUNCTION_NAME](input) {
  // validate input
  // core logic
  // return structured result
}
```

### Integration Points
```yaml
# List all integration points with existing code
[COMPONENT_TYPE_1]:
  - [Integration point description]
  - [Files that will be modified]

[COMPONENT_TYPE_2]:
  - [Integration point description]
```

---

## Validation Loop

**CRITICAL:** You MUST iterate through these checks until ALL pass. Do not mark work complete with failing checks or tests.

### Level 1: Syntax & Style
```bash
[PROJECT_LINT_COMMAND]

# Common examples by language:
# JavaScript/TypeScript: npm run lint (or eslint . --fix && prettier --write .)
# Python: ruff check --fix && black .
# Go: gofmt -w . && golangci-lint run
# Rust: cargo fmt && cargo clippy
# Ruby: rubocop -A
```

**Exit criteria:** Zero errors, zero warnings.

**If this fails:**
1. Read the error output carefully
2. Fix the issues in the code
3. Re-run Level 1
4. Do NOT proceed to Level 2 until Level 1 passes cleanly

### Level 2: Unit Tests
```bash
[PROJECT_TEST_COMMAND]

# Common examples by language:
# JavaScript/TypeScript: npm test (or vitest run / jest)
# Python: pytest tests/ -v
# Go: go test ./...
# Rust: cargo test
# Ruby: rspec
```

**Exit criteria:** All tests pass. If this introduces new code, add tests for it first.

**If this fails:**
1. Read the test failure output
2. Fix the code or update tests if requirements changed
3. Re-run BOTH Level 1 and Level 2
4. Iterate until both pass

---

## Final Validation Checklist
- [ ] All validation levels pass cleanly
- [ ] No linting errors or warnings
- [ ] All unit tests pass
- [ ] New code has test coverage
- [ ] Manual verification completed (if applicable)
- [ ] Documentation updated (if needed)

---

## Anti-Patterns to Avoid
- ❌ Don't skip validation because "it looks fine"
- ❌ Don't ignore failing tests or linting errors
- ❌ Don't proceed to next task with broken code
- ❌ Don't modify files outside the scope of this PRP
- ❌ Don't add TODO comments instead of implementing features

---

## Notes
[Add any work-item-specific notes, edge cases, or special considerations]
