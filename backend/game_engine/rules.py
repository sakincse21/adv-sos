from .state import GameState, Move, EMPTY, S, O, X, TYPE_PLACE, TYPE_SKIP, PLAYER_1, PLAYER_2
from .board import is_valid_pos, get_empty_cells

def check_sos(board, r, c):
    """
    Given a board and a newly placed position (r, c),
    returns the number of newly formed SOS patterns.
    """
    symbol = board[r][c]
    if symbol not in (S, O):
        return 0

    count = 0
    directions = [(0, 1), (1, 0), (1, 1), (1, -1)]

    for dr, dc in directions:
        if symbol == S:
            # Check 'S' at one end, 'O' in middle, 'S' at other end
            # Forward direction
            if (is_valid_pos(r + dr, c + dc) and board[r + dr][c + dc] == O and
                is_valid_pos(r + 2 * dr, c + 2 * dc) and board[r + 2 * dr][c + 2 * dc] == S):
                count += 1
            # Backward direction
            if (is_valid_pos(r - dr, c - dc) and board[r - dr][c - dc] == O and
                is_valid_pos(r - 2 * dr, c - 2 * dc) and board[r - 2 * dr][c - 2 * dc] == S):
                count += 1
                
        elif symbol == O:
            # Check 'O' in the middle, 'S' at both ends
            if (is_valid_pos(r - dr, c - dc) and board[r - dr][c - dc] == S and
                is_valid_pos(r + dr, c + dc) and board[r + dr][c + dc] == S):
                count += 1
                
    return count


def check_sos_patterns(board, r, c):
    """
    Like check_sos but returns the actual cell positions of each SOS pattern.
    Returns a list of lists: [[(r1,c1), (r2,c2), (r3,c3)], ...]
    """
    symbol = board[r][c]
    if symbol not in (S, O):
        return []

    patterns = []
    directions = [(0, 1), (1, 0), (1, 1), (1, -1)]

    for dr, dc in directions:
        if symbol == S:
            # Forward: S(placed) - O - S
            if (is_valid_pos(r + dr, c + dc) and board[r + dr][c + dc] == O and
                is_valid_pos(r + 2 * dr, c + 2 * dc) and board[r + 2 * dr][c + 2 * dc] == S):
                patterns.append([(r, c), (r + dr, c + dc), (r + 2 * dr, c + 2 * dc)])
            # Backward: S - O - S(placed)
            if (is_valid_pos(r - dr, c - dc) and board[r - dr][c - dc] == O and
                is_valid_pos(r - 2 * dr, c - 2 * dc) and board[r - 2 * dr][c - 2 * dc] == S):
                patterns.append([(r - 2 * dr, c - 2 * dc), (r - dr, c - dc), (r, c)])
        elif symbol == O:
            # Middle: S - O(placed) - S
            if (is_valid_pos(r - dr, c - dc) and board[r - dr][c - dc] == S and
                is_valid_pos(r + dr, c + dc) and board[r + dr][c + dc] == S):
                patterns.append([(r - dr, c - dc), (r, c), (r + dr, c + dc)])

    return patterns


def apply_move(state: GameState, move: Move) -> GameState:
    new_state = state.clone()
    
    current_player = new_state.player_turn
    next_player = PLAYER_2 if current_player == PLAYER_1 else PLAYER_1
    
    # 1. Handle Skip Move
    if move.type == TYPE_SKIP:
        # A skip chooses an empty cell to force the opponent
        new_state.forced_cell = move.position
        new_state.skip_history[current_player] = True
        new_state.player_turn = next_player
        return new_state

    # 2. Handle Place Move
    r, c = move.position
    new_state.board[r][c] = move.symbol
    new_state.skip_history[current_player] = False  # Reset skip history since we placed
    
    # If the cell was a forced cell, clear it now that it's played
    if new_state.forced_cell == (r, c):
        new_state.forced_cell = None
        
    # Get detailed SOS pattern positions
    new_patterns = check_sos_patterns(new_state.board, r, c)
    sos_formed = len(new_patterns)
    
    if sos_formed > 0:
        # Record each pattern with the player who scored it
        for pattern_cells in new_patterns:
            new_state.sos_patterns.append({
                "player": current_player,
                "cells": pattern_cells
            })
        
        if current_player == PLAYER_1:
            new_state.score_p1 += sos_formed
        else:
            new_state.score_p2 += sos_formed
        # If SOS is formed, the player gets another turn.
        new_state.player_turn = current_player
    else:
        new_state.player_turn = next_player

    return new_state

def is_terminal(state: GameState) -> bool:
    """Game over if there are no empty cells."""
    return len(get_empty_cells(state.board)) == 0

def calculate_utility(state: GameState) -> int:
    """Utility = Player1Score - Player2Score"""
    return state.score_p1 - state.score_p2

