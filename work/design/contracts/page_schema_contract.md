# Page Schema Contract

Page schemas define structured screens as data-like typed objects rather than
renderer-specific widget trees.

## Required Concepts

- `PageSchema`
- `PageHeaderSchema`
- `SectionSchema`
- `ActionSchema`
- `MetricSchema`
- `FieldSchema`
- `StateSchema`

## Approved Section Variants

- `info_banner`
- `status_banner`
- `surface_group`
- `setting_group`
- `toggle_group`
- `form_group`
- `metric_group`
- `list_group`
- `detail_group`
- `cta_group`
- `empty_state`
- `loading_state`
- `error_state`
- `timeline_group`
- `split_panel`

## Rules

- Schemas define structure, not renderer details.
- Schemas should be typed Dart objects first for migration speed.
- Renderer-specific visuals must be expressed through shared primitives, not per-page widget styling.
- Highly custom map/chat/visualization flows may schema-ize chrome first and custom content later.
