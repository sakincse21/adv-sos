# Advanced SOS — AI Board Game Simulation

> An autonomous 8×8 SOS Board Game where two AI agents (Minimax with Alpha-Beta Pruning and Monte Carlo Tree Search) compete against each other, visualized in a 3D Godot 4 jungle environment.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Game Rules](#game-rules)
3. [Architecture](#architecture)
4. [Setup & Running](#setup--running)
5. [Documentation Index](#documentation-index)

---

## Project Overview

This project implements the classic **SOS board game** on an **8×8 grid** with advanced mechanics (blocking symbols, skip-and-force turns), driven entirely by two AI agents:

| Player | Agent | Algorithm |
|--------|-------|-----------|
| **Player 1 (King Kong 🦍)** | `MinimaxAgent` | Minimax with Alpha-Beta Pruning |
| **Player 2 (Godzilla 🦎)** | `MCTSAgent` | Monte Carlo Tree Search (UCT) |

Humans start and observe. The AI match unfolds autonomously with full 3D visualization in **Godot 4**, complete with animated Kaiju characters, a jungle environment, lightning VFX, and an interactive HUD.

---

## Game Rules

### Symbols

| Symbol | Code | Purpose |
|--------|------|---------|
| **S** | `1` | Standard SOS letter |
| **O** | `2` | Standard SOS letter |
| **X** | `3` | Blocking piece — cannot form SOS |

### Scoring

- A player scores **1 point** for each **S-O-S** sequence formed (horizontal, vertical, diagonal, anti-diagonal).
- If a player forms an SOS, they **get another turn immediately**.
- The game ends when **all 64 cells are filled**.
- **Winner** = player with the higher score. `Utility = P1 Score − P2 Score`.

### Skip & Forced Move

- A player may **skip** their turn by selecting an empty cell.
- The opponent **must** place their next symbol in that forced cell.
- A player **cannot skip two turns in a row**.
- Both players **cannot skip simultaneously**.

### Blocking Symbol X

- X permanently occupies a cell but **cannot be part of any SOS pattern**.
- Placing X **gives no points** — it's purely strategic defense.

---

## Architecture

```
adv-sos/
│
├── backend/                     # Python game engine & AI
│   ├── game_engine/
│   │   ├── state.py             # GameState, Move, constants
│   │   ├── board.py             # Board utilities
│   │   ├── rules.py             # SOS detection, apply_move, terminal check
│   │   └── move_generator.py    # Legal move generation
│   │
│   ├── ai_agents/
│   │   ├── minimax_agent.py     # Minimax + Alpha-Beta
│   │   └── mcts_agent.py        # Monte Carlo Tree Search
│   │
│   ├── simulation/
│   │   ├── game_manager.py      # AI vs AI match loop
│   │   └── match_runner.py      # Automated batch experiment runner
│   │
│   └── main.py                  # FastAPI server for Godot integration
│
├── ui/
│   └── godot_project/           # Godot 4 3D visualization
│       ├── project.godot
│       ├── main.tscn
│       ├── board_renderer.gd    # 3D board + King Kong/Godzilla + animations
│       ├── agent_visualizer.gd  # HUD overlay (scores, logs, buttons)
│       ├── http_client.gd       # REST API polling client
│       └── jungle_environment.gd # Procedural tree generation
│
└── docs/                        # Documentation (you are here)
    ├── README.md
    ├── GAME_ENGINE.md
    ├── AI_ALGORITHMS.md
    ├── SIMULATION.md
    ├── GODOT_VISUALIZATION.md
    └── API_REFERENCE.md
```

---

## Setup & Running

### Prerequisites

- **Python 3.10+**
- **Godot 4.x** (for the 3D visualization)
- `pip install fastapi uvicorn`

### Run the API Server

```bash
cd adv-sos
uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

### Run the Godot Visualization

1. Open Godot 4 → Import Project → select `ui/godot_project/`
2. Press **F5** (Play) — click a Start button on the HUD
3. Watch King Kong vs Godzilla battle it out on the SOS board

### Run Headless Experiments (No UI)

```bash
cd adv-sos
python -m backend.simulation.match_runner
```

This runs 5 quick matches by default. Edit the file to configure 100+ match experiments.

---

## Documentation Index

| Document | Description |
|----------|-------------|
| [GAME_ENGINE.md](docs/GAME_ENGINE.md) | Game state, board, rules, move generation — full code explanation |
| [AI_ALGORITHMS.md](docs/AI_ALGORITHMS.md) | Minimax with Alpha-Beta and MCTS — algorithm theory + code walkthrough |
| [SIMULATION.md](docs/SIMULATION.md) | Match engine, experiment runner, statistics tracking |
| [GODOT_VISUALIZATION.md](docs/GODOT_VISUALIZATION.md) | 3D UI, character models, animations, jungle environment |
| [API_REFERENCE.md](docs/API_REFERENCE.md) | FastAPI endpoints for Godot–Python communication |
