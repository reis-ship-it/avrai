# Master Summary: All Marketing Scenarios

**Generated:** 2025-12-21 21:48:33
**Total Scenarios:** 31

---

## Execution Summary

| Scenario ID | Name | Type | Status | Time (s) |
|-------------|------|------|--------|----------|
| price_low_25 | Low-Ticket Events ($25) | price_variation | success | 0.08 |
| price_high_100 | High-Ticket Events ($100) | price_variation | success | 0.08 |
| price_high_200 | High-Ticket Events ($200) | price_variation | success | 0.08 |
| price_free_addons | Free Events with Add-ons | price_variation | success | 0.10 |
| category_food | Food Events Only | category_performance | success | 0.08 |
| category_entertainment | Entertainment Events Only | category_performance | success | 0.08 |
| category_culture | Culture Events Only | category_performance | success | 0.08 |
| category_outdoor | Outdoor Events Only | category_performance | success | 0.08 |
| category_health | Health Events Only | category_performance | success | 0.08 |
| category_education | Education Events Only | category_performance | success | 0.08 |
| category_niche | Niche Events Only | category_performance | success | 0.08 |
| category_mainstream | Mainstream Events Only | category_performance | success | 0.08 |
| scale_small_100 | Small Market (100 Users) | user_scale | success | 0.01 |
| scale_large_10000 | Large Market (10,000 Users) | user_scale | success | 0.80 |
| scale_network_effects | Network Effects (Growing User Base) | user_scale | success | 0.08 |
| timing_last_minute | Last-Minute Events (24-48 Hours) | timing_urgency | success | 0.08 |
| budget_low_500 | Low Budget ($500 per Event) | budget_variation | success | 0.08 |
| budget_high_5000 | High Budget ($5,000 per Event) | budget_variation | success | 0.08 |
| quality_new_hosts | New Hosts (No Reputation) | event_quality | success | 0.10 |
| quality_established_hosts | Established Hosts (High Reputation) | event_quality | success | 0.08 |
| competitive_multiple_events | Multiple Competing Events (10 on Same Day) | competitive | success | 0.08 |
| repeat_attendance | Repeat Attendance Tracking | repeat_attendance | success | 0.07 |
| geo_urban | Urban Market | geographic | success | 0.08 |
| geo_suburban | Suburban Market | geographic | success | 0.08 |
| word_of_mouth | Word-of-Mouth & Referrals | word_of_mouth | success | 0.08 |
| event_type_tour | Tour Events Only | event_type | success | 0.08 |
| event_type_workshop | Workshop Events Only | event_type | success | 0.08 |
| event_type_meetup | Meetup Events Only | event_type | success | 0.08 |
| event_type_tasting | Tasting Events Only | event_type | success | 0.08 |
| event_type_lecture | Lecture Events Only | event_type | success | 0.10 |
| long_term_12_months | 12-Month Long-Term Simulation | long_term | success | 0.08 |

**Successful:** 31
**Errors:** 0
**Pending Refactor:** 0
**Total Execution Time:** 3.22 seconds

---

## Next Steps

1. Refactor `run_spots_vs_traditional_marketing.py` to accept `ScenarioConfig`
2. Implement scenario-specific logic for each scenario type
3. Run all scenarios and collect results
4. Generate comparative analysis across all scenarios
