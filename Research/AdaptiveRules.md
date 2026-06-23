# Adaptive Rules

Last updated: 2026-06-22

## Purpose

Define measurable rules for adapting layout across photo orientation, aspect ratio, metadata density, text length, and output size.

## Adaptation Inputs

- source photo orientation
- source photo aspect ratio
- output canvas size
- metadata density
- title length
- memory text length
- brand-anchor availability
- target platform or export context

## Required Rule Types

- portrait rules
- landscape rules
- square or near-square rules
- compact metadata rules
- dense metadata rules
- missing metadata rules
- long text rules
- no-brand-anchor rules

## Measurement Requirements

Every adaptive rule must define:

- trigger condition
- affected layout tokens
- min/max bounds
- fallback behavior
- acceptance threshold

## Renderer Boundary

Renderer receives the selected adaptive layout result. Renderer must not decide orientation-specific ratios, text scale fallback, or density behavior.
