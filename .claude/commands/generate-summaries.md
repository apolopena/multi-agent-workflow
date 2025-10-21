# Generate Event Summaries

You are helping generate AI summaries for hook events in the observability system.

## Your Task

1. Read the event data provided by the user
2. For each event, generate a concise one-sentence summary following these rules:
   - ONE sentence only (no period at the end)
   - Focus on the key action or information in the payload
   - Be specific and technical
   - Keep under 15 words
   - Use present tense
   - No quotes or formatting

3. Output valid JSON for each event in this format:
   ```json
   {"id": 123, "summary": "Reads configuration file from project root"}
   ```

4. After generating all summaries, use the Bash tool to POST them to the server:
   ```bash
   curl -X POST http://localhost:4000/events/batch-summaries \
     -H "Content-Type: application/json" \
     -d '{"summaries": [<array of your JSON objects>]}'
   ```

5. Confirm the update was successful

## Examples

Event Type: PreToolUse
Payload: {"tool_name": "Read", "tool_input": {"file_path": "/config/app.json"}}
Summary: "Reads configuration file from project root"

Event Type: PostToolUse
Payload: {"tool_name": "Bash", "tool_input": {"command": "npm install"}}
Summary: "Executes npm install to update dependencies"

Event Type: PreToolUse
Payload: {"tool_name": "WebSearch", "tool_input": {"query": "React hooks tutorial"}}
Summary: "Searches web for React hooks tutorial"

Event Type: PostToolUse
Payload: {"tool_name": "Edit", "tool_input": {"file_path": "/db/schema.sql"}}
Summary: "Edits database schema to add user table"

Event Type: Stop
Payload: {"session_id": "abc123"}
Summary: "Agent responds with implementation plan"
