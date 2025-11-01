# Catalytic Customer - Alpha Implementation

**Version:** 1.1
**Last Updated:** 2025-10-31

---

## Project Overview

Catalytic Customer is an invitation-based session management system designed for conducting timed customer research sessions. The alpha implementation provides complete infrastructure including landing page registration, email invitation system with 30-day token expiry, 1-hour timed sessions with real-time monitoring, admin dashboard with WebSocket updates, and modular placeholder session interface.

The system uses a modern containerized architecture: FastAPI backend (Python 3.11+), multiple Vue.js 3 frontend applications in monorepo pattern, SQLite with WAL mode for data persistence, Caddy 2 as reverse proxy with TLS and authentication, and Docker Compose orchestration. The architecture is explicitly designed for clean transition from alpha placeholder test form to beta production LLM agent without touching core infrastructure.

**Target Users:** Three categories - end users (research participants), administrators (Apolo, Paul, Curtis), and future beta integration with LLM agent systems.

**Core Value:** Enable controlled, timed research sessions with invitation management, progress tracking, and real-time administrative oversight.

---

## Goals

- Deploy working alpha prototype with complete user flow (registration → invitation → session → completion)
- Validate token lifecycle (30-day expiry, one-time use) and session timing mechanisms (1-hour expiry)
- Establish real-time admin dashboard with WebSocket updates for monitoring active sessions
- Create modular architecture allowing clean swap of placeholder test form for real LLM agent in beta
- Maintain clean separation between production-ready components (🟢 REAL) and alpha placeholders (🟡 PLACEHOLDER)
- Test email deliverability and OAuth integration in production-like environment
- Validate database persistence, backup procedures, and WAL mode concurrency

---

## Constraints

- **Alpha scope only:** Placeholder test form with manual progress control instead of real LLM conversation interface
- **Technology stack:** FastAPI (Python 3.11+), Vue.js 3, SQLite with WAL mode, Caddy 2, Docker Compose
- **Email system:** Gmail SMTP for alpha (requires SPF/DKIM configuration before production launch - see Email Deliverability Checklist)
- **Concurrency:** No optimistic locking (acceptable for 3 simultaneous admins in alpha)
- **Session duration:** 1-hour sessions (configurable via environment variable for testing)
- **Authentication:** Google OAuth for admin dashboard + Caddy basic auth (double-layer protection)
- **No agent dependencies:** Neo4j, Open WebUI, agent-specific dependencies are beta-only (not implemented)

---

## Scope

### ✅ In Scope (Alpha Implementation)

**User Registration & Invitation System (🟢 REAL)**
- Landing page with registration form (first name, last name, email required)
- Email invitation delivery via FastAPI-Mail with hardcoded template
- Token generation using `secrets.token_urlsafe(32)` with 30-day expiry
- Duplicate email detection with 5-minute cooldown to prevent spam
- Success/error pages for all flow states

**Session Management (🟢 REAL + 🟡 PLACEHOLDER)**
- Token validation and activation (one-time use)
- Session timing (1-hour countdown from activation)
- Real-time expiration monitoring and enforcement
- Progress tracking (questions_answered / questions_total)
- Placeholder completion flow with hardcoded summary and transcript text (🟡 PLACEHOLDER)

**Admin Dashboard (🟢 REAL)**
- Google OAuth authentication with session management
- Caddy basic auth (three admin users: Apolo, Paul, Curtis)
- Read-only data table with derived status (Invited, Active, Incomplete, Completed)
- Real-time updates via WebSocket (user_added, user_update, user_deleted events)
- Admin actions: Add User (manual URL copy), Delete User (all statuses), Reissue Invite (Incomplete/Completed only)
- Connection status indicators and toast notifications

**Infrastructure (🟢 REAL)**
- Docker Compose multi-container setup (single network)
- Caddy reverse proxy with TLS auto-provisioning and path-based routing
- Environment-aware configuration (.env.dev, .env.prod, .env.example committed)
- SQLite database with WAL mode enabled for better concurrency
- Modular placeholder stack (docker-compose.placeholder.yml) for clean beta transition
- Backup script using SQLite `.backup` command

**WebSocket Real-Time Communication (🟢 REAL)**
- Admin dashboard stream (`/admin/stream`) with broadcast to all connected admins
- Session stream (`/session/{id}/stream`) for time updates and expiration notices
- Heartbeat/ping mechanism (30-second intervals) for connection health
- Exponential backoff reconnection with jitter (1s → 2s → 4s → 8s → 16s → 30s max)
- Async broadcast protection to prevent blocking

### ❌ Not in Scope (Beta Only - Do Not Implement)

- Real LLM conversation interface
- AI-generated summaries from actual conversations
- AI-generated transcripts from actual conversations
- Open WebUI or agent application integration
- Neo4j or other agent-specific dependencies
- Modal/notification reminders triggered by LLM
- Automatic email sending from admin dashboard (manual copy/paste URL only in alpha)
- Resend email button for Invited users
- Advanced filtering/search in admin dashboard
- Export user data (CSV/JSON)
- User session replay/transcript viewer
- Analytics dashboard (conversion rates, completion rates)

---

## Detailed Specifications

### Database Schema

**Complete SQLite Schema with WAL Mode:**

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,

  -- Token Management
  access_token TEXT UNIQUE,
  token_issued_at DATETIME,
  token_expires_at DATETIME,        -- 30 days from issued_at

  -- Session Timing
  session_started_at DATETIME,      -- When link clicked (NULL until activated)
  session_expires_at DATETIME,      -- 1 hour from started_at (NULL until activated)

  -- State Flags (Booleans)
  token_activated BOOLEAN DEFAULT 0,  -- Has user clicked invite link?
  session_expired BOOLEAN DEFAULT 0,  -- Has 1-hour session timer expired?

  -- Progress Tracking
  questions_answered INTEGER DEFAULT 0,
  questions_total INTEGER DEFAULT 10,

  -- Results (TEXT fields, not URLs - Alpha stores placeholder text)
  transcript_url TEXT,              -- Placeholder: "Q1: Test\nA1: Test..."
  summary_url TEXT,                 -- Placeholder: "User completed 10 questions"

  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE conversation (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER REFERENCES users(id),
  message_type TEXT CHECK(message_type IN ('user', 'assistant')),
  content TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admin_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  google_user_id TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  expires_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_users_token ON users(access_token);
CREATE INDEX idx_users_email ON users(email);

-- Enable WAL mode for better concurrency
PRAGMA journal_mode=WAL;
```

**Status Derivation Logic (Not Stored):**

```python
def get_status(user):
    """Derive status from database fields - NOT stored in DB"""
    if user.questions_answered == user.questions_total:
        return "Completed"
    elif not user.token_activated:
        return "Invited"
    elif user.token_activated and not user.session_expired:
        return "Active"
    else:  # session_expired and questions_answered < questions_total
        return "Incomplete"
```

**Four Status Values:**

| Status | Meaning | Admin Actions |
|--------|---------|---------------|
| **Invited** | Token sent, not clicked yet | Resend email (future), Delete |
| **Active** | Session in progress (within 1-hour window) | None (let them finish) |
| **Incomplete** | Session expired before finishing | Reissue Invite, Delete |
| **Completed** | Answered all questions | Reissue Invite (for new session), Delete |

---

### API Endpoints

#### Public Endpoints (Open Access)

**POST /api/register**
```python
# Request body
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com"
}

# Validation logic
existing_user = db.query("SELECT * FROM users WHERE email = ?", email)

if existing_user:
    if existing_user.token_activated:
        # User already participated
        return redirect("/error/already-used")

    # Check cooldown (5 minutes)
    if (now() - existing_user.token_issued_at) < timedelta(minutes=5):
        return redirect("/error/cooldown")

    # Valid unactivated token exists - resend email
    if now() < existing_user.token_expires_at:
        send_invite_email(existing_user.email, existing_user.access_token)
        return redirect("/success")

# Create new user
token = secrets.token_urlsafe(32)
db.execute("""
    INSERT INTO users (first_name, last_name, email, access_token,
                       token_issued_at, token_expires_at)
    VALUES (?, ?, ?, ?, ?, ?)
""", first_name, last_name, email, token, now(), now() + timedelta(days=30))

send_invite_email(email, token)
return redirect("/success")
```

**GET /session?token={token}**
```python
# Session activation endpoint
user = db.query("SELECT * FROM users WHERE access_token = ?", token)

if not user:
    return redirect("/session/invalid")

if now() > user.token_expires_at:
    return redirect("/session/invalid")  # Token expired (30 days passed)

if user.token_activated:
    return redirect("/session/invalid")  # Already used (one-time token)

# Activate session
db.execute("""
    UPDATE users
    SET token_activated = ?, session_started_at = ?, session_expires_at = ?
    WHERE id = ?
""", True, now(), now() + timedelta(hours=1), user.id)

# Broadcast to admin dashboard via WebSocket
broadcast_to_admins({
    "type": "user_update",
    "data": get_user_dict(user.id)
})

# Redirect to placeholder test form
return redirect(f"/session/test?session_id={user.id}")
```

**GET /api/session/{id}**
```python
# Get session data (for placeholder interface)
# Returns: user object with all fields, computed status, remaining time

def check_session_expiry(user):
    if user.token_activated and now() > user.session_expires_at:
        if not user.session_expired:
            db.execute("UPDATE users SET session_expired = ? WHERE id = ?", True, user.id)

            # Notify placeholder via WebSocket
            broadcast_to_session(user.id, {"type": "session_expired"})

            # Notify admin dashboard
            broadcast_to_admins({
                "type": "user_update",
                "data": get_user_dict(user.id)
            })

        raise HTTPException(403, "Session expired")
```

**POST /api/session/{id}/progress**
```python
# Update questions_answered (placeholder test form)
# Request body: { "questions_answered": 5 }

@app.post("/api/session/{id}/progress")
async def update_progress(id: int, data: dict):
    user = get_user_by_id(id)

    # Check session not expired
    if now() > user.session_expires_at:
        db.execute("UPDATE users SET session_expired = ? WHERE id = ?", True, id)
        raise HTTPException(403, "Session expired")

    # Update progress
    db.execute(
        "UPDATE users SET questions_answered = ? WHERE id = ?",
        data["questions_answered"], id
    )

    # Check if complete
    if data["questions_answered"] == user.questions_total:
        # Generate PLACEHOLDER content
        summary = "Placeholder summary: User completed 10 questions in alpha test."
        transcript = """Placeholder transcript:
Q1: Test question 1
A1: Test answer 1
Q2: Test question 2
A2: Test answer 2
Q3: Test question 3
A3: Test answer 3
Q4: Test question 4
A4: Test answer 4
Q5: Test question 5
A5: Test answer 5
Q6: Test question 6
A6: Test answer 6
Q7: Test question 7
A7: Test answer 7
Q8: Test question 8
A8: Test answer 8
Q9: Test question 9
A9: Test answer 9
Q10: Test question 10
A10: Test answer 10"""

        # Store in database and force expire session
        db.execute("""
            UPDATE users
            SET transcript_url = ?, summary_url = ?, session_expired = ?
            WHERE id = ?
        """, transcript, summary, True, id)

        # Broadcast completion to admins
        broadcast_to_admins({
            "type": "user_update",
            "data": get_user_dict(id)
        })

        return {"completed": True, "redirect": "/session/complete"}

    # Not complete yet, broadcast progress update
    broadcast_to_admins({
        "type": "user_update",
        "data": get_user_dict(id)
    })

    return {"completed": False}
```

#### Admin Endpoints (OAuth + Basic Auth Required)

**POST /api/admin/users**
```python
# Add new user from admin dashboard
# Request body: { "first_name": "Jane", "last_name": "Smith", "email": "jane@example.com" }

@app.post("/api/admin/users")
async def add_user(data: dict):
    # Check if email already exists
    existing = db.query("SELECT * FROM users WHERE email = ?", data["email"])
    if existing:
        raise HTTPException(400, "Email already exists")

    # Generate token
    token = secrets.token_urlsafe(32)

    # Create user
    db.execute("""
        INSERT INTO users (first_name, last_name, email, access_token,
                           token_issued_at, token_expires_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, data["first_name"], data["last_name"], data["email"],
         token, now(), now() + timedelta(days=30))

    # Get new user ID
    user_id = db.lastrowid

    # Generate invite URL
    invite_url = f"https://{DOMAIN}/session?token={token}"

    # Broadcast to all admins
    broadcast_to_admins({
        "type": "user_added",
        "data": get_user_dict(user_id)
    })

    # Return URL for admin to copy (no automatic email sent)
    return {
        "success": True,
        "invite_url": invite_url,
        "user_id": user_id
    }
```

**DELETE /api/admin/users/{id}**
```python
# Delete user (available for all statuses)

@app.delete("/api/admin/users/{id}")
async def delete_user(id: int):
    # Delete user and related data
    db.execute("DELETE FROM conversation WHERE user_id = ?", id)
    db.execute("DELETE FROM users WHERE id = ?", id)

    # Broadcast deletion to all admins
    broadcast_to_admins({
        "type": "user_deleted",
        "data": {"id": id}
    })

    return {"success": True}
```

**POST /api/admin/users/{id}/reissue**
```python
# Reissue invite (enabled for Incomplete and Completed statuses only)

@app.post("/api/admin/users/{id}/reissue")
async def reissue_invite(id: int):
    user = get_user_by_id(id)

    # Validate user can be reissued
    if not user.token_activated:
        raise HTTPException(400, "User hasn't used first invite yet")

    if not user.session_expired:
        raise HTTPException(400, "Session still active")

    # Generate new token
    new_token = secrets.token_urlsafe(32)

    # Reset user state
    db.execute("""
        UPDATE users
        SET access_token = ?,
            token_issued_at = ?,
            token_expires_at = ?,
            token_activated = ?,
            session_expired = ?,
            questions_answered = ?,
            session_started_at = NULL,
            session_expires_at = NULL,
            transcript_url = NULL,
            summary_url = NULL
        WHERE id = ?
    """, new_token, now(), now() + timedelta(days=30),
         False, False, 0, id)

    # Generate new invite URL
    invite_url = f"https://{DOMAIN}/session?token={new_token}"

    # Broadcast update to all admins
    broadcast_to_admins({
        "type": "user_update",
        "data": get_user_dict(id)
    })

    return {
        "success": True,
        "invite_url": invite_url
    }
```

#### Auth Endpoints

**GET /api/auth/login**
```python
# Redirect to Google OAuth consent screen
google_auth_url = f"https://accounts.google.com/o/oauth2/v2/auth?client_id={GOOGLE_CLIENT_ID}&redirect_uri={GOOGLE_REDIRECT_URI}&response_type=code&scope=openid%20email%20profile"
return RedirectResponse(google_auth_url)
```

**GET /api/auth/callback**
```python
# Handle OAuth callback, exchange code for tokens, create admin session
# Returns: Session cookie and redirects to /admin
```

---

### WebSocket Architecture

#### Three WebSocket Channels

**Channel 1: Admin Dashboard Stream**
- **Endpoint:** `ws://backend:8000/admin/stream`
- **Purpose:** Real-time updates of all user changes
- **Authentication:** Requires valid OAuth session (checked on upgrade)
- **Messages Sent:**
  - `{ "type": "initial", "data": [all users] }` (on connect)
  - `{ "type": "user_added", "data": {user} }`
  - `{ "type": "user_update", "data": {user} }`
  - `{ "type": "user_deleted", "data": {id} }`
  - `{ "type": "ping" }` (heartbeat every 30 seconds)
- **Messages Received:**
  - `{ "type": "pong" }` (heartbeat response)

**Channel 2: Session Stream (Placeholder)**
- **Endpoint:** `ws://backend:8000/session/{session_id}/stream`
- **Purpose:** Push updates to active placeholder session
- **Authentication:** Validates session_id exists and is Active
- **Messages Sent:**
  - `{ "type": "time_update", "remaining_seconds": 2843 }`
  - `{ "type": "session_expired" }`
  - `{ "type": "ping" }` (heartbeat every 30 seconds)
- **Messages Received:**
  - `{ "type": "pong" }` (heartbeat response)

**Channel 3: (Future) Real Agent Stream (Beta Reference)**
- Same pattern as Channel 2
- Additional messages for LLM interactions

#### Backend WebSocket Implementation

**Admin Stream:**
```python
admin_ws_clients = set()

@app.websocket("/admin/stream")
async def admin_stream(websocket: WebSocket):
    # Check OAuth session
    session_cookie = websocket.cookies.get("admin_session")
    if not validate_admin_session(session_cookie):
        await websocket.close(code=1008)
        return

    await websocket.accept()
    admin_ws_clients.add(websocket)

    # Send initial data
    users = get_all_users()
    await websocket.send_json({"type": "initial", "data": users})

    # Start heartbeat task
    async def heartbeat():
        try:
            while True:
                await asyncio.sleep(30)  # Ping every 30 seconds
                await websocket.send_json({"type": "ping"})
        except:
            pass  # Connection closed, exit loop

    heartbeat_task = asyncio.create_task(heartbeat())

    try:
        while True:
            data = await websocket.receive_text()  # Receive pongs
    except:
        pass
    finally:
        heartbeat_task.cancel()
        admin_ws_clients.discard(websocket)

async def broadcast_to_admins(message: dict):
    """Broadcast message to all connected admin clients"""
    data = json.dumps(message)
    dead_clients = []

    for client in admin_ws_clients:
        try:
            await client.send_text(data)
            await asyncio.sleep(0)  # Yield to event loop (async broadcast protection)
        except Exception as e:
            dead_clients.append(client)

    # Clean up dead connections
    for client in dead_clients:
        admin_ws_clients.discard(client)
```

**Session Stream:**
```python
session_ws_clients = {}  # {session_id: set(websockets)}

@app.websocket("/session/{session_id}/stream")
async def session_stream(websocket: WebSocket, session_id: str):
    # Validate session exists and is active
    user = get_user_by_id(int(session_id))
    if not user or not user.token_activated or user.session_expired:
        await websocket.close(code=1008)
        return

    await websocket.accept()

    if session_id not in session_ws_clients:
        session_ws_clients[session_id] = set()
    session_ws_clients[session_id].add(websocket)

    # Start heartbeat task
    async def heartbeat():
        try:
            while True:
                await asyncio.sleep(30)
                await websocket.send_json({"type": "ping"})
        except:
            pass

    heartbeat_task = asyncio.create_task(heartbeat())

    try:
        while True:
            await websocket.receive_text()
    except:
        pass
    finally:
        heartbeat_task.cancel()
        session_ws_clients[session_id].discard(websocket)
```

#### Frontend WebSocket Implementation

**Admin Dashboard Composable:**
```typescript
// composables/useAdminWebSocket.ts
import { ref, onMounted, onUnmounted } from 'vue';

export function useAdminWebSocket() {
  const users = ref<any[]>([]);
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
        console.log('WebSocket connected');
        isConnected.value = true;
        error.value = null;
        reconnectAttempts = 0; // Reset on successful connection
      };

      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);

          // Respond to ping with pong
          if (message.type === 'ping') {
            ws.send(JSON.stringify({ type: 'pong' }));
            return;
          }

          if (message.type === 'initial') {
            users.value = message.data;
          } else if (message.type === 'user_added') {
            users.value.push(message.data);
          } else if (message.type === 'user_update') {
            const index = users.value.findIndex(u => u.id === message.data.id);
            if (index !== -1) {
              users.value[index] = { ...users.value[index], ...message.data };
            }
          } else if (message.type === 'user_deleted') {
            users.value = users.value.filter(u => u.id !== message.data.id);
          }
        } catch (err) {
          console.error('Failed to parse message:', err);
        }
      };

      ws.onerror = (err) => {
        console.error('WebSocket error:', err);
        error.value = 'Connection error';
      };

      ws.onclose = () => {
        console.log('WebSocket disconnected');
        isConnected.value = false;

        // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (max)
        const delay = Math.min(
          1000 * Math.pow(2, reconnectAttempts) + Math.random() * 1000, // Add jitter
          maxDelay
        );

        reconnectAttempts++;

        reconnectTimeout = window.setTimeout(() => {
          console.log(`Reconnecting (attempt ${reconnectAttempts})...`);
          connect();
        }, delay);
      };
    } catch (err) {
      console.error('Failed to connect:', err);
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
    connect();
  });

  onUnmounted(() => {
    disconnect();
  });

  return {
    users,
    isConnected,
    error
  };
}
```

**Environment Auto-Detection:**
Uses `window.location` for environment-aware WebSocket URLs - works in both dev and prod without config:
- Dev: `ws://localhost:8000/admin/stream`
- Prod: `wss://catalytic.learnstream.tech/admin/stream`

---

### Component Structure

```
catalytic-customer/
├── docker-compose.yml              # 🟢 Main stack
├── docker-compose.placeholder.yml  # 🟡 Alpha placeholder stack
├── Caddyfile                       # 🟢 Reverse proxy config
├── .env.dev                        # 🟢 Dev environment
├── .env.prod                       # 🟢 Prod environment
├── .env.example                    # 🟢 Template (committed)
├── .gitignore                      # 🟢
├── README.md                       # 🟢
│
├── backend/                        # 🟢 REAL - Main backend
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py
│   ├── config.py
│   ├── models.py
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── public.py       # User registration, email sending
│   │   ├── session.py      # Session APIs (progress, data)
│   │   ├── admin.py        # Admin CRUD (add, delete, reissue)
│   │   └── auth.py         # Google OAuth flow
│   ├── services/
│   │   ├── __init__.py
│   │   ├── email.py        # FastAPI-Mail wrapper
│   │   ├── tokens.py       # Token generation/validation
│   │   ├── db.py           # SQLite operations
│   │   └── websocket.py    # Broadcast helpers
│   └── websockets/
│       ├── __init__.py
│       ├── admin_stream.py      # Admin dashboard WebSocket
│       └── session_stream.py    # Session WebSocket
│
├── frontend-public/                # 🟢 REAL - Public frontend
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── App.vue
│       ├── main.js
│       ├── router.js
│       ├── views/
│       │   ├── Landing.vue           # 🟢 REAL - Registration form
│       │   ├── Success.vue           # 🟢 REAL - "Check your email"
│       │   ├── ErrorAlreadyUsed.vue  # 🟢 REAL - "Already participated"
│       │   └── ErrorCooldown.vue     # 🟢 REAL - "Link already sent"
│       └── components/
│           └── RegistrationForm.vue  # 🟢 REAL - Form component
│
├── frontend-admin/                 # 🟢 REAL - Admin dashboard
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── App.vue
│       ├── main.js
│       ├── router.js
│       ├── views/
│       │   ├── Login.vue             # 🟢 REAL - OAuth login
│       │   └── AdminDashboard.vue    # 🟢 REAL - Main dashboard
│       ├── components/
│       │   ├── UserTable.vue         # 🟢 REAL - Data table
│       │   ├── AddUserModal.vue      # 🟢 REAL - Add user form
│       │   ├── ReissueModal.vue      # 🟢 REAL - Shows new URL
│       │   ├── ConfirmDialog.vue     # 🟢 REAL - Delete confirmation
│       │   ├── ToastNotification.vue # 🟢 REAL - Real-time toasts
│       │   └── ConnectionStatus.vue  # 🟢 REAL - WebSocket indicator
│       └── composables/
│           ├── useAdminWebSocket.ts  # 🟢 REAL - Admin WS connection
│           └── useAuth.ts            # 🟢 REAL - OAuth state
│
├── placeholder-agent/              # 🟡 PLACEHOLDER (Alpha Only)
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── App.vue
│       ├── main.js
│       ├── router.js
│       ├── views/
│       │   ├── SessionTestForm.vue   # 🟡 PLACEHOLDER - Test form
│       │   ├── ThankYou.vue          # 🟡 PLACEHOLDER - Completion
│       │   ├── SessionExpired.vue    # 🟡 PLACEHOLDER - Expired
│       │   └── InvalidToken.vue      # 🟡 PLACEHOLDER - Invalid
│       ├── components/
│       │   ├── TestControlPanel.vue  # 🟡 PLACEHOLDER - Progress form
│       │   └── SessionTimer.vue      # 🟡 PLACEHOLDER - Countdown
│       └── composables/
│           └── useSessionWebSocket.ts # 🟡 PLACEHOLDER - Session WS
│
├── data/                           # 🟢 REAL (gitignored)
│   └── catalytic.db                # SQLite database
│
├── backups/                        # 🟢 REAL (gitignored)
│   └── catalytic_20251031_143022.db
│
└── scripts/
    └── backup-db.sh                # 🟢 REAL - SQLite backup script
```

---

### Caddyfile Configuration

**Alpha Caddyfile (Basic Auth on Everything):**
```caddyfile
{$DOMAIN} {
    # Protect entire site with basic auth (alpha only)
    basicauth {
        apolo {$APOLO_HASH}
        paul {$PAUL_HASH}
        curtis {$CURTIS_HASH}
    }

    # Admin frontend
    handle /admin* {
        reverse_proxy frontend-admin:3001
    }

    # Backend API
    handle /api/* {
        reverse_proxy backend:8000
    }

    # Placeholder session interface
    handle /session* {
        reverse_proxy placeholder-agent:3002
    }

    # Public frontend
    handle /* {
        reverse_proxy frontend-public:3000
    }
}
```

**Beta Caddyfile (Selective Protection - Reference Only):**
```caddyfile
{$DOMAIN} {
    # Admin routes - double protection
    handle /admin* {
        basicauth {
            apolo {$APOLO_HASH}
            paul {$PAUL_HASH}
            curtis {$CURTIS_HASH}
        }
        reverse_proxy frontend-admin:3001
    }

    # Admin API - double protection
    handle /api/admin/* {
        basicauth {
            apolo {$APOLO_HASH}
            paul {$PAUL_HASH}
            curtis {$CURTIS_HASH}
        }
        reverse_proxy backend:8000
    }

    # Session interface
    handle /session* {
        reverse_proxy agent-app:3002  # Real agent in beta
    }

    # Public API - open
    handle /api/* {
        reverse_proxy backend:8000
    }

    # Public routes - open
    handle /* {
        reverse_proxy frontend-public:3000
    }
}
```

**Environment Variable Passthrough:**
Caddy requires explicit environment variable declaration in docker-compose.yml:
```yaml
environment:
  - DOMAIN=${DOMAIN}
  - APOLO_HASH=${APOLO_HASH}
  - PAUL_HASH=${PAUL_HASH}
  - CURTIS_HASH=${CURTIS_HASH}
```

---

### Docker Compose Configuration

**Main Stack (docker-compose.yml):**
```yaml
services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
    environment:
      # Explicit passthrough for Caddyfile substitution
      - DOMAIN=${DOMAIN}
      - APOLO_HASH=${APOLO_HASH}
      - PAUL_HASH=${PAUL_HASH}
      - CURTIS_HASH=${CURTIS_HASH}
    env_file:
      - .env.${ENV:-dev}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - app_network

  backend:
    build: ./backend
    env_file:
      - .env.${ENV:-dev}
    volumes:
      - ./backend:/app
      - ./data:/data
    networks:
      - app_network

  frontend-public:
    build: ./frontend-public
    env_file:
      - .env.${ENV:-dev}
    volumes:
      - ./frontend-public/src:/app/src
    command: npm run dev
    networks:
      - app_network

  frontend-admin:
    build: ./frontend-admin
    env_file:
      - .env.${ENV:-dev}
    volumes:
      - ./frontend-admin/src:/app/src
    command: npm run dev
    networks:
      - app_network

volumes:
  caddy_data:
  caddy_config:

networks:
  app_network:
    driver: bridge
```

**Placeholder Stack (docker-compose.placeholder.yml):**
```yaml
services:
  placeholder-agent:
    build: ./placeholder-agent
    env_file:
      - .env.${ENV:-dev}
    volumes:
      - ./placeholder-agent/src:/app/src
    command: npm run dev
    networks:
      - catalytic-customer_app_network  # Join main network

networks:
  catalytic-customer_app_network:
    external: true
```

**Usage:**
```bash
# Start main stack
ENV=dev docker compose up -d

# Start placeholder (alpha)
ENV=dev docker compose -f docker-compose.placeholder.yml up -d

# Production
ENV=prod docker compose up -d
ENV=prod docker compose -f docker-compose.placeholder.yml up -d
```

---

### Environment Configuration

**.env.dev (Local Development):**
```bash
# Domain
DOMAIN=localhost

# Caddy Admin Credentials (bcrypt hashes)
# Generate with: caddy hash-password --plaintext "password"
APOLO_HASH='$2a$14$...'
PAUL_HASH='$2a$14$...'
CURTIS_HASH='$2a$14$...'

# Google OAuth
GOOGLE_CLIENT_ID=dev-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=dev-secret
GOOGLE_REDIRECT_URI=http://localhost/api/auth/callback

# Database
DATABASE_PATH=/data/catalytic-dev.db

# Mail (Development)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=dev@example.com
MAIL_PASSWORD=dev_password
MAIL_FROM=noreply@localhost
```

**.env.prod (Production):**
```bash
# Domain
DOMAIN=catalytic.learnstream.tech

# Caddy Admin Credentials
APOLO_HASH='$2a$14$...'
PAUL_HASH='$2a$14$...'
CURTIS_HASH='$2a$14$...'

# Google OAuth
GOOGLE_CLIENT_ID=prod-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=prod-secret
GOOGLE_REDIRECT_URI=https://catalytic.learnstream.tech/api/auth/callback

# Database
DATABASE_PATH=/data/catalytic.db

# Mail (Production)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=noreply@learnstream.tech
MAIL_PASSWORD=prod_password
MAIL_FROM=noreply@learnstream.tech
```

**.env.example (Committed Template):**
```bash
# Domain Configuration
DOMAIN=localhost

# Caddy Admin Credentials
# Generate with: caddy hash-password --plaintext "your_password"
APOLO_HASH=
PAUL_HASH=
CURTIS_HASH=

# Google OAuth
# Setup: https://console.cloud.google.com/
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=http://localhost/api/auth/callback

# Database
DATABASE_PATH=/data/catalytic.db

# Email (Gmail SMTP)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_FROM=noreply@localhost
```

---

### Email System

**Email Flow:**
ONLY the public registration form sends emails automatically. Admin dashboard actions (Add User, Reissue Invite) do NOT send emails - admin manually copies URL.

**FastAPI-Mail Configuration:**
```python
# backend/services/email.py
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
import os

conf = ConnectionConfig(
    MAIL_USERNAME=os.getenv("MAIL_USERNAME"),
    MAIL_PASSWORD=os.getenv("MAIL_PASSWORD"),
    MAIL_FROM=os.getenv("MAIL_FROM"),
    MAIL_PORT=int(os.getenv("MAIL_PORT", 587)),
    MAIL_SERVER=os.getenv("MAIL_SERVER"),
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
)

fm = FastMail(conf)

async def send_invite_email(email: str, first_name: str, token: str):
    """Send invitation email with token link"""
    invite_url = f"https://{os.getenv('DOMAIN')}/session?token={token}"

    message = MessageSchema(
        subject="Your Catalytic Customer Invitation",
        recipients=[email],
        body=f"""Hi {first_name},

You've been invited to participate in Catalytic Customer!

Click here to start your session:
{invite_url}

This link is valid for 30 days.

Best regards,
Catalytic Customer Team
""",
        subtype="plain"
    )

    await fm.send_message(message)
```

**5-Minute Cooldown:**
Prevents email spam from public form - if user submits same email within 5 minutes, show error page instead of sending duplicate email.

**Email Deliverability Checklist:**

**IMPORTANT:** Email deliverability must be tested before launch. Without proper DNS configuration, invitation emails may be flagged as spam or rejected entirely.

**Pre-Launch Checklist:**
- [ ] Configure SPF record for learnstream.tech domain
- [ ] Configure DKIM signing for outbound mail
- [ ] Test email delivery to Gmail accounts
- [ ] Test email delivery to Outlook/Office365 accounts
- [ ] Test email delivery to Yahoo accounts
- [ ] Monitor bounce rates during alpha testing
- [ ] Check spam folder placement rates
- [ ] Have fallback manual invitation process ready (copy/paste URL)

**Risk Assessment:** Without SPF/DKIM configuration, production emails have 30-50% chance of being flagged as spam.

**Fallback Strategy:** If email deliverability issues occur, admins can use manual invitation flow (Add User → Copy URL → Send via personal email client).

---

### UI/UX Specifications

**Admin Dashboard Data Table:**

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| First Name | Text | User's first name | John |
| Last Name | Text | User's last name | Doe |
| Email | Text | User's email | john@example.com |
| Status | Derived | Current state | Active |
| Progress | Text | Questions answered / total | 3/10 |
| Invite URL | Text | Token link (copyable) | https://catalytic.learnstream.tech/session?token=abc123 |
| Token Valid | Computed | Expiry status | Yes (15 days left) |
| Session Timer | Computed | Time remaining (if active) | 45 minutes left |
| Transcript | Text | Completion data | (placeholder text or NULL) |
| Summary | Text | Completion data | (placeholder text or NULL) |

**All fields READ-ONLY** - no inline editing.

**Placeholder Test Form Layout:**
```
┌──────────────────────────────────────────┐
│ Session Test Form (Alpha)                │
├──────────────────────────────────────────┤
│ Session Timer: 47:23 remaining           │
│                                          │
│ Questions Answered: [___] / 10           │
│ [Set Value]                              │
│                                          │
│ Current State:                           │
│ • Token Activated: Yes                   │
│ • Session Expired: No                    │
│ • Progress: 0/10                         │
└──────────────────────────────────────────┘
```

**Connection Status Indicator (Admin Dashboard):**
```vue
<template>
  <div class="flex items-center space-x-2">
    <div v-if="isConnected" class="flex items-center space-x-2">
      <span class="relative flex h-3 w-3">
        <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
        <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
      </span>
      <span class="text-white font-semibold">Connected</span>
    </div>
    <div v-else class="flex items-center space-x-2">
      <span class="relative flex h-3 w-3 bg-red-500 rounded-full"></span>
      <span class="text-white font-semibold">Disconnected</span>
    </div>
  </div>
</template>
```

**Toast Notification (Real-Time Updates):**
```vue
<template>
  <Transition name="toast">
    <div
      v-if="isVisible"
      class="fixed left-1/2 transform -translate-x-1/2 z-50 flex items-center gap-3 px-4 py-3 bg-blue-500 text-white rounded-lg shadow-2xl"
      :style="{ top: `${16 + (index * 68)}px` }"
    >
      <span class="text-sm font-semibold">{{ message }}</span>
      <button
        @click="dismiss"
        class="ml-2 text-white hover:text-white/80 font-bold text-lg"
      >
        ×
      </button>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';

const props = defineProps<{
  message: string;
  index: number;
  duration?: number;
}>();

const emit = defineEmits<{
  dismiss: [];
}>();

const isVisible = ref(false);

const dismiss = () => {
  isVisible.value = false;
  setTimeout(() => emit('dismiss'), 300);
};

onMounted(() => {
  isVisible.value = true;
  setTimeout(dismiss, props.duration || 4000);
});
</script>

<style scoped>
.toast-enter-active, .toast-leave-active {
  transition: all 0.3s ease;
}
.toast-enter-from, .toast-leave-to {
  opacity: 0;
  transform: translate(-50%, -20px);
}
</style>
```

---

### Backup System

**Backup Script:**
```bash
#!/bin/bash
# scripts/backup-db.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_PATH=${DATABASE_PATH:-/data/catalytic.db}
BACKUP_DIR=./backups

mkdir -p $BACKUP_DIR

# Use SQLite's built-in backup (safer than cp)
sqlite3 $DB_PATH ".backup $BACKUP_DIR/catalytic_$TIMESTAMP.db"

echo "✓ Backup created: $BACKUP_DIR/catalytic_$TIMESTAMP.db"
```

**Usage:**
```bash
chmod +x scripts/backup-db.sh
./scripts/backup-db.sh
```

**Container-Based Backup (for cron on host):**

If scheduling backups via cron on the host machine, use Docker exec to run backup inside container:

```bash
# Cron entry (runs daily at 2 AM)
0 2 * * * docker exec catalytic-backend sqlite3 /data/catalytic.db ".backup /data/backups/catalytic_$(date +\%Y\%m\%d_\%H\%M\%S).db"
```

**Note:** Ensure `/data/backups/` directory exists and is mounted as volume for persistence.

---

### Testing Strategy

**Alpha Testing Goals:**
1. Validate complete user flow end-to-end
2. Test token lifecycle (generation, validation, expiry)
3. Verify session timing (1-hour expiry)
4. Test admin dashboard real-time updates
5. Verify WebSocket reliability (reconnection, multiple admins)
6. Test all error states (expired tokens, cooldowns, etc.)
7. Validate OAuth flow with Google
8. Test placeholder → completion flow
9. Verify database persistence and backups
10. Test environment switching (dev → prod)

**Manual Test Scenarios:**

**1. Public Registration Flow**
- Register new user → receive email → click link → activate session
- Register duplicate email within cooldown → see error
- Register duplicate email after activation → see "already used" error

**2. Session Flow**
- Activate session → set progress to 5 → verify admin sees update
- Set progress to 10 → verify completion page with placeholder content
- Let session expire (1 hour) → verify "session expired" page

**3. Admin Dashboard**
- Add new user → copy URL → verify appears in table
- Delete user → verify removed from table
- Reissue invite for completed user → verify reset state
- Open dashboard in multiple browsers → verify real-time sync

**4. WebSocket**
- Disconnect network → verify "Disconnected" indicator
- Reconnect → verify auto-reconnect and data sync
- Multiple admins → verify all see same updates

**5. Token Expiry**
- Create user → wait 30 days (or modify DB) → click link → see invalid token error

---

### Deployment Checklist

**Initial Setup:**
- [ ] Clone repository
- [ ] Copy `.env.example` to `.env.dev` and `.env.prod`
- [ ] Generate Caddy password hashes for Apolo, Paul, Curtis
- [ ] Set up Google OAuth credentials (dev + prod)
- [ ] Configure SMTP credentials
- [ ] Set domain in `.env.prod`

**Development Environment:**
- [ ] Start main stack: `ENV=dev docker compose up -d`
- [ ] Start placeholder: `ENV=dev docker compose -f docker-compose.placeholder.yml up -d`
- [ ] Verify all containers running: `docker compose ps`
- [ ] Test WebSocket connections
- [ ] Test OAuth flow
- [ ] Test email sending

**Production Deployment:**
- [ ] Update DNS: `catalytic.learnstream.tech` → server IP
- [ ] Start main stack: `ENV=prod docker compose up -d`
- [ ] Start placeholder: `ENV=prod docker compose -f docker-compose.placeholder.yml up -d`
- [ ] Verify Caddy TLS certificate obtained
- [ ] Test basic auth with Apolo/Paul/Curtis accounts
- [ ] Test OAuth with production redirect URI
- [ ] Test email delivery
- [ ] Set up backup cron job: `0 2 * * * /path/to/backup-db.sh`

---

### Key Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| OAuth Location | Backend handles OAuth | Simpler than Caddy plugin, standard pattern |
| Token Type | Random (`secrets.token_urlsafe(32)`) | Simpler than JWT, sufficient for one-time use |
| Token Reuse | One-time use only | More secure, explicit reissue process |
| Backup Method | SQLite `.backup` command | Safer than `cp` during active use |
| Docker Networks | Single network | Simpler for alpha, all containers trusted |
| Caddy Admin Auth | Path-based with basic auth | Cleaner than subdomain for prototype |
| SQLite WAL | Enabled | Better concurrency with minimal overhead |
| SMTP Service | Gmail SMTP | Quick setup for alpha |
| Rate Limiting | 5-minute cooldown on public form | Prevents spam, simple implementation |
| Frontend Mode | Dev mode with hot reload | Faster iteration during alpha |
| Admin Fields | Read-only display | No inline editing, actions via buttons/modals |
| Email from Admin | Manual copy/paste URL | No auto-send in alpha (may add in beta) |
| WebSocket Security | Validate session/admin on connect | Standard practice, sufficient security |
| Concurrency | No optimistic locking | Acceptable for 3 admins in alpha |
| Placeholder Modularity | Separate Docker stack | Clean transition to real agent in beta |

---

## Work Table

**Execution Order:**
1. **Group A** (sequential): Complete WP-A-1, then WP-A-2
2. **Groups B, C, D** (parallel): After WP-A-1 completes, all three can run simultaneously
3. **Group E** (parallel): After WP-A-2 completes, WP-E-1, WP-E-2, WP-E-3 can run simultaneously
4. **Group F** (parallel): After Groups B, C, D complete, WP-F-1 and WP-F-2 can run simultaneously
5. **Group G** (sequential): After Groups E, F complete, run WP-G-1, then WP-G-2

| ID | Title | Description |
|----|-------|-------------|
| WP-A-1 | Backend Core Setup | Create `backend/` directory structure with `main.py`, `config.py`, `models.py`. Implement complete SQLite schema (see Database Schema), enable WAL mode, create indexes, status derivation logic. FastAPI app bootstrap with CORS, config loader, SQLite connection. |
| WP-A-2 | Backend Services Layer | Create `backend/services/` directory. Implement `email.py` (FastAPI-Mail integration, see Email System), `tokens.py` (secrets.token_urlsafe(32) generation and validation), `db.py` (SQLite operations and WAL queries), `websocket.py` (broadcast_to_admins and broadcast_to_session helpers with async protection). Depends on: WP-A-1. |
| WP-B-1 | Frontend Public Complete | Create complete `frontend-public/` directory. Vue.js 3 app with Vite, router, all views (Landing.vue with registration form, Success.vue, ErrorAlreadyUsed.vue, ErrorCooldown.vue), RegistrationForm component with validation, API integration calling POST /api/register. Dockerfile with hot reload. Depends on: WP-A-1. |
| WP-C-1 | Frontend Admin Complete | Create complete `frontend-admin/` directory. Vue.js 3 app with Vite, router with auth guards, all views (Login.vue, AdminDashboard.vue), all components (UserTable.vue per UI/UX Specifications, AddUserModal.vue, ReissueModal.vue, ConfirmDialog.vue, ToastNotification.vue, ConnectionStatus.vue), all composables (useAdminWebSocket.ts with exponential backoff/jitter per WebSocket Architecture, useAuth.ts). Tailwind CSS integration. Dockerfile with hot reload. Depends on: WP-A-1. |
| WP-D-1 | Placeholder Agent Complete | Create complete `placeholder-agent/` directory. Vue.js 3 app with Vite, router, all views (SessionTestForm.vue per UI/UX Specifications, ThankYou.vue, SessionExpired.vue, InvalidToken.vue), all components (TestControlPanel.vue, SessionTimer.vue), useSessionWebSocket composable with ping/pong handling. Dockerfile with hot reload. Create docker-compose.placeholder.yml joining main network. Depends on: WP-A-1. |
| WP-E-1 | Public & Session APIs | Create `backend/routes/public.py` and `backend/routes/session.py`. Implement POST /api/register with duplicate detection and 5-min cooldown, GET /session?token activation endpoint, GET /api/session/{id}, POST /api/session/{id}/progress with completion detection (see API Endpoints). All validation, error handling, WebSocket broadcasts. Depends on: WP-A-2. |
| WP-E-2 | Admin & Auth APIs | Create `backend/routes/admin.py` and `backend/routes/auth.py`. Implement POST /api/admin/users, DELETE /api/admin/users/{id}, POST /api/admin/users/{id}/reissue with Incomplete/Completed validation, GET /api/auth/login, GET /api/auth/callback with admin_sessions integration (see API Endpoints). OAuth + basic auth checks. Depends on: WP-A-2. |
| WP-E-3 | WebSocket Endpoints | Create `backend/websockets/admin_stream.py` and `backend/websockets/session_stream.py`. Implement /admin/stream with OAuth validation and heartbeat/ping (30s), /session/{id}/stream with session validation and time_update messages (see WebSocket Architecture). Route registration in main.py. Depends on: WP-A-2. |
| WP-F-1 | Docker & Proxy Configuration | Create `Caddyfile`, `docker-compose.yml`, and all `Dockerfile` files in backend/, frontend-public/, frontend-admin/, placeholder-agent/. Alpha Caddyfile with site-wide basic auth (see Caddyfile Configuration), path-based routing, TLS auto-provisioning, env var substitution. docker-compose.yml with explicit Caddy env passthrough, volume mounts, hot reload commands (see Docker Compose Configuration). Depends on: WP-B-1, WP-C-1, WP-D-1. |
| WP-F-2 | Environment & Backup | Create `.env.example`, update `.gitignore` for env entries, create `scripts/backup-db.sh` and `backups/` directory. Complete .env.example with all variables and comments (see Environment Configuration), backup script using SQLite .backup command (see Backup System), chmod +x, document cron setup for container-based backup. |
| WP-G-1 | Testing & Validation | Execute all manual test scenarios (see Testing Strategy): token lifecycle end-to-end, session timing validation, WebSocket reconnection with network disconnect, multi-admin real-time sync, email delivery to Gmail/Outlook/Yahoo, all error states (cooldown, expired, invalid token). Depends on: WP-E-1, WP-E-2, WP-E-3, WP-F-1. |
| WP-G-2 | Documentation & Deployment | Create `README.md` and deployment docs. README with architecture overview, setup instructions, usage guide for both stacks, deployment checklist (see Deployment Checklist). Production .env.prod setup guide, DNS configuration instructions, TLS verification steps, backup cron setup documentation. Depends on: WP-G-1. |

---

**Note:** Context sections above (Project Overview through Detailed Specifications) are frozen after initial build. Work Table grows as new work items are added post-MVP. See `.ai/prp/proposals/` for adding standalone work items.
