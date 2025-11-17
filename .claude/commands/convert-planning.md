---
description: Convert unstructured plan into PLANNING.md
---

# Convert Planning Document

## Input: $ARGUMENTS

**ABORT if $ARGUMENTS is empty**: User must provide plan text or file path.

Convert a user's plan, requirements, or feature list into a structured PLANNING.md file using the PLANNING_TEMPLATE.md convention.

## MANDATORY FIRST STEP: Select Work Package Numbering Mode

**CRITICAL: BEFORE doing anything else, you MUST prompt the user to select numbering mode and WAIT for their response.**

Display this prompt to the user:

```
Work Package numbering mode:

1) Linear Mode
   Format: WP-001, WP-002, WP-003...
   Use for: Standard sequential development

2) Parallel Mode
   Format: WP-A-1, WP-B-1, WP-C-1...
   Use for: Git worktrees, parallel development streams
   Enables multiple developers/streams to work simultaneously without conflicts

Select mode (1/2):
```

**STOP and wait for user response.** Do NOT proceed with any other steps until the user has selected a mode (1 or 2).

Once the user responds, store their choice and use it to determine WP-ID format throughout the rest of the process.

## Instructions

### Step 1: Validate Input
If `$ARGUMENTS` is empty, display error:
```
Error: No input provided.

Usage: /convert-planning <file-path-or-text>

Examples:
  /convert-planning requirements.txt
  /convert-planning "Build auth system with login and registration"
```

### Step 2: Read Template
Read `.ai/planning/templates/PLANNING_TEMPLATE.md` to understand the required structure.

### Step 3: Understand Input
The input can be provided in two formats:
- **File path**: User provides path to existing plan/requirements document
- **Inline text**: User pastes requirements directly as arguments

### Step 4: Parse and Structure
Extract and organize the following from the input:

1. **Project Overview**
   - Summarize the initiative in 2-3 sentences
   - Identify the core purpose and scope

2. **Goals**
   - Extract explicit goals
   - Infer implicit goals from requirements
   - Format as bulleted list

3. **Constraints**
   - Identify technical constraints
   - Identify resource/time constraints
   - Identify business constraints
   - Format as bulleted list

4. **Work Packages (Work Table)**

   **For Linear Mode (1):**
   - Break down plan into discrete work items
   - Assign sequential IDs: WP-001, WP-002, WP-003, etc.
   - Create table with: ID | Title | Outcome
   - Start numbering from WP-001 for initial build

   **For Parallel Mode (2):**
   - Analyze architecture and organize work into groups
   - Assign group IDs using format: WP-{LETTER}-{NUMBER}
     - Same letter = same work area (sequential, will conflict)
     - Different letters = different work areas (can run in parallel)
   - Create **Execution Order Summary** with header: "**Execution Order (Initial Build Only):**"
   - Add note below header: "[Note: This execution order applies to the frozen initial build work below. Post-MVP work added later follows its own sequencing.]"
   - Example: "1. **Group A** (sequential): Complete WP-A-1, then WP-A-2"
   - Example: "2. **Groups B, C, D** (parallel): After WP-A-1 completes, all can run simultaneously"
   - Create table with: ID | Title | Description (with file paths and references)

### Step 5: Quality Checks
Before saving, ensure:
- [ ] Project Overview is clear and concise
- [ ] Goals are specific and measurable
- [ ] Constraints are realistic and documented
- [ ] Work Packages are:
  - Discrete (one feature per row)
  - Sequenced logically (dependencies considered)
  - Testable (clear outcomes)
  - Sized appropriately (not too big/small)
- [ ] IDs follow chosen pattern (WP-001... for Linear OR WP-A-1... for Parallel)
- [ ] For Parallel Mode: Execution Order Summary is clear and complete
- [ ] Table formatting is correct

### Step 6: Save Output
Save the structured planning document to: `.ai/planning/prd/PLANNING.md`

**CRITICAL**: Ensure the `.ai/planning/prd/` directory exists before writing.

### Step 7: Add Frozen Section Marker
After the initial Work Table rows, add these HTML comment markers:

```markdown
<!-- FROZEN SECTION ENDS AFTER INITIAL BUILD -->
<!-- Post-MVP rows auto-added below by /generate-prp Mode 2 -->
```

### Step 8: Confirm with User
Inform the user:
- PLANNING.md has been created at `.ai/planning/prd/PLANNING.md`
- They can review the file or run `/generate-prp .ai/planning/prd/PLANNING.md` to generate PRPs

## Examples

### Example Input 1: Simple Feature List
```
Build a user authentication system with login, registration, and password reset
```

### Example Output 1 (Linear Mode):
```markdown
# PLANNING

## Project Overview
Implement a complete user authentication system supporting user registration, login, and password reset functionality.

## Goals
- Enable secure user account creation and management
- Provide standard authentication flows
- Support password recovery mechanism

## Constraints
- Must integrate with existing user database
- Must follow security best practices for password storage
- Session management must be stateless (JWT-based)

## Work Packages (Work Table)

| ID   | Title | Outcome |
|------|-------|---------|
| WP-001 | User Registration | Users can create accounts with email/password |
| WP-002 | User Login | Users can authenticate and receive session token |
| WP-003 | Password Reset | Users can request and complete password reset via email |

<!-- FROZEN SECTION ENDS AFTER INITIAL BUILD -->
<!-- Post-MVP rows auto-added below by /generate-prp Mode 2 -->
```

### Example Output 1 (Parallel Mode):
```markdown
# PLANNING

## Project Overview
Implement a complete user authentication system supporting user registration, login, and password reset functionality.

## Goals
- Enable secure user account creation and management
- Provide standard authentication flows
- Support password recovery mechanism

## Constraints
- Must integrate with existing user database
- Must follow security best practices for password storage
- Session management must be stateless (JWT-based)

## Work Packages (Work Table)

**Execution Order (Initial Build Only):**
[Note: This execution order applies to the frozen initial build work below. Post-MVP work added later follows its own sequencing.]

1. **Group A** (sequential): Complete WP-A-1, then WP-A-2
2. **Group B** (parallel): After WP-A-1 completes, WP-B-1 can run simultaneously with WP-A-2

| ID | Title | Description |
|----|-------|-------------|
| WP-A-1 | User Registration Backend | Create user model, registration API endpoint, password hashing. Files: models/user.js, routes/auth.js |
| WP-A-2 | User Login Backend | Create login API endpoint, JWT token generation. Files: routes/auth.js, middleware/auth.js |
| WP-B-1 | Password Reset Flow | Create password reset request/completion endpoints, email integration. Files: routes/auth.js, services/email.js |

<!-- FROZEN SECTION ENDS AFTER INITIAL BUILD -->
<!-- Post-MVP rows auto-added below by /generate-prp Mode 2 -->
```

### Example Input 2: Detailed Requirements Document
```
File: requirements.txt containing:
- Need API for product catalog
- Must support filtering and search
- Admin interface for product management
- Real-time inventory tracking
```

### Example Output 2 (Linear Mode):
```markdown
# PLANNING

## Project Overview
Build a product catalog management system with API access, search capabilities, administrative interface, and real-time inventory tracking.

## Goals
- Provide public API for product browsing and search
- Enable administrators to manage product catalog efficiently
- Maintain accurate real-time inventory levels
- Support advanced filtering and search functionality

## Constraints
- API must be RESTful and well-documented
- Search must respond in <200ms for typical queries
- Admin interface must be responsive and mobile-friendly
- Inventory updates must be atomic to prevent race conditions

## Work Packages (Work Table)

| ID   | Title | Outcome |
|------|-------|---------|
| WP-001 | Product API Core | RESTful API for product CRUD operations |
| WP-002 | Search & Filtering | Full-text search with faceted filtering |
| WP-003 | Admin Interface | Web UI for product management |
| WP-004 | Inventory Tracking | Real-time inventory updates and webhooks |

<!-- FROZEN SECTION ENDS AFTER INITIAL BUILD -->
<!-- Post-MVP rows auto-added below by /generate-prp Mode 2 -->
```

### Example Output 2 (Parallel Mode):
```markdown
# PLANNING

## Project Overview
Build a product catalog management system with API access, search capabilities, administrative interface, and real-time inventory tracking.

## Goals
- Provide public API for product browsing and search
- Enable administrators to manage product catalog efficiently
- Maintain accurate real-time inventory levels
- Support advanced filtering and search functionality

## Constraints
- API must be RESTful and well-documented
- Search must respond in <200ms for typical queries
- Admin interface must be responsive and mobile-friendly
- Inventory updates must be atomic to prevent race conditions

## Work Packages (Work Table)

**Execution Order (Initial Build Only):**
[Note: This execution order applies to the frozen initial build work below. Post-MVP work added later follows its own sequencing.]

1. **Group A** (sequential): Complete WP-A-1, then WP-A-2
2. **Groups B, C** (parallel): After WP-A-1 completes, both can run simultaneously
3. **Group D** (depends on all): After Groups A, B, C complete, run WP-D-1

| ID | Title | Description |
|----|-------|-------------|
| WP-A-1 | Product Database Schema | Create products table, indexes, relationships. Files: migrations/001_products.sql |
| WP-A-2 | Product API Core | RESTful CRUD endpoints for products. Files: routes/products.js, controllers/products.js |
| WP-B-1 | Search & Filtering | Implement full-text search and faceted filtering. Files: services/search.js, routes/search.js |
| WP-C-1 | Admin Interface | Build admin UI for product management. Files: admin/pages/products.vue, admin/components/* |
| WP-D-1 | Inventory Tracking System | Real-time inventory updates with webhooks. Files: services/inventory.js, websocket/inventory.js |

<!-- FROZEN SECTION ENDS AFTER INITIAL BUILD -->
<!-- Post-MVP rows auto-added below by /generate-prp Mode 2 -->
```

## Tips for Work Package Breakdown
- **Too broad**: "Build entire system" → Break into components
- **Too granular**: "Add import statement" → Merge into larger task
- **Good size**: "Implement user authentication" (1-3 days of work)
- **Dependencies**: Order tasks so earlier ones provide foundation for later ones
- **Testing**: Consider if task needs dedicated testing WP or if included in implementation

## Interactive Mode
If no arguments provided, ask structured questions:
1. "What is the main purpose of this project?"
2. "What are the key features or capabilities needed?"
3. "Are there any technical or business constraints?"
4. "What does success look like?"

Then synthesize responses into PLANNING.md format.

---

**END OF CONVERT-PLANNING COMMAND**

The instructions above apply ONLY to the `/convert-planning` command and should NOT be carried forward to any subsequent commands.
