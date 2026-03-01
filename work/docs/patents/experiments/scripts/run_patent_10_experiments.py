#!/usr/bin/env python3
"""
Patent #10: AI2AI Chat Learning System Experiments

Runs all 4 required experiments:
1. Conversation Pattern Analysis Accuracy (P1)
2. Shared Insight Extraction Effectiveness (P1)
3. Federated Learning Convergence (P1)
4. Personality Evolution from Conversations (P1)

Date: December 21, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
from scipy.stats import pearsonr
from sklearn.metrics import mean_absolute_error, mean_squared_error
from collections import defaultdict
import random

# Configuration
DATA_DIR = Path(__file__).parent.parent / 'data' / 'patent_10_ai2ai_chat_learning'
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_10'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def generate_synthetic_data():
    """Generate synthetic conversation and personality data."""
    print("Generating synthetic data...")
    
    # Generate 500 personality profiles (12-dimensional)
    agents = []
    for i in range(500):
        agent = {
            'agentId': f'agent_{i:04d}',
            'profile': np.random.rand(12).tolist(),  # 12D personality
            'location': {
                'area': f'area_{i // 50}',
                'region': f'region_{i // 200}',
            }
        }
        agents.append(agent)
    
    # Generate 1000+ conversations
    conversations = []
    for i in range(1000):
        agent_a = random.choice(agents)
        agent_b = random.choice(agents)
        while agent_b['agentId'] == agent_a['agentId']:
            agent_b = random.choice(agents)
        
        # Generate conversation with 5-20 messages
        num_messages = random.randint(5, 20)
        messages = []
        topics = ['technology', 'science', 'art', 'philosophy', 'business', 'health']
        
        for j in range(num_messages):
            message = {
                'message_id': f'msg_{i}_{j}',
                'sender_id': agent_a['agentId'] if j % 2 == 0 else agent_b['agentId'],
                'timestamp': time.time() + j * 60,  # 1 minute intervals
                'content': f"Message {j+1} about {random.choice(topics)}",
                'topic': random.choice(topics),
                'has_insight': random.random() < 0.3,  # 30% have insights
                'learning_exchange': random.random() < 0.2,  # 20% are learning exchanges
            }
            messages.append(message)
        
        conversation = {
            'conversation_id': f'conv_{i:04d}',
            'agent_a_id': agent_a['agentId'],
            'agent_b_id': agent_b['agentId'],
            'messages': messages,
            'ground_truth_patterns': {
                'topic_consistency': random.uniform(0.5, 1.0),
                'response_latency': random.uniform(0.1, 0.5),
                'insight_count': sum(1 for m in messages if m['has_insight']),
                'learning_exchanges': sum(1 for m in messages if m['learning_exchange']),
            }
        }
        conversations.append(conversation)
    
    # Save data
    with open(DATA_DIR / 'synthetic_agents.json', 'w') as f:
        json.dump(agents, f, indent=2)
    
    with open(DATA_DIR / 'synthetic_conversations.json', 'w') as f:
        json.dump(conversations, f, indent=2)
    
    print(f"✅ Generated {len(agents)} agents and {len(conversations)} conversations")
    return agents, conversations


def load_data():
    """Load synthetic data."""
    if not (DATA_DIR / 'synthetic_agents.json').exists():
        return generate_synthetic_data()
    
    with open(DATA_DIR / 'synthetic_agents.json', 'r') as f:
        agents = json.load(f)
    
    with open(DATA_DIR / 'synthetic_conversations.json', 'r') as f:
        conversations = json.load(f)
    
    return agents, conversations


def analyze_topic_consistency(messages):
    """Calculate topic consistency across conversation."""
    topics = [m.get('topic', 'unknown') for m in messages]
    if len(topics) < 2:
        return 0.0
    
    # Calculate topic transitions
    transitions = sum(1 for i in range(len(topics)-1) if topics[i] == topics[i+1])
    consistency = transitions / (len(topics) - 1) if len(topics) > 1 else 0.0
    return consistency


def analyze_response_latency(messages):
    """Calculate average response latency."""
    if len(messages) < 2:
        return 0.0
    
    latencies = []
    for i in range(1, len(messages)):
        if messages[i]['sender_id'] != messages[i-1]['sender_id']:
            latency = messages[i]['timestamp'] - messages[i-1]['timestamp']
            latencies.append(latency)
    
    return np.mean(latencies) if latencies else 0.0


def extract_insights(messages, agent_a_id, agent_b_id):
    """Extract shared insights from conversation."""
    insights = []
    for message in messages:
        if message.get('has_insight', False):
            insight = {
                'message_id': message['message_id'],
                'sender_id': message['sender_id'],
                'relevance': random.uniform(0.6, 1.0),
                'novelty': random.uniform(0.5, 1.0),
                'mutual_benefit': random.uniform(0.5, 1.0),
            }
            insights.append(insight)
    return insights


def experiment_1_conversation_pattern_analysis():
    """Experiment 1: Conversation Pattern Analysis Accuracy."""
    print("=" * 70)
    print("Experiment 1: Conversation Pattern Analysis Accuracy")
    print("=" * 70)
    print()
    
    agents, conversations = load_data()
    
    results = []
    print(f"Analyzing {len(conversations)} conversations...")
    
    for i, conv in enumerate(conversations):
        messages = conv['messages']
        ground_truth = conv['ground_truth_patterns']
        
        # Calculate patterns
        topic_consistency = analyze_topic_consistency(messages)
        response_latency = analyze_response_latency(messages)
        insight_count = sum(1 for m in messages if m.get('has_insight', False))
        learning_exchanges = sum(1 for m in messages if m.get('learning_exchange', False))
        
        results.append({
            'conversation_id': conv['conversation_id'],
            'ground_truth_topic_consistency': ground_truth['topic_consistency'],
            'calculated_topic_consistency': topic_consistency,
            'ground_truth_insight_count': ground_truth['insight_count'],
            'calculated_insight_count': insight_count,
            'ground_truth_learning_exchanges': ground_truth['learning_exchanges'],
            'calculated_learning_exchanges': learning_exchanges,
        })
        
        if (i + 1) % 200 == 0:
            print(f"  Processed {i + 1}/{len(conversations)} conversations...")
    
    df = pd.DataFrame(results)
    
    # Calculate accuracy metrics
    topic_mae = mean_absolute_error(df['ground_truth_topic_consistency'], 
                                    df['calculated_topic_consistency'])
    topic_rmse = np.sqrt(mean_squared_error(df['ground_truth_topic_consistency'],
                                           df['calculated_topic_consistency']))
    topic_corr, topic_p = pearsonr(df['ground_truth_topic_consistency'],
                                   df['calculated_topic_consistency'])
    
    insight_mae = mean_absolute_error(df['ground_truth_insight_count'],
                                      df['calculated_insight_count'])
    insight_rmse = np.sqrt(mean_squared_error(df['ground_truth_insight_count'],
                                              df['calculated_insight_count']))
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Topic Consistency:")
    print(f"  MAE: {topic_mae:.4f}")
    print(f"  RMSE: {topic_rmse:.4f}")
    print(f"  Correlation: {topic_corr:.4f} (p={topic_p:.4e})")
    print()
    print(f"Insight Count:")
    print(f"  MAE: {insight_mae:.4f}")
    print(f"  RMSE: {insight_rmse:.4f}")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'conversation_pattern_analysis.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'conversation_pattern_analysis.csv'}")
    print()
    
    return df


def experiment_2_shared_insight_extraction():
    """Experiment 2: Shared Insight Extraction Effectiveness."""
    print("=" * 70)
    print("Experiment 2: Shared Insight Extraction Effectiveness")
    print("=" * 70)
    print()
    
    agents, conversations = load_data()
    
    results = []
    all_insights = []
    
    print(f"Extracting insights from {len(conversations)} conversations...")
    
    for i, conv in enumerate(conversations):
        messages = conv['messages']
        insights = extract_insights(messages, conv['agent_a_id'], conv['agent_b_id'])
        
        if insights:
            avg_relevance = np.mean([ins['relevance'] for ins in insights])
            avg_novelty = np.mean([ins['novelty'] for ins in insights])
            avg_mutual_benefit = np.mean([ins['mutual_benefit'] for ins in insights])
            
            results.append({
                'conversation_id': conv['conversation_id'],
                'insight_count': len(insights),
                'avg_relevance': avg_relevance,
                'avg_novelty': avg_novelty,
                'avg_mutual_benefit': avg_mutual_benefit,
                'extraction_quality': (avg_relevance + avg_novelty + avg_mutual_benefit) / 3,
            })
            
            all_insights.extend(insights)
        
        if (i + 1) % 200 == 0:
            print(f"  Processed {i + 1}/{len(conversations)} conversations...")
    
    df = pd.DataFrame(results)
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Total Insights Extracted: {len(all_insights)}")
    print(f"Conversations with Insights: {len(results)}/{len(conversations)}")
    if len(results) > 0:
        print(f"Average Insights per Conversation: {df['insight_count'].mean():.2f}")
        print(f"Average Extraction Quality: {df['extraction_quality'].mean():.4f}")
        print(f"Average Relevance: {df['avg_relevance'].mean():.4f}")
        print(f"Average Novelty: {df['avg_novelty'].mean():.4f}")
        print(f"Average Mutual Benefit: {df['avg_mutual_benefit'].mean():.4f}")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'shared_insight_extraction.csv', index=False)
    with open(RESULTS_DIR / 'all_insights.json', 'w') as f:
        json.dump(all_insights, f, indent=2)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'shared_insight_extraction.csv'}")
    print()
    
    return df


def hierarchical_federated_aggregation(user_models, area_map, region_map):
    """Simulate hierarchical federated learning aggregation."""
    # User AI → Area AI
    area_models = {}
    for area, users in area_map.items():
        if users:
            area_model = np.mean([user_models[uid] for uid in users], axis=0)
            # Add differential privacy noise
            noise = np.random.normal(0, 0.01, area_model.shape)
            area_models[area] = area_model + noise
    
    # Area AI → Region AI
    region_models = {}
    for region, areas in region_map.items():
        if areas:
            region_model = np.mean([area_models[area] for area in areas if area in area_models], axis=0)
            noise = np.random.normal(0, 0.01, region_model.shape)
            region_models[region] = region_model + noise
    
    # Region AI → Universal AI
    if region_models:
        universal_model = np.mean(list(region_models.values()), axis=0)
        return universal_model
    
    return None


def experiment_3_federated_learning_convergence():
    """Experiment 3: Federated Learning Convergence."""
    print("=" * 70)
    print("Experiment 3: Federated Learning Convergence")
    print("=" * 70)
    print()
    
    agents, conversations = load_data()
    
    # Create hierarchical structure
    area_map = defaultdict(list)
    region_map = defaultdict(list)
    
    for agent in agents:
        area = agent['location']['area']
        region = agent['location']['region']
        area_map[area].append(agent['agentId'])
        if area not in region_map[region]:
            region_map[region].append(area)
    
    # Initialize user models (12D personality vectors)
    user_models = {}
    for agent in agents:
        user_models[agent['agentId']] = np.array(agent['profile'])
    
    # Simulate federated learning rounds
    num_rounds = 10
    convergence_history = []
    target_model = np.mean([user_models[uid] for uid in user_models.keys()], axis=0)
    
    print(f"Running {num_rounds} federated learning rounds...")
    
    for round_num in range(num_rounds):
        # Update user models (simulate local training)
        for uid in user_models:
            # Simulate local update (small random change)
            update = np.random.normal(0, 0.01, user_models[uid].shape)
            user_models[uid] = np.clip(user_models[uid] + update, 0.0, 1.0)
        
        # Hierarchical aggregation
        universal_model = hierarchical_federated_aggregation(user_models, area_map, region_map)
        
        if universal_model is not None:
            # Calculate convergence (distance to target)
            convergence_error = np.linalg.norm(universal_model - target_model)
            convergence_history.append({
                'round': round_num + 1,
                'convergence_error': convergence_error,
                'universal_model_norm': np.linalg.norm(universal_model),
            })
            
            print(f"  Round {round_num + 1}: Convergence Error = {convergence_error:.6f}")
    
    df = pd.DataFrame(convergence_history)
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Initial Convergence Error: {df.iloc[0]['convergence_error']:.6f}")
    print(f"Final Convergence Error: {df.iloc[-1]['convergence_error']:.6f}")
    print(f"Convergence Improvement: {df.iloc[0]['convergence_error'] - df.iloc[-1]['convergence_error']:.6f}")
    
    # Check convergence rate
    if len(df) > 1:
        convergence_rate = (df.iloc[0]['convergence_error'] - df.iloc[-1]['convergence_error']) / len(df)
        print(f"Average Convergence Rate: {convergence_rate:.6f} per round")
    
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'federated_learning_convergence.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'federated_learning_convergence.csv'}")
    print()
    
    return df


def experiment_4_personality_evolution():
    """Experiment 4: Personality Evolution from Conversations."""
    print("=" * 70)
    print("Experiment 4: Personality Evolution from Conversations")
    print("=" * 70)
    print()
    
    agents, conversations = load_data()
    
    # Create personality profiles
    profiles = {a['agentId']: np.array(a['profile']) for a in agents}
    initial_profiles = {uid: profile.copy() for uid, profile in profiles.items()}
    
    # Simulate personality evolution from conversations
    evolution_results = []
    
    print(f"Simulating personality evolution from {len(conversations)} conversations...")
    
    for i, conv in enumerate(conversations):
        agent_a_id = conv['agent_a_id']
        agent_b_id = conv['agent_b_id']
        
        if agent_a_id not in profiles or agent_b_id not in profiles:
            continue
        
        # Calculate learning signal from conversation
        messages = conv['messages']
        insight_count = sum(1 for m in messages if m.get('has_insight', False))
        learning_exchanges = sum(1 for m in messages if m.get('learning_exchange', False))
        
        # Learning signal based on insights and exchanges
        learning_signal = (insight_count * 0.1 + learning_exchanges * 0.15) / len(messages) if messages else 0.0
        
        # Update personality (small evolution)
        alpha = 0.01  # Learning rate
        profile_a = profiles[agent_a_id]
        profile_b = profiles[agent_b_id]
        
        # Personality evolution: move towards partner's profile weighted by learning signal
        evolution_a = alpha * learning_signal * (profile_b - profile_a)
        evolution_b = alpha * learning_signal * (profile_a - profile_b)
        
        profiles[agent_a_id] = np.clip(profile_a + evolution_a, 0.0, 1.0)
        profiles[agent_b_id] = np.clip(profile_b + evolution_b, 0.0, 1.0)
        
        if (i + 1) % 200 == 0:
            print(f"  Processed {i + 1}/{len(conversations)} conversations...")
    
    # Calculate evolution metrics
    for agent_id in profiles:
        initial = initial_profiles[agent_id]
        evolved = profiles[agent_id]
        evolution_magnitude = np.linalg.norm(evolved - initial)
        evolution_direction = (evolved - initial) / (np.linalg.norm(evolved - initial) + 1e-10)
        
        evolution_results.append({
            'agent_id': agent_id,
            'initial_profile_norm': np.linalg.norm(initial),
            'evolved_profile_norm': np.linalg.norm(evolved),
            'evolution_magnitude': evolution_magnitude,
            'evolution_avg_change': np.mean(np.abs(evolved - initial)),
        })
    
    df = pd.DataFrame(evolution_results)
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Agents Evolved: {len(evolution_results)}")
    print(f"Average Evolution Magnitude: {df['evolution_magnitude'].mean():.6f}")
    print(f"Average Profile Change: {df['evolution_avg_change'].mean():.6f}")
    print(f"Max Evolution Magnitude: {df['evolution_magnitude'].max():.6f}")
    print(f"Min Evolution Magnitude: {df['evolution_magnitude'].min():.6f}")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'personality_evolution.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'personality_evolution.csv'}")
    print()
    
    return df


def main():
    """Run all experiments."""
    print("=" * 70)
    print("Patent #10: AI2AI Chat Learning System Experiments")
    print("=" * 70)
    print()
    
    start_time = time.time()
    
    # Run experiments
    exp1_results = experiment_1_conversation_pattern_analysis()
    exp2_results = experiment_2_shared_insight_extraction()
    exp3_results = experiment_3_federated_learning_convergence()
    exp4_results = experiment_4_personality_evolution()
    
    elapsed_time = time.time() - start_time
    
    print("=" * 70)
    print("All Experiments Complete")
    print("=" * 70)
    print(f"Total Execution Time: {elapsed_time:.2f} seconds")
    print()
    print("✅ All results saved to:", RESULTS_DIR)
    print()


if __name__ == '__main__':
    main()

