# BHAM Replay Holdout Evaluation

- Environment: `bham-replay-world-2023`
- Replay year: `2023`
- Passed: `true`
- Training months: `2023-01, 2023-02, 2023-04, 2023-05, 2023-07, 2023-08, 2023-10, 2023-11`
- Validation months: `2023-03, 2023-09`
- Holdout months: `2023-06, 2023-12`

## Metrics

- `event_density` `true` train=`738.5` validation=`963.0` holdout=`658.5` threshold=`0.35`
- `attendance_plausibility` `true` train=`1.0` validation=`1.0` holdout=`1.0` threshold=`0.2`
- `locality_pressure` `true` train=`50.85052910052911` validation=`54.785714285714285` holdout=`50.478835978835974` threshold=`0.25`
- `venue_community_participation` `true` train=`0.09278` validation=`0.11214` holdout=`0.08352` threshold=`0.03`
- `exchange_participation` `true` train=`0.5122` validation=`0.5122` holdout=`0.5122` threshold=`0.0`
- `offline_queue_behavior` `true` train=`0.16029424343512103` validation=`0.16029424343512103` holdout=`0.16029424343512103` threshold=`0.0`

## Notes

- Held-out 2023 windows stay within replay variation thresholds.
