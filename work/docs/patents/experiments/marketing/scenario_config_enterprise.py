#!/usr/bin/env python3
"""
Enterprise-Scale Marketing Scenario Configuration

Tests SPOTS against traditional marketing at enterprise scale:
- Millions of dollars in marketing budget
- 100,000+ users
- Large-scale event marketing
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
from enum import Enum

class ScenarioType(Enum):
    """Types of enterprise scenarios"""
    ENTERPRISE_SCALE = "enterprise_scale"

@dataclass
class ScenarioConfig:
    """Configuration for enterprise-scale test scenario"""
    # Scenario identification
    scenario_id: str
    scenario_name: str
    scenario_type: ScenarioType
    description: str
    
    # Test parameters
    ticket_price: float = 50.00
    marketing_budget: float = 2000.00
    num_users_per_group: int = 1000
    num_events_per_group: int = 500
    num_months: int = 6
    
    # Timing parameters
    traditional_lead_time_days: Tuple[float, float] = (30, 60)
    traditional_duration_days: Tuple[float, float] = (28, 56)
    spots_lead_time_days: Tuple[float, float] = (7, 14)
    spots_duration_days: Tuple[float, float] = (7, 14)
    use_equal_timeline: bool = False
    
    # Event filtering
    event_categories: Optional[List[str]] = None
    event_types: Optional[List[str]] = None
    niche_only: bool = False
    mainstream_only: bool = False
    
    # Special parameters
    free_event_with_addons: bool = False
    addon_revenue_per_attendee: Tuple[float, float] = (10, 50)
    addon_conversion_rate_spots: Tuple[float, float] = (0.30, 0.60)
    addon_conversion_rate_traditional: Tuple[float, float] = (0.10, 0.20)
    last_minute_event: bool = False
    last_minute_hours: Tuple[float, float] = (24, 48)
    new_hosts_only: bool = False
    established_hosts_only: bool = False
    simulate_user_growth: bool = False
    initial_users: int = 500
    users_added_per_month: int = 100
    track_repeat_attendance: bool = False
    market_type: Optional[str] = None
    city_name: Optional[str] = None
    competing_events_count: int = 0
    track_referrals: bool = False
    track_social_shares: bool = False
    long_term_months: int = 12
    
    # Aggressive marketing parameters (for compatibility)
    aggressive_data_collection: bool = False
    privacy_invasive_tracking: bool = False
    behavioral_manipulation: bool = False
    micro_targeting_enabled: bool = False
    cross_platform_tracking: bool = False
    psychological_manipulation: bool = False
    dark_patterns_enabled: bool = False
    
    # Output
    output_subfolder: Optional[str] = None

# ============================================================================
# ENTERPRISE-SCALE SCENARIOS
# ============================================================================

def get_enterprise_scenarios() -> List[ScenarioConfig]:
    """Get enterprise-scale marketing scenarios"""
    scenarios = []
    
    # Enterprise scale: Millions in budget, 100k users
    scenarios.append(ScenarioConfig(
        scenario_id="enterprise_millions_100k",
        scenario_name="Enterprise Scale - $2M Budget, 100,000 Users",
        scenario_type=ScenarioType.ENTERPRISE_SCALE,
        description="Test SPOTS vs Traditional at enterprise scale: $2M marketing budget, 100,000 users, 1,000 events",
        marketing_budget=2000000.00,  # $2 million per event (enterprise scale)
        num_users_per_group=100000,  # 100,000 users
        num_events_per_group=1000,  # 1,000 events
        output_subfolder="enterprise_scale/millions_100k"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="enterprise_5m_100k",
        scenario_name="Enterprise Scale - $5M Budget, 100,000 Users",
        scenario_type=ScenarioType.ENTERPRISE_SCALE,
        description="Test SPOTS vs Traditional at enterprise scale: $5M marketing budget, 100,000 users, 1,000 events",
        marketing_budget=5000000.00,  # $5 million per event
        num_users_per_group=100000,  # 100,000 users
        num_events_per_group=1000,  # 1,000 events
        output_subfolder="enterprise_scale/5m_100k"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="enterprise_10m_100k",
        scenario_name="Enterprise Scale - $10M Budget, 100,000 Users",
        scenario_type=ScenarioType.ENTERPRISE_SCALE,
        description="Test SPOTS vs Traditional at enterprise scale: $10M marketing budget, 100,000 users, 1,000 events",
        marketing_budget=10000000.00,  # $10 million per event
        num_users_per_group=100000,  # 100,000 users
        num_events_per_group=1000,  # 1,000 events
        output_subfolder="enterprise_scale/10m_100k"
    ))
    
    return scenarios

def get_scenario_by_id(scenario_id: str) -> Optional[ScenarioConfig]:
    """Get a specific scenario by ID"""
    for scenario in get_enterprise_scenarios():
        if scenario.scenario_id == scenario_id:
            return scenario
    return None

