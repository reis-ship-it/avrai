#!/usr/bin/env python3
"""
Scenario Configuration - Biased Towards Traditional Marketing

These scenarios are designed to favor traditional marketing to test
SPOTS' performance under adverse conditions.

Scenarios favor traditional marketing through:
- High budgets (traditional can outspend)
- Mainstream events (broad reach works)
- Established hosts (reputation matters)
- Long lead times (traditional needs time)
- Large markets (traditional can reach more)
- Simple demographics (traditional targeting works)
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
from enum import Enum

class ScenarioType(Enum):
    """Types of scenarios to test"""
    HIGH_BUDGET = "high_budget"
    MAINSTREAM_FAVORED = "mainstream_favored"
    ESTABLISHED_BRANDS = "established_brands"
    LONG_LEAD_TIME = "long_lead_time"
    LARGE_MARKET = "large_market"
    DEMOGRAPHIC_TARGETING = "demographic_targeting"
    OUTSPEND_COMPETITION = "outspend_competition"

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
    
    # Network effects
    simulate_user_growth: bool = False
    initial_users: int = 500
    users_added_per_month: int = 100
    
    # Repeat attendance tracking
    track_repeat_attendance: bool = False
    
    # Geographic
    market_type: Optional[str] = None
    city_name: Optional[str] = None
    
    # Competitive scenarios
    competing_events_count: int = 0
    
    # Word of mouth
    track_referrals: bool = False
    track_social_shares: bool = False
    
    # Long-term
    long_term_months: int = 12
    
    # Output
    output_subfolder: Optional[str] = None

# ============================================================================
# BIASED SCENARIOS - Favor Traditional Marketing
# ============================================================================

def get_biased_scenarios() -> List[ScenarioConfig]:
    """Get scenarios biased towards traditional marketing"""
    scenarios = []
    
    # ========================================================================
    # 1. HIGH BUDGET SCENARIOS (Traditional can outspend)
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_high_budget_10k",
        scenario_name="Very High Budget ($10,000 per Event) - Traditional Advantage",
        scenario_type=ScenarioType.HIGH_BUDGET,
        description="Test with very high budget where traditional can outspend and reach more people",
        marketing_budget=10000.00,  # $10,000 - traditional can reach massive audience
        output_subfolder="biased_traditional/high_budget_10k"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_high_budget_20k",
        scenario_name="Extremely High Budget ($20,000 per Event) - Traditional Advantage",
        scenario_type=ScenarioType.HIGH_BUDGET,
        description="Test with extremely high budget where traditional marketing scale matters",
        marketing_budget=20000.00,  # $20,000 - traditional can dominate with scale
        output_subfolder="biased_traditional/high_budget_20k"
    ))
    
    # ========================================================================
    # 2. MAINSTREAM EVENTS (Traditional broad reach works)
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_mainstream_only",
        scenario_name="Mainstream Events Only - Traditional Broad Reach Advantage",
        scenario_type=ScenarioType.MAINSTREAM_FAVORED,
        description="Test with only mainstream/popular events where traditional broad reach excels",
        mainstream_only=True,
        output_subfolder="biased_traditional/mainstream_only"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_popular_categories",
        scenario_name="Popular Categories Only (Food, Entertainment) - Traditional Advantage",
        scenario_type=ScenarioType.MAINSTREAM_FAVORED,
        description="Test with only popular categories where traditional demographic targeting works",
        event_categories=["food", "entertainment"],  # Most popular categories
        output_subfolder="biased_traditional/popular_categories"
    ))
    
    # ========================================================================
    # 3. ESTABLISHED BRANDS/HOSTS (Reputation matters more)
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_established_brands_only",
        scenario_name="Established Brands Only - Reputation Advantage",
        scenario_type=ScenarioType.ESTABLISHED_BRANDS,
        description="Test with only established hosts where reputation and brand recognition matter",
        established_hosts_only=True,
        output_subfolder="biased_traditional/established_brands"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_high_reputation",
        scenario_name="High Reputation Hosts (4.5+ stars, 1000+ events) - Traditional Advantage",
        scenario_type=ScenarioType.ESTABLISHED_BRANDS,
        description="Test with highly established hosts where brand recognition trumps targeting",
        established_hosts_only=True,
        output_subfolder="biased_traditional/high_reputation"
    ))
    
    # ========================================================================
    # 4. LONG LEAD TIME (Traditional needs time to build campaigns)
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_long_lead_time_90_days",
        scenario_name="Very Long Lead Time (90 days) - Traditional Campaign Building",
        scenario_type=ScenarioType.LONG_LEAD_TIME,
        description="Test with 90-day lead time where traditional can build comprehensive campaigns",
        traditional_lead_time_days=(90, 120),  # 90-120 days
        traditional_duration_days=(60, 90),  # 60-90 day campaigns
        use_equal_timeline=True,  # Force SPOTS to use same timeline
        output_subfolder="biased_traditional/long_lead_90_days"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_extended_campaigns",
        scenario_name="Extended Campaign Duration (12 weeks) - Traditional Advantage",
        scenario_type=ScenarioType.LONG_LEAD_TIME,
        description="Test with extended campaign duration where traditional can build awareness",
        traditional_lead_time_days=(60, 90),
        traditional_duration_days=(84, 112),  # 12-16 weeks
        use_equal_timeline=True,
        output_subfolder="biased_traditional/extended_campaigns"
    ))
    
    # ========================================================================
    # 5. LARGE MARKETS (Traditional can reach more people)
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_large_market_50k",
        scenario_name="Very Large Market (50,000 Users) - Traditional Scale Advantage",
        scenario_type=ScenarioType.LARGE_MARKET,
        description="Test in very large market where traditional can reach massive audience",
        num_users_per_group=50000,  # 50,000 users
        num_events_per_group=2000,  # More events
        output_subfolder="biased_traditional/large_market_50k"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_mega_market_100k",
        scenario_name="Mega Market (100,000 Users) - Traditional Mass Reach",
        scenario_type=ScenarioType.LARGE_MARKET,
        description="Test in mega market where traditional mass marketing excels",
        num_users_per_group=100000,  # 100,000 users
        num_events_per_group=5000,  # Many events
        output_subfolder="biased_traditional/mega_market_100k"
    ))
    
    # ========================================================================
    # 6. DEMOGRAPHIC TARGETING (Traditional demographic targeting works)
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_simple_demographics",
        scenario_name="Simple Demographics (Age, Location) - Traditional Targeting",
        scenario_type=ScenarioType.DEMOGRAPHIC_TARGETING,
        description="Test with simple demographic targeting where traditional excels",
        event_categories=["entertainment"],  # Simple demographics work well
        output_subfolder="biased_traditional/simple_demographics"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_broad_appeal",
        scenario_name="Broad Appeal Events (General Interest) - Traditional Advantage",
        scenario_type=ScenarioType.DEMOGRAPHIC_TARGETING,
        description="Test with broad appeal events where personality matching is less critical",
        event_categories=["entertainment", "food"],  # Broad appeal
        mainstream_only=True,
        output_subfolder="biased_traditional/broad_appeal"
    ))
    
    # ========================================================================
    # 7. OUTSPEND COMPETITION (Traditional can outspend)
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_traditional_outspend",
        scenario_name="Traditional Outspends (3x Budget) - Spending Advantage",
        scenario_type=ScenarioType.OUTSPEND_COMPETITION,
        description="Test where traditional marketing has 3x the budget of SPOTS",
        marketing_budget=6000.00,  # Traditional gets $6,000
        # SPOTS will use lower budget in experiment runner
        output_subfolder="biased_traditional/outspend_3x"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_traditional_outspend_5x",
        scenario_name="Traditional Outspends (5x Budget) - Massive Spending Advantage",
        scenario_type=ScenarioType.OUTSPEND_COMPETITION,
        description="Test where traditional marketing has 5x the budget of SPOTS",
        marketing_budget=10000.00,  # Traditional gets $10,000
        # SPOTS will use lower budget in experiment runner
        output_subfolder="biased_traditional/outspend_5x"
    ))
    
    # ========================================================================
    # 8. COMBINED ADVANTAGES (Multiple traditional advantages)
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_perfect_storm",
        scenario_name="Perfect Storm for Traditional (High Budget + Mainstream + Established + Long Lead)",
        scenario_type=ScenarioType.HIGH_BUDGET,
        description="Combine multiple traditional advantages: high budget, mainstream events, established hosts, long lead time",
        marketing_budget=15000.00,  # High budget
        mainstream_only=True,  # Mainstream events
        established_hosts_only=True,  # Established hosts
        traditional_lead_time_days=(90, 120),  # Long lead time
        traditional_duration_days=(84, 112),  # Extended campaigns
        use_equal_timeline=True,  # Force SPOTS to use same timeline
        output_subfolder="biased_traditional/perfect_storm"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="biased_traditional_optimal",
        scenario_name="Traditional Optimal Conditions (All Advantages)",
        scenario_type=ScenarioType.HIGH_BUDGET,
        description="All conditions favor traditional: high budget, large market, mainstream, established, long lead",
        marketing_budget=20000.00,  # Very high budget
        num_users_per_group=50000,  # Large market
        mainstream_only=True,  # Mainstream events
        established_hosts_only=True,  # Established hosts
        traditional_lead_time_days=(90, 120),  # Long lead time
        traditional_duration_days=(84, 112),  # Extended campaigns
        use_equal_timeline=True,  # Force SPOTS to use same timeline
        output_subfolder="biased_traditional/optimal_conditions"
    ))
    
    return scenarios

def get_scenario_by_id(scenario_id: str) -> Optional[ScenarioConfig]:
    """Get a specific scenario by ID"""
    for scenario in get_biased_scenarios():
        if scenario.scenario_id == scenario_id:
            return scenario
    return None

