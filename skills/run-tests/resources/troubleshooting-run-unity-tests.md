# Troubleshooting the `run_unity_tests` Tool

## Tool Not Found

If the `run_unity_tests` tool is not available, consider the following causes:

1. **MCP Server Extension for Unity** plugin is not installed: Install it from **Settings > Plugins**.
2. Built-in MCP Server is not enabled: Open **Settings > Tools > MCP Server** and turn on **Enable MCP Server**.
3. The tool is disabled: Open **Settings > Tools > MCP Server > Exposed Tools** and turn on **UnityEditorToolset** and **run_unity_tests**.

## Connection Errors

When a tool fails with a connection error, it may be due to the following reasons:

- Play Mode tests cannot be run if there are any compilation errors. Check for any compilation errors using the `get_unity_compilation_result` tool.
- The connection may have been disconnected due to domain reloading caused by compilation, etc. Wait a moment and try again.
- If the Unity Editor is not running, use the `execute_run_configuration` tool to launch it by running the `Start Unity` configuration, then retry.