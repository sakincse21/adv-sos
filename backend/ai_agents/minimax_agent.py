import time
import math
from ..game_engine.rules import apply_move, is_terminal, check_sos
from ..game_engine.move_generator import generate_legal_moves
from ..game_engine.state import PLAYER_1, PLAYER_2, S, O, EMPTY

class MinimaxAgent:
    def __init__(self, player_id, max_depth=4):
        self.player_id = player_id
        self.opponent_id = PLAYER_2 if player_id == PLAYER_1 else PLAYER_1
        self.max_depth = max_depth
        self.nodes_explored = 0

    def evaluate(self, state):
        my_score = state.score_p1 if self.player_id == PLAYER_1 else state.score_p2
        opp_score = state.score_p2 if self.player_id == PLAYER_1 else state.score_p1
        
        # Center control (middle 4x4)
        center_control = 0
        for r in range(2, 6):
            for c in range(2, 6):
                if state.board[r][c] != EMPTY:
                    center_control += 1
                    
        # Open SOS potentials (immediate threats)
        potential_matches = 0
        from ..game_engine.board import get_empty_cells
        empty_cells = get_empty_cells(state.board)
        for r, c in empty_cells:
            # Temporarily place S to check
            state.board[r][c] = S
            if check_sos(state.board, r, c) > 0:
                potential_matches += 1
            # Temporarily place O to check
            state.board[r][c] = O
            if check_sos(state.board, r, c) > 0:
                potential_matches += 1
            state.board[r][c] = EMPTY
            
        my_potential = 0
        opp_potential = 0
        if state.player_turn == self.player_id:
            my_potential = potential_matches
        else:
            opp_potential = potential_matches
            
        # Example heuristic from prompt
        score = 10 * (my_score - opp_score) + 3 * my_potential - 2 * opp_potential + 1 * center_control
        return score

    def choose_move(self, state):
        self.nodes_explored = 0
        best_move = None
        best_val = -math.inf
        
        alpha = -math.inf
        beta = math.inf
        start_time = time.time()
        
        legal_moves = generate_legal_moves(state)
        if not legal_moves:
            return None
            
        for move in legal_moves:
            next_state = apply_move(state, move)
            if next_state.player_turn == self.player_id:
                val = self.max_value(next_state, alpha, beta, 1)
            else:
                val = self.min_value(next_state, alpha, beta, 1)
                
            if val > best_val:
                best_val = val
                best_move = move
            alpha = max(alpha, best_val)
            
            # 2 second limit check
            if time.time() - start_time > 1.9:
                break
                
        if best_move is None:
            best_move = legal_moves[0]
            
        print(f"Minimax (P{self.player_id}): evaluated {self.nodes_explored} nodes in {time.time() - start_time:.2f}s, Best Heuristic: {best_val}")
        return best_move

    def max_value(self, state, alpha, beta, depth):
        self.nodes_explored += 1
        if depth >= self.max_depth or is_terminal(state):
            return self.evaluate(state)
            
        v = -math.inf
        for move in generate_legal_moves(state):
            next_state = apply_move(state, move)
            if next_state.player_turn == self.player_id:
                v = max(v, self.max_value(next_state, alpha, beta, depth + 1))
            else:
                v = max(v, self.min_value(next_state, alpha, beta, depth + 1))
            if v >= beta:
                return v
            alpha = max(alpha, v)
        return v

    def min_value(self, state, alpha, beta, depth):
        self.nodes_explored += 1
        if depth >= self.max_depth or is_terminal(state):
            return self.evaluate(state)
            
        v = math.inf
        for move in generate_legal_moves(state):
            next_state = apply_move(state, move)
            if next_state.player_turn == self.opponent_id:
                v = min(v, self.min_value(next_state, alpha, beta, depth + 1))
            else:
                v = min(v, self.max_value(next_state, alpha, beta, depth + 1))
            if v <= alpha:
                return v
            beta = min(beta, v)
        return v
