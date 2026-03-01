#!/usr/bin/env python3
"""
Scenario Configuration - Aggressive/Untraditional Marketing Techniques

These scenarios test SPOTS against aggressive, privacy-invasive, and
manipulative marketing techniques that go beyond traditional methods.

Techniques tested:
- Aggressive data collection and user profiling
- Privacy-invasive targeting (tracking, cookies, cross-platform)
- Behavioral manipulation and dark patterns
- Data harvesting and reselling
- Micro-targeting with extensive user data
- Psychological manipulation techniques
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
from enum import Enum

class ScenarioType(Enum):
    """Types of aggressive marketing scenarios"""
    DATA_HARVESTING = "data_harvesting"
    PRIVACY_INVASIVE = "privacy_invasive"
    BEHAVIORAL_MANIPULATION = "behavioral_manipulation"
    MICRO_TARGETING = "micro_targeting"
    CROSS_PLATFORM_TRACKING = "cross_platform_tracking"
    PSYCHOLOGICAL_MANIPULATION = "psychological_manipulation"
    DARK_PATTERNS = "dark_patterns"

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
    
    # Special parameters (needed for experiment runner compatibility)
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
    
    # Aggressive marketing parameters
    aggressive_data_collection: bool = False  # Extensive user data collection
    privacy_invasive_tracking: bool = False  # Cross-platform tracking, cookies
    behavioral_manipulation: bool = False  # Dark patterns, psychological tricks
    micro_targeting_enabled: bool = False  # Micro-targeting with extensive data
    cross_platform_tracking: bool = False  # Track users across all platforms
    psychological_manipulation: bool = False  # FOMO, scarcity, social proof manipulation
    dark_patterns_enabled: bool = False  # Deceptive UI, hidden costs, etc.
    
    # Output
    output_subfolder: Optional[str] = None

# ============================================================================
# AGGRESSIVE MARKETING SCENARIOS
# ============================================================================

def get_aggressive_scenarios() -> List[ScenarioConfig]:
    """Get scenarios testing aggressive/untraditional marketing techniques"""
    scenarios = []
    
    # ========================================================================
    # 1. DATA HARVESTING SCENARIOS
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="aggressive_data_harvesting",
        scenario_name="Aggressive Data Harvesting - Extensive User Profiling",
        scenario_type=ScenarioType.DATA_HARVESTING,
        description="Test against competitors who collect extensive user data (purchases, browsing, location, social media)",
        aggressive_data_collection=True,
        output_subfolder="aggressive_marketing/data_harvesting"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="aggressive_data_reselling",
        scenario_name="Data Reselling - Third-Party User Profiles",
        scenario_type=ScenarioType.DATA_HARVESTING,
        description="Test against competitors who buy user data from data brokers and third-party sources",
        aggressive_data_collection=True,
        micro_targeting_enabled=True,
        output_subfolder="aggressive_marketing/data_reselling"
    ))
    
    # ========================================================================
    # 2. PRIVACY-INVASIVE TARGETING
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="privacy_invasive_tracking",
        scenario_name="Privacy-Invasive Tracking - Cross-Platform Cookies",
        scenario_type=ScenarioType.PRIVACY_INVASIVE,
        description="Test against competitors using extensive cookie tracking, fingerprinting, and cross-site tracking",
        privacy_invasive_tracking=True,
        cross_platform_tracking=True,
        output_subfolder="aggressive_marketing/privacy_invasive"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="privacy_invasive_location",
        scenario_name="Aggressive Location Tracking - Always-On GPS",
        scenario_type=ScenarioType.PRIVACY_INVASIVE,
        description="Test against competitors using always-on location tracking and geofencing",
        privacy_invasive_tracking=True,
        output_subfolder="aggressive_marketing/location_tracking"
    ))
    
    # ========================================================================
    # 3. BEHAVIORAL MANIPULATION
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="behavioral_manipulation",
        scenario_name="Behavioral Manipulation - Dark Patterns & Psychological Tricks",
        scenario_type=ScenarioType.BEHAVIORAL_MANIPULATION,
        description="Test against competitors using dark patterns, FOMO, scarcity, and psychological manipulation",
        behavioral_manipulation=True,
        psychological_manipulation=True,
        dark_patterns_enabled=True,
        output_subfolder="aggressive_marketing/behavioral_manipulation"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="fomo_scarcity",
        scenario_name="FOMO & Scarcity Manipulation - Fake Urgency",
        scenario_type=ScenarioType.BEHAVIORAL_MANIPULATION,
        description="Test against competitors using fake scarcity, countdown timers, and FOMO tactics",
        psychological_manipulation=True,
        output_subfolder="aggressive_marketing/fomo_scarcity"
    ))
    
    # ========================================================================
    # 4. MICRO-TARGETING WITH EXTENSIVE DATA
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="micro_targeting_extensive",
        scenario_name="Micro-Targeting - Extensive User Data Profiles",
        scenario_type=ScenarioType.MICRO_TARGETING,
        description="Test against competitors using micro-targeting with extensive user data (100+ data points per user)",
        micro_targeting_enabled=True,
        aggressive_data_collection=True,
        output_subfolder="aggressive_marketing/micro_targeting"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="micro_targeting_ai",
        scenario_name="AI-Powered Micro-Targeting - Machine Learning Profiling",
        scenario_type=ScenarioType.MICRO_TARGETING,
        description="Test against competitors using AI/ML to create detailed user profiles from all available data",
        micro_targeting_enabled=True,
        aggressive_data_collection=True,
        privacy_invasive_tracking=True,
        output_subfolder="aggressive_marketing/ai_micro_targeting"
    ))
    
    # ========================================================================
    # 5. CROSS-PLATFORM TRACKING
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="cross_platform_tracking",
        scenario_name="Cross-Platform Tracking - User Behavior Across All Apps",
        scenario_type=ScenarioType.CROSS_PLATFORM_TRACKING,
        description="Test against competitors tracking users across all platforms, apps, and services",
        cross_platform_tracking=True,
        privacy_invasive_tracking=True,
        output_subfolder="aggressive_marketing/cross_platform"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="device_fingerprinting",
        scenario_name="Device Fingerprinting - Unique Device Identification",
        scenario_type=ScenarioType.CROSS_PLATFORM_TRACKING,
        description="Test against competitors using device fingerprinting to track users without cookies",
        privacy_invasive_tracking=True,
        cross_platform_tracking=True,
        output_subfolder="aggressive_marketing/device_fingerprinting"
    ))
    
    # ========================================================================
    # 6. PSYCHOLOGICAL MANIPULATION
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="psychological_social_proof",
        scenario_name="Social Proof Manipulation - Fake Reviews & Testimonials",
        scenario_type=ScenarioType.PSYCHOLOGICAL_MANIPULATION,
        description="Test against competitors using fake social proof, reviews, and testimonials",
        psychological_manipulation=True,
        output_subfolder="aggressive_marketing/social_proof"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="psychological_anchoring",
        scenario_name="Price Anchoring - Manipulative Pricing Strategies",
        scenario_type=ScenarioType.PSYCHOLOGICAL_MANIPULATION,
        description="Test against competitors using price anchoring, fake discounts, and manipulative pricing",
        psychological_manipulation=True,
        output_subfolder="aggressive_marketing/price_anchoring"
    ))
    
    # ========================================================================
    # 7. DARK PATTERNS
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="dark_patterns_ui",
        scenario_name="Dark Patterns - Deceptive UI & Hidden Costs",
        scenario_type=ScenarioType.DARK_PATTERNS,
        description="Test against competitors using deceptive UI, hidden costs, and confusing interfaces",
        dark_patterns_enabled=True,
        behavioral_manipulation=True,
        output_subfolder="aggressive_marketing/dark_patterns"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="dark_patterns_consent",
        scenario_name="Consent Dark Patterns - Forced Opt-Ins",
        scenario_type=ScenarioType.DARK_PATTERNS,
        description="Test against competitors using dark patterns to force consent and data sharing",
        dark_patterns_enabled=True,
        privacy_invasive_tracking=True,
        output_subfolder="aggressive_marketing/consent_dark_patterns"
    ))
    
    # ========================================================================
    # 8. COMBINED AGGRESSIVE TECHNIQUES
    # ========================================================================
    
    scenarios.append(ScenarioConfig(
        scenario_id="aggressive_perfect_storm",
        scenario_name="Perfect Storm - All Aggressive Techniques Combined",
        scenario_type=ScenarioType.DATA_HARVESTING,
        description="Test against competitors using ALL aggressive techniques: data harvesting, tracking, manipulation, dark patterns",
        aggressive_data_collection=True,
        privacy_invasive_tracking=True,
        behavioral_manipulation=True,
        micro_targeting_enabled=True,
        cross_platform_tracking=True,
        psychological_manipulation=True,
        dark_patterns_enabled=True,
        output_subfolder="aggressive_marketing/perfect_storm"
    ))
    
    scenarios.append(ScenarioConfig(
        scenario_id="aggressive_optimal",
        scenario_name="Aggressive Marketing Optimal - Maximum Invasion",
        scenario_type=ScenarioType.DATA_HARVESTING,
        description="Test against competitors using maximum data collection, tracking, and manipulation",
        aggressive_data_collection=True,
        privacy_invasive_tracking=True,
        behavioral_manipulation=True,
        micro_targeting_enabled=True,
        cross_platform_tracking=True,
        psychological_manipulation=True,
        dark_patterns_enabled=True,
        marketing_budget=5000.00,  # Higher budget for aggressive marketing
        output_subfolder="aggressive_marketing/optimal_invasion"
    ))
    
    return scenarios

def get_scenario_by_id(scenario_id: str) -> Optional[ScenarioConfig]:
    """Get a specific scenario by ID"""
    for scenario in get_aggressive_scenarios():
        if scenario.scenario_id == scenario_id:
            return scenario
    return None

