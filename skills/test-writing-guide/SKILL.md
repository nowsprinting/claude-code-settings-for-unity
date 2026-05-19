---
name: test-writing-guide
description: >-
  Provides guidelines for writing test code for Unity projects.
  Make sure to use this skill whenever writing, creating, editing, or modifying test code files (files under Tests/).
  This includes implementing new tests, fixing test failures, adding test cases, or any task that results in test code changes.
  Even for small edits or one-line fixes, load this skill to ensure test conventions are followed.
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for writing test code for Unity projects.

## Rules

- Before modifying any test file, check if the editor is in Play Mode. If it is, stop it using the `unity_play_control` tool first.
- Never create `.meta` files. Unity editor creates them automatically.

## Resources

Read the appropriate resource file based on the situation:

- Before writing or modifying any test code file: Read `.claude/skills/test-writing-guide/resources/unity-test-framework.md`
- Before writing or modifying any test code file: Read `.claude/skills/test-writing-guide/resources/test-helper.md`
- Before writing or modifying test code that operates UI (e.g., using `GameObjectFinder`, `Monkey`, or uGUI operators): Read `.claude/skills/test-writing-guide/resources/test-helper-ui.md`
