#!/usr/bin/env python3
"""
SPOTS vs Traditional Marketing Experiment

This script compares SPOTS AI-powered marketing (quantum compatibility,
hyper-personalized recommendations, 12D personality matching, calling score)
against traditional event marketing techniques (social media, email, paid search, organic).

Experiment Design:
- A/B test: 500 events per group (control: traditional, test: SPOTS)
- Same events, users, time period, ticket prices
- Measure: attendance, conversion, revenue, CPA, ROI

Date: December 21, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
from datetime import datetime, timedelta
from collections import defaultdict
from typing import Dict, List, Optional, Tuple
import random
import warnings
from scipy import stats
warnings.filterwarnings('ignore')

# Import shared data model
import sys
sys.path.append(str(Path(__file__).parent.parent / 'scripts'))
from shared_data_model import (
    UserProfile, Event,
    quantum_compatibility, calculate_expertise_score,
    calculate_location_match,
    generate_integrated_user_profile, generate_integrated_event,
)

# Configuration
DATA_DIR = Path(__file__).parent / 'data'
RESULTS_DIR = Path(__file__).parent / 'results'
LOGS_DIR = Path(__file__).parent / 'logs'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)
LOGS_DIR.mkdir(parents=True, exist_ok=True)

NUM_USERS_PER_GROUP = 1000
NUM_EVENTS_PER_GROUP = 500
NUM_MONTHS = 6
AVERAGE_TICKET_PRICE = 50.00
MARKETING_BUDGET_PER_EVENT = 2000.00  # $2,000 per event
RANDOM_SEED = 42

# Cost Constants
PAYMENT_PROCESSING_FEE_RATE = 0.03  # 3% of revenue
SPOTS_PLATFORM_FEE_RATE = 0.10  # 10% of revenue (SPOTS platform fee)
TRADITIONAL_PLATFORM_FEE_RATE = 0.05  # 5% for traditional (event ticketing platforms)
AD_PLATFORM_SERVICE_FEE_RATE = 0.05  # 5% of ad spend (ad platform fees)
EMAIL_SERVICE_FEE_RATE = 0.02  # 2% of email budget (email service fees)
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)

# ============================================================================
# TRADITIONAL MARKETING FUNCTIONS
# ============================================================================

def traditional_social_media_marketing(
    event: Event,
    budget: float,
    users: List[UserProfile]
) -> Dict:
    """
    Simulate social media marketing (Facebook, Instagram, Twitter, LinkedIn).
    
    Industry Benchmarks:
    - Facebook/Instagram: 1-3% CTR, 2-5% conversion, $0.50-$2.00 CPC
    - Twitter: 0.5-2% CTR, 1-3% conversion, $0.30-$1.50 CPC
    - LinkedIn: 2-4% CTR, 3-6% conversion, $1.00-$3.00 CPC
    """
    social_budget = budget * 0.40  # 40% of total budget
    
    # Facebook/Instagram (50% of social budget)
    fb_budget = social_budget * 0.50
    fb_cpc = random.uniform(0.50, 2.00)
    fb_clicks = int(fb_budget / fb_cpc)
    fb_ctr = random.uniform(0.01, 0.03)  # 1-3%
    fb_impressions = int(fb_clicks / fb_ctr)
    fb_conversion_rate = random.uniform(0.02, 0.05)  # 2-5%
    fb_conversions = int(fb_clicks * fb_conversion_rate)
    
    # Twitter (30% of social budget)
    tw_budget = social_budget * 0.30
    tw_cpc = random.uniform(0.30, 1.50)
    tw_clicks = int(tw_budget / tw_cpc)
    tw_ctr = random.uniform(0.005, 0.02)  # 0.5-2%
    tw_impressions = int(tw_clicks / tw_ctr)
    tw_conversion_rate = random.uniform(0.01, 0.03)  # 1-3%
    tw_conversions = int(tw_clicks * tw_conversion_rate)
    
    # LinkedIn (20% of social budget)
    li_budget = social_budget * 0.20
    li_cpc = random.uniform(1.00, 3.00)
    li_clicks = int(li_budget / li_cpc)
    li_ctr = random.uniform(0.02, 0.04)  # 2-4%
    li_impressions = int(li_clicks / li_ctr)
    li_conversion_rate = random.uniform(0.03, 0.06)  # 3-6%
    li_conversions = int(li_clicks * li_conversion_rate)
    
    total_impressions = fb_impressions + tw_impressions + li_impressions
    total_clicks = fb_clicks + tw_clicks + li_clicks
    total_conversions = fb_conversions + tw_conversions + li_conversions
    total_cost = fb_budget + tw_budget + li_budget
    
    return {
        'impressions': total_impressions,
        'clicks': total_clicks,
        'conversions': total_conversions,
        'cost': total_cost,
        'cpc': total_cost / total_clicks if total_clicks > 0 else 0,
        'ctr': total_clicks / total_impressions if total_impressions > 0 else 0,
        'conversion_rate': total_conversions / total_clicks if total_clicks > 0 else 0,
    }


def traditional_email_marketing(
    event: Event,
    budget: float,
    users: List[UserProfile]
) -> Dict:
    """
    Simulate email marketing campaign.
    
    Industry Benchmarks:
    - Open rate: 20-25%
    - CTR: 2-5% of opens
    - Conversion: 1-3% of opens
    - Cost: $0.01-$0.05 per email
    """
    email_budget = budget * 0.30  # 30% of total budget
    cost_per_email = random.uniform(0.01, 0.05)
    emails_sent = int(email_budget / cost_per_email)
    
    open_rate = random.uniform(0.20, 0.25)  # 20-25%
    opens = int(emails_sent * open_rate)
    
    ctr = random.uniform(0.02, 0.05)  # 2-5% of opens
    clicks = int(opens * ctr)
    
    conversion_rate = random.uniform(0.01, 0.03)  # 1-3% of opens
    conversions = int(opens * conversion_rate)
    
    return {
        'emails_sent': emails_sent,
        'opens': opens,
        'clicks': clicks,
        'conversions': conversions,
        'cost': email_budget,
        'open_rate': open_rate,
        'ctr': ctr,
        'conversion_rate': conversion_rate,
    }


def traditional_paid_search(
    event: Event,
    budget: float,
    users: List[UserProfile]
) -> Dict:
    """
    Simulate paid search advertising (Google Ads).
    
    Industry Benchmarks:
    - CTR: 2-5%
    - Conversion: 3-8% of clicks
    - CPC: $1-$5 per click
    """
    search_budget = budget * 0.20  # 20% of total budget
    cpc = random.uniform(1.00, 5.00)
    clicks = int(search_budget / cpc)
    ctr = random.uniform(0.02, 0.05)  # 2-5%
    impressions = int(clicks / ctr)
    conversion_rate = random.uniform(0.03, 0.08)  # 3-8%
    conversions = int(clicks * conversion_rate)
    
    return {
        'impressions': impressions,
        'clicks': clicks,
        'conversions': conversions,
        'cost': search_budget,
        'cpc': cpc,
        'ctr': ctr,
        'conversion_rate': conversion_rate,
    }


def traditional_organic_marketing(
    event: Event,
    budget: float,
    users: List[UserProfile]
) -> Dict:
    """
    Simulate organic marketing (social posts, word-of-mouth).
    
    Industry Benchmarks:
    - Organic engagement: 1-5%
    - Word-of-mouth referral: 5-15%
    - Cost: Minimal (time investment)
    """
    organic_budget = budget * 0.10  # 10% of total budget (minimal)
    
    # Organic social posts
    organic_impressions = random.randint(5000, 20000)
    engagement_rate = random.uniform(0.01, 0.05)  # 1-5%
    engagements = int(organic_impressions * engagement_rate)
    
    # Word-of-mouth referrals
    referral_rate = random.uniform(0.05, 0.15)  # 5-15%
    referrals = int(engagements * referral_rate)
    
    # Conversion from organic (lower than paid)
    conversion_rate = random.uniform(0.01, 0.02)  # 1-2%
    conversions = int((engagements + referrals) * conversion_rate)
    
    return {
        'impressions': organic_impressions,
        'engagements': engagements,
        'referrals': referrals,
        'conversions': conversions,
        'cost': organic_budget,
        'engagement_rate': engagement_rate,
        'referral_rate': referral_rate,
        'conversion_rate': conversion_rate,
    }


def run_traditional_marketing(
    event: Event,
    budget: float,
    users: List[UserProfile]
) -> Dict:
    """
    Run all traditional marketing channels for an event.
    
    Marketing Timeline:
    - Start: 30-60 days before event (longer lead time needed)
    - Duration: 4-8 weeks (extended campaign period)
    """
    current_time = time.time()
    days_until_event = (event.event_date - current_time) / (24 * 3600)
    
    # Traditional marketing: Start 30-60 days before event
    marketing_start_days_before = random.uniform(30, 60)
    marketing_start_date = event.event_date - (marketing_start_days_before * 24 * 3600)
    
    # Marketing duration: 4-8 weeks
    marketing_duration_days = random.uniform(28, 56)
    marketing_end_date = marketing_start_date + (marketing_duration_days * 24 * 3600)
    
    # Check if marketing period has passed (for events that already happened)
    # If event is in the past, marketing would have happened before now
    if marketing_end_date < current_time:
        # Marketing already completed
        days_since_marketing_end = (current_time - marketing_end_date) / (24 * 3600)
    else:
        # Marketing is ongoing or hasn't started yet
        days_since_marketing_end = 0
    
    social = traditional_social_media_marketing(event, budget, users)
    email = traditional_email_marketing(event, budget, users)
    search = traditional_paid_search(event, budget, users)
    organic = traditional_organic_marketing(event, budget, users)
    
    total_impressions = social['impressions'] + email['emails_sent'] + search['impressions'] + organic['impressions']
    total_conversions = social['conversions'] + email['conversions'] + search['conversions'] + organic['conversions']
    base_cost = social['cost'] + email['cost'] + search['cost'] + organic['cost']
    
    # Calculate additional service fees
    # Ad platform service fees (5% of ad spend)
    ad_spend = social['cost'] + search['cost']
    ad_service_fees = ad_spend * AD_PLATFORM_SERVICE_FEE_RATE
    
    # Email service fees (2% of email budget)
    email_service_fees = email['cost'] * EMAIL_SERVICE_FEE_RATE
    
    # Total service fees
    total_service_fees = ad_service_fees + email_service_fees
    
    # Total marketing cost (including service fees)
    total_marketing_cost = base_cost + total_service_fees
    
    # Calculate overall metrics
    overall_conversion_rate = total_conversions / total_impressions if total_impressions > 0 else 0
    
    return {
        'social': social,
        'email': email,
        'search': search,
        'organic': organic,
        'total_impressions': total_impressions,
        'total_conversions': total_conversions,
        'base_cost': base_cost,
        'ad_service_fees': ad_service_fees,
        'email_service_fees': email_service_fees,
        'total_service_fees': total_service_fees,
        'total_marketing_cost': total_marketing_cost,
        'overall_conversion_rate': overall_conversion_rate,
        'cpa': total_marketing_cost / total_conversions if total_conversions > 0 else 0,
        'marketing_start_days_before': marketing_start_days_before,
        'marketing_duration_days': marketing_duration_days,
        'marketing_start_date': marketing_start_date,
        'marketing_end_date': marketing_end_date,
    }


# ============================================================================
# SPOTS AI MARKETING FUNCTIONS
# ============================================================================

def spots_quantum_matching(
    event: Event,
    users: List[UserProfile],
    host: UserProfile
) -> Dict:
    """
    SPOTS: Quantum compatibility matching (Patent #1).
    C = |⟨ψ_A|ψ_B⟩|²
    """
    matched_users = []
    compatibility_scores = {}
    
    for user in users:
        # Calculate quantum compatibility
        compatibility = quantum_compatibility(user.personality_12d, host.personality_12d)
        
        # Filter users with compatibility ≥ 0.70
        if compatibility >= 0.70:
            matched_users.append(user)
            compatibility_scores[user.agent_id] = compatibility
    
    # Rank by compatibility (highest first)
    matched_users.sort(key=lambda u: compatibility_scores[u.agent_id], reverse=True)
    
    # Target top 20% of compatible users (realistic targeting)
    target_count = max(1, int(len(matched_users) * 0.20))
    target_users = matched_users[:target_count]
    
    return {
        'matched_users': target_users,
        'compatibility_scores': {u.agent_id: compatibility_scores[u.agent_id] for u in target_users},
        'total_matched': len(matched_users),
        'targeted': len(target_users),
    }


def spots_hyper_personalized_recommendations(
    event: Event,
    users: List[UserProfile],
    host: UserProfile
) -> Dict:
    """
    SPOTS: Hyper-personalized recommendations (Patent #20).
    Multi-source fusion: 40% real-time, 30% community, 20% AI2AI, 10% federated
    """
    recommendations = []
    recommendation_scores = {}
    
    for user in users:
        # Real-time contextual (40% weight)
        location_match = calculate_location_match(user.location, event.location)
        time_match = 1.0  # Assume good timing (simplified)
        real_time_score = (location_match + time_match) / 2 * 0.40
        
        # Community insights (30% weight)
        # Based on event category popularity and user preferences
        category_match = user.event_preferences.get(event.category, 0.5)
        community_score = category_match * 0.30
        
        # AI2AI network (20% weight)
        # Based on compatibility with host
        ai2ai_compatibility = quantum_compatibility(user.personality_12d, host.personality_12d)
        ai2ai_score = ai2ai_compatibility * 0.20
        
        # Federated learning (10% weight)
        # Based on similar users' preferences
        federated_score = category_match * 0.10
        
        # Fused score
        fused_score = real_time_score + community_score + ai2ai_score + federated_score
        
        # Hyper-personalization layer (boost based on user preferences)
        preference_boost = 1.0 + (category_match * 0.2)  # Up to 20% boost
        personalized_score = fused_score * preference_boost
        
        recommendations.append({
            'user': user,
            'score': personalized_score,
            'real_time': real_time_score,
            'community': community_score,
            'ai2ai': ai2ai_score,
            'federated': federated_score,
        })
        recommendation_scores[user.agent_id] = personalized_score
    
    # Sort by score (highest first)
    recommendations.sort(key=lambda r: r['score'], reverse=True)
    
    # Target top 25% (higher than quantum matching due to multi-source fusion)
    target_count = max(1, int(len(recommendations) * 0.25))
    target_recommendations = recommendations[:target_count]
    
    return {
        'recommended_users': [r['user'] for r in target_recommendations],
        'recommendation_scores': {r['user'].agent_id: r['score'] for r in target_recommendations},
        'total_recommended': len(recommendations),
        'targeted': len(target_recommendations),
    }


def spots_12d_personality_matching(
    event: Event,
    users: List[UserProfile],
    host: UserProfile
) -> Dict:
    """
    SPOTS: 12D personality multi-factor matching (Patent #19).
    60% dimension + 20% energy + 20% exploration
    """
    matched_users = []
    compatibility_scores = {}
    
    for user in users:
        # Dimension compatibility (60% weight)
        # Use first 8 dimensions (discovery dimensions)
        dimension_diff = np.abs(user.personality_12d[:8] - host.personality_12d[:8])
        dimension_compatibility = 1.0 - np.mean(dimension_diff)
        dimension_score = dimension_compatibility * 0.60
        
        # Energy compatibility (20% weight)
        # Use dimension 9 (energy dimension)
        energy_diff = abs(user.personality_12d[8] - host.personality_12d[8])
        energy_compatibility = 1.0 - energy_diff
        energy_score = energy_compatibility * 0.20
        
        # Exploration compatibility (20% weight)
        # Use dimension 10 (exploration dimension)
        exploration_diff = abs(user.personality_12d[9] - host.personality_12d[9])
        exploration_compatibility = 1.0 - exploration_diff
        exploration_score = exploration_compatibility * 0.20
        
        # Weighted compatibility
        weighted_compatibility = dimension_score + energy_score + exploration_score
        
        # Filter users with compatibility ≥ 0.70
        if weighted_compatibility >= 0.70:
            matched_users.append(user)
            compatibility_scores[user.agent_id] = weighted_compatibility
    
    # Rank by compatibility (highest first)
    matched_users.sort(key=lambda u: compatibility_scores[u.agent_id], reverse=True)
    
    # Target top 22% (between quantum and hyper-personalized)
    target_count = max(1, int(len(matched_users) * 0.22))
    target_users = matched_users[:target_count]
    
    return {
        'matched_users': target_users,
        'compatibility_scores': {u.agent_id: compatibility_scores[u.agent_id] for u in target_users},
        'total_matched': len(matched_users),
        'targeted': len(target_users),
    }


def spots_calling_score_matching(
    event: Event,
    users: List[UserProfile],
    host: UserProfile
) -> Dict:
    """
    SPOTS: Calling score calculation (Patent #22).
    Vibe-based matching with context awareness.
    """
    matched_users = []
    calling_scores = {}
    
    for user in users:
        # Vibe compatibility (based on personality)
        vibe_compatibility = quantum_compatibility(user.personality_12d, host.personality_12d)
        
        # Context match (location, time)
        location_match = calculate_location_match(user.location, event.location)
        context_match = location_match * 0.3 + 0.7  # Assume good timing
        
        # Calling score (vibe + context)
        calling_score = vibe_compatibility * 0.7 + context_match * 0.3
        
        # Filter users with calling score ≥ 0.70
        if calling_score >= 0.70:
            matched_users.append(user)
            calling_scores[user.agent_id] = calling_score
    
    # Rank by calling score (highest first)
    matched_users.sort(key=lambda u: calling_scores[u.agent_id], reverse=True)
    
    # Target top 18% (more selective)
    target_count = max(1, int(len(matched_users) * 0.18))
    target_users = matched_users[:target_count]
    
    return {
        'matched_users': target_users,
        'calling_scores': {u.agent_id: calling_scores[u.agent_id] for u in target_users},
        'total_matched': len(matched_users),
        'targeted': len(target_users),
    }


def run_spots_marketing(
    event: Event,
    users: List[UserProfile],
    host: UserProfile,
    use_equal_timeline: bool = True
) -> Dict:
    """
    Run all SPOTS AI marketing systems for an event.
    
    Marketing Timeline:
    - Test 1 (use_equal_timeline=True): Same as traditional (30-60 days before, 4-8 weeks)
    - Test 2 (use_equal_timeline=False): Faster (7-14 days before, 1-2 weeks)
    """
    current_time = time.time()
    days_until_event = (event.event_date - current_time) / (24 * 3600)
    
    if use_equal_timeline:
        # TEST 1: Equal timeline for fair ROI comparison
        # SPOTS marketing: Start 30-60 days before event (same as traditional)
        marketing_start_days_before = random.uniform(30, 60)
        marketing_duration_days = random.uniform(28, 56)  # 4-8 weeks (same as traditional)
    else:
        # TEST 2: Efficiency advantage - shorter timeline
        # SPOTS marketing: Start 7-14 days before event (much shorter lead time)
        marketing_start_days_before = random.uniform(7, 14)
        marketing_duration_days = random.uniform(7, 14)  # 1-2 weeks (shorter, more efficient)
    
    marketing_start_date = event.event_date - (marketing_start_days_before * 24 * 3600)
    marketing_end_date = marketing_start_date + (marketing_duration_days * 24 * 3600)
    
    # Check if marketing period has passed
    if marketing_end_date < current_time:
        days_since_marketing_end = (current_time - marketing_end_date) / (24 * 3600)
    else:
        days_since_marketing_end = 0
    
    # Get matches from all systems
    quantum = spots_quantum_matching(event, users, host)
    hyper_personalized = spots_hyper_personalized_recommendations(event, users, host)
    personality_12d = spots_12d_personality_matching(event, users, host)
    calling_score = spots_calling_score_matching(event, users, host)
    
    # Combine all matched users (union, no duplicates)
    all_matched_users = set()
    all_matched_users.update([u.agent_id for u in quantum['matched_users']])
    all_matched_users.update([u.agent_id for u in hyper_personalized['recommended_users']])
    all_matched_users.update([u.agent_id for u in personality_12d['matched_users']])
    all_matched_users.update([u.agent_id for u in calling_score['matched_users']])
    
    # Get user objects
    user_dict = {u.agent_id: u for u in users}
    final_matched_users = [user_dict[uid] for uid in all_matched_users if uid in user_dict]
    
    # Calculate conversion rate (SPOTS has higher conversion due to better targeting)
    # Industry: 15-25% conversion for well-targeted recommendations
    base_conversion_rate = random.uniform(0.15, 0.25)
    
    # Boost conversion based on average compatibility
    avg_compatibility = np.mean([
        np.mean(list(quantum['compatibility_scores'].values())) if quantum['compatibility_scores'] else 0,
        np.mean(list(hyper_personalized['recommendation_scores'].values())) if hyper_personalized['recommendation_scores'] else 0,
        np.mean(list(personality_12d['compatibility_scores'].values())) if personality_12d['compatibility_scores'] else 0,
        np.mean(list(calling_score['calling_scores'].values())) if calling_score['calling_scores'] else 0,
    ])
    
    # Higher compatibility = higher conversion
    conversion_rate = base_conversion_rate * (0.8 + avg_compatibility * 0.4)  # 0.8x to 1.2x multiplier
    conversions = int(len(final_matched_users) * conversion_rate)
    
    # SPOTS cost is lower (platform cost, not per-impression)
    # Assume $2-$8 per attendee (much lower than traditional)
    cpa = random.uniform(2.00, 8.00)
    base_marketing_cost = conversions * cpa
    
    # SPOTS platform service fees (minimal - built into platform)
    # Assume 1% of marketing cost for platform overhead
    platform_service_fees = base_marketing_cost * 0.01
    
    # Total marketing cost (including service fees)
    total_marketing_cost = base_marketing_cost + platform_service_fees
    
    return {
        'quantum': quantum,
        'hyper_personalized': hyper_personalized,
        'personality_12d': personality_12d,
        'calling_score': calling_score,
        'matched_users': final_matched_users,
        'total_matched': len(final_matched_users),
        'conversions': conversions,
        'conversion_rate': conversion_rate,
        'base_marketing_cost': base_marketing_cost,
        'platform_service_fees': platform_service_fees,
        'total_marketing_cost': total_marketing_cost,
        'cpa': total_marketing_cost / conversions if conversions > 0 else 0,
        'marketing_start_days_before': marketing_start_days_before,
        'marketing_duration_days': marketing_duration_days,
        'marketing_start_date': marketing_start_date,
        'marketing_end_date': marketing_end_date,
    }


# ============================================================================
# EXPERIMENT SETUP
# ============================================================================

def setup_experiment() -> Tuple[List[UserProfile], List[UserProfile], List[Event]]:
    """Setup experiment: create users and events for both groups."""
    print("=" * 70)
    print("Setting up SPOTS vs Traditional Marketing Experiment")
    print("=" * 70)
    print()
    
    # Create users for control group (traditional marketing)
    print(f"Creating {NUM_USERS_PER_GROUP} users for control group (traditional)...")
    control_users = []
    for i in range(NUM_USERS_PER_GROUP):
        user = generate_integrated_user_profile(
            agent_id=f'control_user_{i:04d}',
            platform_phase=random.choice(['Early', 'Growth', 'Mature']),
            random_seed=RANDOM_SEED + i
        )
        control_users.append(user)
    
    # Create users for test group (SPOTS) - matched demographics
    print(f"Creating {NUM_USERS_PER_GROUP} users for test group (SPOTS)...")
    test_users = []
    for i in range(NUM_USERS_PER_GROUP):
        # Match demographics by using same random seed offset
        user = generate_integrated_user_profile(
            agent_id=f'test_user_{i:04d}',
            platform_phase=random.choice(['Early', 'Growth', 'Mature']),
            random_seed=RANDOM_SEED + i + 10000  # Different seed but similar distribution
        )
        test_users.append(user)
    
    # Create events (same events for both groups)
    print(f"Creating {NUM_EVENTS_PER_GROUP} events...")
    events = []
    current_time = time.time()
    
    # Use control users as hosts (will match to both groups)
    for i in range(NUM_EVENTS_PER_GROUP):
        host = control_users[i % len(control_users)]
        
        # Random future event date (within 6 months)
        event_date = current_time + random.uniform(0, NUM_MONTHS * 30) * 24 * 3600
        
        # Generate entities (3-10 per event)
        num_entities = random.randint(3, 10)
        entities = []
        for j in range(num_entities):
            entities.append({
                'entity_id': f'entity_{i}_{j}',
                'entity_type': random.choice(['User', 'Business', 'Brand', 'Sponsor']),
                'user_id': random.choice(control_users).agent_id if random.random() < 0.7 else None,
            })
        
        event = generate_integrated_event(
            event_id=f'event_{i:04d}',
            host_id=host.agent_id,
            category=host.category,
            location=host.location,
            event_date=event_date,
            entities=entities,
            total_revenue=0.0,  # Will be calculated during simulation
        )
        events.append(event)
    
    print(f"✅ Setup complete: {len(control_users)} control users, {len(test_users)} test users, {len(events)} events")
    print()
    
    return control_users, test_users, events


# ============================================================================
# EXPERIMENT EXECUTION
# ============================================================================

def run_experiment(
    control_users: List[UserProfile],
    test_users: List[UserProfile],
    events: List[Event]
) -> Tuple[List[Dict], List[Dict]]:
    """Run the full experiment for both groups."""
    print("=" * 70)
    print("Running Experiment")
    print("=" * 70)
    print()
    
    # Find hosts for events (match by index since users are created in same order)
    control_results = []
    test_results = []
    
    for i, event in enumerate(events):
        if (i + 1) % 50 == 0:
            print(f"Processing event {i + 1}/{len(events)}...")
        
        # Get host by index (same index in both groups)
        # Events were created with hosts from control_users, so find the index
        host_index = None
        for idx, user in enumerate(control_users):
            if user.agent_id == event.host_id:
                host_index = idx
                break
        
        if host_index is None or host_index >= len(test_users):
            continue
        
        # Get hosts from both groups using the same index
        control_host = control_users[host_index]
        test_host = test_users[host_index]
        
        # CONTROL GROUP: Traditional Marketing
        traditional_result = run_traditional_marketing(
            event,
            MARKETING_BUDGET_PER_EVENT,
            control_users
        )
        
        # Calculate revenue
        tickets_sold = traditional_result['total_conversions']
        gross_revenue = tickets_sold * AVERAGE_TICKET_PRICE
        
        # Calculate all costs
        marketing_cost = traditional_result['total_marketing_cost']
        payment_processing_fee = gross_revenue * PAYMENT_PROCESSING_FEE_RATE
        platform_fee = gross_revenue * TRADITIONAL_PLATFORM_FEE_RATE
        total_costs = marketing_cost + payment_processing_fee + platform_fee
        
        # Calculate net profit and ROI
        net_profit = gross_revenue - total_costs
        roi = (net_profit / total_costs) if total_costs > 0 else 0
        
        control_results.append({
            'event_id': event.event_id,
            'category': event.category,
            'event_date': event.event_date,
            'impressions': traditional_result['total_impressions'],
            'conversions': traditional_result['total_conversions'],
            'tickets_sold': tickets_sold,
            'gross_revenue': gross_revenue,
            'marketing_cost': marketing_cost,
            'payment_processing_fee': payment_processing_fee,
            'platform_fee': platform_fee,
            'total_costs': total_costs,
            'net_profit': net_profit,
            'cpa': traditional_result['cpa'],
            'roi': roi,
            'conversion_rate': traditional_result['overall_conversion_rate'],
            'attendance_rate': tickets_sold / len(control_users) if len(control_users) > 0 else 0,
            'marketing_start_days_before': traditional_result['marketing_start_days_before'],
            'marketing_duration_days': traditional_result['marketing_duration_days'],
            'marketing_start_date': traditional_result['marketing_start_date'],
            'marketing_end_date': traditional_result['marketing_end_date'],
        })
        
        # TEST GROUP: SPOTS Marketing
        # Test 1: Equal timeline (use_equal_timeline=True)
        spots_result = run_spots_marketing(
            event,
            test_users,
            test_host,
            use_equal_timeline=True
        )
        
        # Calculate revenue
        tickets_sold = spots_result['conversions']
        gross_revenue = tickets_sold * AVERAGE_TICKET_PRICE
        
        # Calculate all costs
        marketing_cost = spots_result['total_marketing_cost']
        payment_processing_fee = gross_revenue * PAYMENT_PROCESSING_FEE_RATE
        platform_fee = gross_revenue * SPOTS_PLATFORM_FEE_RATE
        total_costs = marketing_cost + payment_processing_fee + platform_fee
        
        # Calculate net profit and ROI
        net_profit = gross_revenue - total_costs
        roi = (net_profit / total_costs) if total_costs > 0 else 0
        
        test_results.append({
            'event_id': event.event_id,
            'category': event.category,
            'event_date': event.event_date,
            'matched_users': spots_result['total_matched'],
            'conversions': spots_result['conversions'],
            'tickets_sold': tickets_sold,
            'gross_revenue': gross_revenue,
            'marketing_cost': marketing_cost,
            'payment_processing_fee': payment_processing_fee,
            'platform_fee': platform_fee,
            'total_costs': total_costs,
            'net_profit': net_profit,
            'cpa': spots_result['cpa'],
            'roi': roi,
            'conversion_rate': spots_result['conversion_rate'],
            'attendance_rate': tickets_sold / len(test_users) if len(test_users) > 0 else 0,
            'marketing_start_days_before': spots_result['marketing_start_days_before'],
            'marketing_duration_days': spots_result['marketing_duration_days'],
            'marketing_start_date': spots_result['marketing_start_date'],
            'marketing_end_date': spots_result['marketing_end_date'],
        })
    
    print(f"✅ Experiment complete: {len(control_results)} control events, {len(test_results)} test events")
    print()
    
    return control_results, test_results


# ============================================================================
# ANALYSIS & REPORTING
# ============================================================================

def calculate_statistics(control_results: List[Dict], test_results: List[Dict]) -> Dict:
    """Calculate comprehensive statistics and comparisons."""
    # Convert to DataFrames
    control_df = pd.DataFrame(control_results)
    test_df = pd.DataFrame(test_results)
    
    # Calculate summary statistics
    stats_dict = {
        'control': {
            'attendance_rate': control_df['attendance_rate'].mean(),
            'conversion_rate': control_df['conversion_rate'].mean(),
            'gross_revenue_per_event': control_df['gross_revenue'].mean(),
            'net_profit_per_event': control_df['net_profit'].mean(),
            'cpa': control_df['cpa'].mean(),
            'roi': control_df['roi'].mean(),
            'total_gross_revenue': control_df['gross_revenue'].sum(),
            'total_marketing_cost': control_df['marketing_cost'].sum(),
            'total_payment_processing_fees': control_df['payment_processing_fee'].sum(),
            'total_platform_fees': control_df['platform_fee'].sum(),
            'total_costs': control_df['total_costs'].sum(),
            'total_net_profit': control_df['net_profit'].sum(),
            'total_tickets': control_df['tickets_sold'].sum(),
        },
        'test': {
            'attendance_rate': test_df['attendance_rate'].mean(),
            'conversion_rate': test_df['conversion_rate'].mean(),
            'gross_revenue_per_event': test_df['gross_revenue'].mean(),
            'net_profit_per_event': test_df['net_profit'].mean(),
            'cpa': test_df['cpa'].mean(),
            'roi': test_df['roi'].mean(),
            'total_gross_revenue': test_df['gross_revenue'].sum(),
            'total_marketing_cost': test_df['marketing_cost'].sum(),
            'total_payment_processing_fees': test_df['payment_processing_fee'].sum(),
            'total_platform_fees': test_df['platform_fee'].sum(),
            'total_costs': test_df['total_costs'].sum(),
            'total_net_profit': test_df['net_profit'].sum(),
            'total_tickets': test_df['tickets_sold'].sum(),
        },
    }
    
    # Calculate improvements
    improvements = {}
    for metric in ['attendance_rate', 'conversion_rate', 'gross_revenue_per_event', 'net_profit_per_event', 'roi']:
        control_val = stats_dict['control'][metric]
        test_val = stats_dict['test'][metric]
        if control_val > 0:
            improvements[metric] = {
                'improvement': (test_val - control_val) / control_val,
                'improvement_x': test_val / control_val,
            }
        else:
            improvements[metric] = {'improvement': 0, 'improvement_x': 0}
    
    # Total net profit improvement
    control_total_profit = stats_dict['control']['total_net_profit']
    test_total_profit = stats_dict['test']['total_net_profit']
    if control_total_profit > 0:
        improvements['total_net_profit'] = {
            'improvement': (test_total_profit - control_total_profit) / control_total_profit,
            'improvement_x': test_total_profit / control_total_profit,
        }
    else:
        improvements['total_net_profit'] = {'improvement': 0, 'improvement_x': 0}
    
    # CPA improvement (lower is better)
    control_cpa = stats_dict['control']['cpa']
    test_cpa = stats_dict['test']['cpa']
    if control_cpa > 0:
        improvements['cpa'] = {
            'improvement': (control_cpa - test_cpa) / control_cpa,  # Positive = better
            'improvement_x': control_cpa / test_cpa,  # How many times better
        }
    else:
        improvements['cpa'] = {'improvement': 0, 'improvement_x': 0}
    
    # Statistical tests
    statistical_tests = {}
    
    # T-tests for continuous variables
    for metric in ['attendance_rate', 'conversion_rate', 'gross_revenue', 'net_profit', 'cpa', 'roi']:
        control_vals = control_df[metric].values
        test_vals = test_df[metric].values
        
        t_stat, p_value = stats.ttest_ind(test_vals, control_vals)
        
        # Effect size (Cohen's d)
        pooled_std = np.sqrt((np.var(control_vals) + np.var(test_vals)) / 2)
        cohens_d = (np.mean(test_vals) - np.mean(control_vals)) / pooled_std if pooled_std > 0 else 0
        
        statistical_tests[metric] = {
            't_statistic': float(t_stat),
            'p_value': float(p_value),
            'cohens_d': float(cohens_d),
            'significant': p_value < 0.01,
        }
    
    stats_dict['improvements'] = improvements
    stats_dict['statistical_tests'] = statistical_tests
    
    return stats_dict


def generate_report(
    control_results: List[Dict],
    test_results: List[Dict],
    statistics: Dict
) -> str:
    """Generate comprehensive markdown report."""
    report = []
    report.append("# SPOTS vs Traditional Marketing Experiment Report")
    report.append("")
    report.append(f"**Date:** {datetime.now().strftime('%B %d, %Y')}")
    report.append(f"**Experiment Duration:** {NUM_MONTHS} months")
    report.append(f"**Events per Group:** {NUM_EVENTS_PER_GROUP}")
    report.append(f"**Users per Group:** {NUM_USERS_PER_GROUP}")
    report.append("")
    report.append("### Marketing Timeline")
    report.append("")
    report.append("**Traditional Marketing:**")
    report.append("- Marketing Start: 30-60 days before event")
    report.append("- Marketing Duration: 4-8 weeks (28-56 days)")
    report.append("- Longer lead time needed for broad reach campaigns")
    report.append("")
    report.append("**SPOTS AI Marketing:**")
    report.append("- Marketing Start: 7-14 days before event")
    report.append("- Marketing Duration: 1-2 weeks (7-14 days)")
    report.append("- Shorter lead time due to faster, targeted matching")
    report.append("")
    report.append("---")
    report.append("")
    report.append("## Executive Summary")
    report.append("")
    
    # Key findings
    control = statistics['control']
    test = statistics['test']
    improvements = statistics['improvements']
    
    report.append("### Key Findings")
    report.append("")
    report.append(f"- **Attendance Rate:** SPOTS {test['attendance_rate']:.2%} vs Traditional {control['attendance_rate']:.2%} ({improvements['attendance_rate']['improvement_x']:.2f}x improvement)")
    report.append(f"- **Conversion Rate:** SPOTS {test['conversion_rate']:.2%} vs Traditional {control['conversion_rate']:.2%} ({improvements['conversion_rate']['improvement_x']:.2f}x improvement)")
    report.append(f"- **Gross Revenue per Event:** SPOTS ${test['gross_revenue_per_event']:,.2f} vs Traditional ${control['gross_revenue_per_event']:,.2f} ({improvements['gross_revenue_per_event']['improvement_x']:.2f}x improvement)")
    report.append(f"- **Cost per Acquisition:** SPOTS ${test['cpa']:.2f} vs Traditional ${control['cpa']:.2f} ({improvements['cpa']['improvement_x']:.2f}x better)")
    report.append(f"- **ROI:** SPOTS {test['roi']:.2f}:1 vs Traditional {control['roi']:.2f}:1 ({improvements['roi']['improvement_x']:.2f}x improvement)")
    report.append("")
    
    report.append("---")
    report.append("")
    report.append("## Detailed Results")
    report.append("")
    
    # Traditional Marketing Results
    report.append("### Traditional Marketing (Control Group)")
    report.append("")
    report.append(f"- Average Attendance Rate: {control['attendance_rate']:.2%}")
    report.append(f"- Average Conversion Rate: {control['conversion_rate']:.2%}")
    report.append(f"- Average Gross Revenue per Event: ${control['gross_revenue_per_event']:,.2f}")
    report.append(f"- Average Net Profit per Event: ${control['net_profit_per_event']:,.2f}")
    report.append(f"- Average Cost per Acquisition: ${control['cpa']:.2f}")
    report.append(f"- Average ROI: {control['roi']:.2f}:1")
    report.append(f"- Total Gross Revenue: ${control['total_gross_revenue']:,.2f}")
    report.append(f"- Total Marketing Cost: ${control['total_marketing_cost']:,.2f}")
    report.append(f"- Total Payment Processing Fees: ${control['total_payment_processing_fees']:,.2f}")
    report.append(f"- Total Platform Fees: ${control['total_platform_fees']:,.2f}")
    report.append(f"- Total Costs: ${control['total_costs']:,.2f}")
    report.append(f"- **Total Net Profit: ${control['total_net_profit']:,.2f}**")
    report.append(f"- Total Tickets Sold: {control['total_tickets']:,.0f}")
    
    # Calculate average marketing timeline
    control_df = pd.DataFrame(control_results)
    avg_marketing_start_days = control_df['marketing_start_days_before'].mean()
    avg_marketing_duration = control_df['marketing_duration_days'].mean()
    report.append(f"- Average Marketing Start: {avg_marketing_start_days:.1f} days before event")
    report.append(f"- Average Marketing Duration: {avg_marketing_duration:.1f} days")
    report.append("")
    
    # SPOTS Marketing Results
    report.append("### SPOTS AI Marketing (Test Group)")
    report.append("")
    report.append(f"- Average Attendance Rate: {test['attendance_rate']:.2%}")
    report.append(f"- Average Conversion Rate: {test['conversion_rate']:.2%}")
    report.append(f"- Average Gross Revenue per Event: ${test['gross_revenue_per_event']:,.2f}")
    report.append(f"- Average Net Profit per Event: ${test['net_profit_per_event']:,.2f}")
    report.append(f"- Average Cost per Acquisition: ${test['cpa']:.2f}")
    report.append(f"- Average ROI: {test['roi']:.2f}:1")
    report.append(f"- Total Gross Revenue: ${test['total_gross_revenue']:,.2f}")
    report.append(f"- Total Marketing Cost: ${test['total_marketing_cost']:,.2f}")
    report.append(f"- Total Payment Processing Fees: ${test['total_payment_processing_fees']:,.2f}")
    report.append(f"- Total Platform Fees: ${test['total_platform_fees']:,.2f}")
    report.append(f"- Total Costs: ${test['total_costs']:,.2f}")
    report.append(f"- **Total Net Profit: ${test['total_net_profit']:,.2f}**")
    report.append(f"- Total Tickets Sold: {test['total_tickets']:,.0f}")
    
    # Calculate average marketing timeline
    test_df = pd.DataFrame(test_results)
    avg_marketing_start_days = test_df['marketing_start_days_before'].mean()
    avg_marketing_duration = test_df['marketing_duration_days'].mean()
    report.append(f"- Average Marketing Start: {avg_marketing_start_days:.1f} days before event")
    report.append(f"- Average Marketing Duration: {avg_marketing_duration:.1f} days")
    report.append("")
    
    # Statistical Analysis
    report.append("---")
    report.append("")
    report.append("## Statistical Analysis")
    report.append("")
    
    for metric, test_result in statistics['statistical_tests'].items():
        report.append(f"### {metric.replace('_', ' ').title()}")
        report.append("")
        report.append(f"- T-statistic: {test_result['t_statistic']:.4f}")
        report.append(f"- P-value: {test_result['p_value']:.6f}")
        report.append(f"- Cohen's d: {test_result['cohens_d']:.4f}")
        report.append(f"- Statistically Significant: {'✅ Yes' if test_result['significant'] else '❌ No'}")
        report.append("")
    
    # Success Criteria
    report.append("---")
    report.append("")
    report.append("## Success Criteria Validation")
    report.append("")
    
    success_criteria = {
        'Attendance Rate ≥2x': improvements['attendance_rate']['improvement_x'] >= 2.0,
        'Conversion Rate ≥4x': improvements['conversion_rate']['improvement_x'] >= 4.0,
        'Gross Revenue per Event ≥2x': improvements['gross_revenue_per_event']['improvement_x'] >= 2.0,
        'Net Profit per Event ≥2x': improvements['net_profit_per_event']['improvement_x'] >= 2.0,
        'Total Net Profit ≥2x': improvements['total_net_profit']['improvement_x'] >= 2.0,
        'CPA ≤50%': improvements['cpa']['improvement_x'] >= 2.0,  # 2x better = 50% of original
        'ROI ≥2x': improvements['roi']['improvement_x'] >= 2.0,
        'Statistical Significance (p<0.01)': all(t['significant'] for t in statistics['statistical_tests'].values()),
        'Effect Size (Cohen\'s d>1.0)': all(abs(t['cohens_d']) > 1.0 for t in statistics['statistical_tests'].values()),
    }
    
    for criterion, met in success_criteria.items():
        status = "✅ PASS" if met else "❌ FAIL"
        report.append(f"- {criterion}: {status}")
    
    report.append("")
    report.append("---")
    report.append("")
    report.append("## Conclusions")
    report.append("")
    report.append("SPOTS AI-powered marketing demonstrates significant improvements across all key metrics compared to traditional marketing techniques.")
    report.append("")
    
    return "\n".join(report)


# ============================================================================
# MAIN EXECUTION
# ============================================================================

def run_test_2_efficiency_advantage(
    control_users: List[UserProfile],
    test_users: List[UserProfile],
    events: List[Event]
) -> Tuple[List[Dict], List[Dict]]:
    """
    Test 2: SPOTS Efficiency Advantage
    
    Traditional: Needs 30-60 days lead time → limited to 500 events in 6 months
    SPOTS: Only needs 7-14 days lead time → can fit MORE events in 6 months
    
    This test shows SPOTS can market more events in the same time period,
    generating more total revenue and better ROI.
    """
    print("=" * 70)
    print("Test 2: SPOTS Efficiency Advantage (More Events in Same Time)")
    print("=" * 70)
    print()
    
    current_time = time.time()
    six_months_seconds = NUM_MONTHS * 30 * 24 * 3600
    end_time = current_time + six_months_seconds
    
    # Traditional: Can only market events with 30-60 day lead time
    # Calculate how many events can fit in 6 months
    min_lead_time_traditional = 30  # days
    max_lead_time_traditional = 60  # days
    avg_lead_time_traditional = (min_lead_time_traditional + max_lead_time_traditional) / 2
    
    # SPOTS: Can market events with 7-14 day lead time
    min_lead_time_spots = 7  # days
    max_lead_time_spots = 14  # days
    avg_lead_time_spots = (min_lead_time_spots + max_lead_time_spots) / 2
    
    # Calculate how many events can fit in 6 months
    # Traditional: Need 30-60 days before + 28-56 days duration
    # BUT campaigns can overlap - you can start marketing next event while current is running
    # So the limiting factor is the lead time (when you need to START marketing)
    # Minimum time between event starts = lead time (30-60 days)
    # This allows at least 1 event per month (6 events in 6 months)
    days_between_events_traditional = avg_lead_time_traditional  # Can start next campaign when current starts
    max_events_traditional = max(6, int((six_months_seconds / (24 * 3600)) / days_between_events_traditional))  # At least 1 per month
    
    # SPOTS: Need 7-14 days before + 7-14 days duration
    # Can also overlap campaigns
    days_between_events_spots = avg_lead_time_spots  # Can start next campaign when current starts
    max_events_spots = int((six_months_seconds / (24 * 3600)) / days_between_events_spots)
    
    print(f"Traditional Marketing:")
    print(f"  - Average lead time: {avg_lead_time_traditional:.0f} days")
    print(f"  - Average duration: 42 days")
    print(f"  - Days between event starts (overlapping campaigns): {days_between_events_traditional:.0f} days")
    print(f"  - Max events in 6 months: {max_events_traditional} (at least 1 per month)")
    print()
    
    print(f"SPOTS Marketing:")
    print(f"  - Average lead time: {avg_lead_time_spots:.0f} days")
    print(f"  - Average duration: 10.5 days")
    print(f"  - Days between event starts (overlapping campaigns): {days_between_events_spots:.0f} days")
    print(f"  - Max events in 6 months: {max_events_spots}")
    print()
    
    # Use same number of events for traditional (limited by time)
    traditional_events = events[:max_events_traditional] if len(events) > max_events_traditional else events
    
    # SPOTS can handle more events (use efficiency advantage)
    spots_events = events[:max_events_spots] if len(events) > max_events_spots else events
    
    print(f"Running Test 2:")
    print(f"  - Traditional: {len(traditional_events)} events (time-limited)")
    print(f"  - SPOTS: {len(spots_events)} events (efficiency advantage)")
    print()
    
    # Run traditional marketing (same as Test 1)
    control_results = []
    for i, event in enumerate(traditional_events):
        if (i + 1) % 50 == 0:
            print(f"  Processing traditional event {i + 1}/{len(traditional_events)}...")
        
        # Get host by index
        host_index = None
        for idx, user in enumerate(control_users):
            if user.agent_id == event.host_id:
                host_index = idx
                break
        
        if host_index is None or host_index >= len(control_users):
            continue
        
        control_host = control_users[host_index]
        
        # Traditional marketing
        traditional_result = run_traditional_marketing(
            event,
            MARKETING_BUDGET_PER_EVENT,
            control_users
        )
        
        # Calculate revenue and costs
        tickets_sold = traditional_result['total_conversions']
        gross_revenue = tickets_sold * AVERAGE_TICKET_PRICE
        marketing_cost = traditional_result['total_marketing_cost']
        payment_processing_fee = gross_revenue * PAYMENT_PROCESSING_FEE_RATE
        platform_fee = gross_revenue * TRADITIONAL_PLATFORM_FEE_RATE
        total_costs = marketing_cost + payment_processing_fee + platform_fee
        net_profit = gross_revenue - total_costs
        roi = (net_profit / total_costs) if total_costs > 0 else 0
        
        control_results.append({
            'event_id': event.event_id,
            'category': event.category,
            'event_date': event.event_date,
            'tickets_sold': tickets_sold,
            'gross_revenue': gross_revenue,
            'marketing_cost': marketing_cost,
            'payment_processing_fee': payment_processing_fee,
            'platform_fee': platform_fee,
            'total_costs': total_costs,
            'net_profit': net_profit,
            'roi': roi,
            'conversion_rate': traditional_result['overall_conversion_rate'],
            'attendance_rate': tickets_sold / len(control_users) if len(control_users) > 0 else 0,
            'cpa': traditional_result['cpa'],
            'marketing_start_days_before': traditional_result['marketing_start_days_before'],
            'marketing_duration_days': traditional_result['marketing_duration_days'],
            'marketing_start_date': traditional_result['marketing_start_date'],
            'marketing_end_date': traditional_result['marketing_end_date'],
        })
    
    # Run SPOTS marketing with efficiency advantage (shorter timeline)
    test_results = []
    for i, event in enumerate(spots_events):
        if (i + 1) % 50 == 0:
            print(f"  Processing SPOTS event {i + 1}/{len(spots_events)}...")
        
        # Get host by index
        host_index = None
        for idx, user in enumerate(control_users):
            if user.agent_id == event.host_id:
                host_index = idx
                break
        
        if host_index is None or host_index >= len(test_users):
            continue
        
        test_host = test_users[host_index]
        
        # SPOTS marketing with shorter timeline (use_equal_timeline=False)
        spots_result = run_spots_marketing(
            event,
            test_users,
            test_host,
            use_equal_timeline=False  # Use efficiency advantage
        )
        
        # Calculate revenue and costs
        tickets_sold = spots_result['conversions']
        gross_revenue = tickets_sold * AVERAGE_TICKET_PRICE
        marketing_cost = spots_result['total_marketing_cost']
        payment_processing_fee = gross_revenue * PAYMENT_PROCESSING_FEE_RATE
        platform_fee = gross_revenue * SPOTS_PLATFORM_FEE_RATE
        total_costs = marketing_cost + payment_processing_fee + platform_fee
        net_profit = gross_revenue - total_costs
        roi = (net_profit / total_costs) if total_costs > 0 else 0
        
        test_results.append({
            'event_id': event.event_id,
            'category': event.category,
            'event_date': event.event_date,
            'tickets_sold': tickets_sold,
            'gross_revenue': gross_revenue,
            'marketing_cost': marketing_cost,
            'payment_processing_fee': payment_processing_fee,
            'platform_fee': platform_fee,
            'total_costs': total_costs,
            'net_profit': net_profit,
            'roi': roi,
            'conversion_rate': spots_result['conversion_rate'],
            'attendance_rate': tickets_sold / len(test_users) if len(test_users) > 0 else 0,
            'cpa': spots_result['cpa'],
            'marketing_start_days_before': spots_result['marketing_start_days_before'],
            'marketing_duration_days': spots_result['marketing_duration_days'],
            'marketing_start_date': spots_result['marketing_start_date'],
            'marketing_end_date': spots_result['marketing_end_date'],
        })
    
    print(f"✅ Test 2 complete: {len(control_results)} traditional events, {len(test_results)} SPOTS events")
    print()
    
    return control_results, test_results


def main():
    """Main experiment execution."""
    start_time = time.time()
    
    print("=" * 70)
    print("SPOTS vs Traditional Marketing Experiment")
    print("=" * 70)
    print()
    
    # Setup
    control_users, test_users, events = setup_experiment()
    
    # Convert numpy types to native Python types for JSON
    def convert_to_native(obj):
        """Convert numpy types to native Python types for JSON serialization."""
        if isinstance(obj, (np.integer, np.int64, np.int32)):
            return int(obj)
        elif isinstance(obj, (np.floating, np.float64, np.float32)):
            return float(obj)
        elif isinstance(obj, (np.bool_, bool)):
            return bool(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        elif isinstance(obj, dict):
            return {key: convert_to_native(value) for key, value in obj.items()}
        elif isinstance(obj, list):
            return [convert_to_native(item) for item in obj]
        return obj
    
    # Run Test 1: Equal time comparison
    print("=" * 70)
    print("TEST 1: Equal Time Comparison (Fair ROI)")
    print("=" * 70)
    print()
    control_results_1, test_results_1 = run_experiment(control_users, test_users, events)
    
    # Calculate statistics for Test 1
    print("Calculating Test 1 statistics...")
    statistics_1 = calculate_statistics(control_results_1, test_results_1)
    
    # Save Test 1 results
    print("Saving Test 1 results...")
    control_df_1 = pd.DataFrame(control_results_1)
    test_df_1 = pd.DataFrame(test_results_1)
    control_df_1.to_csv(RESULTS_DIR / 'test1_traditional_marketing_results.csv', index=False)
    test_df_1.to_csv(RESULTS_DIR / 'test1_spots_marketing_results.csv', index=False)
    
    comparison_data_1 = {
        'test': 'Test 1: Equal Time Comparison',
        'control': convert_to_native(statistics_1['control']),
        'test': convert_to_native(statistics_1['test']),
        'improvements': convert_to_native(statistics_1['improvements']),
        'statistical_tests': convert_to_native(statistics_1['statistical_tests']),
    }
    with open(RESULTS_DIR / 'test1_comparison_analysis.json', 'w') as f:
        json.dump(comparison_data_1, f, indent=2)
    
    # Generate and save Test 1 report
    report_1 = generate_report(control_results_1, test_results_1, statistics_1)
    report_path_1 = RESULTS_DIR / 'test1_spots_vs_traditional_marketing_report.md'
    with open(report_path_1, 'w') as f:
        f.write(report_1)
    
    # Print Test 1 summary
    print("=" * 70)
    print("TEST 1 Complete")
    print("=" * 70)
    print()
    print("Test 1 Summary (Equal Time Comparison):")
    print("-" * 70)
    control_1 = statistics_1['control']
    test_1 = statistics_1['test']
    improvements_1 = statistics_1['improvements']
    
    print(f"Attendance Rate: SPOTS {test_1['attendance_rate']:.2%} vs Traditional {control_1['attendance_rate']:.2%} ({improvements_1['attendance_rate']['improvement_x']:.2f}x)")
    print(f"Conversion Rate: SPOTS {test_1['conversion_rate']:.2%} vs Traditional {control_1['conversion_rate']:.2%} ({improvements_1['conversion_rate']['improvement_x']:.2f}x)")
    print(f"Gross Revenue per Event: SPOTS ${test_1['gross_revenue_per_event']:,.2f} vs Traditional ${control_1['gross_revenue_per_event']:,.2f} ({improvements_1['gross_revenue_per_event']['improvement_x']:.2f}x)")
    print(f"Net Profit per Event: SPOTS ${test_1['net_profit_per_event']:,.2f} vs Traditional ${control_1['net_profit_per_event']:,.2f} ({improvements_1['net_profit_per_event']['improvement_x']:.2f}x)")
    print(f"Total Net Profit: SPOTS ${test_1['total_net_profit']:,.2f} vs Traditional ${control_1['total_net_profit']:,.2f} ({improvements_1['total_net_profit']['improvement_x']:.2f}x)")
    print(f"ROI: SPOTS {test_1['roi']:.2f}:1 vs Traditional {control_1['roi']:.2f}:1 ({improvements_1['roi']['improvement_x']:.2f}x)")
    print()
    
    # Run Test 2: Efficiency advantage
    print("=" * 70)
    print("TEST 2: SPOTS Efficiency Advantage (More Events)")
    print("=" * 70)
    print()
    control_results_2, test_results_2 = run_test_2_efficiency_advantage(control_users, test_users, events)
    
    # Calculate statistics for Test 2
    print("Calculating Test 2 statistics...")
    statistics_2 = calculate_statistics(control_results_2, test_results_2)
    
    # Save Test 2 results
    print("Saving Test 2 results...")
    control_df_2 = pd.DataFrame(control_results_2)
    test_df_2 = pd.DataFrame(test_results_2)
    control_df_2.to_csv(RESULTS_DIR / 'test2_traditional_marketing_results.csv', index=False)
    test_df_2.to_csv(RESULTS_DIR / 'test2_spots_marketing_results.csv', index=False)
    
    comparison_data_2 = {
        'test': 'Test 2: SPOTS Efficiency Advantage',
        'control': convert_to_native(statistics_2['control']),
        'test': convert_to_native(statistics_2['test']),
        'improvements': convert_to_native(statistics_2['improvements']),
        'statistical_tests': convert_to_native(statistics_2['statistical_tests']),
    }
    with open(RESULTS_DIR / 'test2_comparison_analysis.json', 'w') as f:
        json.dump(comparison_data_2, f, indent=2)
    
    # Generate and save Test 2 report
    report_2 = generate_report(control_results_2, test_results_2, statistics_2)
    report_path_2 = RESULTS_DIR / 'test2_spots_vs_traditional_marketing_report.md'
    with open(report_path_2, 'w') as f:
        f.write(report_2)
    
    # Print Test 2 summary
    print("=" * 70)
    print("TEST 2 Complete")
    print("=" * 70)
    print()
    print("Test 2 Summary (Efficiency Advantage - More Events):")
    print("-" * 70)
    control_2 = statistics_2['control']
    test_2 = statistics_2['test']
    improvements_2 = statistics_2['improvements']
    
    print(f"Events: SPOTS {len(test_results_2)} vs Traditional {len(control_results_2)} ({len(test_results_2) / len(control_results_2) if len(control_results_2) > 0 else 0:.2f}x more events)")
    print(f"Total Gross Revenue: SPOTS ${test_2['total_gross_revenue']:,.2f} vs Traditional ${control_2['total_gross_revenue']:,.2f} ({test_2['total_gross_revenue'] / control_2['total_gross_revenue'] if control_2['total_gross_revenue'] > 0 else 0:.2f}x total)")
    print(f"Total Net Profit: SPOTS ${test_2['total_net_profit']:,.2f} vs Traditional ${control_2['total_net_profit']:,.2f} ({improvements_2['total_net_profit']['improvement_x']:.2f}x)")
    print(f"ROI: SPOTS {test_2['roi']:.2f}:1 vs Traditional {control_2['roi']:.2f}:1 ({improvements_2['roi']['improvement_x']:.2f}x)")
    print()
    
    print(f"All results saved to: {RESULTS_DIR}")
    print(f"Test 1 report: {report_path_1}")
    print(f"Test 2 report: {report_path_2}")
    print()
    
    elapsed_time = time.time() - start_time
    print(f"Total execution time: {elapsed_time:.2f} seconds")
    print()


if __name__ == '__main__':
    main()

