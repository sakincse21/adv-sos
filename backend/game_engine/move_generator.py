from .state import GameState, Move, EMPTY, S, O, X, TYPE_PLACE, TYPE_SKIP, PLAYER_1, PLAYER_2
from .board import get_empty_cells

def generate_legal_moves(state: GameState):
    moves = []
    current_player = state.player_turn
    empty_cells = get_empty_cells(state.board)
    
    if not empty_cells:
        return moves

    # If there's a forced cell, we MUST play in it (cannot skip)
    if state.forced_cell is not None:
        r, c = state.forced_cell
        moves.append(Move(TYPE_PLACE, S, (r, c)))
        moves.append(Move(TYPE_PLACE, O, (r, c)))
        moves.append(Move(TYPE_PLACE, X, (r, c)))
        return moves
        
    # Normal placement moves
    for r, c in empty_cells:
        moves.append(Move(TYPE_PLACE, S, (r, c)))
        moves.append(Move(TYPE_PLACE, O, (r, c)))
        moves.append(Move(TYPE_PLACE, X, (r, c)))

    # Skip moves
    opponent = PLAYER_2 if current_player == PLAYER_1 else PLAYER_1
    player_skipped_last = state.skip_history[current_player]
    opponent_skipped_last = state.skip_history[opponent]
    
    # "A player cannot skip twice consecutively."
    # "Both players cannot skip simultaneously." (Handled implicitly if they skipped, we are in forced cell)
    # But just to be sure we enforce the rule explicitly here if needed.
    if not player_skipped_last and not opponent_skipped_last:
        for r, c in empty_cells:
            # A skip move requires choosing an empty cell to force the opponent
            moves.append(Move(TYPE_SKIP, EMPTY, (r, c)))
            
    return moves
