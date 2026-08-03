# Rally Architecture

Rally uses a feature-first Flutter architecture. Product functionality belongs
inside `lib/features`, while application-wide infrastructure remains outside
individual features.

## Project structure

- `lib/app` contains the root application widget.
- `lib/routes` contains route paths and GoRouter configuration.
- `lib/features` contains product features and their presentation layers.
- `lib/shared` contains reusable widgets shared across features.
- `lib/theme` contains the design-system tokens and Material theme.
- `lib/core` is reserved for genuinely application-wide constants, services,
  extensions, and utilities.

## Application shell

`main.dart` initializes Flutter, creates the Riverpod `ProviderScope`, and
launches `RallyApp`. `RallyApp` owns `MaterialApp.router`, the application theme,
and the router configuration.

## Feature boundaries

Features should own their screens, widgets, state, and data abstractions.
Cross-feature code should move into `shared` or `core` only when it has a clear,
demonstrated reuse case.

UI code should depend on abstractions rather than concrete backend services.
Business and data layers should be added only when a feature requires them.
