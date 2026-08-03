# Firebase Integration

Firebase is not configured in the current project.

## Intended boundary

If Firebase is adopted, platform configuration and concrete implementations
should remain behind feature-owned repository or service abstractions. UI and
domain code should not depend directly on Firebase SDK types.

## Configuration rules

- Keep API keys and credentials out of source control when they are secret.
- Use environment-appropriate Firebase projects and platform configuration.
- Never commit service-account credentials.
- Do not initialize Firebase until a feature requires it.
- Do not use fake backend behavior as production logic.

## Future work

Firebase package selection, initialization, authentication, database structure,
security rules, analytics, and messaging remain intentionally undecided. They
require separate implementation milestones and verification.
