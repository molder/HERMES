---
name: knowledge-base-handover
description: Preserve verified project knowledge, decisions and session continuity. Use proactively during substantial work and whenever context approaches its limit.
---

# Knowledge Base Handover

## Mission

Prevent loss of project knowledge when Hermes sessions approach their context limit or end unexpectedly.

Saving verified project knowledge takes priority over finishing an investigation.

## Context thresholds

- 35,000 tokens: save an intermediate checkpoint.
- 45,000 tokens: prepare the handover and stop expanding the investigation.
- 50,000 tokens: mandatory handover. Stop new research and development.
- 55,000 tokens: emergency handover. Save immediately.

These are operational targets, not guaranteed automatic triggers. Check available context indicators regularly. If exact token usage is unavailable, use available context warnings and err on the side of an earlier checkpoint.

Never wait for a tool call to fail before saving.

## Mandatory handover procedure

1. Stop starting new investigations and tool operations.
2. Review the current conversation and available tool results.
3. Record completed and verified work.
4. Record findings, evidence and decisions.
5. Record files created or modified, with exact paths.
6. Record failed attempts and known problems.
7. Identify unresolved tasks and blockers.
8. Define the exact next action for the next session.
9. Save and verify the handover.

Classify findings:

- CONFIRMED: directly verified.
- UNVERIFIED: not yet tested.
- PROPOSED: recommended but not implemented.
- OUTDATED: superseded information.
- BLOCKED: requires further input or access.

Never describe an intended operation as completed.

## Knowledge Base destination

C:\Users\cc2\Documents\Hermes_Workspace\Knowledge_Base

For SimpleMixer, preserve the existing structure:

- SimpleMixer\CURRENT_PROGRESS.md
- SimpleMixer\INDEX.md
- SimpleMixer\reports\
- SimpleMixer\topics\

Save dated handover reports in the appropriate reports directory.

For other projects, use their existing Knowledge Base structure.

Do not create reports or temporary files in source repositories.

## Session start

When resuming a project:

1. Read the latest relevant handover.
2. Read CURRENT_PROGRESS.md.
3. Read INDEX.md.
4. Identify completed and outstanding tasks.
5. Resume from the first unfinished task.
6. Do not repeat completed investigations unnecessarily.

## Session end

Before ending a substantial session:

1. Save verified findings and decisions.
2. Update CURRENT_PROGRESS.md where appropriate.
3. Update INDEX.md when new reports or topics have been added.
4. Verify that files were actually written.
5. Report exact paths and the next action.

## Safety and permissions

Respect the user's filesystem permissions:

- SimpleMixer_Framework: read-only unless a specific write is authorised.
- td_system: never write without explicit authorisation.
- HERMES: read/write for Hermes-related files.
- Hermes_Workspace: read/write for working documents and knowledge-base material.
- Notion: read/search only unless explicitly authorised.

Never perform Git commits, pushes, destructive operations or unauthorised source modifications during handover.

## Final confirmation

Report:

1. Exact path of the saved handover.
2. Files created or updated.
3. Current verified project state.
4. Outstanding work.
5. Exact next recommended action.
6. Anything that could not be saved or verified.

If context is critically low, save the handover immediately rather than continuing the task.
