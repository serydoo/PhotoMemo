# Panel Specification

Last updated: 2026-06-22

## Purpose

Define the information panel as a measurable layout structure.

## Panel Responsibilities

The information panel can contain:

- title or primary memory line
- capture time
- camera/device metadata
- memory/anchor result
- brand anchor or badge
- secondary context

The panel must not be treated as a renderer-specific decoration.

## Required Measurements

For each researched sample, record:

- panel bounds
- outer padding
- inner grid columns
- row count
- vertical alignment mode
- divider bounds if present
- brand anchor bounds
- primary text bounds
- secondary text bounds
- metadata group bounds
- empty-space distribution

## Panel Layout Questions

- Is the panel organized by columns, rows, clusters, or optical groups?
- Does the primary text align to a geometric grid or optical center?
- Does the brand anchor define the grid, or does the grid define the brand anchor?
- How does the panel react when metadata is missing?
- How does the panel react when metadata is long?

## Renderer Boundary

Renderer receives panel bounds, slot bounds, text styles, and drawing primitives. Renderer must not choose panel padding, spacing, column widths, or text cluster alignment.
