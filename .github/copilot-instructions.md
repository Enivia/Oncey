# Oncey Copilot Instructions

For every task in this repository, before any exploration, planning, implementation, answer generation, workspace reads, searches, tool calls, terminal commands, or subagent invocation, read and follow this skill file in full:

- .github/skills/swift-task-workflow/SKILL.md

Treat that skill as mandatory process guidance for all tasks in this repository. The only allowed action before loading it is reading the skill file itself.

## Repository Context

- This repository contains a SwiftUI iOS app named Oncey.
- The main app target and default scheme are Oncey.
- Treat this repository as an iOS mobile app project for workflow, documentation lookup, and validation, even if the Xcode project currently exposes additional platforms. If that mismatch matters for the task, call it out explicitly.
- The project already uses SwiftData in the app target.
- Sosumi MCP and Chrome DevTools MCP are configured in .vscode/mcp.json.

## Required Behavior

1. Read and follow the skill before any workspace inspection, search, tool call, terminal command, subagent invocation, planning, implementation, or answer generation.
2. Do not skip the skill's clarification rules.
3. Do not skip the skill's documentation lookup rules.
4. Do not skip the skill's post-change validation rules.
5. Do not skip the skill's final response ordering requirements.

## Validation Baseline

1. Use xcodebuild -scheme Oncey build as the default build validation for app changes.
2. Use any available destination or signing configuration that allows the build to complete successfully.
3. If a specific destination or signing requirement blocks validation, state that explicitly.
4. If a change affects model logic, SwiftData flows, navigation, state handling, or existing tested behavior, run the narrowest relevant automated tests available or state why they were not run.
5. If SwiftData is touched, explicitly verify create, read, update, and delete behavior.
