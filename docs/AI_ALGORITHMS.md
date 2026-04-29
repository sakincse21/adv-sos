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

| Parameter        | Default | Description                                                 |
| ---------------- | ------- | ----------------------------------------------------------- |
| `player_id`      | —       | Which player this agent controls (`PLAYER_1` or `PLAYER_2`) |
| `max_depth`      | `4`     | How many moves ahead to search                              |
| `nodes_explored` | `0`     | Counter reset each turn for statistics                      |

### Heuristic Evaluation Function

The `evaluate(state)` function scores a board position from the agent's perspective:

```python
score = 10 * (my_score - opp_score)
       + 3 * my_potential_sos
       - 2 * opp_potential_sos
       + 1 * center_control
```

| Component                  | Weight | Meaning                                             |
| -------------------------- | ------ | --------------------------------------------------- |
| **Score difference**       | ×10    | Most important — actual points scored               |
| **My potential SOS**       | ×3     | Empty cells where I could form SOS next turn        |
| **Opponent potential SOS** | ×2     | Penalize opponent's opportunities (negative weight) |
| **Center control**         | ×1     | Number of non-empty cells in the middle 4×4 zone    |

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

| Component                           | Meaning                                                     |
| ----------------------------------- | ----------------------------------------------------------- |
| `wins / visits`                     | **Exploitation** — prefer moves that have won often         |
| `C × √(ln(parent_visits) / visits)` | **Exploration** — prefer moves that haven't been tried much |
| `C = 1.15`                          | Exploration constant (balances exploitation/exploration)    |

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

| Parameter              | Default | Description                            |
| ---------------------- | ------- | -------------------------------------- |
| `player_id`            | —       | Which player this agent controls       |
| `iterations`           | `2000`  | Max number of MCTS iterations per move |
| `exploration_constant` | `1.15`  | The `C` value in UCT formula           |
| `time_limit`           | `1.5s`  | Hard time cap per decision             |
| `max_branching`        | `12`    | Top N moves considered (move pruning)  |
| `rollout_depth`        | `10`    | Max depth of simulation playouts       |

### Move Pruning

To manage the high branching factor (~256 moves), MCTS prunes to the **top 12 moves** using a heuristic scoring function:

```
move_score =
  -1.0                        for SKIP moves
  12 + 4·nSOS                 if SOS would be formed
  +3.0                        if move matches forced cell
  0.35·(4.5 - d_center)       center proximity bonus
  +0.4 (S), +0.25 (O), -0.2 (X)  symbol preference
```

Where `d_center = |r - 3.5| + |c - 3.5|` (Manhattan distance from board center).

### Simulation Strategy

From the expanded node, **heuristic-guided weighted random playouts** are conducted:

```python
while rollout_depth < max_depth and not is_terminal(sim_state):
    moves = generate_legal_moves(sim_state)
    scored_moves = [_score_move(m) for m in moves]
    m = weighted_random_choice(scored_moves)  # Top candidates preferred
    sim_state = apply_move(sim_state, m)
    rollout_depth += 1
```

After the rollout completes, a heuristic evaluation estimates the value:

```
value = 0.5 + (Δscore / 40) + 0.04·threats_mine - 0.05·threats_opp
```

This hybrid approach (heuristic-guided simulation) produces better play than pure random rollouts.

### Backpropagation Scoring

The post-rollout evaluation value is backpropagated up the tree. Visits and wins are updated:

```python
node.visits += 1
node.wins += value  # Sum of heuristic values (0.0–1.0)
```

Standard UCB/UCT selection then uses this win/visit ratio to balance exploration and exploitation.

### Move Selection

After the iteration budget is exhausted (either `iterations` reached or `time_limit` exceeded), the agent returns the child with the **highest visit count**:

```python
best_child = max(root.children, key=lambda c: c.visits)
return best_child.move
```

This statistical confidence measure is more robust than selecting by win rate alone.

---

## Algorithm Comparison

| Feature                  | Minimax + Alpha-Beta            | MCTS + Hybrid                          |
| ------------------------ | ------------------------------- | -------------------------------------- |
| **Strategy**             | Exhaustive depth-limited search | Statistical simulation + heuristic     |
| **Evaluation**           | Handcrafted heuristic at leaves | Heuristic-guided playouts + evaluation |
| **Branching Management** | Alpha-Beta pruning              | Move pruning (top 12) + UCT            |
| **Time/Move**            | ~2 seconds                      | ~1.5 seconds                           |
| **Nodes Explored**       | 15,000–35,000                   | 500–2,000 iterations                   |
| **Opening Phase**        | Weak (limited depth)            | Strong ⭐                              |
| **Midgame**              | Moderate                        | Strong ⭐                              |
| **Endgame**              | Strong ⭐                       | Moderate (heuristic-limited)           |
| **SOS Detection**        | Excellent                       | Good                                   |
| **Best At**              | Tactical sequences              | Strategic planning                     |
