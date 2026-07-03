# V1 UX Feedback Iteration 001

Last updated: 2026-07-03

## Purpose

This document records the first V1 real-usage UX feedback batch as a dedicated
product-polish line.

It is intentionally separate from:

- architecture RFC work
- baseline work
- renderer or expression-language redesign

RFCs change architectural facts.

V1 UX Feedback iterations capture product-usage friction, prioritization, and
interface simplification opportunities.

## Current Product Insight

The strongest signal from this iteration is:

```text
The Configuration Center should become lighter, not fuller.
```

The current issue is not missing capability. The current issue is that too much
information competes for attention in the configuration flow.

## Status

- Line: `V1 UX Feedback`
- Iteration: `001`
- State: `Open`
- Scheduling: `Not yet committed to implementation`

## Workflow Role

This document belongs to the Product Line.

- Engineering Line should be evidence-driven:
  - tests
  - architecture facts
  - baseline references
  - verification
- Product Line should be scenario-driven:
  - usage friction
  - interaction confusion
  - language mismatch
  - repeated operational cost

Issue intake rule:

- every item should declare one primary source
- valid values are:
  - `Product Loop`
  - `Engineering Loop`
- UX feedback iterations default to `Product Loop`
- if an item needs two sources to justify itself, it should be reframed before
  implementation starts

## Configuration Center Product Principle

```text
The Configuration Center should become lighter, not fuller.
```

Use this as a product filter:

- if a change makes the Configuration Center lighter, clearer, or easier to
  scan, it is directionally aligned
- if a change makes the Configuration Center heavier, noisier, or more
  cognitively dense, it should be re-evaluated

## Iteration Lifecycle

UX feedback iterations should not grow forever.

Preferred lifecycle:

```text
Open
    ->
Selected
    ->
Implemented / Rejected / Deferred
    ->
Closed
```

Iteration 001 should eventually close before Iteration 002 becomes the active
feedback batch.

## Entry Template

Preferred shape for Product Loop items:

```text
Source
Observation
Scenario
Frequency
Proposal
Resolution
```

Product Loop items should not start as implementation demands. They should
start as observed usage problems and only then move toward a proposal.

## P0 Must Fix

### 1. Time anchor title does not refresh after Memory Subject switch

Source:

- Product Loop

Observation:

- after switching Memory Subject, the time-anchor title area can still show the
  previous subject context such as `途途生日`

Scenario:

- after switching the current Memory Subject, all of the following should
  refresh together, otherwise the interface still appears to belong to the
  previous subject:
  - current active anchor
  - anchor title
  - expression formula
  - preview

Frequency:

- Every Switch

Proposal:

- refresh current active anchor, anchor title, expression formula, and preview
  as one synchronized subject-switch result

Resolution:

- Implemented

## P1 Configuration Simplification

### 2. Reorganize the overview section

Source:

- Product Loop

Observation:

- the overview area currently carries more information than is needed to
  understand the current effective configuration state

Scenario:

- during normal configuration use, the overview should help the user confirm
  the current state at a glance rather than enumerate secondary information

Frequency:

- Every configuration pass

Proposal:

- keep Memory Subject identity as the first line
- keep current active time anchor as the highlighted state
- remove time-anchor count

Resolution:

- Implemented

### 3. Remove `关系类型`

Source:

- Product Loop

Observation:

- `关系类型` has no current business value

Scenario:

- users notice it during configuration, but it does not currently contribute to
  a real decision or output

Frequency:

- Every configuration pass

Proposal:

- remove `关系类型` from the current configuration surface

Resolution:

- Implemented

### 4. Remove `对象定义`

Source:

- Product Loop

Observation:

- `对象定义` is not currently referenced

Scenario:

- this field occupies interface weight without clearly affecting present
  configuration decisions

Frequency:

- Every configuration pass

Proposal:

- remove `对象定义` for now
- redesign it later only if a real product use case emerges

Resolution:

- Implemented

## P1 Time Anchor Configuration

### 5. Rename copy

Source:

- Product Loop

Observation:

- the current label is `当前锚点名称`

Scenario:

- the current label sounds like a passive state label, while the field is
  actually user-defined naming

Frequency:

- Every anchor edit

Proposal:

- rename it to `自定义锚点名称`

Resolution:

- Implemented

### 6. Remove duplicated formula display

Source:

- Product Loop

Observation:

- the gray `当前表达公式` display duplicates the editable expression formula
  shown below it

Scenario:

- while editing anchors, the user sees the same concept twice but can only act
  on one of them, which adds noise instead of clarity

Frequency:

- Every anchor edit

Proposal:

- remove the gray duplicate formula display

Resolution:

- Not present in current V1 iOS path

### 7. Re-layout the expression formula selector

Source:

- Product Loop

Observation:

- the current formula selection layout is vertically fragmented for a
  single-step choice

Scenario:

- the formula selector should read as one compact action instead of a stacked
  block

Frequency:

- Every anchor edit

Proposal:

- current:

```text
当前已选
────────────

表达公式
▼
```

- suggested:

```text
请选择表达公式                 ▼
```

- move the label to the left
- move the selector to the right
- keep the entire action on one row

Resolution:

- Not present in current V1 iOS path

### 8. Remove inactive helper information

Source:

- Product Loop

Observation:

- `锚点说明` and `映射说明` currently appear without a clear decision-support
  role

Scenario:

- if these helper texts do not support a real decision, they increase reading
  cost without reducing uncertainty

Frequency:

- Every anchor edit

Proposal:

- remove them if they still do not serve a real product purpose

Resolution:

- Implemented

## P2 Expression Formula

Not part of this iteration.

Source:

- Product Loop

Observation:

- the current expression formula feels too mechanical

Scenario:

- users can complete configuration, but the expression system does not yet feel
  natural enough to count as this iteration's polish target

Frequency:

- Frequent

Proposal:

- defer expression-language redesign to a later dedicated pass

Resolution:

- Deferred

## Working Boundary

This feedback line should remain separate from RFC work.

- if a change only simplifies presentation, naming, or state communication, it
  belongs here
- if a change requires a new architectural fact, it must enter a separate RFC

## Next Use

This document is a capture artifact, not an automatic implementation queue.

Future V1 polish slices may select items from this iteration after observing
real usage further.
