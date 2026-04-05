#!/usr/bin/env python3
"""
Refactored Experiment Runner

This module provides a flexible experiment runner that can execute
marketing experiments with various configurations.
"""

import numpy as np
import pandas as pd
import json
import time
import random
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from collections import defaultdict
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
    load_profiles_with_fallback,
)

# Import scenario config
from scenario_config import ScenarioConfig

# Cost Constants (can be overridden by config)
PAYMENT_PROCESSING_FEE_RATE = 0.03  # 3% of revenue
SPOTS_PLATFORM_FEE_RATE = 0.10  # 10% of revenue
TRADITIONAL_PLATFORM_FEE_RATE = 0.05  # 5% for traditional
AD_PLATFORM_SERVICE_FEE_RATE = 0.05  # 5% of ad spend
EMAIL_SERVICE_FEE_RATE = 0.02  # 2% of email budget

class ExperimentRunner:
    """Flexible experiment runner that accepts ScenarioConfig"""
    
    def __init__(self, config: ScenarioConfig, random_seed: int = 42):
        self.config = config
        self.random_seed = random_seed
        np.random.seed(random_seed)
        random.seed(random_seed)
        
        # Set up results directory
        if config.output_subfolder:
            self.results_dir = Path(__file__).parent / 'results' / config.output_subfolder
        else:
            self.results_dir = Path(__file__).parent / 'results' / config.scenario_id
        self.results_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize tracking for repeat attendance, referrals, etc.
        self.user_attendance_history = defaultdict(list)  # user_id -> [event_ids]
        self.host_attendance_history = defaultdict(list)  # host_id -> [user_ids]
        self.referrals = defaultdict(int)  # event_id -> referral_count
        self.social_shares = defaultdict(int)  # event_id -> share_count
        
    def setup_experiment(self) -> Tuple[List[UserProfile], List[UserProfile], List[Event]]:
        """Set up users and events for the experiment"""
        # Load profiles from Big Five data (with synthetic fallback)
        project_root = Path(__file__).parent.parent.parent.parent.parent
        
        print(f"Loading {self.config.num_users_per_group} users for control group from Big Five data...")
        control_users = load_profiles_with_fallback(
            num_profiles=self.config.num_users_per_group,
            use_big_five=True,
            project_root=project_root,
            fallback_generator=lambda agent_id: generate_integrated_user_profile(agent_id)
        )
        
        print(f"Loading {self.config.num_users_per_group} users for test group from Big Five data...")
        test_users = load_profiles_with_fallback(
            num_profiles=self.config.num_users_per_group,
            use_big_five=True,
            project_root=project_root,
            fallback_generator=lambda agent_id: generate_integrated_user_profile(agent_id)
        )
        
        print(f"Creating {self.config.num_events_per_group} events...")
        events = []
        current_time = time.time()
        six_months_seconds = self.config.num_months * 30 * 24 * 3600
        
        for i in range(self.config.num_events_per_group):
            # Determine event date
            if self.config.last_minute_event:
                # Last-minute event: 24-48 hours from now
                hours_before = random.uniform(*self.config.last_minute_hours)
                event_date = current_time + (hours_before * 3600)
            else:
                # Normal event: within the next 6 months
                event_date = current_time + random.uniform(0, six_months_seconds)
            
            # Filter by category/type if specified
            category = None
            event_type = None
            
            if self.config.event_categories:
                category = random.choice(self.config.event_categories)
            if self.config.event_types:
                event_type = random.choice(self.config.event_types)
            
            # Generate event
            host = random.choice(control_users)  # Use control user as host
            
            # Determine category (use host's category if not specified)
            if not category:
                category = host.category if hasattr(host, 'category') else 'entertainment'
            
            # Generate entities for the event (required by generate_integrated_event)
            num_entities = random.randint(3, 5)
            entities = [{
                'entity_id': f'entity_{i}_{j}',
                'entity_type': random.choice(['User', 'Business', 'Brand']),
                'user_id': host.agent_id if random.random() < 0.7 else None,
            } for j in range(num_entities)]
            
            # Generate event using correct signature
            event = generate_integrated_event(
                event_id=f"event_{i:04d}",
                host_id=host.agent_id,
                category=category,
                location=host.location,
                event_date=event_date,
                entities=entities,
                total_revenue=0.0
            )
            
            # Set ticket price (Event model may not have price attribute directly)
            # We'll track price separately in results
            event_price = 0.0 if self.config.free_event_with_addons else self.config.ticket_price
            event.is_paid = not self.config.free_event_with_addons
            
            # Store price in event metadata or track separately
            if not hasattr(event, 'price'):
                event.price = event_price
            
            events.append(event)
        
        print(f"✅ Setup complete: {len(control_users)} control users, "
              f"{len(test_users)} test users, {len(events)} events")
        return control_users, test_users, events
    
    def run_traditional_marketing(
        self,
        event: Event,
        users: List[UserProfile],
        traditional_budget_override: Optional[float] = None
    ) -> Dict:
        """Run traditional marketing for an event"""
        # For outspend scenarios, traditional gets more budget
        budget = traditional_budget_override if traditional_budget_override else self.config.marketing_budget
        
        # Calculate marketing timeline
        if self.config.last_minute_event:
            # Last-minute: can't market effectively
            marketing_start_days_before = random.uniform(0.5, 1.0)
            marketing_duration_days = random.uniform(0.5, 1.0)
        else:
            marketing_start_days_before = random.uniform(*self.config.traditional_lead_time_days)
            marketing_duration_days = random.uniform(*self.config.traditional_duration_days)
        
        marketing_start_date = event.event_date - (marketing_start_days_before * 24 * 3600)
        marketing_end_date = marketing_start_date + (marketing_duration_days * 24 * 3600)
        
        # Simulate marketing channels (simplified - full implementation would use original functions)
        # For now, use simplified conversion calculation
        base_conversion_rate = 0.0015  # 0.15% baseline
        
        # Handle aggressive marketing techniques (from aggressive_marketing scenarios)
        # These techniques improve conversion but still can't match SPOTS' personality matching
        if hasattr(self.config, 'aggressive_data_collection') and self.config.aggressive_data_collection:
            # Aggressive data collection improves targeting slightly (but still worse than SPOTS)
            base_conversion_rate *= 1.2  # 20% improvement from better data
        
        if hasattr(self.config, 'micro_targeting_enabled') and self.config.micro_targeting_enabled:
            # Micro-targeting improves conversion
            base_conversion_rate *= 1.3  # 30% improvement from micro-targeting
        
        if hasattr(self.config, 'privacy_invasive_tracking') and self.config.privacy_invasive_tracking:
            # Privacy-invasive tracking improves reach
            base_conversion_rate *= 1.15  # 15% improvement from better tracking
        
        if hasattr(self.config, 'psychological_manipulation') and self.config.psychological_manipulation:
            # Psychological manipulation improves conversion
            base_conversion_rate *= 1.25  # 25% improvement from manipulation
        
        if hasattr(self.config, 'behavioral_manipulation') and self.config.behavioral_manipulation:
            # Behavioral manipulation improves conversion
            base_conversion_rate *= 1.2  # 20% improvement from dark patterns
        
        if self.config.last_minute_event:
            base_conversion_rate *= 0.1  # Much lower for last-minute
        
        # Calculate conversions
        impressions = int(budget * 10)  # Simplified
        conversions = int(impressions * base_conversion_rate)
        
        # Aggressive techniques also increase costs (data collection, tracking infrastructure)
        budget_multiplier = 1.0
        if hasattr(self.config, 'aggressive_data_collection') and self.config.aggressive_data_collection:
            budget_multiplier = 1.1  # 10% cost increase for data infrastructure
        if hasattr(self.config, 'privacy_invasive_tracking') and self.config.privacy_invasive_tracking:
            budget_multiplier = max(budget_multiplier, 1.15)  # 15% cost increase for tracking infrastructure
        if hasattr(self.config, 'cross_platform_tracking') and self.config.cross_platform_tracking:
            budget_multiplier = max(budget_multiplier, 1.2)  # 20% cost increase for cross-platform tracking
        
        # Calculate costs
        total_marketing_cost = budget * budget_multiplier * 1.05  # Include service fees and aggressive technique costs
        ticket_price = getattr(event, 'price', self.config.ticket_price)
        gross_revenue = conversions * (ticket_price if ticket_price > 0 else 0)
        
        # Handle free events with add-ons
        if self.config.free_event_with_addons:
            addon_rate = random.uniform(*self.config.addon_conversion_rate_traditional)
            addon_revenue = conversions * addon_rate * random.uniform(*self.config.addon_revenue_per_attendee)
            gross_revenue = addon_revenue
        
        payment_processing_fee = gross_revenue * PAYMENT_PROCESSING_FEE_RATE
        platform_fee = gross_revenue * TRADITIONAL_PLATFORM_FEE_RATE
        total_costs = total_marketing_cost + payment_processing_fee + platform_fee
        net_profit = gross_revenue - total_costs
        roi = (net_profit / total_costs) if total_costs > 0 else 0
        
        return {
            'total_conversions': conversions,
            'total_marketing_cost': total_marketing_cost,
            'gross_revenue': gross_revenue,
            'payment_processing_fee': payment_processing_fee,
            'platform_fee': platform_fee,
            'total_costs': total_costs,
            'net_profit': net_profit,
            'roi': roi,
            'conversion_rate': base_conversion_rate,
            'marketing_start_days_before': marketing_start_days_before,
            'marketing_duration_days': marketing_duration_days,
        }
    
    def run_spots_marketing(
        self,
        event: Event,
        users: List[UserProfile],
        host: UserProfile,
        spots_budget_override: Optional[float] = None
    ) -> Dict:
        """Run SPOTS marketing for an event"""
        # Calculate marketing timeline
        if self.config.use_equal_timeline:
            marketing_start_days_before = random.uniform(*self.config.traditional_lead_time_days)
            marketing_duration_days = random.uniform(*self.config.traditional_duration_days)
        else:
            if self.config.last_minute_event:
                marketing_start_days_before = random.uniform(0.5, 1.0)
                marketing_duration_days = random.uniform(0.5, 1.0)
            else:
                marketing_start_days_before = random.uniform(*self.config.spots_lead_time_days)
                marketing_duration_days = random.uniform(*self.config.spots_duration_days)
        
        # Simplified SPOTS matching (full implementation would use quantum matching, etc.)
        # SPOTS has much better conversion due to targeting
        base_conversion_rate = random.uniform(0.15, 0.25)  # 15-25% baseline
        if self.config.last_minute_event:
            base_conversion_rate *= 0.7  # Slightly lower for last-minute, but still much better
        
        # Simulate matched users (SPOTS finds better matches)
        matched_users_count = int(len(users) * random.uniform(0.20, 0.40))  # 20-40% match rate
        conversions = int(matched_users_count * base_conversion_rate)
        
        # SPOTS cost is lower (CPA-based)
        # For outspend scenarios, SPOTS uses standard budget
        if spots_budget_override:
            # If budget override provided, use it (for outspend scenarios where SPOTS gets less)
            total_marketing_cost = spots_budget_override
        else:
            cpa = random.uniform(2.00, 8.00)
            total_marketing_cost = conversions * cpa
        
        # Calculate revenue
        ticket_price = getattr(event, 'price', self.config.ticket_price)
        gross_revenue = conversions * (ticket_price if ticket_price > 0 else 0)
        
        # Handle free events with add-ons
        if self.config.free_event_with_addons:
            addon_rate = random.uniform(*self.config.addon_conversion_rate_spots)
            addon_revenue = conversions * addon_rate * random.uniform(*self.config.addon_revenue_per_attendee)
            gross_revenue = addon_revenue
        
        payment_processing_fee = gross_revenue * PAYMENT_PROCESSING_FEE_RATE
        platform_fee = gross_revenue * SPOTS_PLATFORM_FEE_RATE
        total_costs = total_marketing_cost + payment_processing_fee + platform_fee
        net_profit = gross_revenue - total_costs
        roi = (net_profit / total_costs) if total_costs > 0 else 0
        
        # Track repeat attendance
        if self.config.track_repeat_attendance:
            for user in users[:conversions]:  # Simulate converted users
                self.user_attendance_history[user.agent_id].append(event.event_id)
                self.host_attendance_history[host.agent_id].append(user.agent_id)
        
        # Track referrals and social shares
        if self.config.track_referrals:
            referral_rate = random.uniform(0.25, 0.40)  # SPOTS: 25-40%
            self.referrals[event.event_id] = int(conversions * referral_rate)
        
        if self.config.track_social_shares:
            share_rate = random.uniform(0.30, 0.50)  # SPOTS: 30-50% share
            self.social_shares[event.event_id] = int(conversions * share_rate)
        
        return {
            'conversions': conversions,
            'total_marketing_cost': total_marketing_cost,
            'gross_revenue': gross_revenue,
            'payment_processing_fee': payment_processing_fee,
            'platform_fee': platform_fee,
            'total_costs': total_costs,
            'net_profit': net_profit,
            'roi': roi,
            'conversion_rate': base_conversion_rate,
            'marketing_start_days_before': marketing_start_days_before,
            'marketing_duration_days': marketing_duration_days,
        }
    
    def run_experiment(self) -> Tuple[List[Dict], List[Dict]]:
        """Run the full experiment"""
        control_users, test_users, events = self.setup_experiment()
        
        control_results = []
        test_results = []
        
        print(f"Running experiment with {len(events)} events...")
        
        for i, event in enumerate(events):
            if (i + 1) % 50 == 0:
                print(f"Processing event {i+1}/{len(events)}...")
            
            # Find host
            control_host = next((u for u in control_users if u.agent_id == event.host_id), None)
            if not control_host:
                control_host = random.choice(control_users)
            
            # Handle outspend scenarios
            traditional_budget = self.config.marketing_budget
            spots_budget = None
            
            if 'outspend' in self.config.scenario_id:
                # Traditional gets full budget, SPOTS gets standard budget
                if 'outspend_3x' in self.config.scenario_id:
                    spots_budget = self.config.marketing_budget / 3  # SPOTS gets 1/3
                elif 'outspend_5x' in self.config.scenario_id:
                    spots_budget = self.config.marketing_budget / 5  # SPOTS gets 1/5
            
            # Run marketing
            traditional_result = self.run_traditional_marketing(
                event, control_users, 
                traditional_budget_override=traditional_budget if 'outspend' in self.config.scenario_id else None
            )
            spots_result = self.run_spots_marketing(
                event, test_users, control_host,
                spots_budget_override=spots_budget
            )
            
            # Store results
            control_results.append({
                'event_id': event.event_id,
                'category': event.category,
                'event_date': event.event_date,
                'tickets_sold': traditional_result['total_conversions'],
                'gross_revenue': traditional_result['gross_revenue'],
                'net_profit': traditional_result['net_profit'],
                'roi': traditional_result['roi'],
                **traditional_result
            })
            
            test_results.append({
                'event_id': event.event_id,
                'category': event.category,
                'event_date': event.event_date,
                'tickets_sold': spots_result['conversions'],
                'gross_revenue': spots_result['gross_revenue'],
                'net_profit': spots_result['net_profit'],
                'roi': spots_result['roi'],
                **spots_result
            })
        
        print(f"✅ Experiment complete: {len(control_results)} control events, "
              f"{len(test_results)} test events")
        
        return control_results, test_results
    
    def calculate_statistics(
        self,
        control_results: List[Dict],
        test_results: List[Dict]
    ) -> Dict:
        """Calculate statistics from results"""
        control_df = pd.DataFrame(control_results)
        test_df = pd.DataFrame(test_results)
        
        # Basic statistics
        stats_dict = {
            'control': {
                'attendance_rate': control_df['tickets_sold'].sum() / (len(control_results) * self.config.num_users_per_group) if len(control_results) > 0 else 0,
                'conversion_rate': control_df['conversion_rate'].mean() if 'conversion_rate' in control_df else 0,
                'gross_revenue_per_event': control_df['gross_revenue'].mean(),
                'net_profit_per_event': control_df['net_profit'].mean(),
                'total_gross_revenue': control_df['gross_revenue'].sum(),
                'total_net_profit': control_df['net_profit'].sum(),
                'roi': control_df['roi'].mean(),
            },
            'test': {
                'attendance_rate': test_df['tickets_sold'].sum() / (len(test_results) * self.config.num_users_per_group) if len(test_results) > 0 else 0,
                'conversion_rate': test_df['conversion_rate'].mean() if 'conversion_rate' in test_df else 0,
                'gross_revenue_per_event': test_df['gross_revenue'].mean(),
                'net_profit_per_event': test_df['net_profit'].mean(),
                'total_gross_revenue': test_df['gross_revenue'].sum(),
                'total_net_profit': test_df['net_profit'].sum(),
                'roi': test_df['roi'].mean(),
            }
        }
        
        # Calculate improvements
        improvements = {}
        for key in ['attendance_rate', 'conversion_rate', 'gross_revenue_per_event',
                    'net_profit_per_event', 'total_net_profit', 'roi']:
            if key in stats_dict['control'] and key in stats_dict['test']:
                control_val = stats_dict['control'][key]
                test_val = stats_dict['test'][key]
                if control_val > 0:
                    improvement = (test_val - control_val) / control_val
                    improvement_x = test_val / control_val
                    improvements[key] = {
                        'improvement': improvement,
                        'improvement_x': improvement_x
                    }
        
        stats_dict['improvements'] = improvements
        
        return stats_dict
    
    def save_results(
        self,
        control_results: List[Dict],
        test_results: List[Dict],
        statistics: Dict
    ):
        """Save results to files"""
        # Save CSV files
        pd.DataFrame(control_results).to_csv(
            self.results_dir / 'traditional_results.csv',
            index=False
        )
        pd.DataFrame(test_results).to_csv(
            self.results_dir / 'spots_results.csv',
            index=False
        )
        
        # Save statistics JSON
        def convert_to_native(obj):
            """Convert numpy types to native Python types"""
            if isinstance(obj, (np.integer, np.int64)):
                return int(obj)
            elif isinstance(obj, (np.floating, np.float64)):
                return float(obj)
            elif isinstance(obj, np.bool_):
                return bool(obj)
            elif isinstance(obj, np.ndarray):
                return obj.tolist()
            elif isinstance(obj, dict):
                return {k: convert_to_native(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [convert_to_native(item) for item in obj]
            return obj
        
        with open(self.results_dir / 'statistics.json', 'w') as f:
            json.dump(convert_to_native(statistics), f, indent=2)
        
        print(f"💾 Results saved to: {self.results_dir}")

def run_scenario(config: ScenarioConfig) -> Dict:
    """Run a single scenario and return results"""
    runner = ExperimentRunner(config)
    control_results, test_results = runner.run_experiment()
    statistics = runner.calculate_statistics(control_results, test_results)
    runner.save_results(control_results, test_results, statistics)
    
    return {
        'scenario_id': config.scenario_id,
        'status': 'success',
        'statistics': statistics,
        'results_dir': str(runner.results_dir)
    }

