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
6. Reply to the user in Chinese by default, keep responses concise, and use emoji sparingly only when they add clarity.
7. When coding, use the globally installed skills `using-superpowers` and `karpathy-guidelines` on demand when they materially improve implementation quality, debugging, planning, or review.

## Validation Baseline

1. Prefer the narrowest executable validation that can verify the change before running a full Xcode build.
2. Use xcodebuild -scheme Oncey build as the default build validation only when changes affect app code, project configuration, dependencies, integration wiring, or when narrower validation is insufficient.
3. Skip full Xcode build for prompt, instruction, skill, documentation, or similarly non-app changes, and state that explicitly.
4. When a build is required, use any available destination or signing configuration that allows the build to complete successfully.
5. If a specific destination or signing requirement blocks validation, state that explicitly.
6. If a change affects model logic, SwiftData flows, navigation, state handling, or existing tested behavior, run the narrowest relevant automated tests available in addition to any required build, or state why they were not run.
7. If SwiftData is touched, explicitly verify create, read, update, and delete behavior.
