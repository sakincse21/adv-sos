from .state import EMPTY, S, O, X

def is_valid_pos(r, c):
    return 0 <= r < 8 and 0 <= c < 8

def get_empty_cells(board):
    return [(r, c) for r in range(8) for c in range(8) if board[r][c] == EMPTY]

def print_board(board):
    symbol_map = {EMPTY: '.', S: 'S', O: 'O', X: 'X'}
    print("  " + " ".join(str(i) for i in range(8)))
    for r in range(8):
        row_str = " ".join(symbol_map[board[r][c]] for c in range(8))
        print(f"{r} {row_str}")
