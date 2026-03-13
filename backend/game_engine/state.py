# Constants
EMPTY = 0
S = 1
O = 2
X = 3

PLAYER_1 = 1
PLAYER_2 = 2

# Move Types
TYPE_PLACE = 1
TYPE_SKIP  = 2

class Move:
    def __init__(self, move_type, symbol=EMPTY, position=None):
        self.type = move_type
        self.symbol = symbol
        self.position = position  # (row, col)

    def __repr__(self):
        type_str = "PLACE" if self.type == TYPE_PLACE else "SKIP"
        sym_str = {EMPTY: "EMPTY", S: "S", O: "O", X: "X"}.get(self.symbol, str(self.symbol))
        return f"Move({type_str}, {sym_str}, {self.position})"


class GameState:
    def __init__(self, board=None, player_turn=PLAYER_1, score_p1=0, score_p2=0, forced_cell=None, skip_history=None, sos_patterns=None):
        if board is None:
            self.board = [[EMPTY for _ in range(8)] for _ in range(8)]
        else:
            self.board = [row[:] for row in board]
            
        self.player_turn = player_turn
        self.score_p1 = score_p1
        self.score_p2 = score_p2
        
        # (row, col) that the opponent must play in if we skipped
        self.forced_cell = forced_cell 
        
        # Dictionary tracking if a player skipped their PREVIOUS turn
        if skip_history is None:
            self.skip_history = {PLAYER_1: False, PLAYER_2: False}
        else:
            self.skip_history = skip_history.copy()
        
        # List of all scored SOS patterns: [{"player": 1, "cells": [(r,c),(r,c),(r,c)]}, ...]
        if sos_patterns is None:
            self.sos_patterns = []
        else:
            self.sos_patterns = [p.copy() for p in sos_patterns]

    def clone(self):
        return GameState(
            board=self.board,
            player_turn=self.player_turn,
            score_p1=self.score_p1,
            score_p2=self.score_p2,
            forced_cell=self.forced_cell,
            skip_history=self.skip_history,
            sos_patterns=self.sos_patterns
        )
