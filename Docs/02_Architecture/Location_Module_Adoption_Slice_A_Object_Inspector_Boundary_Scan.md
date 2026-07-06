# Location Module Adoption Slice A - Object Inspector Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Feature Adoption

## Mission

Expose existing Location configuration capability through Object Inspector.

## Non-Goal

Slice A does not add Location provider capability, change Expression Platform
contracts, modify renderer behavior, change export/share/photo-library
behavior, or adopt production configuration consumption.

## Product Freeze

Primary product reference:

- `Docs/02_Architecture/Location_Module_Adoption_Slice_A_Product_Freeze.md`

## Ownership Scan

| Boundary | Owner | Decision |
| --- | --- | --- |
| Selection Ownership | `ConfigurationCenteriOSView` selected region + `ConfigurationCenterRegionDraftStore` modules | The current editable Location module is resolved from the selected region's inserted modules. |
| Configuration Ownership | `IOSInsertedModule.expressionConfiguration` | Object Inspector updates the selected Location module's `ExpressionModuleConfiguration`. |
| Refresh Ownership | `ConfigurationCenterPreviewCompositionHelper` + existing region preview update path | Configuration changes recompute the Location module value and update region preview immediately. |
| Presentation Ownership | New UI presenter backed by existing `LocationPresentationMode` / `LocationConfigurationAdapter` mapping | Inspector receives user labels and configuration values; it does not define provider behavior. |

## Approved Seam

Slice A may modify only the Configuration Center Object Inspector surface and
the existing region draft writeback path:

```text
ConfigurationCenteriOSView
    -> selected region modules
    -> current Location module
    -> Object Inspector row: 位置显示
    -> user selects display option
    -> IOSInsertedModule.expressionConfiguration
    -> ConfigurationCenterPreviewCompositionHelper.moduleDisplayText(.location)
    -> session.updateRegionPreview(...)
```

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider`, `LocationResolver`,
  `LocationFormatter`, or `LocationConfigurationAdapter` behavior
- Changes to `CardTextBlockEngine`, `CardVariableProvider`, `RecordCard`, or
  `RecordCardBuildService`
- Production consumption of persisted Location configuration
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Tests Before Implementation Freeze

Implementation must add focused tests for:

1. Product language:

```text
位置显示
自动兼容
省份 · 城市
城市 · 区县
省份 · 城市 · 区县
经纬度
位置模块未插入
```

2. Writeback and preview:

```text
Object Inspector selection -> ExpressionModuleConfiguration
Configuration writeback -> Location preview refresh
```

3. Boundary protection:

```text
No Provider / Expression / Presentation Mode implementation terms in user-facing presenter labels
No renderer / production files changed
```

## Review Checklist

- Does this slice introduce new capability? Expected answer: No.
- Does the Inspector use user language only? Expected answer: Yes.
- Does writeback update configuration only? Expected answer: Yes.
- Does preview refresh use existing provider / adapter capability? Expected
  answer: Yes.
