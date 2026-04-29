import time
from ..game_engine.state import GameState, PLAYER_1, PLAYER_2
from ..game_engine.rules import is_terminal, apply_move

class GameManager:
    def __init__(self, agent1, agent2):
        self.agent1 = agent1
        self.agent2 = agent2
        self.state = GameState()
        
        self.stats = {
            'total_moves': 0,
            'time_p1': 0.0,
            'time_p2': 0.0,
            'p1_moves': 0,
            'p2_moves': 0
        }

    def play_match(self, verbose=True):
        while not is_terminal(self.state):
            current_player = self.state.player_turn
            agent = self.agent1 if current_player == PLAYER_1 else self.agent2
            
            if verbose:
                from ..game_engine.board import print_board
                print("---")
                print_board(self.state.board)
                print(f"Player {current_player}'s turn. Score: {self.state.score_p1}-{self.state.score_p2}")
            
            start_time = time.time()
            move = agent.choose_move(self.state)
            elapsed = time.time() - start_time
            
            if current_player == PLAYER_1:
                self.stats['time_p1'] += elapsed
                self.stats['p1_moves'] += 1
            else:
                self.stats['time_p2'] += elapsed
                self.stats['p2_moves'] += 1
                
            self.stats['total_moves'] += 1
            
            if verbose:
                print(f"P{current_player} chose {move} in {elapsed:.3f}s")
                
            self.state = apply_move(self.state, move)
            
        score_diff = self.state.score_p1 - self.state.score_p2
        winner = PLAYER_1 if score_diff > 0 else (PLAYER_2 if score_diff < 0 else 0)
        
        if verbose:
            print(f"Game Over. Score: {self.state.score_p1}-{self.state.score_p2}")
            
        return {
            'winner': winner,
            'score_p1': self.state.score_p1,
            'score_p2': self.state.score_p2,
            'stats': self.stats
        }
