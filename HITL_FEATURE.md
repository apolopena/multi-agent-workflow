# Human-in-the-Loop (HITL) Feature

## Overview

The Human-in-the-Loop (HITL) feature enables Claude Code agents to pause execution and request feedback, permissions, or choices from human operators through the observability dashboard in real-time.

## Use Cases

- 🔐 **Permission Requests**: Agent asks approval before executing dangerous operations
- ❓ **Questions**: Agent requests clarification on ambiguous requirements
- 🎯 **Choices**: Agent presents multiple options and waits for human selection
- 💡 **Decision Making**: Agent seeks human guidance for critical choices

## How It Works

### Data Flow

```
┌─────────────────┐
│  Claude Agent   │
│   (Hook Code)   │
└────────┬────────┘
         │ 1. Creates local WebSocket server
         │ 2. Sends HookEvent w/ HumanInTheLoop
         ▼
┌─────────────────┐
│  Observability  │
│     Server      │
└────────┬────────┘
         │ 3. Broadcasts event to clients
         ▼
┌─────────────────┐
│  Vue Client     │
│  (Dashboard)    │
└────────┬────────┘
         │ 4. Displays question UI
         │ 5. User provides response
         ▼
┌─────────────────┐
│ Response Server │
│(Agent WS URL)   │
└────────┬────────┘
         │ 6. Agent receives response
         │ 7. Agent continues execution
         ▼
┌─────────────────┐
│  Claude Agent   │
│   (Resumes)     │
└─────────────────┘
```

## Quick Start

### 1. Install Dependencies

The HITL utility requires `requests` and `websockets` packages:

```bash
# From your .claude/hooks directory
uv pip install requests websockets
```

### 2. Basic Usage Examples

#### Ask a Question

```python
from utils.hitl import ask_question

session_data = {
    "source_app": "my-app",
    "session_id": "session-123"
}

answer = ask_question(
    "What coding style should I use: functional or OOP?",
    session_data,
    timeout=60  # 60 seconds to respond
)

if answer:
    print(f"User answered: {answer}")
else:
    print("No response received")
```

#### Request Permission

```python
from utils.hitl import ask_permission

session_data = {
    "source_app": "my-app",
    "session_id": "session-123"
}

approved = ask_permission(
    "⚠️ Agent wants to execute: rm -rf /tmp/test_data\n\nAllow?",
    session_data,
    timeout=60
)

if approved:
    # Execute dangerous operation
    print("Permission granted!")
else:
    # Block the operation
    print("Permission denied!")
```

#### Present Multiple Choices

```python
from utils.hitl import ask_choice

session_data = {
    "source_app": "my-app",
    "session_id": "session-123"
}

choice = ask_choice(
    "Which testing framework should I use?",
    ["Jest", "Vitest", "Mocha", "Jasmine"],
    session_data,
    timeout=60
)

if choice:
    print(f"User selected: {choice}")
```

### 3. Integration in Hooks

Example: Using HITL in `pre_tool_use.py` hook:

```python
#!/usr/bin/env python3
import sys
import json
from utils.hitl import ask_permission

def main():
    input_data = json.loads(sys.stdin.read())

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    # Check for dangerous operations
    if tool_name == "Bash":
        command = tool_input.get("command", "")

        dangerous_keywords = ["rm -rf", "sudo", "format", "delete"]
        if any(keyword in command.lower() for keyword in dangerous_keywords):
            # Ask for human permission
            session_data = {
                "source_app": input_data.get("source_app", "unknown"),
                "session_id": input_data.get("session_id", "unknown")
            }

            question = f"⚠️ Agent wants to execute: {command}\n\nAllow?"
            approved = ask_permission(question, session_data, timeout=60)

            if not approved:
                # Block the operation
                output = {
                    "continue": False,
                    "decision": "block",
                    "reason": "User denied permission"
                }
                print(json.dumps(output))
                sys.exit(2)  # Exit code 2 = blocking error

    # Allow the operation
    output = {"continue": True, "decision": "allow"}
    print(json.dumps(output))
    sys.exit(0)

if __name__ == "__main__":
    main()
```

## Dashboard UI

### Pending Request Display

When a HITL request is active, it appears at the top of the event with:
- 🟨 **Yellow highlight** with pulsing animation
- **Question text** prominently displayed
- **Response input** based on type:
  - **Question**: Text area for free-form response
  - **Permission**: Approve ✅ / Deny ❌ buttons
  - **Choice**: Multiple choice buttons

### After Response

Once responded, the request shows:
- ✅ **Green indicator** with timestamp
- **"Show Details"** button to view the response
- Full response preserved in event history

## API Reference

### Python Utilities

#### `ask_question(question, session_data, timeout=300)`

Ask a free-form question and wait for text response.

**Parameters:**
- `question` (str): The question to ask
- `session_data` (dict): Session info with `source_app` and `session_id`
- `timeout` (int): Seconds to wait for response (default: 300)

**Returns:** `str | None` - User's response text or None if timeout

---

#### `ask_permission(question, session_data, timeout=300)`

Request yes/no permission from user.

**Parameters:**
- `question` (str): Permission request message
- `session_data` (dict): Session info
- `timeout` (int): Seconds to wait (default: 300)

**Returns:** `bool` - True if approved, False if denied or timeout

---

#### `ask_choice(question, choices, session_data, timeout=300)`

Present multiple choice options to user.

**Parameters:**
- `question` (str): The question/prompt
- `choices` (list[str]): List of options to choose from
- `session_data` (dict): Session info
- `timeout` (int): Seconds to wait (default: 300)

**Returns:** `str | None` - Selected choice or None if timeout

---

### Advanced Usage: HITLRequest Class

For more control, use the `HITLRequest` class directly:

```python
from utils.hitl import HITLRequest

# Create request
hitl = HITLRequest(
    question="What should I do?",
    hitl_type='choice',  # 'question', 'permission', or 'choice'
    choices=["Option A", "Option B"],
    timeout=120,
    observability_url="http://localhost:4000"
)

# Send and wait for response
response = hitl.send_and_wait(
    hook_event_data={"hook_event_type": "HumanInTheLoop", "payload": {}},
    session_data={"source_app": "my-app", "session_id": "session-123"}
)

if response:
    print(f"Response received: {response}")
```

## Type Definitions

### TypeScript/Server Types

```typescript
interface HumanInTheLoop {
  question: string;
  responseWebSocketUrl: string;
  type: 'question' | 'permission' | 'choice';
  choices?: string[];
  timeout?: number;
  requiresResponse?: boolean;
}

interface HumanInTheLoopResponse {
  response?: string;
  permission?: boolean;
  choice?: string;
  hookEvent: HookEvent;
  respondedAt: number;
  respondedBy?: string;
}

interface HumanInTheLoopStatus {
  status: 'pending' | 'responded' | 'timeout' | 'error';
  respondedAt?: number;
  response?: HumanInTheLoopResponse;
}
```

## Example Scenarios

### Scenario 1: Dangerous Command Validation

```python
# In pre_tool_use.py
permission = ask_permission(
    "Agent wants to run: rm -rf /tmp/*\nAllow?",
    session_data
)
if not permission:
    block_tool_use()
```

### Scenario 2: Code Style Decision

```python
# In custom hook
response = ask_question(
    "Should this refactoring use async/await or promises?",
    session_data
)
# Agent uses response to make architectural decision
```

### Scenario 3: Framework Selection

```python
# In custom hook
choice = ask_choice(
    "Which testing framework should I use?",
    ["Jest", "Vitest", "Mocha", "Jasmine"],
    session_data
)
# Agent proceeds with selected framework
```

## Testing

Run the included example script to test all HITL request types:

```bash
# Make sure server and client are running
./scripts/observability-start.sh

# Run the example
uv run .claude/hooks/examples/hitl_example.py
```

This will demonstrate:
1. Question with free-form text response
2. Permission request with approve/deny
3. Multiple choice selection

## Troubleshooting

### WebSocket Connection Fails

**Problem**: Agent can't establish WebSocket server for receiving responses.

**Solutions**:
- Ensure `websockets` package is installed: `uv pip install websockets`
- Check firewall settings allow local WebSocket connections
- Verify no other service is using the assigned port

### Response Never Received

**Problem**: Agent waits but doesn't receive response.

**Solutions**:
- Verify observability server is running (`http://localhost:4000`)
- Check dashboard is open (`http://localhost:5173`)
- Increase timeout value if response takes longer
- Check browser console for errors

### Request Not Appearing in Dashboard

**Problem**: HITL request doesn't show in the UI.

**Solutions**:
- Verify event was sent to server (check server logs)
- Refresh the dashboard
- Check WebSocket connection is active (check browser dev tools)
- Ensure `humanInTheLoop` field is properly structured

## Best Practices

1. **Set Appropriate Timeouts**: Default is 5 minutes, adjust based on expected response time
2. **Provide Clear Questions**: Be specific and concise in your questions
3. **Handle Timeouts Gracefully**: Always have a fallback when timeout occurs
4. **Use Descriptive Session IDs**: Helps with debugging and tracking
5. **Test in Development**: Always test HITL flow before deploying to production

## Security Considerations

- HITL requests create temporary WebSocket servers on random ports
- All WebSocket connections are localhost-only
- Responses are not authenticated (add authentication if needed)
- Questions are stored in the database (don't include sensitive data)

## Future Enhancements

Planned improvements:
- 📸 Rich media questions (images, code snippets, diffs)
- 🔁 Multi-step conversational workflows
- 📊 Response history and analytics
- ⚡ Priority levels and urgent requests
- 👥 Multi-user collaboration on requests
- 🔔 Advanced notification options

## Related Documentation

- [Implementation Plan](specs/human-in-the-loop-feedback.md) - Detailed technical specification
- [Hook System Documentation](https://docs.claude.com/en/docs/claude-code/hooks) - Claude Code hooks guide
- [Main README](README.md) - Project overview and setup
