---
name: agent-builder
description: Build Claude Code subagents with proper formatting, tools, workflow, and testing. Use when user asks to create a new agent or modify existing agent definitions.
---

# Agent Builder Skill

Build well-structured Claude Code subagents following established patterns and best practices.

## When to Use

- User wants to create a new subagent
- User wants to modify or improve an existing agent
- User asks to standardize agent formatting
- User wants to test agent functionality

## Agent File Structure

Agents are stored in `.claude/agents/` as Markdown files with YAML frontmatter:

```yaml
---
name: AgentName
description: "Brief description. **AUTO-DISPATCH**: Trigger phrase."
tools: Bash(git log), Read(CHANGELOG.md), Edit(CHANGELOG.md)
model: haiku
color: blue
---
```

## Frontmatter Fields

**name:** Agent identifier (used for dispatch)
**description:** What agent does + auto-dispatch trigger phrase
**tools:** Restricted tool list with specific commands/files in parentheses
**model:** `haiku` (fast/cheap) or `sonnet` (complex tasks)
**color:** Visual identifier in UI

## Tool Restrictions

**Principle of least privilege** - only grant necessary tools:

```yaml
# Good - specific restrictions
tools: Bash(git log), Bash(git show), Read(CHANGELOG.md), Edit(CHANGELOG.md)

# Bad - too broad
tools: Bash, Read, Edit

# Good - specific bash commands only
tools: Bash(./scripts/observability-start.sh), Bash(./scripts/observability-stop.sh)
```

## Agent Prompt Structure

```markdown
You are **AgentName**, the [Role]. **[Core instruction].**

## [Section Name]

Brief, actionable instructions.

## Workflow

1. **Step name:**
   - Bullet points
   - Concrete actions

2. **Next step:**
   - More bullets

## Examples

**Good example:**
[Show concrete example]

## Important

- Critical rules
- Key constraints
- Error handling
```

## Writing Style

**Concise and directive:**
- Use imperative mood: "Run script" not "You should run"
- Short paragraphs and bullet points
- Concrete examples over abstract explanations
- Clear workflow steps

**Avoid:**
- Long explanations
- Verbose descriptions
- Unnecessary context
- Signatures at end (no `- AgentName`)

## Agent Building Process

### 1. Research Existing Agents

Read existing agents to understand patterns:

```bash
ls .claude/agents/
```

Look at similar agents for style reference.

### 2. Define Agent Scope

- What is the agent's single responsibility?
- What triggers should auto-dispatch it?
- What tools does it minimally need?
- Which model (haiku vs sonnet)?

### 3. Write Frontmatter

```yaml
---
name: pedro
description: "Maintains CHANGELOG.md. **AUTO-DISPATCH**: When user says 'update changelog'."
tools: Bash(git log), Read(CHANGELOG.md), Edit(CHANGELOG.md)
model: haiku
color: blue
---
```

### 4. Write Core Instruction

Single sentence describing what the agent does:

```markdown
You are **Pedro**, the CHANGELOG Manager. **Update CHANGELOG.md following the approved format.**
```

### 5. Document Format/Rules

Show exact format with examples:

```markdown
## Format

```markdown
- [[hash](url)] **TYPE:** *subtype*
  - Description
```
```

### 6. Define Workflow

Step-by-step process:

```markdown
## Workflow

1. **Read context:**
   - Read existing file for style reference
   - Gather required information

2. **Process data:**
   - Extract information
   - Categorize and format

3. **Update file:**
   - Use Edit tool
   - Report success
```

### 7. Add Examples

Concrete examples showing good output:

```markdown
## Examples

**Good entry:**
[exact example]
```

### 8. List Important Rules

Critical constraints and error handling:

```markdown
## Important

- Critical rule 1
- Critical rule 2

## Error Handling

**If X fails:**
- Action to take
- Fallback behavior
```

### 9. Test Agent

Create test file to verify agent works correctly:

1. Restart Claude Code to load agent
2. Dispatch agent with test task
3. Verify output matches expectations
4. Refine prompt if needed

## Testing Pattern

When testing agents:

1. **Create test output** to separate file
2. **Compare with expected** format
3. **Iterate prompt** to match style
4. **Add constraints** like "DO NOT copy" or "match existing style"

## Example: Building Pedro

**Goal:** Agent to maintain CHANGELOG.md

**Process:**
1. Checked existing agents (Jerry, Kim) for style
2. Defined scope: Update changelog only
3. Restricted tools to git commands and CHANGELOG.md
4. Chose haiku for speed
5. Wrote concise workflow
6. Added format examples
7. Tested with example file
8. Found it was too verbose
9. Added "match existing style" constraint
10. Retested - success!

## Common Patterns

**Read-only agents:**
```yaml
tools: Bash(git log), Read(file.md)
```

**Update agents:**
```yaml
tools: Bash(git log), Read(file.md), Edit(file.md)
```

**Script runners:**
```yaml
tools: Bash(./scripts/specific-script.sh)
```

**GitHub read-only exception:**
```yaml
tools: Bash(gh release view)
# Note: Document exception in CLAUDE.md
```

## Agent Naming

- **name:** lowercase, no spaces
- **Color:** Choose unique color for visual distinction
- **Description:** Include auto-dispatch trigger

## Integration with CLAUDE.md

Document special cases in project `CLAUDE.md`:

```markdown
### Agent Protocols

**AgentName:** Handles X operations
- Restricted to Y tools
- Exception: Can use Z for read-only access
```

## Success Criteria

Agent is ready when:
- ✅ Frontmatter is valid YAML
- ✅ Tools follow least privilege
- ✅ Prompt is concise and clear
- ✅ Workflow has concrete steps
- ✅ Examples show expected output
- ✅ Testing produces correct results
- ✅ No extraneous content (signatures, verbose explanations)
