---
description: Debug a UI issue using MCP screenshot and accessibility tools
---

Debug the current UI state using the iOS Simulator MCP:

1. Ensure the app is running in the simulator
2. Take a screenshot using `mcp__ios-simulator__screenshot`
3. Describe all UI elements using `mcp__XcodeBuildMCP__describe_ui`
4. Identify any layout issues, missing elements, or accessibility problems
5. If issues found, suggest specific code fixes with file paths

For interaction testing:
- Use `mcp__XcodeBuildMCP__tap` for button taps (get coordinates from describe_ui)
- Use `mcp__XcodeBuildMCP__type_text` for text input
- Use `mcp__XcodeBuildMCP__swipe` for scroll/swipe gestures

Always check the log server for errors: `curl -s http://localhost:8765/logs`
