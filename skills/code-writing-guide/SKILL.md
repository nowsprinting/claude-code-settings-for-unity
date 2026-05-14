---
name: code-writing-guide
description: >-
  Provides coding guidelines for Unity projects.
  Make sure to use this skill whenever writing, creating, editing, or modifying code files.
  This includes implementing new features, fixing bugs, refactoring, adding tests, or any task that results in code changes.
  Even for small edits or one-line fixes, load this skill to ensure project conventions are followed.
---

Guide for writing code in Unity projects.

## Rules

- Before modifying any code file, check if the editor is in Play Mode. If it is, stop it using the `unity_play_control` tool first.
- Never create `.meta` files. Unity editor creates them automatically.

## Resources

Read the appropriate resource file based on the situation:

- Before writing or modifying any code file: Read `.claude/skills/code-writing-guide/resources/coding-guideline.md`
- Before writing or modifying any code file: Read `.claude/skills/code-writing-guide/resources/unity-modern-guidelines.md`
- Before referencing an API, verifying a package behavior, or looking up documentation: Read `.claude/skills/code-writing-guide/resources/unity-references.md`