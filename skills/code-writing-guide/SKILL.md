---
name: code-writing-guide
description: >-
  Provides project-specific coding guidelines for this project.
  Make sure to use this skill whenever writing, creating, editing, or modifying
  code files. This includes implementing new features, fixing bugs, refactoring,
  adding tests, or any task that results in code changes. Even for small edits
  or one-line fixes, load this skill to ensure project conventions are followed.
---

Guide for writing code in this project.

## Backward Compatibility

Do NOT maintain backward compatibility unless explicitly requested. Break things boldly.

## "Why Not" Comments

Add a comment whenever a non-obvious implementation choice was made — especially when a natural
or standard approach was tried and rejected. The goal is to prevent future readers (human or AI)
from re-discovering the same dead end.

**Triggers that require a "why not" comment:**

- A standard API or language feature is avoided because it misbehaves in a specific environment
  (e.g., `withTimeout` deadlocks on the IntelliJ platform test JVM EDT → use `java.util.Timer`)
- A less-efficient or more verbose pattern is chosen over a simpler one for correctness reasons
- A seemingly redundant guard, indirection, or workaround exists due to a framework constraint
