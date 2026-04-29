from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import threading
import time

from .game_engine.state import GameState, PLAYER_1, PLAYER_2
from .game_engine.rules import is_terminal, apply_move
from .ai_agents.minimax_agent import MinimaxAgent
from .ai_agents.mcts_agent import MCTSAgent

app = FastAPI()

# Allow CORS for Godot HTML5 exports if needed, though Godot 4 native handles HTTP fine
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class GameEngine:
    def __init__(self):
        self.state = GameState()
        self.agent1 = None
        self.agent2 = None
        self.running = False
        self.thread = None
        self.last_move = None
        self.logs = []
        
    def log(self, msg):
        self.logs.append(msg)
        if len(self.logs) > 50:
            self.logs.pop(0)
            
    def play_loop(self):
        while self.running and not is_terminal(self.state):
            current_player = self.state.player_turn
            agent = self.agent1 if current_player == PLAYER_1 else self.agent2
            
            start_time = time.time()
            move = agent.choose_move(self.state)
            elapsed = time.time() - start_time
            
            # Record last move details before applying
            self.last_move = {
                'player': current_player,
                'move_type': move.type, # 1=PLACE, 2=SKIP
                'symbol': move.symbol,  # 0=EMPTY, 1=S, 2=O, 3=X
                'position': move.position,
                'time': round(elapsed, 3)
            }
            
            move_str = f"P{current_player} chose "
            move_str += f"{'SKIP' if move.type == 2 else 'PLACE'} "
            move_str += {0: 'EMPTY', 1: 'S', 2: 'O', 3: 'X'}.get(move.symbol, str(move.symbol))
            move_str += f" at {move.position} in {elapsed:.2f}s"
            
            self.log(move_str)
            print(f"API Engine: {move_str}")
            
            self.state = apply_move(self.state, move)
            
            # Artificial delay so UI can animate smoothly
            time.sleep(1.0)
            
        if is_terminal(self.state):
            self.running = False
            self.log("Game Over! Terminal State Reached.")

engine = GameEngine()

@app.get("/api/state")
def get_state():
    return {
        "board": engine.state.board,
        "score_p1": engine.state.score_p1,
        "score_p2": engine.state.score_p2,
        "turn": engine.state.player_turn,
        "forced_cell": engine.state.forced_cell,
        "running": engine.running,
        "logs": engine.logs[-5:], # send last 5 logs for UI
        "last_move": engine.last_move,
        "sos_patterns": [
            {"player": p["player"], "cells": [list(c) for c in p["cells"]]}
            for p in engine.state.sos_patterns
        ]
    }

class StartConfig(BaseModel):
    agent1: str = "minimax"
    agent2: str = "mcts"
    
@app.post("/api/start")
def start_game(config: StartConfig):
    engine.running = False
    if engine.thread and engine.thread.is_alive():
        engine.thread.join(timeout=2.0)
        
    engine.state = GameState()
    engine.logs = []
    engine.last_move = None
    
    if config.agent1 == "minimax":
        engine.agent1 = MinimaxAgent(PLAYER_1, max_depth=3)
    else:
        engine.agent1 = MCTSAgent(PLAYER_1, iterations=2000, time_limit=1.5)
        
    if config.agent2 == "minimax":
        engine.agent2 = MinimaxAgent(PLAYER_2, max_depth=3)
    else:
        engine.agent2 = MCTSAgent(PLAYER_2, iterations=2000, time_limit=1.5)
    engine.running = True
    engine.log(f"Started Match: {config.agent1} vs {config.agent2}")
    engine.thread = threading.Thread(target=engine.play_loop)
    engine.thread.start()
    return {"status": "started", "config": config.dict()}

@app.post("/api/pause")
def toggle_pause():
    if not engine.thread and not engine.running:
        return {"running": False, "msg": "Game not started"}
        
    engine.running = not engine.running
    if engine.running and not engine.thread.is_alive():
        engine.thread = threading.Thread(target=engine.play_loop)
        engine.thread.start()
        engine.log("Game Resumed")
    else:
        if not engine.running:
            engine.log("Game Paused")
            
    return {"running": engine.running}
