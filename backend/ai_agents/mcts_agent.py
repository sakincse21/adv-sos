import math
import random
import time

from ..game_engine.board import get_empty_cells
from ..game_engine.move_generator import generate_legal_moves
from ..game_engine.rules import apply_move, check_sos, is_terminal
from ..game_engine.state import EMPTY, O, PLAYER_1, PLAYER_2, S, TYPE_SKIP, X


class MCTSNode:
    __slots__ = ["state", "parent", "move", "children", "wins", "visits", "untried_moves"]

    def __init__(self, state, parent=None, move=None):
        self.state = state
        self.parent = parent
        self.move = move
        self.children = []
        self.wins = 0.0
        self.visits = 0
        self.untried_moves = generate_legal_moves(state)


class MCTSAgent:
    def __init__(self, player_id, iterations=2000, exploration_constant=1.15, time_limit=1.5):
        self.player_id = player_id
        self.opponent_id = PLAYER_2 if player_id == PLAYER_1 else PLAYER_1
        self.iterations = iterations
        self.exploration_constant = exploration_constant
        self.time_limit = time_limit
        self.max_branching = 12
        self.rollout_depth = 10
        self.endgame_threshold = 8
        self.endgame_depth = 4

    def choose_move(self, state):
        root = MCTSNode(state)
        root.untried_moves = self._trim_candidate_moves(root.untried_moves, root.state)
        legal_moves = root.untried_moves
        if not legal_moves:
            return None

        start_time = time.perf_counter()
        iters = 0

        while iters < self.iterations and (time.perf_counter() - start_time) < self.time_limit:
            node = root
            path = [node]

            while not node.untried_moves and node.children:
                node = self._select_child(node)
                path.append(node)

            if node.untried_moves:
                move = node.untried_moves.pop()
                child = MCTSNode(apply_move(node.state, move), parent=node, move=move)
                child.untried_moves = self._trim_candidate_moves(child.untried_moves, child.state)
                node.children.append(child)
                node = child
                path.append(node)

            result = self._rollout(node.state)

            for visited in path:
                visited.visits += 1
                visited.wins += result

            iters += 1

        if not root.children:
            return legal_moves[0]

        best_child = max(root.children, key=lambda child: (child.visits, child.wins / max(1, child.visits)))
        elapsed = time.perf_counter() - start_time
        winrate = 100.0 * best_child.wins / max(1, best_child.visits)
        print(f"MCTS (P{self.player_id}): {iters} iter in {elapsed:.2f}s, win%={winrate:.1f}")
        return best_child.move

    def _select_child(self, node):
        best_score = -math.inf
        best_child = None
        root_turn = node.state.player_turn == self.player_id
        log_parent = math.log(node.visits + 1)

        for child in node.children:
            exploit = child.wins / max(1, child.visits)
            if not root_turn:
                exploit = 1.0 - exploit

            explore = self.exploration_constant * math.sqrt(log_parent / max(1, child.visits))
            score = exploit + explore
            if score > best_score:
                best_score = score
                best_child = child

        return best_child

    def _trim_candidate_moves(self, moves, state):
        if len(moves) <= self.max_branching or state.forced_cell is not None:
            return list(moves)

        scored = []
        for move in moves:
            scored.append((self._score_move(move, state), random.random(), move))

        scored.sort(key=lambda item: (item[0], item[1]))
        top_moves = [move for _, _, move in scored[-self.max_branching :]]
        return top_moves

    def _score_move(self, move, state):
        if move.type == TYPE_SKIP:
            return -1.0

        r, c = move.position
        score = 0.0

        formed = self._count_move_sos(state.board, move)
        if formed:
            score += 12.0 + (4.0 * formed)

        if state.forced_cell == (r, c):
            score += 3.0

        center_distance = abs(r - 3.5) + abs(c - 3.5)
        score += max(0.0, 4.5 - center_distance) * 0.35

        if move.symbol == S:
            score += 0.4
        elif move.symbol == O:
            score += 0.25
        else:
            score -= 0.2

        return score

    def _rollout(self, state):
        sim_state = state.clone()

        for _ in range(self.rollout_depth):
            if is_terminal(sim_state):
                break

            moves = generate_legal_moves(sim_state)
            if not moves:
                break

            move = self._select_rollout_move(moves, sim_state)
            sim_state = apply_move(sim_state, move)

        return self._evaluate_state(sim_state)

    def _select_rollout_move(self, moves, state):
        if len(moves) > 10 and state.forced_cell is None:
            moves = random.sample(moves, 10)

        tactical = []
        for move in moves:
            score = self._score_move(move, state)
            tactical.append((score, random.random(), move))

        tactical.sort(key=lambda item: (item[0], item[1]), reverse=True)
        shortlist = tactical[: min(4, len(tactical))]

        if len(shortlist) == 1:
            return shortlist[0][2]

        weights = [max(0.05, item[0] + 0.5) for item in shortlist]
        return random.choices([item[2] for item in shortlist], weights=weights, k=1)[0]

    def _evaluate_state(self, state):
        my_score = state.score_p1 if self.player_id == PLAYER_1 else state.score_p2
        opp_score = state.score_p2 if self.player_id == PLAYER_1 else state.score_p1
        score_diff = my_score - opp_score

        if is_terminal(state):
            if score_diff > 0:
                return 1.0
            if score_diff < 0:
                return 0.0
            return 0.5

        my_threats = self._count_immediate_threats(state)
        opp_threats = 0
        if state.player_turn != self.player_id:
            opp_threats = my_threats
            my_threats = 0

        value = 0.5
        value += score_diff / 40.0
        value += my_threats * 0.04
        value -= opp_threats * 0.05
        return max(0.0, min(1.0, value))

    def _count_immediate_threats(self, state):
        threats = 0
        board = state.board

        if state.forced_cell is not None:
            cells = [state.forced_cell]
        else:
            cells = [
                (r, c)
                for r in range(8)
                for c in range(8)
                if board[r][c] == EMPTY
            ]

        for r, c in cells:
            for symbol in (S, O):
                board[r][c] = symbol
                if check_sos(board, r, c) > 0:
                    threats += 1
                board[r][c] = EMPTY

        return threats

    def _count_move_sos(self, board, move):
        if move.type == TYPE_SKIP or move.symbol == X:
            return 0

        r, c = move.position
        if board[r][c] != EMPTY:
            return 0

        board[r][c] = move.symbol
        formed = check_sos(board, r, c)
        board[r][c] = EMPTY
        return formed