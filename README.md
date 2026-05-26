# Example settings and skills for developing Unity projects with Claude Code

> [!WARNING]  
> The Agent skills previously published in this repository will now be managed at https://github.com/nowsprinting/unity-coding-skills.

## Usage

When creating an implementation plan in plan mode, the `plan-feature` skill produces a lean, maintainable test design and a test-first workflow, enabling Claude Code to implement and verify autonomously.

## Included Skills

| Skill                      | Description                                                                           | Required                                                                                                                                                                                                     |
|----------------------------|---------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `code-writing-guide`       | Coding conventions and guidelines for Unity C# projects                               |                                                                                                                                                                                                              |
| `fix-bug`                  | Diagnoses and fixes bugs using a test-first workflow (reproduce, diagnose, fix)       |                                                                                                                                                                                                              |
| `plan-feature`             | Orchestrates the test-first planning workflow for feature implementation in plan mode |                                                                                                                                                                                                              |
| `run-tests`                | Running Unity tests via the `run_unity_tests` tool                                    | JetBrains built-in [MCP server](https://www.jetbrains.com/help/rider/mcp-server.html) and [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin |
| `edit-scene`               | Creates and modifies `.unity` and `.prefab` files                                     | JetBrains built-in [MCP server](https://www.jetbrains.com/help/rider/mcp-server.html) and [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin |
| `test-designing-guide`     | Test design methodology for deriving test cases from requirements                     |                                                                                                                                                                                                              |
| `test-writing-guide`       | Conventions for writing Unity Test Framework test code                                | [Test Helper](https://github.com/nowsprinting/test-helper) and [UI Test Helper](https://github.com/nowsprinting/test-helper.ui) package                                                                      |
| `unity-yaml-editing-guide` | Guidelines for directly hand-editing Unity YAML asset files                           |                                                                                                                                                                                                              |

## Included Agents

| Agent           | Description                                                                                                         |
|-----------------|---------------------------------------------------------------------------------------------------------------------|
| `test-designer` | Designs test cases during plan mode after class/method designs are produced, using the `test-designing-guide` skill |

## Recommended Project Settings

### 1. MCP Server Configuration

The `run-tests` and `edit-scene` skills require JetBrains MCP servers. Add the following to your project `.mcp.json` or user MCP settings:

```json
{
  "mcpServers": {
    "jetbrains": {
      "type": "http",
      "url": "http://localhost:64342/stream"
    }
  }
}
```

> [!IMPORTANT]  
> Do not change the MCP server name (e.g., `jetbrains`).

> [!NOTE]  
> The JetBrains MCP server is provided by the JetBrains built-in MCP server and [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity).

### 2. Triggering `plan-feature` reliably

If Claude does not load the `plan-feature` skill automatically during planning, add the following block to your `CLAUDE.md`:

```markdown
<important if="Feature implementation planning (writing or modifying a feature implementation plan in plan mode)">
- Read the `/plan-feature` skill to orchestrate the test-first planning workflow
</important>
```

### 3. Enforcing coding rules via `.editorconfig`

Any coding rules or Roslyn analyzer diagnostics you want Claude to respect should be set to `warning` or higher severity in `.editorconfig`.
