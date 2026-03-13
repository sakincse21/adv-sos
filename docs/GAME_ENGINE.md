# Game Engine — Detailed Code Documentation

This document explains every file in `backend/game_engine/`, the core logic layer that manages the SOS board, game state, rules, and move generation.

---

## File: `state.py` — Constants, Move, and GameState

### Constants

```python
EMPTY = 0   # Cell is empty
S = 1       # Cell contains 'S'
O = 2       # Cell contains 'O'
X = 3       # Cell contains 'X' (blocker)

PLAYER_1 = 1
PLAYER_2 = 2

TYPE_PLACE = 1   # Normal placement move
TYPE_SKIP  = 2   # Skip turn + force opponent
```

These integer constants are used for efficient board representation. The board is stored as a list of lists (8×8 matrix), where each cell holds one of these values.

---

### Class: `Move`

```python
class Move:
    def __init__(self, move_type, symbol=EMPTY, position=None):
        self.type = move_type       # TYPE_PLACE or TYPE_SKIP
        self.symbol = symbol        # S, O, X, or EMPTY (for skip)
        self.position = position    # (row, col) tuple
```

**Move** represents a single player action:

| Field | Type | Description |
|-------|------|-------------|
| `type` | `int` | `TYPE_PLACE` (1) — place a symbol, or `TYPE_SKIP` (2) — skip and force |
| `symbol` | `int` | Which symbol to place: `S`, `O`, `X`, or `EMPTY` (skip has no symbol) |
| `position` | `tuple` | `(row, col)` coordinates on the 8×8 board |

The `__repr__` method provides human-readable output like `Move(PLACE, S, (3, 4))`.

---

### Class: `GameState`

```python
class GameState:
    def __init__(self, board=None, player_turn=PLAYER_1, score_p1=0,
                 score_p2=0, forced_cell=None, skip_history=None):
```

**GameState** is the complete snapshot of the game at any point:

| Attribute | Type | Description |
|-----------|------|-------------|
| `board` | `list[list[int]]` | 8×8 matrix of cell values (EMPTY/S/O/X) |
| `player_turn` | `int` | Who plays next: `PLAYER_1` or `PLAYER_2` |
| `score_p1` | `int` | Player 1's accumulated SOS count |
| `score_p2` | `int` | Player 2's accumulated SOS count |
| `forced_cell` | `tuple or None` | `(row, col)` if the current player is forced to play here |
| `skip_history` | `dict` | `{PLAYER_1: bool, PLAYER_2: bool}` — did each player skip last turn? |

**`clone()`** creates a deep copy of the state. The board is copied row-by-row (`[row[:] for row in board]`) and skip_history is `.copy()`'d. This is critical because AI agents explore thousands of hypothetical states without mutating the real game.

---

## File: `board.py` — Board Utility Functions

```python
def is_valid_pos(r, c):
    return 0 <= r < 8 and 0 <= c < 8
```

Simple bounds check. Used extensively by `check_sos()` to avoid index-out-of-range errors when scanning patterns near board edges.

```python
def get_empty_cells(board):
    return [(r, c) for r in range(8) for c in range(8) if board[r][c] == EMPTY]
```

Returns all `(row, col)` positions that are still `EMPTY`. Used by:
- **Move generator** — to know where pieces can be placed
- **Terminal check** — game ends when this returns empty
- **Minimax heuristic** — to probe for potential SOS opportunities

```python
def print_board(board):
```

Debug-only ASCII renderer. Prints the board with `.`, `S`, `O`, `X` symbols and numbered row/column headers.

---

## File: `rules.py` — SOS Detection, Apply Move, Terminal Check

### `check_sos(board, r, c)` — SOS Pattern Detection

This is the most important function in the game engine. After placing a symbol at `(r, c)`, it counts how many **new** SOS patterns were formed.

**Algorithm:**

```
directions = [(0,1), (1,0), (1,1), (1,-1)]
  → horizontal, vertical, diagonal, anti-diagonal
```

For each direction `(dr, dc)`:

1. **If the placed symbol is `S`** (start/end of SOS):
   - Check **forward**: Is `(r+dr, c+dc) == O` AND `(r+2*dr, c+2*dc) == S`?
   - Check **backward**: Is `(r-dr, c-dc) == O` AND `(r-2*dr, c-2*dc) == S`?
   - Each match = +1 SOS

2. **If the placed symbol is `O`** (middle of SOS):
   - Check both ends: Is `(r-dr, c-dc) == S` AND `(r+dr, c+dc) == S`?
   - Each match = +1 SOS

3. **If the placed symbol is `X`**: Returns `0` — X cannot form SOS.

**Why this works:** Any SOS is exactly 3 cells long. The newly placed piece is either an endpoint (`S`) or the midpoint (`O`). We only need to check 4 directional axes × 2 orientations = at most 8 checks per placement.

---

### `apply_move(state, move)` — State Transition

```python
def apply_move(state: GameState, move: Move) -> GameState:
```

Creates a **new state** (via `clone()`) after applying a move. Never mutates the original.

**Skip Move (`TYPE_SKIP`):**
1. Set `forced_cell` to the chosen empty cell
2. Mark `skip_history[current_player] = True`
3. Switch turn to opponent

**Place Move (`TYPE_PLACE`):**
1. Place the symbol on the board
2. Reset `skip_history[current_player] = False`
3. Clear `forced_cell` if this cell was the forced one
4. Count SOS patterns via `check_sos()`
5. If SOS formed → add to player's score, **same player plays again**
6. If no SOS → switch turn to opponent

---

### `is_terminal(state)` — Game Over Check

```python
def is_terminal(state: GameState) -> bool:
    return len(get_empty_cells(state.board)) == 0
```

The game is over when all 64 cells are filled. Simple but effective — the board is dense so this is O(64).

---

### `calculate_utility(state)` — Final Score

```python
def calculate_utility(state: GameState) -> int:
    return state.score_p1 - state.score_p2
```

Positive = Player 1 winning, Negative = Player 2 winning, Zero = draw.

---

## File: `move_generator.py` — Legal Move Enumeration

```python
def generate_legal_moves(state: GameState):
```

This function returns **all legal moves** for the current player, respecting all game constraints.

### Logic Flow

```
1. If board is full → return [] (no moves possible)

2. If forced_cell exists:
   → Only 3 moves allowed: Place S, O, or X at forced_cell
   → Cannot skip when forced

3. Normal moves:
   → For each empty cell: PLACE S, PLACE O, PLACE X (3 moves per cell)

4. Skip moves (only if allowed):
   → Cannot skip if current player skipped last turn
   → Cannot skip if opponent skipped last turn (prevents simultaneous skips)
   → For each empty cell: SKIP targeting that cell
```

**Move count example:** On an empty 8×8 board with 64 cells:
- Placement moves: 64 × 3 = 192
- Skip moves: 64
- Total: **256 possible moves** at game start

This is why the AI agents use depth limits and pruning — the branching factor is enormous.
