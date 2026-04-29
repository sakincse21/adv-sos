# Simulation System — Detailed Code Documentation

This document explains `backend/simulation/`, which manages AI vs AI match execution and automated batch experiments.

---

## File: `game_manager.py` — Single Match Engine

### Class: `GameManager`

```python
class GameManager:
    def __init__(self, agent1, agent2):
```

| Attribute | Type | Description |
|-----------|------|-------------|
| `agent1` | Agent instance | Controls Player 1 |
| `agent2` | Agent instance | Controls Player 2 |
| `state` | `GameState` | The live game state, initialized to a fresh empty board |
| `stats` | `dict` | Performance tracking dictionary |

### Statistics Tracked

```python
stats = {
    'total_moves': 0,      # Total moves played in the match
    'time_p1': 0.0,        # Cumulative decision time for P1
    'time_p2': 0.0,        # Cumulative decision time for P2
    'p1_moves': 0,         # Number of moves P1 played
    'p2_moves': 0          # Number of moves P2 played
}
```

### `play_match(verbose=True)` — Game Loop

The core match loop:

```python
while not is_terminal(self.state):
    1. Determine current player
    2. Select the correct agent (agent1 for P1, agent2 for P2)
    3. Time the agent's decision:  move = agent.choose_move(state)
    4. Update cumulative stats
    5. Apply the move: state = apply_move(state, move)
```

**Extra turns:** The loop doesn't need special handling for SOS extra turns — `apply_move()` already sets `player_turn` back to the current player when an SOS is formed. The loop just checks `state.player_turn` each iteration.

**Return value:**

```python
{
    'winner': 1 or 2 or 0,       # 0 = draw
    'score_p1': int,
    'score_p2': int,
    'stats': { ... }
}
```

---

## File: `match_runner.py` — Batch Experiment Runner

### `run_experiment(agent1_class, agent1_args, agent2_class, agent2_args, num_games=100)`

Runs `num_games` consecutive matches between two agent configurations and aggregates statistics.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `agent1_class` | class | e.g. `MinimaxAgent` |
| `agent1_args` | dict | e.g. `{'max_depth': 3}` |
| `agent2_class` | class | e.g. `MCTSAgent` |
| `agent2_args` | dict | e.g. `{'iterations': 500}` |
| `num_games` | int | Number of matches to run (default: 100) |

### Tracked Metrics

For each game:
- Winner (P1, P2, or Draw)
- Final scores
- Total decision time per player
- Total moves per player

### Report Output

After all games complete, the runner prints:

```
--- Experiment Results (100 games) ---
P1 Wins (MinimaxAgent): 62 (62.0%)
P2 Wins (MCTSAgent):    31 (31.0%)
Draws:                    7 (7.0%)
Avg Score P1: 4.32 | Avg Score P2: 2.87
Avg Time per Move -> P1: 1.82s | P2: 1.23s
Total Experiment Time: 1847.3s
```

### Experiment Configurations

The default configuration (at the bottom of the file) runs a quick 5-game test:

```python
run_experiment(MinimaxAgent, {'max_depth': 3}, MCTSAgent, {'iterations': 500}, 5)
```

You can modify this for full experiments:

```python
# Minimax vs MCTS (100 games)
run_experiment(MinimaxAgent, {'max_depth': 4}, MCTSAgent, {'iterations': 1000}, 100)

# MCTS vs MCTS (100 games)
run_experiment(MCTSAgent, {'iterations': 1000}, MCTSAgent, {'iterations': 1000}, 100)

# Minimax vs Minimax (100 games)
run_experiment(MinimaxAgent, {'max_depth': 3}, MinimaxAgent, {'max_depth': 3}, 100)
```
