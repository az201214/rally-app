# Rally Design System

Rally is a dark-first performance product for padel. Its interface combines
athletic clarity with calm, precise controls. The system avoids generic Material
defaults without fighting platform conventions.

## Foundations

- Color: carbon and midnight surfaces form the hierarchy. Off-white carries
  content. Electric green is reserved for primary actions, selected state,
  success, and live telemetry.
- Typography: Barlow Condensed gives high-impact headings an athletic voice;
  Inter remains the interface and long-form typeface. Body copy is never below
  14 logical pixels and supports system scaling.
- Spacing: all layout uses the 4/8-point scale in `AppSpacing`. Phone gutters are
  24, reducing only where compact layouts require it.
- Shape: 14 is the standard control radius and 20 is the standard card radius.
  Pills are reserved for short status values.
- Elevation: separation comes from surface tone and a one-pixel border first.
  Shadows are restrained and never used on every nested surface.

## Components

Buttons have a minimum 48-point target and one visually dominant action per
screen. Inputs retain visible labels, inline errors, and high-contrast focus
borders. Cards use `GlassCard` for a smoked, bordered surface; accent borders are
opt-in. Dialogs, sheets, snackbars, tooltips, chips, navigation, and progress
indicators inherit their presentation from `AppTheme`.

Loading below 300 ms should not flash. Longer loading uses bounded progress or a
layout-stable skeleton. Empty and error states explain what happened and offer a
specific next action where recovery is possible.

## Responsive and accessible behavior

All layouts must work at 320, 360, 390, and 430 logical pixels, then constrain
content measure on tablet and desktop. Controls remain keyboard reachable, icon
buttons have tooltips, meaning never relies on color alone, and scroll content
clears safe areas. Text scaling and reduced-motion behavior are release checks.

## Implementation rule

Tokens live in `lib/theme`; shared primitives live in `lib/shared/widgets`.
Feature code must not introduce raw colors, arbitrary radii, or duplicate button
and surface treatments when a shared token or component exists.
