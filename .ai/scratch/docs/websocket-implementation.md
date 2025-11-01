# WebSocket Implementation Guide - Catalytic Customer

**Purpose:** Complete reference implementation for production-grade WebSocket connections with heartbeat monitoring, graceful cleanup, and resilient reconnection.

---

## Overview

This system uses three WebSocket channels:
1. **Admin Dashboard Stream** - Real-time user updates for all connected admins
2. **Session Stream** - Push updates to active placeholder sessions
3. **Future Agent Stream** - Reserved for Beta LLM agent integration

---

## Backend Implementation (FastAPI)

### 1. Connection Management

```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import Set
import asyncio
import json

app = FastAPI()

# Store connected clients
admin_ws_clients: Set[WebSocket] = set()
session_ws_clients: dict[str, Set[WebSocket]] = {}  # {session_id: set(websockets)}
```

### 2. Admin Dashboard WebSocket

```python
@app.websocket("/admin/stream")
async def admin_stream_endpoint(websocket: WebSocket):
    """
    Admin dashboard real-time stream with:
    - OAuth session validation
    - Automatic heartbeat ping
    - Dead connection cleanup
    """
    # Validate admin session
    session_cookie = websocket.cookies.get("admin_session")
    if not validate_admin_session(session_cookie):
        await websocket.close(code=1008, reason="Unauthorized")
        return

    await websocket.accept()
    admin_ws_clients.add(websocket)

    # Send initial data
    users = await get_all_users()
    await websocket.send_json({"type": "initial", "data": users})

    # Start heartbeat task to detect dead connections
    async def heartbeat():
        """Send ping every 30 seconds to detect dead connections"""
        try:
            while True:
                await asyncio.sleep(30)
                await websocket.send_json({"type": "ping"})
        except Exception as e:
            # Connection closed, exit loop
            print(f"Heartbeat stopped: {e}")

    heartbeat_task = asyncio.create_task(heartbeat())

    try:
        while True:
            # Keep connection alive and handle client messages
            data = await websocket.receive_text()
            message = json.loads(data)

            # Client should respond with pong to pings
            if message.get("type") == "pong":
                continue  # Connection is alive

    except WebSocketDisconnect:
        print("Admin client disconnected gracefully")
    except Exception as e:
        print(f"Admin WebSocket error: {e}")
    finally:
        heartbeat_task.cancel()
        admin_ws_clients.discard(websocket)
        print(f"Admin client cleaned up. Active clients: {len(admin_ws_clients)}")
```

### 3. Session Stream WebSocket

```python
@app.websocket("/session/{session_id}/stream")
async def session_stream_endpoint(websocket: WebSocket, session_id: str):
    """
    Session-specific stream for placeholder agent with:
    - Session validation (must be active)
    - Time remaining updates
    - Expiration notifications
    """
    # Validate session exists and is active
    user = await get_user_by_id(int(session_id))
    if not user or not user.token_activated or user.session_expired:
        await websocket.close(code=1008, reason="Invalid or expired session")
        return

    await websocket.accept()

    # Add to session-specific client set
    if session_id not in session_ws_clients:
        session_ws_clients[session_id] = set()
    session_ws_clients[session_id].add(websocket)

    # Start heartbeat
    async def heartbeat():
        try:
            while True:
                await asyncio.sleep(30)
                await websocket.send_json({"type": "ping"})
        except:
            pass

    heartbeat_task = asyncio.create_task(heartbeat())

    # Send periodic time updates
    async def send_time_updates():
        try:
            while True:
                user = await get_user_by_id(int(session_id))
                if user and not user.session_expired:
                    remaining = (user.session_expires_at - datetime.now()).total_seconds()
                    if remaining > 0:
                        await websocket.send_json({
                            "type": "time_update",
                            "remaining_seconds": int(remaining)
                        })
                    else:
                        # Session expired
                        await websocket.send_json({"type": "session_expired"})
                        break
                await asyncio.sleep(10)  # Update every 10 seconds
        except:
            pass

    time_task = asyncio.create_task(send_time_updates())

    try:
        while True:
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        print(f"Session {session_id} client disconnected")
    except Exception as e:
        print(f"Session WebSocket error: {e}")
    finally:
        heartbeat_task.cancel()
        time_task.cancel()
        if session_id in session_ws_clients:
            session_ws_clients[session_id].discard(websocket)
            if not session_ws_clients[session_id]:
                del session_ws_clients[session_id]
```

### 4. Broadcast Functions

```python
async def broadcast_to_admins(message: dict):
    """
    Broadcast message to all connected admin clients with:
    - Async iteration to prevent blocking
    - Event loop yielding
    - Dead connection cleanup
    """
    data = json.dumps(message)
    dead_clients = []

    for client in admin_ws_clients:
        try:
            await client.send_text(data)
            await asyncio.sleep(0)  # Yield to event loop
        except Exception as e:
            print(f"Failed to send to admin client: {e}")
            dead_clients.append(client)

    # Clean up dead connections
    for client in dead_clients:
        admin_ws_clients.discard(client)

    if dead_clients:
        print(f"Cleaned up {len(dead_clients)} dead admin connections")


async def broadcast_to_session(session_id: str, message: dict):
    """Broadcast message to specific session clients"""
    if session_id not in session_ws_clients:
        return

    data = json.dumps(message)
    dead_clients = []

    for client in session_ws_clients[session_id]:
        try:
            await client.send_text(data)
            await asyncio.sleep(0)
        except Exception as e:
            print(f"Failed to send to session {session_id}: {e}")
            dead_clients.append(client)

    # Clean up dead connections
    for client in dead_clients:
        session_ws_clients[session_id].discard(client)

    if not session_ws_clients[session_id]:
        del session_ws_clients[session_id]
```

### 5. Helper Functions

```python
def validate_admin_session(session_cookie: str | None) -> bool:
    """Validate admin session from cookie"""
    if not session_cookie:
        return False

    # Query admin_sessions table
    session = db.query(
        "SELECT * FROM admin_sessions WHERE access_token = ? AND expires_at > ?",
        session_cookie, datetime.now()
    )
    return session is not None


async def get_all_users():
    """Get all users with derived status"""
    users = db.query("SELECT * FROM users ORDER BY created_at DESC")
    return [get_user_dict(user) for user in users]


def get_user_dict(user):
    """Convert user record to dictionary with derived status"""
    return {
        "id": user.id,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "email": user.email,
        "status": get_status(user),
        "progress": f"{user.questions_answered}/{user.questions_total}",
        "invite_url": f"https://{DOMAIN}/session?token={user.access_token}",
        "token_valid": is_token_valid(user),
        "session_timer": get_session_timer(user),
        "transcript": user.transcript_url,
        "summary": user.summary_url
    }
```

---

## Frontend Implementation (Vue 3)

### 1. Admin WebSocket Composable

```typescript
// composables/useAdminWebSocket.ts
import { ref, onMounted, onUnmounted } from 'vue';

interface User {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  status: string;
  progress: string;
  invite_url: string;
  token_valid: boolean;
  session_timer: string | null;
  transcript: string | null;
  summary: string | null;
}

export function useAdminWebSocket() {
  const users = ref<User[]>([]);
  const isConnected = ref(false);
  const error = ref<string | null>(null);

  let ws: WebSocket | null = null;
  let reconnectTimeout: number | null = null;
  let reconnectAttempts = 0;
  const maxDelay = 30000; // 30 seconds max

  // Auto-detect environment
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.host;
  const url = `${protocol}//${host}/admin/stream`;

  const connect = () => {
    try {
      ws = new WebSocket(url);

      ws.onopen = () => {
        console.log('✅ Admin WebSocket connected');
        isConnected.value = true;
        error.value = null;
        reconnectAttempts = 0; // Reset on successful connection
      };

      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);

          // Respond to ping with pong (keep connection alive)
          if (message.type === 'ping') {
            ws?.send(JSON.stringify({ type: 'pong' }));
            return;
          }

          // Handle data updates
          switch (message.type) {
            case 'initial':
              users.value = message.data;
              console.log(`📊 Loaded ${users.value.length} users`);
              break;

            case 'user_added':
              users.value.push(message.data);
              console.log(`➕ User added: ${message.data.email}`);
              break;

            case 'user_update':
              const updateIndex = users.value.findIndex(u => u.id === message.data.id);
              if (updateIndex !== -1) {
                users.value[updateIndex] = { ...users.value[updateIndex], ...message.data };
                console.log(`🔄 User updated: ${message.data.email}`);
              }
              break;

            case 'user_deleted':
              users.value = users.value.filter(u => u.id !== message.data.id);
              console.log(`🗑️ User deleted: ${message.data.id}`);
              break;

            default:
              console.warn('Unknown message type:', message.type);
          }
        } catch (err) {
          console.error('Failed to parse WebSocket message:', err);
        }
      };

      ws.onerror = (err) => {
        console.error('❌ WebSocket error:', err);
        error.value = 'Connection error';
      };

      ws.onclose = () => {
        console.log('🔌 WebSocket disconnected');
        isConnected.value = false;

        // Exponential backoff with jitter: 1s, 2s, 4s, 8s, 16s, 30s (max)
        const baseDelay = 1000 * Math.pow(2, reconnectAttempts);
        const jitter = Math.random() * 1000;
        const delay = Math.min(baseDelay + jitter, maxDelay);

        reconnectAttempts++;

        console.log(`🔄 Reconnecting in ${(delay / 1000).toFixed(1)}s (attempt ${reconnectAttempts})...`);

        reconnectTimeout = window.setTimeout(() => {
          connect();
        }, delay);
      };
    } catch (err) {
      console.error('Failed to create WebSocket:', err);
      error.value = 'Failed to connect';
    }
  };

  const disconnect = () => {
    if (reconnectTimeout) {
      clearTimeout(reconnectTimeout);
      reconnectTimeout = null;
    }

    if (ws) {
      ws.close();
      ws = null;
    }
  };

  onMounted(() => {
    console.log('🚀 Starting Admin WebSocket connection...');
    connect();
  });

  onUnmounted(() => {
    console.log('🛑 Stopping Admin WebSocket connection...');
    disconnect();
  });

  return {
    users,
    isConnected,
    error
  };
}
```

### 2. Session WebSocket Composable

```typescript
// composables/useSessionWebSocket.ts
import { ref, onMounted, onUnmounted } from 'vue';

export function useSessionWebSocket(sessionId: string) {
  const remainingSeconds = ref<number | null>(null);
  const isConnected = ref(false);
  const sessionExpired = ref(false);

  let ws: WebSocket | null = null;
  let reconnectTimeout: number | null = null;
  let reconnectAttempts = 0;
  const maxDelay = 30000;

  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.host;
  const url = `${protocol}//${host}/session/${sessionId}/stream`;

  const connect = () => {
    try {
      ws = new WebSocket(url);

      ws.onopen = () => {
        console.log('✅ Session WebSocket connected');
        isConnected.value = true;
        reconnectAttempts = 0;
      };

      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);

          if (message.type === 'ping') {
            ws?.send(JSON.stringify({ type: 'pong' }));
            return;
          }

          if (message.type === 'time_update') {
            remainingSeconds.value = message.remaining_seconds;
          } else if (message.type === 'session_expired') {
            sessionExpired.value = true;
            console.log('⏰ Session expired');
            // Redirect to expired page
            window.location.href = '/session/expired';
          }
        } catch (err) {
          console.error('Failed to parse message:', err);
        }
      };

      ws.onerror = (err) => {
        console.error('❌ Session WebSocket error:', err);
      };

      ws.onclose = () => {
        console.log('🔌 Session WebSocket disconnected');
        isConnected.value = false;

        if (!sessionExpired.value) {
          const delay = Math.min(
            1000 * Math.pow(2, reconnectAttempts) + Math.random() * 1000,
            maxDelay
          );
          reconnectAttempts++;
          reconnectTimeout = window.setTimeout(connect, delay);
        }
      };
    } catch (err) {
      console.error('Failed to create Session WebSocket:', err);
    }
  };

  const disconnect = () => {
    if (reconnectTimeout) {
      clearTimeout(reconnectTimeout);
      reconnectTimeout = null;
    }
    if (ws) {
      ws.close();
      ws = null;
    }
  };

  onMounted(connect);
  onUnmounted(disconnect);

  return {
    remainingSeconds,
    isConnected,
    sessionExpired
  };
}
```

---

## Testing

### Backend Testing

```python
# Test broadcast performance
async def test_broadcast_performance():
    # Simulate 100 concurrent admin clients
    for i in range(100):
        admin_ws_clients.add(MockWebSocket())

    start = time.time()
    await broadcast_to_admins({"type": "test", "data": "hello"})
    duration = time.time() - start

    print(f"Broadcast to 100 clients: {duration * 1000:.2f}ms")
    assert duration < 0.1  # Should complete in < 100ms
```

### Frontend Testing

```typescript
// Test reconnection logic
describe('useAdminWebSocket', () => {
  it('should reconnect with exponential backoff', async () => {
    const { isConnected } = useAdminWebSocket();

    // Simulate disconnect
    ws.close();

    // First attempt: ~1s
    await waitFor(() => expect(reconnectAttempt).toBe(1), { timeout: 2000 });

    // Second attempt: ~2s
    await waitFor(() => expect(reconnectAttempt).toBe(2), { timeout: 4000 });
  });
});
```

---

## Production Monitoring

### Key Metrics to Track

1. **Connection Count** - Active WebSocket connections
2. **Reconnection Rate** - How often clients reconnect
3. **Broadcast Latency** - Time to send message to all clients
4. **Dead Connection Cleanup** - Failed broadcast attempts

### Logging

```python
# Add structured logging
import logging

logger = logging.getLogger("websocket")

@app.websocket("/admin/stream")
async def admin_stream_endpoint(websocket: WebSocket):
    client_id = str(uuid.uuid4())
    logger.info(f"Admin client connected: {client_id}")

    try:
        # ... connection logic
        pass
    finally:
        logger.info(f"Admin client disconnected: {client_id}")
```

---

## Common Issues & Solutions

### Issue: Memory leak from unclosed connections

**Solution:** Heartbeat ping + dead connection cleanup in broadcast functions.

### Issue: Thundering herd on server restart

**Solution:** Exponential backoff with jitter prevents all clients reconnecting simultaneously.

### Issue: Event loop starvation during broadcasts

**Solution:** `await asyncio.sleep(0)` yields control between each send operation.

### Issue: Stale data after reconnection

**Solution:** Send `initial` message with full dataset on every connection.

---

**Status:** Production-ready for alpha deployment.
