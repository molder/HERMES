---
name: knowledge-base-handover
description: Preserve project knowledge, verified findings, decisions and session continuity. Use proactively during long sessions and whenever context approaches its limit.
---

# Knowledge Base Handover

## Priority

This skill has high priority whenever a session involves research, technical development, project documentation or knowledge-base work.

Before substantial work, identify the relevant project checkpoint and handover destination.

Read the full procedure at:

`C:\Users\cc2\Documents\GitHub\HERMES\docs\skill_handover.md`

Follow it throughout the session.

## Context thresholds

- 40,000 tokens: save a checkpoint.
- 50,000 tokens: prepare the handover.
- 60,000 tokens: stop new work and complete the handover.
- 65,000 tokens: emergency handover.

These are operational targets. Do not assume the skill can independently monitor or trigger on an exact token count.

## Session start

At the beginning of a resumed project session:

1. Read the latest handover.
2. Read `CURRENT_PROGRESS.md`.
3. Check the project index.
4. Identify completed and outstanding tasks.
5. Resume from the first unfinished task.

## Session end

Before ending a substantial session:

1. Save verified findings and decisions.
2. Record exact paths and commands.
3. Record unresolved questions and next steps.
4. Update the progress file and index when appropriate.
5. Verify that the files were actually saved.

## Destination

`C:\Users\cc2\Documents\Hermes_Workspace\Knowledge_Base`

Never write handover reports into source repositories.

## Safety

Follow the user's established filesystem permissions. Never perform Git commits, pushes, destructive operations or unauthorised source modifications during handover.