#!/usr/bin/env python3
"""
Scenario Configuration for Marketing Experiments

Defines all test scenarios with their parameters.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
from enum import Enum

class ScenarioType(Enum):
    """Types of scenarios to test"""
    PRICE_VARIATION = "price_variation"
    CATEGORY_PERFORMANCE = "category_performance"
    USER_SCALE = "user_scale"
    TIMING_URGENCY = "timing_urgency"
    BUDGET_VARIATION = "budget_variation"
    EVENT_QUALITY = "event_quality"
    COMPETITIVE = "competitive"
    REPEAT_ATTENDANCE = "repeat_attendance"
    GEOGRAPHIC = "geographic"
    WORD_OF_MOUTH = "word_of_mouth"
    EVENT_TYPE = "event_type"
    LONG_TERM = "long_term"

@dataclass
class ScenarioConfig:
    """Configuration for a single test scenario"""
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
    traditional_lead_time_days: Tuple[float, float] = (30, 60)  # (min, max)
    traditional_duration_days: Tuple[float, float] = (28, 56)  # (min, max)
    spots_lead_time_days: Tuple[float, float] = (7, 14)  # (min, max)
    spots_duration_days: Tuple[float, float] = (7, 14)  # (min, max)
    use_equal_timeline: bool = False  # If True, SPOTS uses traditional timeline
    
    # Event filtering
    event_categories: Optional[List[str]] = None  # None = all categories
    event_types: Optional[List[str]] = None  # None = all types
    niche_only: bool = False  # If True, only test niche events
    mainstream_only: bool = False  # If True, only test mainstream events
    
    # Special parameters
    free_event_with_addons: bool = False  # If True, ticket is free, revenue from add-ons
    addon_revenue_per_attendee: Tuple[float, float] = (10, 50)  # (min, max)
    addon_conversion_rate_spots: Tuple[float, float] = (0.30, 0.60)  # (min, max)
    addon_conversion_rate_traditional: Tuple[float, float] = (0.10, 0.20)  # (min, max)
    
    last_minute_event: bool = False  # If True, event announced 24-48h before
    last_minute_hours: Tuple[float, float] = (24, 48)  # (min, max) hours before event
    
    new_hosts_only: bool = False  # If True, all hosts are new (no reputation)
    established_hosts_only: bool = False  # If True, all hosts are established
    
    # Network effects
    simulate_user_growth: bool = False  # If True, simulate growing user base
    initial_users: int = 500
    users_added_per_month: int = 100
    
    # Repeat attendance tracking
    track_repeat_attendance: bool = False  # If True, track repeat attendees
    
    # Geographic
    market_type: Optional[str] = None  # "urban", "suburban", "rural", None = mixed
    city_name: Optional[str] = None  # Specific city to simulate
    
    # Competitive scenarios
    competing_events_count: int = 0  # Number of competing events on same day
    
    # Word of mouth
    track_referrals: bool = False  # If True, track referral rates
    track_social_shares: bool = False  # If True, track social media shares
    
    # Long-term
    long_term_months: int = 12  # For 12-month simulations
    
    # Output
    output_subfolder: Optional[str] = None  # Subfolder for results (auto-generated if None)

# ============================================================================
# SCENARIO DEFINITIONS
# ============================================================================

def get_all_scenarios() -> List[ScenarioConfig]:
    """Get all scenario configurations"""
    scenarios = []
    
    # ========================================================================
    # 1. PRICE POINT VARIATIONS
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="price_low_25",
        scenario_name="Low-Ticket Events ($25)",
        scenario_type=ScenarioType.PRICE_VARIATION,
        description="Test SPOTS performance with $25 tickets (lower price point)",
        ticket_price=25.00,
        output_subfolder="price_variations/low_ticket_25"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="price_high_100",
        scenario_name="High-Ticket Events ($100)",
        scenario_type=ScenarioType.PRICE_VARIATION,
        description="Test SPOTS performance with $100 tickets (premium pricing)",
        ticket_price=100.00,
        output_subfolder="price_variations/high_ticket_100"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="price_high_200",
        scenario_name="High-Ticket Events ($200)",
        scenario_type=ScenarioType.PRICE_VARIATION,
        description="Test SPOTS performance with $200 tickets (luxury pricing)",
        ticket_price=200.00,
        output_subfolder="price_variations/high_ticket_200"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="price_free_addons",
        scenario_name="Free Events with Add-ons",
        scenario_type=ScenarioType.PRICE_VARIATION,
        description="Test free events where revenue comes from add-ons (food, drinks, merch)",
        ticket_price=0.00,
        free_event_with_addons=True,
        addon_revenue_per_attendee=(10, 50),
        addon_conversion_rate_spots=(0.30, 0.60),
        addon_conversion_rate_traditional=(0.10, 0.20),
        output_subfolder="price_variations/free_with_addons"
    ))
    
    # ========================================================================
    # 2. EVENT CATEGORY PERFORMANCE
    # ========================================================================
    
    categories = ["food", "entertainment", "culture", "outdoor", "health", "education"]
    for category in categories:
        scenarios.append(ScenarioConfig(
            scenario_id=f"category_{category}",
            scenario_name=f"{category.title()} Events Only",
            scenario_type=ScenarioType.CATEGORY_PERFORMANCE,
            description=f"Test SPOTS performance for {category} category events",
            event_categories=[category],
            output_subfolder=f"category_performance/{category}"
        ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="category_niche",
        scenario_name="Niche Events Only",
        scenario_type=ScenarioType.CATEGORY_PERFORMANCE,
        description="Test SPOTS performance for niche/specialized events",
        niche_only=True,
        output_subfolder="category_performance/niche"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="category_mainstream",
        scenario_name="Mainstream Events Only",
        scenario_type=ScenarioType.CATEGORY_PERFORMANCE,
        description="Test SPOTS performance for mainstream/popular events",
        mainstream_only=True,
        output_subfolder="category_performance/mainstream"
    ))
    
    # ========================================================================
    # 3. USER BASE SCALE VARIATIONS
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="scale_small_100",
        scenario_name="Small Market (100 Users)",
        scenario_type=ScenarioType.USER_SCALE,
        description="Test SPOTS performance in small market with 100 users",
        num_users_per_group=100,
        num_events_per_group=50,
        output_subfolder="user_scale/small_100"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="scale_large_10000",
        scenario_name="Large Market (10,000 Users)",
        scenario_type=ScenarioType.USER_SCALE,
        description="Test SPOTS performance in large market with 10,000 users",
        num_users_per_group=10000,
        num_events_per_group=1000,
        output_subfolder="user_scale/large_10000"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="scale_network_effects",
        scenario_name="Network Effects (Growing User Base)",
        scenario_type=ScenarioType.USER_SCALE,
        description="Test SPOTS improvement as user base grows over 6 months",
        simulate_user_growth=True,
        initial_users=500,
        users_added_per_month=100,
        output_subfolder="user_scale/network_effects"
    ))
    
    # ========================================================================
    # 4. EVENT TIMING & URGENCY
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="timing_last_minute",
        scenario_name="Last-Minute Events (24-48 Hours)",
        scenario_type=ScenarioType.TIMING_URGENCY,
        description="Test SPOTS performance for events announced 24-48 hours before",
        last_minute_event=True,
        last_minute_hours=(24, 48),
        traditional_lead_time_days=(0.5, 1.0),  # Can't market effectively
        spots_lead_time_days=(0.5, 1.0),  # But SPOTS can still match
        output_subfolder="timing/last_minute"
    ))
    
    # ========================================================================
    # 5. MARKETING BUDGET VARIATIONS
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="budget_low_500",
        scenario_name="Low Budget ($500 per Event)",
        scenario_type=ScenarioType.BUDGET_VARIATION,
        description="Test SPOTS performance with low marketing budget",
        marketing_budget=500.00,
        output_subfolder="budget_variations/low_500"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="budget_high_5000",
        scenario_name="High Budget ($5,000 per Event)",
        scenario_type=ScenarioType.BUDGET_VARIATION,
        description="Test SPOTS performance with high marketing budget",
        marketing_budget=5000.00,
        output_subfolder="budget_variations/high_5000"
    ))
    
    # ========================================================================
    # 6. EVENT QUALITY & REPUTATION
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="quality_new_hosts",
        scenario_name="New Hosts (No Reputation)",
        scenario_type=ScenarioType.EVENT_QUALITY,
        description="Test SPOTS performance for new hosts with no reputation",
        new_hosts_only=True,
        output_subfolder="event_quality/new_hosts"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="quality_established_hosts",
        scenario_name="Established Hosts (High Reputation)",
        scenario_type=ScenarioType.EVENT_QUALITY,
        description="Test SPOTS performance for established hosts with high reputation",
        established_hosts_only=True,
        output_subfolder="event_quality/established_hosts"
    ))
    
    # ========================================================================
    # 7. COMPETITIVE SCENARIOS
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="competitive_multiple_events",
        scenario_name="Multiple Competing Events (10 on Same Day)",
        scenario_type=ScenarioType.COMPETITIVE,
        description="Test SPOTS performance when 10 events compete on same day",
        competing_events_count=10,
        output_subfolder="competitive/multiple_events"
    ))
    
    # ========================================================================
    # 8. REPEAT ATTENDANCE & LOYALTY
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="repeat_attendance",
        scenario_name="Repeat Attendance Tracking",
        scenario_type=ScenarioType.REPEAT_ATTENDANCE,
        description="Track repeat attendance rates for SPOTS vs Traditional",
        track_repeat_attendance=True,
        num_events_per_group=100,  # More events to track patterns
        output_subfolder="repeat_attendance/tracking"
    ))
    
    # ========================================================================
    # 9. GEOGRAPHIC VARIATIONS
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="geo_urban",
        scenario_name="Urban Market",
        scenario_type=ScenarioType.GEOGRAPHIC,
        description="Test SPOTS performance in urban market (high density)",
        market_type="urban",
        output_subfolder="geographic/urban"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="geo_suburban",
        scenario_name="Suburban Market",
        scenario_type=ScenarioType.GEOGRAPHIC,
        description="Test SPOTS performance in suburban market (moderate density)",
        market_type="suburban",
        output_subfolder="geographic/suburban"
    ))
    
    # ========================================================================
    # 10. WORD-OF-MOUTH AMPLIFICATION
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="word_of_mouth",
        scenario_name="Word-of-Mouth & Referrals",
        scenario_type=ScenarioType.WORD_OF_MOUTH,
        description="Track referral rates and social sharing for SPOTS vs Traditional",
        track_referrals=True,
        track_social_shares=True,
        output_subfolder="word_of_mouth/tracking"
    ))
    
    # ========================================================================
    # 11. EVENT TYPE PERFORMANCE
    # ========================================================================
    
    event_types = ["tour", "workshop", "meetup", "tasting", "lecture"]
    for event_type in event_types:
        scenarios.append(ScenarioConfig(
            scenario_id=f"event_type_{event_type}",
            scenario_name=f"{event_type.title()} Events Only",
            scenario_type=ScenarioType.EVENT_TYPE,
            description=f"Test SPOTS performance for {event_type} type events",
            event_types=[event_type],
            output_subfolder=f"event_types/{event_type}"
        ))
    
    # ========================================================================
    # 12. LONG-TERM PLATFORM HEALTH
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="long_term_12_months",
        scenario_name="12-Month Long-Term Simulation",
        scenario_type=ScenarioType.LONG_TERM,
        description="Test SPOTS performance over 12 months (long-term platform health)",
        num_months=12,
        track_repeat_attendance=True,
        simulate_user_growth=True,
        output_subfolder="long_term/12_months"
    ))
    
    return scenarios

def get_scenario_by_id(scenario_id: str) -> Optional[ScenarioConfig]:
    """Get a specific scenario by ID"""
    for scenario in get_all_scenarios():
        if scenario.scenario_id == scenario_id:
            return scenario
    return None

def get_scenarios_by_type(scenario_type: ScenarioType) -> List[ScenarioConfig]:
    """Get all scenarios of a specific type"""
    return [s for s in get_all_scenarios() if s.scenario_type == scenario_type]

def get_priority_scenarios() -> List[ScenarioConfig]:
    """Get high-priority scenarios for initial testing"""
    priority_ids = [
        "price_low_25",
        "price_high_100",
        "price_free_addons",
        "timing_last_minute",
        "scale_network_effects",
        "category_niche",
        "repeat_attendance",
    ]
    return [s for s in get_all_scenarios() if s.scenario_id in priority_ids]

