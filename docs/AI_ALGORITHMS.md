# AI Algorithms — Detailed Code Documentation

This document explains the two AI agents in `backend/ai_agents/`: the Minimax agent with Alpha-Beta pruning and the Monte Carlo Tree Search (MCTS) agent.

---

## 1. Minimax with Alpha-Beta Pruning

**File:** `minimax_agent.py`

### Algorithm Overview

Minimax is a **depth-limited adversarial search** algorithm. It assumes both players play optimally:
- **Maximizing player** (self) picks the move with the highest evaluation.
- **Minimizing player** (opponent) picks the move with the lowest evaluation.

**Alpha-Beta pruning** eliminates branches that cannot influence the final decision, dramatically reducing the number of nodes explored.

```
           MAX (us)
          / | \
        MIN MIN MIN
       / \      |
     MAX MAX   MAX
      ...      ...
```

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `player_id` | — | Which player this agent controls (`PLAYER_1` or `PLAYER_2`) |
| `max_depth` | `4` | How many moves ahead to search |
| `nodes_explored` | `0` | Counter reset each turn for statistics |

### Heuristic Evaluation Function

The `evaluate(state)` function scores a board position from the agent's perspective:

```python
score = 10 * (my_score - opp_score)
       + 3 * my_potential_sos
       - 2 * opp_potential_sos
       + 1 * center_control
```

| Component | Weight | Meaning |
|-----------|--------|---------|
| **Score difference** | ×10 | Most important — actual points scored |
| **My potential SOS** | ×3 | Empty cells where I could form SOS next turn |
| **Opponent potential SOS** | ×2 | Penalize opponent's opportunities (negative weight) |
| **Center control** | ×1 | Number of non-empty cells in the middle 4×4 zone |

**Potential SOS calculation:** For every empty cell, the agent temporarily places `S` and `O`, checking if either would form an SOS via `check_sos()`. This tells us how many "one-move-away" SOS opportunities exist.

### Alpha-Beta Pruning

```python
def max_value(self, state, alpha, beta, depth):
    # alpha = best guaranteed value for MAX so far
    # beta  = best guaranteed value for MIN so far
    
    for each move:
        v = max(v, min_value(next_state, alpha, beta, depth+1))
        if v >= beta:
            return v    # PRUNE: MIN would never allow this
        alpha = max(alpha, v)
    return v

def min_value(self, state, alpha, beta, depth):
    for each move:
        v = min(v, max_value(next_state, alpha, beta, depth+1))
        if v <= alpha:
            return v    # PRUNE: MAX would never choose this
        beta = min(beta, v)
    return v
```

**Why it's fast:** When a branch is proven to be worse than an already-known option, it's "pruned" (skipped). In practice this reduces the effective branching factor from ~256 to approximately √256 ≈ 16.

### Time Management

The agent enforces a **1.9-second time limit** per move:

```python
if time.time() - start_time > 1.9:
    break
```

If the time runs out mid-search, it returns the best move found so far. This prevents the game from stalling.

### SOS Extra Turn Handling

In SOS, forming a pattern gives an extra turn. The Minimax tree handles this correctly:

```python
if next_state.player_turn == self.player_id:
    val = self.max_value(...)   # Still our turn → keep maximizing
else:
    val = self.min_value(...)   # Opponent's turn → minimize
```

---

## 2. Monte Carlo Tree Search (MCTS)

**File:** `mcts_agent.py`

### Algorithm Overview

MCTS is a **simulation-based search** algorithm. Instead of evaluating positions with a heuristic, it plays thousands of random games ("playouts") from each candidate move and picks the move that wins the most simulations.

```
     Root (current state)
    /     |     \
  Child1  Child2  Child3
  (200    (150    (50
   wins    wins    wins
   /400)   /300)   /100)
```

### The Four Phases (repeated per iteration)

```
1. SELECTION      → Walk down the tree using UCT formula
2. EXPANSION      → Add a new child node for an untried move
3. SIMULATION     → Random playout to terminal state
4. BACKPROPAGATION → Update win/visit counts up the tree
```

### UCT Formula (Selection)

```
UCT = (wins / visits) + C × √(ln(parent_visits) / visits)
```

| Component | Meaning |
|-----------|---------|
| `wins / visits` | **Exploitation** — prefer moves that have won often |
| `C × √(ln(parent_visits) / visits)` | **Exploration** — prefer moves that haven't been tried much |
| `C = 1.4` | Exploration constant (tunable) |

**Opponent perspective handling:** When selecting from a node where it's the opponent's turn, the exploit term is inverted (`1.0 - exploit`) to correctly model adversarial play.

### MCTSNode Class

```python
class MCTSNode:
    state       # GameState at this node
    parent      # Parent MCTSNode
    move        # Move that led to this state
    children    # List of child MCTSNodes
    wins        # Float — accumulated win score
    visits      # Int — number of simulations through this node
    untried_moves  # List of moves not yet expanded
```

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `player_id` | — | Which player this agent controls |
| `iterations` | `1000` | Max number of MCTS iterations per move |
| `exploration_constant` | `1.4` | The `C` value in UCT formula |
| `time_limit` | `1.9s` | Hard time cap per decision |

### Simulation Strategy

The simulation phase uses **uniform random playouts**:

```python
while not is_terminal(sim_state):
    moves = generate_legal_moves(sim_state)
    m = random.choice(moves)
    sim_state = apply_move(sim_state, m)
```

Random play is simple but effective — with enough iterations (500–2000), the law of large numbers produces accurate win-rate estimates.

### Backpropagation Scoring

```python
diff = sim_state.score_p1 - sim_state.score_p2
if self.player_id == PLAYER_1:
    if diff > 0: win_score = 1     # P1 won
    elif diff < 0: win_score = 0   # P1 lost
    else: win_score = 0.5          # Draw
```

Binary win/loss scoring (with 0.5 for draws) is propagated up every ancestor node.

### Move Selection

After all iterations complete, the agent selects the child with the **most visits** (not highest win rate). This is standard MCTS practice — the most-visited node has the most statistical confidence.

---

## Algorithm Comparison

| Feature | Minimax + Alpha-Beta | MCTS |
|---------|---------------------|------|
| **Strategy** | Exhaustive depth-limited search | Statistical simulation sampling |
| **Evaluation** | Handcrafted heuristic | Random playout outcomes |
| **Branching** | Prunes bad branches early | Focuses on promising branches |
| **Strength** | Strong with good heuristic | No domain knowledge needed |
| **Weakness** | Heuristic quality limits play | Needs many iterations |
| **Time per move** | ~2 seconds | ~1.5 seconds |
| **Nodes explored** | 15,000–35,000 | 500–2,000 iterations |
| **Best at** | Tactical SOS completion | Strategic long-term play |
