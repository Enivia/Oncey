---
name: swift-task-workflow
description: Mandatory workflow for every task in this Xcode iOS mobile app repository. Use it before coding, planning, exploration, and question answering. Requires clarification loops in Plan mode, sosumi MCP documentation lookup before action, chrome-devtools MCP review of user-provided links, efficient validation, on-demand subagent use, and final reporting of assumptions and hardcoded values.
---

# Swift Task Workflow

Use this skill for every task in this iOS mobile app workspace before doing anything else. This includes answering questions, reading workspace files, searching the workspace, calling tools, launching subagents, exploring options, writing plans, modifying code, and validating results.

Except for reading this skill file itself, do not inspect workspace files, search the workspace, call tools, launch subagents, or run terminal commands before loading and following this skill.

## Startup Checklist

1. Read the full user request before acting.
2. Identify all ambiguity, guessed intent, implied requirements, and missing constraints.
3. Treat this repository as an iOS mobile app project for workflow, documentation lookup, and validation. If the Xcode project still exposes additional platforms, call out that mismatch explicitly instead of switching away from the iOS-first workflow.
4. If the request includes links, read them with chrome-devtools MCP before relying on their contents.
5. If the task involves Apple components, Apple frameworks, or Apple platform behavior, read the relevant documentation with sosumi MCP before making technical decisions.
6. Inspect the relevant workspace files before proposing or applying changes.
7. Respond in Chinese by default, keep wording concise, and use emoji sparingly only when they improve clarity.
8. If the task involves coding, use the globally installed `using-superpowers` and `karpathy-guidelines` skills on demand when they can improve planning, debugging, implementation, or review quality.

## Confirmation Rules

Apply these rules whenever using Plan mode, and also whenever the request still contains ambiguity that could change implementation behavior.

1. Extract every open question, assumption, guess, inferred requirement, and unresolved behavior choice.
2. Ask the user to confirm all of them before proceeding.
3. If anything remains unclear after that round, ask again.
4. Repeat clarification rounds until no unresolved questions, guesses, or assumptions remain.
5. Do not silently choose between materially different behaviors while in Plan mode.

## Documentation Rules

1. For Apple components:
    - Use sosumi MCP first.
    - Read the API or Human Interface Guidelines material relevant to the exact component or behavior.
    - Base implementation and review comments on that documentation.
2. For user-supplied links:
    - Use chrome-devtools MCP first.
    - Read the linked content before summarizing, planning, or implementing against it.
3. If documentation conflicts with the current code or the request, call out the conflict explicitly before proceeding.

## Implementation Rules

1. Keep a running list of assumptions and independent decisions made during the task.
2. Do not leave unresolved TODO, FIXME, XXX, HACK, or placeholder markers in touched code.
3. If the task changes SwiftData behavior, audit all affected create, read, update, and delete flows.
4. If a required validation step cannot be completed, state exactly what blocked it and what remains unverified.
5. Prefer the cheapest sufficient validation first; do not jump to full Xcode builds when a narrower executable check can validate the touched slice.

## SwiftData Audit Rules

When a task touches SwiftData, confirm all applicable operations are handled correctly:

1. Create: insertion uses the intended modelContext and persistence behavior is correct.
2. Read: queries, predicates, sorting, filtering, and empty states are correct.
3. Update: mutations target the intended model instances and persistence semantics remain correct.
4. Delete: deletions remove the intended records and leave UI state consistent.

## Required Validation After Changes

Every code-changing task must pass all of the following checks. If any check fails, fix the code and validate again before finishing.

1. Build validation:
    - Prefer a narrow executable validation first when it can fully cover the touched behavior.
    - Run a real build for the app target when the change affects Swift or Objective-C source, Xcode project configuration, package or dependency wiring, app integration surfaces, or when narrower validation is insufficient.
    - In this repository, use xcodebuild -scheme Oncey build as the default full-build baseline when a full build is required.
    - Skip full Xcode build for prompt, instruction, skill, documentation, or similarly non-app changes, and state that explicitly.
    - Use any available destination or signing configuration that allows the build to complete successfully.
    - If a specific destination or signing requirement blocks validation, state that explicitly.
2. Automated tests:
    - When changes affect model logic, SwiftData flows, navigation, state handling, or user interactions with existing test coverage, run the narrowest relevant test command in addition to any required build.
    - If no relevant automated test exists or the environment cannot run it, state that explicitly.
3. Documentation conformance:
    - Compare the final implementation against the documentation read through sosumi MCP or linked sources.
4. Unresolved work scan:
    - Search touched files for TODO, FIXME, XXX, HACK, or placeholder markers that remain unresolved.
5. SwiftData audit:
    - If the task touches SwiftData, confirm create, read, update, and delete behavior is fully handled.

## Required Final Response Order

Before returning the result, include the following sections in this exact order:

1. Assumptions and independent decisions
2. Hardcoded numeric values

For hardcoded numeric values, state whether any were introduced or relied on. If yes, list every relevant hardcoded numeric value and why it exists.

## Notes

1. This skill defines execution protocol, not UI or style preferences.
2. Prefer explicit uncertainty over silent assumptions.
