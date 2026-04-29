import time
from ..ai_agents.minimax_agent import MinimaxAgent
from ..ai_agents.mcts_agent import MCTSAgent
from .game_manager import GameManager
from ..game_engine.state import PLAYER_1, PLAYER_2

def run_experiment(agent1_class, agent1_args, agent2_class, agent2_args, num_games=100):
    p1_wins = 0
    p2_wins = 0
    draws = 0
    
    total_time_p1 = 0.0
    total_time_p2 = 0.0
    total_moves_p1 = 0
    total_moves_p2 = 0
    total_score_p1 = 0
    total_score_p2 = 0
    
    start_total = time.time()
    print(f"Starting {num_games} matches: {agent1_class.__name__}(P1) vs {agent2_class.__name__}(P2)")
    
    for i in range(num_games):
        a1 = agent1_class(PLAYER_1, **agent1_args)
        a2 = agent2_class(PLAYER_2, **agent2_args)
        
        gm = GameManager(a1, a2)
        result = gm.play_match(verbose=False)
        
        if result['winner'] == PLAYER_1:
            p1_wins += 1
        elif result['winner'] == PLAYER_2:
            p2_wins += 1
        else:
            draws += 1
            
        total_score_p1 += result['score_p1']
        total_score_p2 += result['score_p2']
        
        stats = result['stats']
        total_time_p1 += stats['time_p1']
        total_time_p2 += stats['time_p2']
        total_moves_p1 += stats['p1_moves']
        total_moves_p2 += stats['p2_moves']
        
        print(f"Game {i+1}/{num_games} done: {'P1' if result['winner']==1 else 'P2' if result['winner']==2 else 'Draw'} won ({result['score_p1']}-{result['score_p2']})")
        
    print(f"\n--- Experiment Results ({num_games} games) ---")
    print(f"P1 Wins ({agent1_class.__name__}): {p1_wins} ({(p1_wins/num_games)*100:.1f}%)")
    print(f"P2 Wins ({agent2_class.__name__}): {p2_wins} ({(p2_wins/num_games)*100:.1f}%)")
    print(f"Draws: {draws} ({(draws/num_games)*100:.1f}%)")
    print(f"Avg Score P1: {total_score_p1/num_games:.2f} | Avg Score P2: {total_score_p2/num_games:.2f}")
    
    avg_time_p1 = (total_time_p1/total_moves_p1) if total_moves_p1 > 0 else 0
    avg_time_p2 = (total_time_p2/total_moves_p2) if total_moves_p2 > 0 else 0
    print(f"Avg Time per Move -> P1: {avg_time_p1:.3f}s | P2: {avg_time_p2:.3f}s")
    print(f"Total Experiment Time: {time.time()-start_total:.1f}s")

if __name__ == "__main__":
    # Short test
    run_experiment(MinimaxAgent, {'max_depth': 3}, MCTSAgent, {'iterations': 500}, 5)
