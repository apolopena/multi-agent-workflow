# Convert Plan to PLANNING.md

## Input: $ARGUMENTS

Read the plan document at the provided path and convert it to PLANNING.md format, **preserving all detailed specifications, schemas, configurations, and implementation details**.

## Conversion Process

### Step 1: Analyze Input Document
- Read the entire source document
- Identify project scope, goals, constraints
- Identify major technical specifications (schemas, APIs, configs)
- Identify major work items/components/features
- Note any explicit scope boundaries

### Step 2: Extract Context Sections (Preserve ALL Detail)

These sections are frozen after initial build and provide complete context for PRP generation.

**Project Overview:**
- What is being built (1-2 paragraphs)
- Target users/audience
- Core purpose and value proposition
- Technology stack overview
- Architecture overview

**Goals:**
- Primary objectives (bullet points)
- Success criteria
- What "done" looks like

**Constraints:**
- Technical constraints (languages, frameworks, dependencies)
- Timeline/phase constraints
- Resource constraints
- Known limitations

**Scope:**
- Major sections/features to be built
- What IS included
- What is NOT included

**Detailed Specifications:**

**CRITICAL: This section contains ALL technical detail from the source plan.**

Organize by category and preserve complete detail:

```
### Database Schema
[Complete SQL schemas, indexes, PRAGMA settings]

### API Endpoints
[Complete endpoint specs with request/response formats]

### WebSocket Architecture
[Complete message formats, connection patterns, broadcast logic]

### Component Structure
[Complete component tree with file paths and purposes]

### Configuration Files
[Complete config file contents - Caddyfile, docker-compose.yml, etc.]

### User Flows
[Complete flow descriptions with validation logic, error states]

### Environment Configuration
[Complete .env structure and all required variables]

### Integration Patterns
[Complete integration details - OAuth, email, etc.]

### UI/UX Specifications
[Complete page layouts, modals, error states]

### Testing Strategy
[Complete test scenarios and validation criteria]
```

**The rule: If it's in the source plan and would help someone implement a work item, it goes in Detailed Specifications.**

### Step 3: Generate Work Table (Optimized for Parallel Work)

Break the plan into work packages that enable **Git worktree parallelism** - multiple developers working simultaneously without merge conflicts.

**Step 3a: Identify Work Groups**

Analyze the plan's architecture and organize work into groups:
- **Group A**: Foundation work (database, core backend, basic config) - these MUST complete first
- **Groups B, C, D...**: Independent modules that can run in parallel (separate frontends, separate services, isolated features)
- **Later Groups**: Integration/glue work that needs multiple groups complete (Docker configs, API wiring, infrastructure)
- **Final Group**: Testing and documentation (needs full system running)

**Step 3b: Assign Group IDs**

Use format `WP-{LETTER}-{NUMBER}`:
- Same letter = same work area (will conflict, must be sequential)
- Different letters = different work areas (can run in parallel if dependencies met)
- Number = sequence within that group

**Step 3c: Generate Execution Order Summary**

Before the table, write an **Execution Order** section that clearly explains when each group runs:

**Pattern:**
- For sequential groups: "Group X (sequential): Complete WP-X-1, then WP-X-2"
- For parallel groups: "Groups X, Y, Z (parallel): After [dependency] completes, all can run simultaneously"

**Example:**
```
**Execution Order:**
1. **Group A** (sequential): Complete WP-A-1, then WP-A-2
2. **Groups B, C, D** (parallel): After WP-A-1 completes, all three can run simultaneously
3. **Group E** (parallel): After WP-A-2 completes, WP-E-1, WP-E-2, WP-E-3 can run simultaneously
4. **Group F** (parallel): After Groups B, C, D complete, WP-F-1 and WP-F-2 can run simultaneously
5. **Group G** (sequential): After Groups E, F complete, run WP-G-1, then WP-G-2
```

**Step 3d: Generate Work Table**

Format each row:
- Start description with action verb: "Create", "Implement", "Execute"
- List specific files/directories being created
- Reference Detailed Specifications sections
- Add "Depends on: WP-X-Y" only if it helps clarify (execution order summary is source of truth)
- Keep concise (2-3 sentences)

### Step 4: Output PLANNING.md Structure

```markdown
# [Project Name]

## Project Overview
[Preserved from source]

## Goals
[Preserved from source]

## Constraints
[Preserved from source]

## Scope
[Preserved from source with full detail for each section]

## Detailed Specifications

### Database Schema
[COMPLETE schemas, SQL, all details]

### API Endpoints
[COMPLETE endpoint specs]

### [Category N]
[COMPLETE specifications]

[Continue for ALL major technical categories from source plan]

## Work Table

**Execution Order:**
[Generate execution order summary following the pattern from Step 3c above]

| ID | Title | Description |
|----|-------|-------------|
[Generate work table rows with WP-{LETTER}-{NUMBER} IDs following Step 3d format]

---

**Note:** Context sections above (Project Overview through Detailed Specifications) are frozen after initial build. Work Table grows as new work items are added post-MVP. See `.ai/prp/proposals/` for adding standalone work items.
```

## Quality Checks
- [ ] All database schemas preserved verbatim
- [ ] All API specifications preserved verbatim
- [ ] All configuration files preserved verbatim
- [ ] All user flows preserved with complete logic
- [ ] All component structures preserved
- [ ] Work Table items reference these preserved specs
- [ ] No information loss from source document
- [ ] Detailed Specifications organized logically by category

## Output
Save as `.ai/prd/PLANNING.md` and report completion.
