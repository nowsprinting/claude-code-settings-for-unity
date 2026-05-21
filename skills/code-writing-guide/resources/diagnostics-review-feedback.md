# Diagnostics and Review Feedback

Diagnostics (IDE inspections, analyzers, linters) and code review feedback are based on general best practices.
They are not always appropriate for the specific code at hand — sometimes following them makes the code less readable or harder to maintain.

## Diagnostics

When a diagnostic recommendation does not fit the specific context (e.g., applying it would hurt readability or conflict with the local design):

- Suppress it with the `[SuppressMessage]` attribute, or
- Suppress it with a `// ReSharper disable once <InspectionName>` comment.

Prefer the narrowest suppression scope possible (a single line or member, not a whole file or assembly).

## Review Feedback

Review comments are also written from a general perspective. Consider each one carefully and decide whether it actually applies to your situation.

- If the suggestion fits, apply it.
- If it does not fit (because the code intentionally takes a different approach), it is fine to decline. **Report the declined item to the user with the reason** — explain what the suggestion was and why it was not applied. If the surrounding code is doing something non-obvious or unconventional, also leave a "why not" code comment (see the "Why Not" Comments section in `coding-guideline.md`). This prevents the same suggestion from being raised again in future reviews and helps future readers (human or AI) understand the intent.
