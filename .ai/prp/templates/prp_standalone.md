# Standalone PRP Template - Single Work Item

## Purpose
Lightweight template for implementing individual features, enhancements, bug fixes, or refactors post-MVP.

---

## Work Item

### What
[Describe what needs to be implemented - be specific about user-visible behavior or technical outcome]

### Why
[Business value, user impact, or problem being solved]

### How
[High-level technical approach - what will change and where]

---

## Success Criteria
- [ ] Work item completed as specified
- [ ] Implementation matches specifications (reference PLANNING.md Detailed Specifications if applicable)
- [ ] Unit tests added/updated and passing
- [ ] Code passes linting/style checks
- [ ] No regressions introduced

---

## Implementation

### Affected Files
```yaml
# List files that will be modified or created
- [path/to/file1]: [what changes]
- [path/to/file2]: [what changes]
```

### Steps
1. [Task description - what to implement]
2. [Task description - what to implement]
3. Add unit tests in `[test_directory]/[name].[test_extension]`
4. Run validation loop

---

## Validation Loop

**CRITICAL:** Iterate through these checks until ALL pass. Do not mark work complete with failing checks or tests.

### Syntax & Style
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
3. Re-run this check
4. Do NOT proceed to testing until this passes cleanly

### Unit Tests
```bash
[PROJECT_TEST_COMMAND]

# Common examples by language:
# JavaScript/TypeScript: npm test (or vitest run / jest)
# Python: pytest tests/ -v
# Go: go test ./...
# Rust: cargo test
# Ruby: rspec
```

**Exit criteria:** All tests pass.

**If this fails:**
1. Read the test failure output
2. Fix the code or update tests if requirements changed
3. Re-run BOTH syntax check and tests
4. Iterate until both pass

---

## Notes
[Any specific gotchas, edge cases, or considerations for this work item]
