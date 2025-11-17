---
description: Generate .ai/scratch/arch-primer.md with codebase architecture overview
---

Read codebase structure and create/update `.ai/scratch/arch-primer.md`.

## CRITICAL LIMITS
- **≤200 lines TOTAL** (not per section, TOTAL file length)
- **Fast execution** - target <10 seconds
- **Minimal file reads** - focus on key structural files only

## Output Format (≤200 LINES TOTAL)

```markdown
# Architecture

## Stack
<One line describing the tech stack>

## Structure
- <key directories and their purpose>
- <scripts and tools>
- <configuration locations>
- <documentation locations>

## Core Patterns
- <Key architectural patterns>
- <Coding conventions>
- <Workflow patterns>
- <Security practices>

## Adding Features
**<Feature Type>:** <step> → <step> → <step>
**<Another Type>:** <step> → <step> → <step>
```

## Rules

- File path: `.ai/scratch/arch-primer.md`
- Always overwrite file
- **HARD LIMIT: ≤200 lines** - if you exceed this, you're doing it wrong
- Bullet points only, no prose paragraphs
- Focus on "how things work" not exhaustive listings
