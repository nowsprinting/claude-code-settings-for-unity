# Example settings and skills for developing Unity projects with Claude Code

## Usage

When creating an implementation plan in plan mode, the `implementation-planning-guide` skill produces a lean, maintainable test design and a test-first workflow, enabling Claude Code to implement and verify autonomously.

## Included Skills

| Skill                           | Description                                                              |
|---------------------------------|--------------------------------------------------------------------------|
| `code-writing-guide`            | Coding conventions and guidelines for Unity C# projects                  |
| `implementation-planning-guide` | Orchestrates the test-first planning workflow in plan mode               |
| `run-tests`                     | Guidelines for running Unity tests via the `run_unity_tests` tool        |
| `scene-editing-guide`           | Guidelines for creating and modifying `.unity` scene and `.prefab` files |
| `test-designing-guide`          | Test design methodology for deriving test cases from requirements        |
| `test-writing-guide`            | Conventions for writing Unity Test Framework test code                   |
| `unity-yaml-editing-guide`      | Guidelines for directly hand-editing Unity YAML asset files              |

## Included Agents

| Agent           | Description                                                                 |
|-----------------|-----------------------------------------------------------------------------|
| `test-designer` | Designs test cases during plan mode after class/method designs are produced |

## Required MCP Servers

- **JetBrains built-in MCP server** — exposes IDE features (build, run, search, refactoring) to AI Coding Agents.
  Setup: https://www.jetbrains.com/help/rider/mcp-server.html

- **MCP Server Extension for Unity** — exposes Unity Editor features (`run_unity_tests`, `run_method_in_unity`, `unity_play_control`, etc.) to AI Coding Agents via a JetBrains plugin.
  Plugin page: https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity

## Recommended Project Settings

### 1. Triggering `implementation-planning-guide` reliably

If Claude does not load the `implementation-planning-guide` skill automatically during planning, add the following block to your `CLAUDE.md`:

```markdown
<important if="Implementation planning (writing or modifying code planning in plan mode)">
- Read the `/implementation-planning-guide` skill to orchestrate the test-first planning workflow (class/method design via Plan agent → test case design via test-design agent → plan file assembly).
</important>
```

### 2. Enforcing coding rules via `.editorconfig`

Any coding rules or Roslyn analyzer diagnostics you want Claude to respect should be set to `warning` or higher severity in `.editorconfig`.

### 3. UPM Packages

The `test-writing-guide` skill assume the following packages are installed:

- **Test Helper** — utilities for Unity Test Framework (file access, scene loading, focus control, etc.).
  https://github.com/nowsprinting/test-helper

- **UI Test Helper** — utilities for uGUI integration testing (element finding, async interaction, etc.).
  https://github.com/nowsprinting/test-helper.ui
