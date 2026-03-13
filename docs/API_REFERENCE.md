# API Reference — Python Backend Endpoints

This document describes the FastAPI server in `backend/main.py` that bridges the Python game engine with the Godot 4 visualization.

---

## Server Details

| Property | Value |
|----------|-------|
| **Framework** | FastAPI |
| **Default URL** | `http://127.0.0.1:8000` |
| **CORS** | Enabled for all origins |
| **Start command** | `uvicorn backend.main:app --host 0.0.0.0 --port 8000` |

---

## Endpoints

### `GET /api/state` — Get Current Game State

Returns the complete state of the running match.

**Response (200 OK):**

```json
{
  "board": [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 2, 0, 0, 0, 0, 0],
    [0, 0, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0]
  ],
  "score_p1": 1,
  "score_p2": 0,
  "turn": 1,
  "forced_cell": null,
  "running": true,
  "logs": [
    "Started Match: minimax vs mcts",
    "P1 chose PLACE S at (1, 1) in 2.34s",
    "P2 chose PLACE O at (1, 2) in 1.52s",
    "P1 chose PLACE S at (2, 2) in 1.91s"
  ],
  "last_move": {
    "player": 1,
    "move_type": 1,
    "symbol": 1,
    "position": [2, 2],
    "time": 1.91
  }
}
```

**Field descriptions:**

| Field | Type | Description |
|-------|------|-------------|
| `board` | `int[][]` | 8×8 matrix. `0`=EMPTY, `1`=S, `2`=O, `3`=X |
| `score_p1` | `int` | Player 1's SOS count |
| `score_p2` | `int` | Player 2's SOS count |
| `turn` | `int` | `1` or `2` — whose turn it is |
| `forced_cell` | `[int,int] or null` | `[row, col]` if next player is forced to play there |
| `running` | `bool` | Whether the match is actively running |
| `logs` | `string[]` | Last 5 log entries |
| `last_move` | `object or null` | Details of the most recent move |

**`last_move` object:**

| Field | Type | Description |
|-------|------|-------------|
| `player` | `int` | `1` or `2` |
| `move_type` | `int` | `1`=PLACE, `2`=SKIP |
| `symbol` | `int` | `0`=EMPTY, `1`=S, `2`=O, `3`=X |
| `position` | `[int,int]` | `[row, col]` |
| `time` | `float` | Decision time in seconds |

---

### `POST /api/start` — Start a New Match

Resets the board and starts a new AI vs AI match in a background thread.

**Request body:**

```json
{
  "agent1": "minimax",
  "agent2": "mcts"
}
```

| Field | Values | Description |
|-------|--------|-------------|
| `agent1` | `"minimax"` or `"mcts"` | Agent type for Player 1 |
| `agent2` | `"minimax"` or `"mcts"` | Agent type for Player 2 |

**Agent configuration:**

| Agent | Config |
|-------|--------|
| `"minimax"` | `MinimaxAgent(player_id, max_depth=3)` |
| `"mcts"` | `MCTSAgent(player_id, iterations=1000)` |

**Response (200 OK):**

```json
{
  "status": "started",
  "config": {
    "agent1": "minimax",
    "agent2": "mcts"
  }
}
```

**Behavior:**
1. Stops any currently running match
2. Resets to a fresh `GameState`
3. Clears all logs
4. Spawns a new background thread running `engine.play_loop()`
5. The loop has a **1-second delay** between moves (so the UI can animate)

---

### `POST /api/pause` — Toggle Pause/Resume

Toggles the match between running and paused states.

**Request body:** None (empty or `{}`)

**Response (200 OK):**

```json
{
  "running": false
}
```

**Behavior:**
- If running → pauses (sets `engine.running = False`, thread exits loop)
- If paused → resumes (sets `engine.running = True`, spawns new thread)
- If no game started → returns `{"running": false, "msg": "Game not started"}`

---

## Internal: `GameEngine` Class

The `GameEngine` singleton manages the live match state:

```python
class GameEngine:
    state       # Current GameState
    agent1      # Player 1 agent instance
    agent2      # Player 2 agent instance
    running     # bool — is the match active?
    thread      # Background thread running play_loop()
    last_move   # Dict with details of the most recent move
    logs        # List of log strings (capped at 50)
```

### `play_loop()`

Runs in a background thread:

```python
while self.running and not is_terminal(self.state):
    1. Select agent based on current player
    2. Time the decision
    3. Record last_move details
    4. Apply the move
    5. Sleep 1.0 second (animation delay)
```

The 1-second sleep between moves ensures the Godot frontend has time to animate each move before the next one arrives. Without this, moves would pile up faster than the UI could render them.

---

## Communication Flow

```
┌─────────────┐         ┌──────────────────┐
│   Godot 4   │  HTTP   │  Python FastAPI   │
│  (Frontend) │ ◄─────► │   (Backend)       │
│             │         │                   │
│ http_client │ GET     │ GET /api/state    │
│   polls     │ ──────► │   → returns board │
│   every     │ ◄────── │     + last_move   │
│   0.5s      │         │                   │
│             │ POST    │ POST /api/start   │
│ UI buttons  │ ──────► │   → spawns match  │
│             │         │     thread        │
│             │ POST    │ POST /api/pause   │
│             │ ──────► │   → toggles pause │
└─────────────┘         └──────────────────┘
```
