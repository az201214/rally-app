# Rally Design System

Rally is dark-first, sports-focused, and built around an electric-green accent.
The interface should feel fast, precise, and premium without unnecessary visual
effects.

## Tokens

Design tokens live in `lib/theme`:

- `AppColors` defines palette and semantic colors.
- `AppSpacing` defines layout spacing and common padding.
- `AppRadius` defines surface and control radii.
- `AppShadows` defines elevation and accent treatments.
- `AppTypography` defines the type scale.
- `AppTheme` maps these tokens into Material 3 component themes.

Feature widgets must reuse these tokens instead of introducing hardcoded visual
values.

## Shared components

Reusable controls and surfaces live in `lib/shared/widgets`. They inherit the
active Material theme and provide consistent states, spacing, and presentation
across features.

## Assets

Brand icons, images, illustrations, and animations live under their matching
directories in `assets`. The `assets/fonts` directory is reserved for future
bundled typefaces and is not registered yet.
