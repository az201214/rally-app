# Rally Engineering Instructions

Rally is a premium Flutter padel matchmaking application.

## Technology

- Flutter 3.44.4
- Dart 3.12.2
- Material 3
- Riverpod
- GoRouter
- Firebase-ready architecture
- Feature-first folder structure

## Product direction

Rally helps padel players find compatible matches quickly.

The application should feel:

- Premium
- Fast
- Precise
- Modern
- Sports-focused
- Dark-first
- Inspired by Formula 1 telemetry
- Built around an electric-green accent

Avoid generic Flutter-template styling and unnecessary visual effects.

## Engineering rules

- Work only inside this repository.
- Inspect existing code before editing.
- Preserve the current architecture unless a change is justified.
- Do not modify unrelated files.
- Reuse existing theme tokens.
- Do not hardcode colors, spacing, radii, shadows, or typography.
- Keep widgets small, reusable, and clearly named.
- Use null-safe Dart.
- Do not add packages unless necessary.
- Never expose API keys, secrets, or credentials.
- Do not implement fake backend code as production logic.
- Do not implement features beyond the current task.
- Explain important architectural decisions.
- Summarize every changed file.

## Required verification

After implementation tasks, run:

```bash
dart format .
flutter analyze
flutter test