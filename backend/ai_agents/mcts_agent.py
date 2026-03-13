import math
import random
import time
from ..game_engine.rules import apply_move, is_terminal
from ..game_engine.move_generator import generate_legal_moves
from ..game_engine.state import PLAYER_1, PLAYER_2

class MCTSNode:
    def __init__(self, state, parent=None, move=None):
        self.state = state
        self.parent = parent
        self.move = move
        self.children = []
        self.wins = 0
        self.visits = 0
        self.untried_moves = generate_legal_moves(state)

class MCTSAgent:
    def __init__(self, player_id, iterations=1000, exploration_constant=1.4, time_limit=1.9):
        self.player_id = player_id
        self.iterations = iterations
        self.exploration_constant = exploration_constant
        self.time_limit = time_limit

    def choose_move(self, state):
        root = MCTSNode(state)
        start_time = time.time()
        
        legal_moves = root.untried_moves
        if not legal_moves:
            return None
            
        iters = 0
        while iters < self.iterations:
            if time.time() - start_time > self.time_limit:
                break
                
            # 1. Select
            node = root
            while not node.untried_moves and node.children:
                node = self.select(node)
                
            # 2. Expand
            if node.untried_moves:
                move = random.choice(node.untried_moves)
                node.untried_moves.remove(move)
                next_state = apply_move(node.state, move)
                child = MCTSNode(next_state, parent=node, move=move)
                node.children.append(child)
                node = child
                
            # 3. Simulate (Random Playout)
            sim_state = node.state.clone()
            while not is_terminal(sim_state):
                moves = generate_legal_moves(sim_state)
                m = random.choice(moves)
                sim_state = apply_move(sim_state, m)
                
            # 4. Backpropagate
            diff = sim_state.score_p1 - sim_state.score_p2
            if self.player_id == PLAYER_1:
                if diff > 0: win_score = 1
                elif diff < 0: win_score = 0
                else: win_score = 0.5
            else:
                if diff < 0: win_score = 1
                elif diff > 0: win_score = 0
                else: win_score = 0.5
                
            curr = node
            while curr is not None:
                curr.visits += 1
                curr.wins += win_score
                curr = curr.parent
            
            iters += 1
            
        # Returning best child move
        best_child = None
        best_visits = -1
        for child in root.children:
            if child.visits > best_visits:
                best_visits = child.visits
                best_child = child
                
        if best_child is None:
            return random.choice(legal_moves)
            
        print(f"MCTS (P{self.player_id}): completed {iters} iterations in {time.time() - start_time:.2f}s")
        return best_child.move

    def select(self, node):
        best_score = -math.inf
        best_child = None
        
        # Are we picking a move for our player_id or opponent?
        # If node.state.player_turn == self.player_id, we want to maximize our UCT.
        root_perspective = (node.state.player_turn == self.player_id)
        
        for child in node.children:
            if child.visits == 0:
                continue
                
            exploit = child.wins / child.visits
            if not root_perspective:
                exploit = 1.0 - exploit
                
            explore = self.exploration_constant * math.sqrt(math.log(node.visits) / child.visits)
            score = exploit + explore
            
            if score > best_score:
                best_score = score
                best_child = child
                
        if best_child is None:
            return random.choice(node.children)
            
        return best_child
