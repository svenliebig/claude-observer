---
name: implement
description: Implement features or tasks with documentation and human validation checkpoints.
disable-model-invocation: true
---

# Implement Skill

Structured workflow for implementing features or tasks with documentation and human validation checkpoints.

## Usage

`/implement <what to implement>`

## Workflow

### Phase 1: Documentation

Review `./documentation` and determine what needs to be created or updated for this task:

- Architecture decisions relevant to the change
- Feature documentation
- Technology or dependency notes

Skip any documentation that is not necessary for this task. Keep it concise and useful.

### Phase 2: Human Validation — Documentation

Present a summary of what was documented (or skipped and why). Ask the user:

> "Does the documentation look sufficient to proceed with implementation?"

Wait for explicit approval before continuing.

### Phase 3: Investigation

With the documentation as context, investigate the codebase:

- Read relevant files
- Understand existing patterns, conventions, and architecture
- Identify exactly what needs to change (files, functions, data structures)
- Note any risks or constraints

Summarize findings and the planned approach.

### Phase 4: Implementation

Implement the task based on the investigation:

- Follow existing code patterns and conventions
- Make only the changes necessary for the task
- Do not refactor unrelated code or add unrequested features

### Phase 5: Testing

Write tests for the changes.

### Phase 6: Playwright Verification

Use Playwright MCP to verify the changes.

### Phase 7: Human Validation — Implementation

Present what was changed and how it addresses the task. Ask the user:

> "Does the implementation look correct? Anything to adjust?"

Wait for explicit approval before continuing.

### Phase 8: Worklog

Write a worklog entry in `./documentation/worklog/`. Use the filename format `YYYY-MM-DD-<short-slug>.md`.

Include:

- Date
- Task description (the `$ARGUMENT`)
- What was investigated
- What was changed and why
- Any decisions or trade-offs made
