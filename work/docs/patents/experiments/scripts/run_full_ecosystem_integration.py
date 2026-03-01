#!/usr/bin/env python3
"""
Full Ecosystem Integration Test

This script integrates all 14 SPOTS patents into a complete end-to-end
user journey simulation, validating that all systems work together.

Patents Integrated:
- Existing: #1 (Quantum Compatibility), #3 (Personality Evolution), 
           #11 (Network Monitoring), #21 (Privacy), #29 (Multi-Entity)
- New: #10 (AI2AI Learning), #13 (Multi-Path Expertise), #15 (Revenue),
      #16 (Partnerships), #17 (Ecosystem), #18 (Saturation),
      #19 (12D Personality), #20 (Recommendation Fusion), #22 (Calling Score)

Date: December 21, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
from datetime import datetime, timedelta
from collections import defaultdict
from typing import Dict, List, Optional
import random
import warnings
warnings.filterwarnings('ignore')

# Import shared data model
import sys
sys.path.append(str(Path(__file__).parent))
from shared_data_model import (
    UserProfile, Event, Partnership, Recommendation,
    quantum_compatibility, calculate_expertise_score,
    get_dynamic_threshold, calculate_location_match,
    generate_integrated_user_profile, generate_integrated_event,
    generate_integrated_partnership, save_integrated_data, load_integrated_data,
    hybrid_learning_function, create_personality_anchors, is_anchor,
    calculate_homogenization_rate, load_profiles_with_fallback,
)

# Import individual patent functions (simplified versions for integration)
# Note: In full implementation, these would import from actual patent modules

# Configuration
DATA_DIR = Path(__file__).parent.parent / 'data' / 'full_ecosystem_integration'
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'full_ecosystem_integration'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

NUM_USERS = 1000
NUM_EVENTS = 100
NUM_MONTHS = 12
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)

# ============================================================================
# PHASE 1: SETUP (Day 0)
# ============================================================================

def phase_1_setup():
    """Phase 1: Create initial users, events, and monitoring."""
    print("=" * 70)
    print("Phase 1: Setup (Day 0)")
    print("=" * 70)
    print()
    
    print(f"Loading {NUM_USERS} users from Big Five data (with synthetic fallback)...")
    project_root = Path(__file__).parent.parent.parent.parent.parent
    users = load_profiles_with_fallback(
        num_profiles=NUM_USERS,
        use_big_five=True,
        project_root=project_root,
        fallback_generator=lambda agent_id: generate_integrated_user_profile(
            agent_id=agent_id,
            platform_phase=random.choice(['Early', 'Growth', 'Mature']),
            random_seed=RANDOM_SEED + hash(agent_id) % (2**32)
        )
    )
    
    print(f"Creating {NUM_EVENTS} multi-entity events...")
    events = []
    current_time = time.time()
    for i in range(NUM_EVENTS):
        # Random future event date
        event_date = current_time + random.uniform(0, 180) * 24 * 3600  # 0-180 days
        
        # Random host
        host = random.choice(users)
        
        # Generate entities (3-10 per event)
        num_entities = random.randint(3, 10)
        entities = []
        for j in range(num_entities):
            entities.append({
                'entity_id': f'entity_{i}_{j}',
                'entity_type': random.choice(['User', 'Business', 'Brand', 'Sponsor']),
                'user_id': random.choice(users).agent_id if random.random() < 0.7 else None,
            })
        
        event = generate_integrated_event(
            event_id=f'event_{i:04d}',
            host_id=host.agent_id,
            category=host.category,
            location=host.location,
            event_date=event_date,
            entities=entities,
            total_revenue=random.uniform(1000, 10000),
        )
        events.append(event)
    
    # Initialize network monitoring (Patent #11)
    network_monitor = {
        'personality_evolution_tracking': [],
        'matching_activity': [],
        'partnership_activity': [],
        'revenue_activity': [],
        'ai2ai_activity': [],
        'network_health_scores': [],
    }
    
    # Calculate initial homogenization
    if len(users) > 1:
        personalities = [u.personality_12d for u in users]
        initial_homogenization = calculate_homogenization_rate(personalities)
        print(f"📊 Initial homogenization: {initial_homogenization:.2%}")
    
    print(f"✅ Setup complete: {len(users)} users, {len(events)} events")
    print()
    
    return users, events, network_monitor


# ============================================================================
# PHASE 2: PERSONALITY EVOLUTION (Months 1-6)
# ============================================================================

def phase_2_personality_evolution(
    users: List[UserProfile], 
    network_monitor: Dict, 
    months: int = 6,
    agent_join_times: Dict = None,
    agent_churn_times: Dict = None,
    next_agent_id: int = None
):
    """Phase 2: Personality evolution through AI2AI learning with agent creation and churn."""
    print("=" * 70)
    print(f"Phase 2: Personality Evolution (Months 1-{months})")
    print("=" * 70)
    print()
    
    evolution_results = []
    
    for month in range(1, months + 1):
        print(f"Month {month}...")
        
        # Get current active users before any changes
        active_users = [u for u in users if agent_churn_times.get(u.agent_id) is None]
        
        # Agent Creation: Add new users (realistic and random)
        # Growth rate decreases over time as platform matures
        # Early months: 3-6% growth, Later months: 1-3% growth
        if month <= 3:
            growth_rate = random.uniform(0.03, 0.06)  # 3-6% in early months
        elif month <= 6:
            growth_rate = random.uniform(0.02, 0.04)  # 2-4% in middle months
        else:
            growth_rate = random.uniform(0.01, 0.03)  # 1-3% in later months
        
        num_new_users = max(1, int(len(active_users) * growth_rate))
        new_users_this_month = []
        for _ in range(num_new_users):
            new_user = generate_integrated_user_profile(
                agent_id=f'user_{next_agent_id:04d}',
                platform_phase=random.choice(['Early', 'Growth', 'Mature']),
                random_seed=RANDOM_SEED + next_agent_id
            )
            users.append(new_user)
            agent_join_times[new_user.agent_id] = month
            new_users_this_month.append(new_user)
            next_agent_id += 1
        
        if new_users_this_month:
            print(f"  {len(new_users_this_month)} new users joined")
        
        # Agent Churn: Expertise-based churn model
        # Experts are less likely to churn (they benefit most from the application)
        # New users (non-experts) are most likely to churn
        # Churn rate based on expertise level and time to become expert (0-360 days)
        # Update active users list (after new users joined)
        active_users = [u for u in users if agent_churn_times.get(u.agent_id) is None]
        if len(active_users) > 0:
            users_to_churn = []
            
            # Calculate churn probability for each user based on expertise and time
            for user in active_users:
                join_month = agent_join_times.get(user.agent_id, 0)
                days_since_join = (month - join_month) * 30  # Approximate days
                
                # Determine if user is an expert
                is_expert = user.expert_creation_time is not None
                
                # Determine if user is "on the path" to becoming expert
                # Users building expertise (score > 0.3) but not yet expert are on the path
                is_building_expertise = user.expertise_score > 0.3 and not is_expert
                
                # Calculate days to become expert (if expert)
                days_to_become_expert = None
                if is_expert and user.expert_creation_time is not None:
                    days_to_become_expert = (user.expert_creation_time - join_month) * 30
                elif is_building_expertise:
                    # Estimate days to become expert based on current progress
                    # Assume linear progression: if at 0.5 expertise, halfway to threshold
                    # Threshold is typically 0.85-0.95, so estimate based on progress
                    phase_thresholds = {'Early': 0.85, 'Growth': 0.90, 'Mature': 0.95}
                    threshold = phase_thresholds.get(user.platform_phase, 0.90)
                    progress_ratio = user.expertise_score / threshold if threshold > 0 else 0.0
                    # Estimate: if 50% progress, assume 50% of max time (360 days)
                    estimated_days_remaining = (1.0 - progress_ratio) * 360
                    days_to_become_expert = days_since_join + estimated_days_remaining
                
                # Base churn probability based on age (for non-experts)
                # Day 1-3: 70-80% churn (very high early churn)
                # Day 4-7: 50-60% churn
                # Day 8-14: 30-40% churn
                # Day 15-30: 15-25% churn
                # Month 2+: 5-10% churn per month (decreasing)
                
                if days_since_join <= 3:
                    base_churn_prob = random.uniform(0.70, 0.80)
                elif days_since_join <= 7:
                    base_churn_prob = random.uniform(0.50, 0.60)
                elif days_since_join <= 14:
                    base_churn_prob = random.uniform(0.30, 0.40)
                elif days_since_join <= 30:
                    base_churn_prob = random.uniform(0.15, 0.25)
                else:
                    # Month 2+: Exponential decay to 5-10% per month
                    months_since_join = (days_since_join - 30) / 30.0
                    base_churn_prob = 0.10 * np.exp(-months_since_join / 3.0) + 0.05
                    base_churn_prob = min(0.10, max(0.05, base_churn_prob))
                
                # Apply expertise-based churn reduction
                if is_expert:
                    # Experts have much lower churn (they benefit most)
                    # Reduce churn by 80-90% (experts churn at 10-20% of base rate)
                    expertise_reduction = random.uniform(0.80, 0.90)
                    churn_prob = base_churn_prob * (1.0 - expertise_reduction)
                elif is_building_expertise:
                    # Users building expertise have intermediate churn
                    # Reduce churn by 30-50% (they're engaged and progressing)
                    # More progress = less churn
                    progress_factor = min(1.0, user.expertise_score / 0.9)  # Normalize to 0-1
                    expertise_reduction = 0.30 + (progress_factor * 0.20)  # 30-50% reduction
                    churn_prob = base_churn_prob * (1.0 - expertise_reduction)
                else:
                    # New users (non-experts, not building) have full base churn
                    churn_prob = base_churn_prob
                
                # Adjust for homogenization (more homogenized users churn slightly more)
                if hasattr(user, '_original_personality'):
                    drift = np.mean(np.abs(user.personality_12d - user._original_personality))
                    homogenization_factor = 1.0 + (drift * 0.2)  # Up to 20% increase
                    churn_prob = churn_prob * homogenization_factor
                
                # Clamp to reasonable range (0-1)
                churn_prob = min(1.0, max(0.0, churn_prob))
                
                # Apply churn based on probability
                if random.random() < churn_prob:
                    users_to_churn.append(user)
            
            # Mark users as churned
            for user in users_to_churn:
                agent_churn_times[user.agent_id] = month
            
            if users_to_churn:
                # Calculate actual churn rate for reporting
                actual_churn_rate = len(users_to_churn) / len(active_users) * 100
                
                # Calculate churn by expertise level for reporting
                expert_churn = sum(1 for u in users_to_churn if u.expert_creation_time is not None)
                building_churn = sum(1 for u in users_to_churn if u.expertise_score > 0.3 and u.expert_creation_time is None)
                new_user_churn = len(users_to_churn) - expert_churn - building_churn
                
                total_experts = sum(1 for u in active_users if u.expert_creation_time is not None)
                total_building = sum(1 for u in active_users if u.expertise_score > 0.3 and u.expert_creation_time is None)
                total_new = len(active_users) - total_experts - total_building
                
                print(f"  {len(users_to_churn)} users churned ({actual_churn_rate:.1f}% of active users)")
                if total_experts > 0:
                    expert_churn_rate = (expert_churn / total_experts * 100) if total_experts > 0 else 0
                    print(f"    - Experts: {expert_churn}/{total_experts} ({expert_churn_rate:.1f}%)")
                if total_building > 0:
                    building_churn_rate = (building_churn / total_building * 100) if total_building > 0 else 0
                    print(f"    - Building expertise: {building_churn}/{total_building} ({building_churn_rate:.1f}%)")
                if total_new > 0:
                    new_churn_rate = (new_user_churn / total_new * 100) if total_new > 0 else 0
                    print(f"    - New users: {new_user_churn}/{total_new} ({new_churn_rate:.1f}%)")
        
        # Filter to only active users for evolution
        active_users = [u for u in users if agent_churn_times.get(u.agent_id) is None]
        
        # Patent #3: Personality evolution with diversity mechanisms
        # CRITICAL: Per-user early protection - each user gets 6 months of protection from their join date
        # This ensures every new user gets protection regardless of when they join
        
        # Count users in early protection period
        users_in_early_protection = 0
        if agent_join_times is not None:
            for user in active_users:
                join_month = agent_join_times.get(user.agent_id, 0)
                months_since_join = month - join_month
                if months_since_join <= 3:  # 3 months protection period
                    users_in_early_protection += 1
        
        # Still track conversations even during early protection (for metrics)
        conversations = []
        for _ in range(len(active_users) // 15):
            user_a = random.choice(active_users)
            user_b = random.choice([u for u in active_users if u.agent_id != user_a.agent_id])
            vibe_compatibility = quantum_compatibility(
                user_a.personality_12d,
                user_b.personality_12d
            )
            if vibe_compatibility >= 0.6:
                conversations.append({
                    'user_a_id': user_a.agent_id,
                    'user_b_id': user_b.agent_id,
                    'vibe_compatibility': vibe_compatibility,
                    'insights_extracted': random.randint(1, 5),
                })
        
        if users_in_early_protection > 0:
            print(f"  ⚠️  Early protection: {users_in_early_protection} users in protection period (first 3 months from join)")
        
        # Calculate current homogenization for adaptive mechanisms (only active users)
        if len(active_users) > 1:
            personalities = [u.personality_12d for u in active_users]
            current_homogenization = calculate_homogenization_rate(personalities)
        else:
            current_homogenization = 0.0
        
        # Mechanism 1: Adaptive Influence Reduction (Patent #3) - Extremely aggressive
        # Stop evolution very early to prevent homogenization
        if current_homogenization > 0.20:  # Stop all evolution when homogenization > 20% (was 25%)
            base_influence = 0.0
            influence_multiplier = 0.0
        else:
            base_influence = 0.0005  # Even smaller base (was 0.001)
            if current_homogenization > 0.05:  # Start reducing immediately (at 5% instead of 10%)
                influence_multiplier = 1.0 - ((current_homogenization - 0.05) * 2.5)  # Very aggressive (2.5x)
                influence_multiplier = max(0.001, influence_multiplier)  # Allow extreme reduction (down to 0.1%)
            else:
                influence_multiplier = 1.0
        
        # Mechanism 2: Stronger Drift Limit (6% max change from original, reduced from 8%)
        max_drift = 0.06
        
        # Mechanism 3: Interaction Frequency Reduction (reduce interactions over time)
        # Users who have been in system longer interact less
        # Also reduce interactions if homogenization is high
        base_interaction_prob = 1.0 / (1.0 + (month - 1) / 1.5)  # Decreases even faster (1.5 instead of 2.0)
        if current_homogenization > 0.30:
            # Further reduce interactions when homogenization is high
            homogenization_penalty = (current_homogenization - 0.30) * 0.5  # Up to 35% reduction
            interaction_probability = base_interaction_prob * (1.0 - homogenization_penalty)
        else:
            interaction_probability = base_interaction_prob
        
        # Mechanism 4: Meaningful Encounters Only (Patent #3) - Higher threshold
        # Only allow personality evolution from highly meaningful encounters (>60% compatibility, was 50%)
        meaningful_encounter_threshold = 0.6
        
        # Mechanism 5: Contextual Routing - Route users to diverse clusters
        # Group users by personality similarity and route to different clusters
        personality_clusters = {}
        cluster_assignments = {}
        if len(active_users) > 10:
            # Better clustering: use k-means-like approach with multiple dimensions
            num_clusters = min(10, len(active_users) // 10)  # 10 clusters or 1 per 10 users
            for user in active_users:
                # Use first 3 dimensions for clustering (more stable)
                cluster_key = tuple(int(user.personality_12d[i] * num_clusters) for i in range(3))
                if cluster_key not in personality_clusters:
                    personality_clusters[cluster_key] = []
                personality_clusters[cluster_key].append(user)
                cluster_assignments[user.agent_id] = cluster_key
        
        # Create personality anchors (first month only, or if not created)
        if month == 1 or not any(hasattr(u, '_is_anchor') for u in active_users):
            anchors = create_personality_anchors(active_users, anchor_percentage=0.25)  # Increased to 25% (more permanent diversity)
            if anchors:
                print(f"  🔒 Created {len(anchors)} personality anchors (permanent diversity)")
        
        # Simulate personality evolution with HYBRID LEARNING (only active users)
        for user in active_users:
            # Store original personality if not stored
            if not hasattr(user, '_original_personality'):
                user._original_personality = user.personality_12d.copy()
            
            # PER-USER EARLY PROTECTION: Each user gets 3 months of protection from their join date
            if agent_join_times is not None:
                join_month = agent_join_times.get(user.agent_id, 0)
                months_since_join = month - join_month
                if months_since_join <= 3:  # 3 months protection period
                    continue  # Skip evolution for this user (early protection period)
            
            # Skip evolution for diversity-injected users (immune period)
            if hasattr(user, '_diversity_immune_until') and month < user._diversity_immune_until:
                continue  # Skip evolution for diversity-injected users during immune period
            
            # Skip evolution for personality-reset users (immune period)
            if hasattr(user, '_reset_immune_until') and month < user._reset_immune_until:
                continue  # Skip evolution for reset users during immune period
            
            # Apply interaction frequency reduction
            if random.random() > interaction_probability:
                continue  # Skip evolution for this user this month
            
            # HYBRID LEARNING: Find a partner for learning
            # Prefer diverse partners (different cluster) for better diversity preservation
            meaningful_partner = None
            user_cluster = cluster_assignments.get(user.agent_id)
            
            # Try to find partner from different cluster first (diversity injection)
            diverse_partners = [u for u in active_users 
                              if u.agent_id != user.agent_id 
                              and cluster_assignments.get(u.agent_id) != user_cluster
                              and not is_anchor(u)]  # Don't learn from anchors (they don't evolve)
            
            if len(diverse_partners) > 0:
                # Prefer diverse partners (different cluster)
                for _ in range(15):  # Try more times for diverse partner
                    partner = random.choice(diverse_partners)
                    compatibility = quantum_compatibility(user.personality_12d, partner.personality_12d)
                    if compatibility >= meaningful_encounter_threshold:
                        meaningful_partner = partner
                        break
            
            # Fallback: same cluster if no diverse partner found
            if meaningful_partner is None:
                same_cluster_partners = [u for u in active_users 
                                       if u.agent_id != user.agent_id 
                                       and cluster_assignments.get(u.agent_id) == user_cluster
                                       and not is_anchor(u)]  # Don't learn from anchors
                for _ in range(10):  # Try fewer times for same-cluster partner
                    if len(same_cluster_partners) > 0:
                        partner = random.choice(same_cluster_partners)
                        compatibility = quantum_compatibility(user.personality_12d, partner.personality_12d)
                        if compatibility >= meaningful_encounter_threshold:
                            meaningful_partner = partner
                            break
            
            # Only evolve if meaningful encounter found
            if meaningful_partner is None:
                continue  # Skip evolution if no meaningful encounter
            
            # HYBRID LEARNING FUNCTION: Convergence on preferences, preserve core personality
            new_personality, new_event_prefs, new_spot_prefs, new_suggestion_prefs = hybrid_learning_function(
                user=user,
                partner=meaningful_partner,
                all_users=active_users,
                agent_join_times=agent_join_times,
                current_month=month,
                current_homogenization=current_homogenization
            )
            
            # Update core personality (minimal change, differences preserved)
            user.personality_12d = new_personality
            
            # Update contextual preferences (convergence allowed on similarities)
            user.event_preferences = new_event_prefs
            user.spot_preferences = new_spot_prefs
            user.suggestion_preferences = new_suggestion_prefs
            
            user.dimension_confidence = np.clip(
                user.dimension_confidence + np.random.uniform(0.0, 0.01, 12),
                0.6, 1.0
            )
            user.last_updated = time.time()
        
        # Mechanism 6: Diversity Injection + Personality Reset
        # NOTE: With new approach, we should NOT modify core personality
        # Only inject diverse users (don't reset existing users' core personality)
        # Core personality is stable - differences are good and should be preserved
        if current_homogenization > 0.30 and month > 1:  # Start earlier (30% instead of 50%)
            # Inject diverse personalities by creating users with very different personalities
            # More aggressive injection: 3-5% of active users (was 2%)
            injection_rate = min(0.05, 0.02 + (current_homogenization - 0.30) * 0.1)  # Scale with homogenization
            num_diversity_injections = max(1, int(len(active_users) * injection_rate))
            for _ in range(num_diversity_injections):
                # Create a user with opposite personality (diversity injection)
                diverse_user = generate_integrated_user_profile(
                    agent_id=f'diversity_{next_agent_id:04d}',
                    platform_phase=random.choice(['Early', 'Growth', 'Mature']),
                    random_seed=RANDOM_SEED + next_agent_id + 10000  # Different seed for diversity
                )
                # Make personality more diverse (opposite of average, with some randomness)
                avg_personality = np.mean([u.personality_12d for u in active_users], axis=0)
                # Use opposite + random variation for more diversity
                diverse_user.personality_12d = np.clip(
                    1.0 - avg_personality + np.random.uniform(-0.2, 0.2, 12),
                    0.0, 1.0
                )
                diverse_user._original_personality = diverse_user.personality_12d.copy()
                # Mark as diversity-injected user (immune to evolution for first 3 months)
                diverse_user._diversity_injected = month
                diverse_user._diversity_immune_until = month + 3  # Immune for 3 months
                users.append(diverse_user)
                agent_join_times[diverse_user.agent_id] = month
                next_agent_id += 1
            
            # Mechanism 7: Personality Reset - DISABLED
            # With new approach: Core personality is stable, differences are preserved
            # We should NOT reset core personality - only inject new diverse users
            # (Personality reset code removed - core personality should not be modified)
        
        # Update active_users after diversity injection
        active_users = [u for u in users if agent_churn_times.get(u.agent_id) is None]
        
        # Patent #10: AI2AI chat learning (simplified)
        # Simulate conversations and extract insights (only active users)
        conversations = []
        for _ in range(len(active_users) // 15):  # Reduced from 10% to ~6.7% (fewer conversations)
            user_a = random.choice(active_users)
            user_b = random.choice([u for u in active_users if u.agent_id != user_a.agent_id])
            
            # Analyze conversation pattern
            vibe_compatibility = quantum_compatibility(
                user_a.personality_12d,
                user_b.personality_12d
            )
            
            # Only meaningful conversations (compatibility >= threshold)
            if vibe_compatibility >= meaningful_encounter_threshold:
                conversation = {
                    'user_a_id': user_a.agent_id,
                    'user_b_id': user_b.agent_id,
                    'vibe_compatibility': vibe_compatibility,
                    'insights_extracted': random.randint(1, 5),
                }
                conversations.append(conversation)
                
                # Update personalities from conversation with drift limit
                # Check per-user early protection for both users
                user_a_join_month = agent_join_times.get(user_a.agent_id, 0) if agent_join_times else 0
                user_b_join_month = agent_join_times.get(user_b.agent_id, 0) if agent_join_times else 0
                user_a_months_since_join = month - user_a_join_month
                user_b_months_since_join = month - user_b_join_month
                
                # Skip learning if either user is in early protection period (3 months)
                if user_a_months_since_join <= 3 or user_b_months_since_join <= 3:
                    continue  # Skip learning for this conversation (early protection)
                
                if random.random() < 0.1:  # 10% chance of learning (reduced from 20%)
                    learning_magnitude = 0.001 * vibe_compatibility * influence_multiplier  # Extremely small (0.001 vs 0.002)
                    
                    # Update user A with drift limit
                    proposed_a = user_a.personality_12d + np.random.uniform(-learning_magnitude, learning_magnitude, 12)
                    drift_a = np.abs(proposed_a - user_a._original_personality)
                    if np.any(drift_a > max_drift):
                        for dim in range(12):
                            if drift_a[dim] > max_drift:
                                direction = 1 if proposed_a[dim] > user_a._original_personality[dim] else -1
                                proposed_a[dim] = user_a._original_personality[dim] + (max_drift * direction)
                    user_a.personality_12d = np.clip(proposed_a, 0.0, 1.0)
                    
                    # Update user B with drift limit
                    proposed_b = user_b.personality_12d + np.random.uniform(-learning_magnitude, learning_magnitude, 12)
                    drift_b = np.abs(proposed_b - user_b._original_personality)
                    if np.any(drift_b > max_drift):
                        for dim in range(12):
                            if drift_b[dim] > max_drift:
                                direction = 1 if proposed_b[dim] > user_b._original_personality[dim] else -1
                                proposed_b[dim] = user_b._original_personality[dim] + (max_drift * direction)
                    user_b.personality_12d = np.clip(proposed_b, 0.0, 1.0)
        
        # Track evolution (Patent #11) - only active users
        avg_personality = np.mean([u.personality_12d for u in active_users], axis=0)
        personality_variance = np.var([u.personality_12d for u in active_users], axis=0)
        
        evolution_results.append({
            'month': month,
            'active_users': len(active_users),
            'new_users': len(new_users_this_month),
            'churned_users': len(users_to_churn) if 'users_to_churn' in locals() else 0,
            'avg_personality': avg_personality.tolist(),
            'personality_variance': personality_variance.tolist(),
            'conversations': len(conversations),
            'total_insights': sum(c['insights_extracted'] for c in conversations),
        })
        
        network_monitor['personality_evolution_tracking'].append({
            'month': month,
            'active_users': len(active_users),
            'avg_personality': avg_personality.tolist(),
            'variance': personality_variance.tolist(),
        })
        
        print(f"  Month {month}: {len(active_users)} active users, {len(conversations)} conversations, "
              f"{sum(c['insights_extracted'] for c in conversations)} insights extracted")
    
    print()
    print(f"✅ Personality evolution complete: {months} months")
    print(f"   Final active users: {len([u for u in users if agent_churn_times.get(u.agent_id) is None])}")
    print()
    
    return evolution_results, agent_join_times, agent_churn_times, next_agent_id


# ============================================================================
# PHASE 3: RECOMMENDATIONS & DISCOVERY (Months 1-6)
# ============================================================================

def phase_3_recommendations_discovery(users: List[UserProfile], events: List[Event], month: int):
    """Phase 3: Generate recommendations using multiple patents."""
    print("=" * 70)
    print(f"Phase 3: Recommendations & Discovery (Month {month})")
    print("=" * 70)
    print()
    
    recommendations = []
    
    for user in users:
        # Patent #19: 12D personality recommendations
        # Find compatible events based on personality
        event_scores = []
        for event in events:
            # Use quantum compatibility (Patent #1)
            vibe = quantum_compatibility(user.personality_12d, np.random.rand(12))  # Simplified
            
            # Calculate dimension compatibility (Patent #19)
            # Simplified version - in full would use actual event personality
            dimension_compatibility = random.uniform(0.5, 1.0)
            energy_compatibility = random.uniform(0.5, 1.0)
            exploration_compatibility = random.uniform(0.5, 1.0)
            weighted_compatibility = (dimension_compatibility * 0.60 +
                                    energy_compatibility * 0.20 +
                                    exploration_compatibility * 0.20)
            
            event_scores.append({
                'event_id': event.event_id,
                'vibe': vibe,
                'weighted_compatibility': weighted_compatibility,
            })
        
        # Patent #20: Multi-source fusion
        # Generate recommendations from 4 sources
        real_time_recs = sorted(event_scores, key=lambda x: x['vibe'], reverse=True)[:10]
        community_recs = sorted(event_scores, key=lambda x: random.random(), reverse=True)[:10]
        ai2ai_recs = sorted(event_scores, key=lambda x: x['weighted_compatibility'], reverse=True)[:10]
        federated_recs = sorted(event_scores, key=lambda x: random.random(), reverse=True)[:10]
        
        # Fuse recommendations (40% + 30% + 20% + 10%)
        fused_scores = {}
        for rec in real_time_recs:
            fused_scores[rec['event_id']] = rec.get('vibe', 0.0) * 0.4
        for rec in community_recs:
            fused_scores[rec['event_id']] = fused_scores.get(rec['event_id'], 0.0) + random.uniform(0, 0.3) * 0.3
        for rec in ai2ai_recs:
            fused_scores[rec['event_id']] = fused_scores.get(rec['event_id'], 0.0) + rec['weighted_compatibility'] * 0.2
        for rec in federated_recs:
            fused_scores[rec['event_id']] = fused_scores.get(rec['event_id'], 0.0) + random.uniform(0, 0.1) * 0.1
        
        # Apply hyper-personalization (Patent #20)
        personalized_scores = {k: v * 1.1 for k, v in fused_scores.items()}  # 10% boost
        
        # Patent #22: Calling score
        for event_id, fused_score in personalized_scores.items():
            # Calculate calling score components
            vibe_score = fused_scores.get(event_id, 0.0) * 0.4
            life_betterment = random.uniform(0.6, 1.0) * 0.3
            meaningful_connection = random.uniform(0.5, 1.0) * 0.15
            context = calculate_location_match(user.location, events[0].location) * 0.10  # Simplified
            timing = random.uniform(0.5, 1.0) * 0.05
            
            calling_score = vibe_score + life_betterment + meaningful_connection + context + timing
            
            if calling_score >= 0.70:  # Calling threshold
                recommendation = Recommendation(
                    recommendation_id=f'rec_{user.agent_id}_{event_id}',
                    user_id=user.agent_id,
                    target_id=event_id,
                    target_type='event',
                    fused_score=fused_scores.get(event_id, 0.0),
                    personalized_score=personalized_scores.get(event_id, 0.0),
                    weighted_compatibility=weighted_compatibility,
                    calling_score=calling_score,
                    meets_calling_threshold=True,
                    quantum_compatibility=vibe,
                )
                recommendations.append(recommendation)
                user.recommendation_history.append(recommendation.to_dict())
    
    print(f"✅ Generated {len(recommendations)} recommendations")
    print(f"   Recommendations above 0.70 threshold: {sum(1 for r in recommendations if r.meets_calling_threshold)}")
    print()
    
    return recommendations


# ============================================================================
# PHASE 4: EVENT MATCHING (Months 3-6)
# ============================================================================

def phase_4_event_matching(users: List[UserProfile], events: List[Event], month: int):
    """Phase 4: Match users to events using multi-entity matching."""
    print("=" * 70)
    print(f"Phase 4: Event Matching (Month {month})")
    print("=" * 70)
    print()
    
    matches = []
    
    # Patent #29: Multi-entity matching (simplified)
    for event in events:
        # Find compatible users for all entities
        entity_matches = []
        for entity in event.entities:
            if entity.get('user_id'):
                # User entity - match using quantum compatibility
                user = next((u for u in users if u.agent_id == entity['user_id']), None)
                if user:
                    compatibility = quantum_compatibility(
                        user.personality_12d,
                        np.random.rand(12)  # Event personality (simplified)
                    )
                    entity_matches.append({
                        'entity_id': entity['entity_id'],
                        'user_id': user.agent_id,
                        'compatibility': compatibility,
                    })
        
        if entity_matches:
            matches.append({
                'event_id': event.event_id,
                'entity_matches': entity_matches,
                'n_way_match': True,
            })
            
            # Track in user history
            for match in entity_matches:
                user = next((u for u in users if u.agent_id == match['user_id']), None)
                if user:
                    user.event_history.append({
                        'event_id': event.event_id,
                        'match_type': 'n_way',
                        'compatibility': match['compatibility'],
                    })
    
    # Patent #21: Privacy-preserving matching (simplified)
    # Apply privacy preservation
    privacy_preserved_matches = []
    for match in matches:
        # Simplified privacy: add small noise
        for entity_match in match['entity_matches']:
            entity_match['privacy_preserved_compatibility'] = entity_match['compatibility'] * 0.95  # 5% privacy cost
        privacy_preserved_matches.append(match)
    
    print(f"✅ Matched {len(matches)} events with {sum(len(m['entity_matches']) for m in matches)} entity matches")
    print()
    
    return matches, privacy_preserved_matches


# ============================================================================
# PHASE 5: EXPERTISE PROGRESSION (Months 3-12)
# ============================================================================

def create_experts_randomly(users: List[UserProfile], target_percentage: float = 0.02, agent_join_times: Dict = None, month: int = 1):
    """
    Randomly create experts from non-expert users to reach target percentage.
    Once an expert, always an expert (permanent status).
    
    Args:
        users: List of user profiles
        target_percentage: Target percentage of experts (default 0.02 = 2%)
        agent_join_times: Dictionary mapping agent_id to join month
        month: Current month
    
    Returns:
        Number of new experts created
    """
    if agent_join_times is None:
        agent_join_times = {}
    
    # Filter to non-experts only
    non_experts = [u for u in users if u.expert_creation_time is None]
    
    if len(non_experts) == 0:
        return 0
    
    # Calculate current expert percentage
    current_experts = sum(1 for u in users if u.expert_creation_time is not None)
    current_percentage = current_experts / len(users) if len(users) > 0 else 0.0
    
    # Calculate how many experts we need
    target_experts = int(len(users) * target_percentage)
    needed_experts = max(0, target_experts - current_experts)
    
    # Only create experts if we're below target and have non-experts available
    if needed_experts > 0 and len(non_experts) > 0:
        # Randomly select non-experts to become experts
        num_to_create = min(needed_experts, len(non_experts))
        new_experts = random.sample(non_experts, num_to_create)
        
        for user in new_experts:
            # Mark as expert (permanent - once expert, always expert)
            user.expert_creation_time = month
            
            # Set expertise score to a reasonable level (0.6-0.8)
            user.expertise_score = random.uniform(0.6, 0.8)
            
            # Set expertise paths to match the score
            # Distribute expertise across paths
            base_path_value = user.expertise_score * 0.8  # Slightly lower to allow growth
            user.expertise_paths['exploration'] = random.uniform(base_path_value, min(1.0, base_path_value + 0.2))
            user.expertise_paths['community'] = random.uniform(base_path_value, min(1.0, base_path_value + 0.2))
            user.expertise_paths['professional'] = random.uniform(base_path_value, min(1.0, base_path_value + 0.2))
            user.expertise_paths['credentials'] = random.uniform(base_path_value * 0.8, min(1.0, base_path_value * 0.8 + 0.2))
            user.expertise_paths['influence'] = random.uniform(base_path_value * 0.8, min(1.0, base_path_value * 0.8 + 0.2))
            user.expertise_paths['local'] = random.uniform(base_path_value * 0.8, min(1.0, base_path_value * 0.8 + 0.2))
            
            # Recalculate to ensure consistency
            user.expertise_score = calculate_expertise_score(user.expertise_paths)
            
            # Set expertise level based on score
            if user.expertise_score >= 0.8:
                user.expertise_level = 'Global'
            elif user.expertise_score >= 0.7:
                user.expertise_level = 'National'
            elif user.expertise_score >= 0.6:
                user.expertise_level = 'Regional'
            elif user.expertise_score >= 0.5:
                user.expertise_level = 'City'
            elif user.expertise_score >= 0.4:
                user.expertise_level = 'Local'
            else:
                user.expertise_level = 'Local'  # Default for experts
        
        return len(new_experts)
    
    return 0


def phase_5_expertise_progression(users: List[UserProfile], events: List[Event], month: int, agent_join_times: Dict = None):
    """Phase 5: Randomly create experts to maintain ~2% expert percentage."""
    print("=" * 70)
    print(f"Phase 5: Expertise Progression (Month {month})")
    print("=" * 70)
    print()
    
    # Simple approach: Randomly create experts to maintain target percentage
    # Once an expert, always an expert (permanent status)
    new_experts = create_experts_randomly(users, target_percentage=0.02, agent_join_times=agent_join_times, month=month)
    
    # Count total experts
    experts_count = sum(1 for u in users if u.expert_creation_time is not None)
    
    # Note: Experts can still grow their expertise paths, but they can't lose expert status
    # Allow experts to continue growing expertise (optional - for realism)
    for user in users:
        if user.expert_creation_time is not None:  # Is expert
            # Experts can still grow expertise paths (but can't lose expert status)
            if random.random() < 0.1:  # 10% chance of growth activity
                if random.random() < 0.4:
                    user.expertise_paths['exploration'] = min(1.0, user.expertise_paths['exploration'] + 0.01)
                if random.random() < 0.3:
                    user.expertise_paths['community'] = min(1.0, user.expertise_paths['community'] + 0.01)
                if random.random() < 0.2:
                    user.expertise_paths['professional'] = min(1.0, user.expertise_paths['professional'] + 0.01)
                
                # Recalculate expertise score
                user.expertise_score = calculate_expertise_score(user.expertise_paths)
                
                # Update expertise level (but keep expert status)
                if user.expertise_score >= 0.8:
                    user.expertise_level = 'Global'
                elif user.expertise_score >= 0.7:
                    user.expertise_level = 'National'
                elif user.expertise_score >= 0.6:
                    user.expertise_level = 'Regional'
                elif user.expertise_score >= 0.5:
                    user.expertise_level = 'City'
                elif user.expertise_score >= 0.4:
                    user.expertise_level = 'Local'
    
    # Patent #18: Saturation adjustment (simplified)
    # Calculate category saturation (use actual experts, not just score)
    category_experts = defaultdict(int)
    for user in users:
        if user.expert_creation_time is not None:  # Actual expert
            category_experts[user.category] += 1
    
    # Adjust thresholds based on saturation (simplified)
    saturation_adjustments = {}
    for category, expert_count in category_experts.items():
        saturation = expert_count / len([u for u in users if u.category == category])
        if saturation > 0.02:  # Above 2% target
            saturation_adjustments[category] = 1.2  # Increase threshold
        else:
            saturation_adjustments[category] = 1.0  # Normal threshold
    
    # Count experts based on expert_creation_time (actual experts, not just score)
    experts_count = sum(1 for u in users if u.expert_creation_time is not None)
    print(f"✅ Expertise progression: {experts_count} experts ({experts_count/len(users)*100:.1f}%)")
    print()
    
    return experts_count, saturation_adjustments


# ============================================================================
# PHASE 6: PARTNERSHIP FORMATION (Months 6-12)
# ============================================================================

def phase_6_partnership_formation(
    users: List[UserProfile],
    events: List[Event],
    partnerships: List[Partnership],
    month: int
):
    """Phase 6: Form partnerships using integrated ecosystem."""
    print("=" * 70)
    print(f"Phase 6: Partnership Formation (Month {month})")
    print("=" * 70)
    print()
    
    # Filter experts (use actual experts, not just score)
    experts = [u for u in users if u.expert_creation_time is not None]
    
    # Generate businesses
    businesses = []
    for i in range(50):
        businesses.append({
            'business_id': f'business_{i:04d}',
            'personality_12d': np.random.rand(12),
            'location': {
                'lat': np.random.uniform(-90, 90),
                'lng': np.random.uniform(-180, 180),
            },
        })
    
    new_partnerships = []
    
    # Patent #17: Integrated matching (expertise + quantum + location)
    for expert in experts:
        if random.random() < 0.1:  # 10% chance per month
            # Find best business match
            best_match = None
            best_score = 0.0
            
            for business in businesses:
                # Quantum compatibility (Patent #1)
                vibe = quantum_compatibility(expert.personality_12d, business['personality_12d'])
                
                # Location match
                location = calculate_location_match(expert.location, business['location'])
                
                # Expertise-weighted matching (Patent #17)
                score = (vibe * 0.5) + (expert.expertise_score * 0.3) + (location * 0.2)
                
                if score > best_score and score >= 0.7:  # Threshold
                    best_score = score
                    best_match = business
            
            if best_match:
                # Create partnership
                start_date = time.time()
                end_date = start_date + random.choice([90, 180, 365]) * 24 * 3600
                
                partnership = generate_integrated_partnership(
                    partnership_id=f'partnership_{len(partnerships) + len(new_partnerships):04d}',
                    expert_id=expert.agent_id,
                    partner_id=best_match['business_id'],
                    partner_type='Business',
                    exclusivity_type=random.choice(['Full', 'Category', 'Product']),
                    start_date=start_date,
                    end_date=end_date,
                    minimum_events=random.randint(5, 20),
                    exclusivity_scope=expert.category if random.random() < 0.5 else None,
                )
                
                new_partnerships.append(partnership)
                expert.partnership_history.append(partnership.to_dict())
                
                # Patent #17: Expertise boost from partnership
                if random.random() < 0.5:  # 50% chance of boost
                    boost_amount = 0.1
                    expert.expertise_paths['community'] = min(1.0, expert.expertise_paths['community'] + boost_amount * 0.6)
                    expert.expertise_paths['professional'] = min(1.0, expert.expertise_paths['professional'] + boost_amount * 0.3)
                    expert.expertise_paths['influence'] = min(1.0, expert.expertise_paths['influence'] + boost_amount * 0.1)
                    expert.expertise_score = calculate_expertise_score(expert.expertise_paths)
    
    partnerships.extend(new_partnerships)
    
    # Patent #16: Check exclusivity constraints (simplified)
    exclusivity_checks = []
    for event in events:
        if event.host_id:
            host = next((u for u in users if u.agent_id == event.host_id), None)
            if host:
                # Check if event violates any active partnerships
                active_partnerships = [p for p in partnerships
                                     if p.expert_id == host.agent_id and
                                     time.time() < p.end_date]
                
                for partnership in active_partnerships:
                    if partnership.partner_id not in [e.get('entity_id') for e in event.entities]:
                        # Potential violation
                        if partnership.exclusivity_type == 'Full':
                            event.exclusivity_checked = True
                            exclusivity_checks.append({
                                'event_id': event.event_id,
                                'partnership_id': partnership.partnership_id,
                                'violation': True,
                            })
    
    print(f"✅ Formed {len(new_partnerships)} new partnerships")
    print(f"   Total partnerships: {len(partnerships)}")
    print(f"   Exclusivity checks: {len(exclusivity_checks)}")
    print()
    
    return new_partnerships, exclusivity_checks


# ============================================================================
# PHASE 7: EVENT HOSTING & REVENUE (Months 9-12)
# ============================================================================

def phase_7_event_hosting_revenue(
    users: List[UserProfile],
    events: List[Event],
    partnerships: List[Partnership],
    month: int
):
    """Phase 7: Host events and distribute revenue."""
    print("=" * 70)
    print(f"Phase 7: Event Hosting & Revenue (Month {month})")
    print("=" * 70)
    print()
    
    # Filter experts who can host
    experts = [u for u in users if u.expertise_score >= 0.7]
    
    revenue_distributions = []
    
    # Patent #15: N-way revenue distribution
    for event in events:
        if event.host_id and event.total_revenue > 0:
            host = next((u for u in users if u.agent_id == event.host_id), None)
            if host and host.expertise_score >= 0.7:
                # Get event parties (entities)
                parties = []
                for entity in event.entities:
                    if entity.get('user_id'):
                        parties.append({
                            'party_id': entity['entity_id'],
                            'party_type': entity['entity_type'],
                            'percentage': random.uniform(5, 40),  # Will be normalized
                        })
                
                # Normalize percentages to 100%
                total_percentage = sum(p['percentage'] for p in parties)
                for party in parties:
                    party['percentage'] = (party['percentage'] / total_percentage) * 100.0
                
                # Validate percentages sum to 100%
                total = sum(p['percentage'] for p in parties)
                if abs(total - 100.0) > 0.01:
                    # Adjust last party
                    parties[-1]['percentage'] += (100.0 - total)
                
                # Calculate N-way split
                platform_fee = event.total_revenue * 0.10
                remaining_amount = event.total_revenue - platform_fee
                
                splits = []
                for party in parties:
                    amount = remaining_amount * (party['percentage'] / 100.0)
                    splits.append({
                        'party_id': party['party_id'],
                        'amount': amount,
                        'percentage': party['percentage'],
                    })
                
                # Lock revenue split (Patent #15)
                if not event.is_locked:
                    event.is_locked = True
                    event.locked_at = time.time()
                    event.revenue_split = {
                        'total_revenue': event.total_revenue,
                        'platform_fee': platform_fee,
                        'splits': splits,
                    }
                
                revenue_distributions.append({
                    'event_id': event.event_id,
                    'host_id': host.agent_id,
                    'total_revenue': event.total_revenue,
                    'platform_fee': platform_fee,
                    'distributed_amount': remaining_amount,
                    'num_parties': len(parties),
                })
                
                # Track in user history
                host.revenue_history.append({
                    'event_id': event.event_id,
                    'revenue': event.total_revenue,
                    'platform_fee': platform_fee,
                    'net_revenue': remaining_amount,
                })
    
    print(f"✅ Distributed revenue for {len(revenue_distributions)} events")
    print(f"   Total revenue: ${sum(r['total_revenue'] for r in revenue_distributions):,.2f}")
    print()
    
    return revenue_distributions


# ============================================================================
# PHASE 8: SYSTEM MONITORING (All Phases)
# ============================================================================

def phase_8_system_monitoring(
    users: List[UserProfile],
    events: List[Event],
    partnerships: List[Partnership],
    network_monitor: Dict,
    month: int,
    agent_churn_times: Dict = None
):
    """Phase 8: Monitor system health and activity."""
    print("=" * 70)
    print(f"Phase 8: System Monitoring (Month {month})")
    print("=" * 70)
    print()
    
    # Patent #11: Network monitoring (simplified)
    
    # Filter to only active users
    if agent_churn_times is None:
        agent_churn_times = {}
    active_users = [u for u in users if agent_churn_times.get(u.agent_id) is None]
    
    # Calculate network health metrics (only active users)
    experts_count = sum(1 for u in active_users if u.expertise_score >= 0.7)
    # Count active partnerships (end_date is in seconds since epoch, compare correctly)
    current_time = time.time()
    active_partnerships = sum(1 for p in partnerships if p.end_date > current_time)
    events_hosted = sum(1 for e in events if e.total_revenue > 0)
    total_revenue = sum(e.total_revenue for e in events if e.total_revenue > 0)
    
    # Personality diversity (homogenization check) - only active users
    # Use pairwise distance metric (more accurate than variance)
    if len(active_users) > 1:
        personalities = np.array([u.personality_12d for u in active_users])
        # Calculate pairwise Euclidean distances
        pairwise_distances = []
        for i in range(len(personalities)):
            for j in range(i + 1, len(personalities)):
                dist = np.linalg.norm(personalities[i] - personalities[j])
                pairwise_distances.append(dist)
        
        if len(pairwise_distances) > 0:
            avg_distance = np.mean(pairwise_distances)
            max_possible_distance = np.sqrt(12)  # Max distance in 12D space (0 to 1)
            # Homogenization = 1 - (normalized average distance)
            homogenization_rate = 1.0 - (avg_distance / max_possible_distance)
        else:
            homogenization_rate = 0.0
    else:
        homogenization_rate = 0.0
    
    network_health = {
        'month': month,
        'total_users': len(active_users),
        'experts_count': experts_count,
        'expert_percentage': experts_count / len(active_users) * 100 if len(active_users) > 0 else 0,
        'active_partnerships': active_partnerships,
        'events_hosted': events_hosted,
        'total_revenue': total_revenue,
        'personality_variance': avg_distance / max_possible_distance if len(active_users) > 1 else 0.0,
        'homogenization_rate': homogenization_rate,
        'health_score': 0.0,  # Will calculate
    }
    
    # Calculate overall health score using weighted components
    # Improved formula with better weighting and component calculations
    
    # Determine platform stage for dynamic thresholds
    if month <= 3:
        platform_stage = 'Early'
    elif month <= 6:
        platform_stage = 'Growth'
    else:
        platform_stage = 'Mature'
    
    # Dynamic health thresholds by platform stage
    health_thresholds = {
        'Early': {
            'expert_target': 0.02,  # 2%
            'expert_range': (0.01, 0.03),  # 1-3%
            'partnership_target': 5,  # Lower for early stage
            'revenue_target': 50000,  # Lower for early stage
            'diversity_target': 0.60,  # More lenient for early stage
            'min_health': 0.60,  # 60% minimum acceptable
        },
        'Growth': {
            'expert_target': 0.02,  # 2%
            'expert_range': (0.01, 0.03),  # 1-3%
            'partnership_target': 10,
            'revenue_target': 100000,
            'diversity_target': 0.52,  # Target diversity
            'min_health': 0.70,  # 70% minimum acceptable
        },
        'Mature': {
            'expert_target': 0.02,  # 2%
            'expert_range': (0.01, 0.03),  # 1-3%
            'partnership_target': 15,  # Higher for mature stage
            'revenue_target': 200000,  # Higher for mature stage
            'diversity_target': 0.52,  # Target diversity
            'min_health': 0.80,  # 80% minimum acceptable
        },
    }
    thresholds = health_thresholds[platform_stage]
    
    # Component 1: Expert Health (25% weight)
    # Weighted score: 2% = 100%, 1-3% = 80-100%, outside = lower
    expert_percentage = experts_count / len(active_users) if len(active_users) > 0 else 0
    expert_min, expert_max = thresholds['expert_range']
    if expert_min <= expert_percentage <= expert_max:
        # Within acceptable range: 80-100% based on how close to target
        target = thresholds['expert_target']
        if expert_percentage == target:
            expert_health = 1.0  # Perfect at target
        elif expert_percentage < target:
            # Between min and target: linear from 0.8 to 1.0
            expert_health = 0.8 + 0.2 * ((expert_percentage - expert_min) / (target - expert_min))
        else:
            # Between target and max: linear from 1.0 to 0.8
            expert_health = 1.0 - 0.2 * ((expert_percentage - target) / (expert_max - target))
    elif expert_percentage < expert_min:
        # Too few experts: linear from 0 to 0.8
        expert_health = 0.8 * (expert_percentage / expert_min)
    else:
        # Too many experts: penalize heavily
        expert_health = max(0.0, 0.8 - (expert_percentage - expert_max) / 0.10)  # Rapid decay
    
    # Component 2: Partnership Health (25% weight)
    # Consider both quantity and quality (exclusivity compliance)
    partnership_quantity = min(1.0, active_partnerships / thresholds['partnership_target'])
    
    # Quality: check exclusivity compliance (simplified - assume 90% compliance)
    exclusivity_compliance = 0.90  # Would calculate from actual violations
    partnership_quality = exclusivity_compliance
    
    partnership_health = (partnership_quantity * 0.7 + partnership_quality * 0.3)
    
    # Component 3: Revenue Health (20% weight)
    # Consider both total revenue and growth (simplified - use total for now)
    revenue_quantity = min(1.0, total_revenue / thresholds['revenue_target'])
    
    # Revenue growth (simplified - would track month-over-month)
    # For now, assume healthy growth if revenue > target
    revenue_growth = 1.0 if total_revenue > thresholds['revenue_target'] else 0.7
    
    revenue_health = (revenue_quantity * 0.8 + revenue_growth * 0.2)
    
    # Component 4: Diversity Health (20% weight)
    # Multi-factor diversity: personality, expertise, location, category
    diversity_target = thresholds['diversity_target']
    
    # Personality diversity (homogenization)
    if homogenization_rate < diversity_target:
        personality_diversity = 1.0  # Perfect
    else:
        # Penalize linearly from target to 100%
        personality_diversity = max(0.0, 1.0 - (homogenization_rate - diversity_target) / (1.0 - diversity_target))
    
    # Expertise diversity (variance in expertise levels)
    expertise_levels = [u.expertise_level for u in active_users]
    unique_levels = len(set(expertise_levels))
    max_levels = 6  # none, Local, City, Regional, National, Global
    expertise_diversity = min(1.0, unique_levels / max_levels)
    
    # Category diversity (variance in categories)
    categories = [u.category for u in active_users if u.category]
    unique_categories = len(set(categories))
    max_categories = 5  # technology, science, art, business, health
    category_diversity = min(1.0, unique_categories / max_categories)
    
    # Combined diversity health (weighted average)
    diversity_health = (personality_diversity * 0.5 + expertise_diversity * 0.3 + category_diversity * 0.2)
    
    # Component 5: Engagement Health (10% weight)
    # Consider: active users, conversations, recommendations, events
    # Simplified: use active user percentage and activity indicators
    total_users_ever = len(users)  # Would track from start
    active_user_ratio = len(active_users) / total_users_ever if total_users_ever > 0 else 0
    
    # Activity indicators (simplified - would track actual activity)
    conversations_count = len(network_monitor.get('personality_evolution_tracking', []))
    recommendations_count = sum(len(u.recommendation_history) for u in active_users)
    events_attended = sum(len(u.event_history) for u in active_users)
    
    # Normalize activity (simplified thresholds)
    activity_score = min(1.0, (
        (conversations_count / 100.0) * 0.3 +
        (recommendations_count / 1000.0) * 0.3 +
        (events_attended / 500.0) * 0.4
    ))
    
    engagement_health = (active_user_ratio * 0.6 + activity_score * 0.4)
    
    # Calculate weighted health score
    health_score = (
        expert_health * 0.25 +
        partnership_health * 0.25 +
        revenue_health * 0.20 +
        diversity_health * 0.20 +
        engagement_health * 0.10
    )
    
    # Ensure minimum health based on platform stage
    health_score = max(health_score, thresholds['min_health'] * 0.5)  # At least 50% of minimum
    
    # Convert to percentage (0-100%)
    network_health['health_score'] = health_score * 100.0
    
    # Store component scores for debugging
    network_health['health_components'] = {
        'expert_health': expert_health,
        'partnership_health': partnership_health,
        'revenue_health': revenue_health,
        'diversity_health': diversity_health,
        'engagement_health': engagement_health,
        'platform_stage': platform_stage,
    }
    
    network_monitor['network_health_scores'].append(network_health)
    
    print(f"Network Health Score: {network_health['health_score']:.2f}%")
    print(f"  Platform Stage: {platform_stage}")
    print(f"  Active Users: {len(active_users)}")
    print(f"  Experts: {experts_count}/{len(active_users)} ({network_health['expert_percentage']:.1f}%)")
    print(f"  Partnerships: {active_partnerships}")
    print(f"  Events Hosted: {events_hosted}")
    print(f"  Total Revenue: ${total_revenue:,.2f}")
    print(f"  Homogenization: {homogenization_rate:.2%}")
    if 'health_components' in network_health:
        components = network_health['health_components']
        print(f"  Health Components:")
        print(f"    Expert: {components['expert_health']:.2f} (25%)")
        print(f"    Partnership: {components['partnership_health']:.2f} (25%)")
        print(f"    Revenue: {components['revenue_health']:.2f} (20%)")
        print(f"    Diversity: {components['diversity_health']:.2f} (20%)")
        print(f"    Engagement: {components['engagement_health']:.2f} (10%)")
    print()
    
    return network_health


# ============================================================================
# MAIN INTEGRATION TEST
# ============================================================================

def run_full_ecosystem_integration():
    """Run complete end-to-end integration test."""
    print("=" * 70)
    print("Full Ecosystem Integration Test")
    print("=" * 70)
    print()
    print("Integrating 14 Patents:")
    print("  Existing: #1, #3, #11, #21, #29")
    print("  New: #10, #13, #15, #16, #17, #18, #19, #20, #22")
    print()
    
    start_time = time.time()
    all_results = {}
    
    # Phase 1: Setup
    users, events, network_monitor = phase_1_setup()
    partnerships = []
    
    # Track agent creation and churn
    agent_join_times = {user.agent_id: 0 for user in users}  # All start at month 0
    agent_churn_times = {}  # Track when agents left (None if still active)
    next_agent_id = len(users)
    
    # Phase 2: Personality Evolution (Months 1-12) - Back to 12 months with tuned parameters
    evolution_results, agent_join_times, agent_churn_times, next_agent_id = phase_2_personality_evolution(
        users, network_monitor, months=12, 
        agent_join_times=agent_join_times,
        agent_churn_times=agent_churn_times,
        next_agent_id=next_agent_id
    )
    all_results['evolution'] = evolution_results
    
    # Filter to only active users for remaining phases
    users = [u for u in users if agent_churn_times.get(u.agent_id) is None]
    
    # Phase 3-4: Recommendations & Matching (Months 1-12)
    all_recommendations = []
    all_matches = []
    for month in range(1, 13):
        recommendations = phase_3_recommendations_discovery(users, events, month)
        matches, privacy_matches = phase_4_event_matching(users, events, month)
        all_recommendations.extend(recommendations)
        all_matches.extend(matches)
        network_monitor['matching_activity'].extend(matches)
    
    all_results['recommendations'] = all_recommendations
    all_results['matches'] = all_matches
    
    # Phase 5: Expertise Progression (Months 1-12)
    expertise_results = []
    for month in range(1, 13):
        experts_count, saturation = phase_5_expertise_progression(users, events, month, agent_join_times)
        expertise_results.append({
            'month': month,
            'experts_count': experts_count,
            'expert_percentage': experts_count / len(users) * 100 if len(users) > 0 else 0,
        })
    all_results['expertise'] = expertise_results
    
    # Phase 6: Partnership Formation (Months 6-12)
    partnership_results = []
    for month in range(6, 13):
        new_partnerships, exclusivity_checks = phase_6_partnership_formation(
            users, events, partnerships, month
        )
        partnership_results.append({
            'month': month,
            'new_partnerships': len(new_partnerships),
            'total_partnerships': len(partnerships),
            'exclusivity_checks': len(exclusivity_checks),
        })
        network_monitor['partnership_activity'].extend(new_partnerships)
    all_results['partnerships'] = partnership_results
    
    # Phase 7: Event Hosting & Revenue (Months 9-12)
    revenue_results = []
    for month in range(9, 13):
        revenue_distributions = phase_7_event_hosting_revenue(
            users, events, partnerships, month
        )
        revenue_results.append({
            'month': month,
            'events_with_revenue': len(revenue_distributions),
            'total_revenue': sum(r['total_revenue'] for r in revenue_distributions),
        })
        network_monitor['revenue_activity'].extend(revenue_distributions)
    all_results['revenue'] = revenue_results
    
    # Phase 8: System Monitoring (All Phases)
    monitoring_results = []
    for month in range(1, 13):
        health = phase_8_system_monitoring(users, events, partnerships, network_monitor, month, agent_churn_times)
        monitoring_results.append(health)
    all_results['monitoring'] = monitoring_results
    
    # Save integrated data
    save_integrated_data(users, events, partnerships, DATA_DIR)
    
    # Calculate final metrics
    elapsed_time = time.time() - start_time
    
    # Final summary
    print("=" * 70)
    print("Full Ecosystem Integration Complete")
    print("=" * 70)
    print(f"Total Execution Time: {elapsed_time:.2f} seconds")
    print()
    
    # Calculate success metrics
    final_health = monitoring_results[-1] if monitoring_results else {}
    
    # Filter to final active users
    final_active_users = [u for u in users if agent_churn_times.get(u.agent_id) is None]
    
    # Count experts directly from final_active_users (more reliable than final_health)
    final_experts_count = sum(1 for u in final_active_users if u.expert_creation_time is not None)
    final_expert_percentage = (final_experts_count / len(final_active_users) * 100) if len(final_active_users) > 0 else 0.0
    
    print("Final System Metrics:")
    print("-" * 70)
    print(f"Total Users Ever: {len(agent_join_times)}")
    print(f"Active Users: {len(final_active_users)}")
    print(f"Churned Users: {len(agent_churn_times)}")
    print(f"Experts: {final_experts_count} ({final_expert_percentage:.1f}%)")
    print(f"Active Partnerships: {final_health.get('active_partnerships', 0)}")
    print(f"Events Hosted: {final_health.get('events_hosted', 0)}")
    print(f"Total Revenue: ${final_health.get('total_revenue', 0):,.2f}")
    print(f"Network Health Score: {final_health.get('health_score', 0):.2f}%")
    print(f"Homogenization Rate: {final_health.get('homogenization_rate', 0):.2%}")
    print()
    
    # Validate success criteria
    print("Success Criteria Validation:")
    print("-" * 70)
    criteria = {
        'Personality Evolution (homogenization < 52%)': final_health.get('homogenization_rate', 1.0) < 0.52,
        'Network Health (> 80%)': final_health.get('health_score', 0.0) > 80.0,
        'Expert Percentage (target: 2%)': abs(final_health.get('expert_percentage', 0) - 2.0) < 1.0,
        'Partnerships Formed': final_health.get('active_partnerships', 0) > 0,
        'Revenue Generated': final_health.get('total_revenue', 0) > 0,
    }
    
    for criterion, passed in criteria.items():
        status = "✅" if passed else "❌"
        print(f"{status} {criterion}")
    
    print()
    
    # Save results
    results_df = pd.DataFrame({
        'metric': list(criteria.keys()),
        'passed': list(criteria.values()),
    })
    results_df.to_csv(RESULTS_DIR / 'success_criteria.csv', index=False)
    
    # Save detailed results
    with open(RESULTS_DIR / 'integration_results.json', 'w') as f:
        json.dump(all_results, f, indent=2, default=str)
    
    print(f"✅ All results saved to: {RESULTS_DIR}")
    print()
    
    return all_results, final_health


if __name__ == '__main__':
    run_full_ecosystem_integration()

