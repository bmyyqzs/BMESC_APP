\# AGENTS.md



\## Project Identity

This repository is a fork/adaptation of vesc\_tool and is being turned into our own branded app for our own hardware/product ecosystem.



\## Main Goal

Transform the codebase into a maintainable branded application with:

\- BM branding

\- simplified user flows

\- iOS-first commercial MVP

\- support for our own hardware defaults and onboarding

\- reduced engineering-only complexity for end users



\## Product Strategy

This is not a generic developer tool.

This app should gradually evolve from an engineering-heavy control tool into a productized app for real users.



Priorities:

1\. Rebrand the app completely

2\. Keep the iOS build usable first

3\. Simplify the UI for target users

4\. Preserve core communication/protocol behavior unless explicitly changed

5\. Isolate product-facing UI from engineering protocol APIs

6\. Add our own hardware presets, onboarding, and product-facing flows

7\. Prefer maintainability over quick hacks



\## Commercial MVP Scope

The first commercial MVP includes only:

\- BLE device discovery and connection

\- live telemetry

\- device information and management

\- user-facing fault and safety messages

\- settings

\- privacy, legal, support, and open-source compliance entry points

The following belong to phase two and must not block the first commercial MVP:

\- firmware updates

\- user accounts and authentication

\- cloud device binding

\- leaderboards

\- social or community features



\## Product Layer Isolation

\- Product-facing QML must use narrow product models or facades rather than calling `Commands` or mutable `ConfigParams` APIs directly.

\- Keep `BleUart`, `Packet`, `Commands`, and protocol-facing parts of `VescInterface` stable unless a task explicitly targets them.

\- Product models own user-facing connection state, device identity, telemetry conversion, stale-data handling, fault presentation, and allowed product actions.

\- Engineering pages may continue using low-level APIs, but they must not be reachable from the commercial MVP navigation.

\- Do not expose motor current, duty, RPM, raw configuration writes, terminal commands, bootloader operations, or unrestricted firmware upload through commercial product models.



\## Important Constraints

\- Do not use the VESC trademark in app name, package name, visible UI strings, icons, splash screens, or release artifacts unless explicitly required for compatibility references.

\- Avoid large risky refactors unless asked.

\- Prefer small, reviewable patches.

\- Before making changes, explain what files are involved and why.

\- Keep protocol-related logic stable unless the task explicitly targets protocol behavior.

\- Treat backend logic and UI changes separately.

\- Minimize changes outside the task scope.



\## Technical Working Style

When working on tasks:

1\. First analyze structure

2\. Identify entry points and affected layers

3\. Propose the smallest safe patch

4\. Then implement

5\. Summarize changed files and side effects



For any medium or large task, always provide:

\- goal

\- files likely involved

\- risks

\- suggested minimal patch plan



\## Architecture Expectations

Please distinguish these layers when analyzing:

\- platform/build layer

\- C++ backend / communication / business logic

\- QML/UI layer

\- assets/branding layer

\- device preset / configuration layer



\## Branding Rules

When doing rebranding work, search for and handle:

\- app name

\- display title

\- package/bundle identifiers

\- icons

\- splash / startup branding

\- about page

\- website links

\- support email

\- visible strings

\- product names

\- config/export/import labels if user-facing

The official user-facing brand is `BM`.



\## UX Direction

Target direction:

\- fewer engineering-facing options visible by default

\- simpler onboarding

\- clearer connection flow

\- fewer intimidating settings for normal users

\- product-oriented structure rather than tool-oriented structure



\## Output Format

When responding, use this structure:



\### Analysis

\- what this task is really changing

\- what layers are touched



\### Files

\- list of files likely involved



\### Risks

\- what might break



\### Plan

\- smallest safe implementation plan



\### Patch Summary

\- what was actually changed



\## Task Boundaries

Do not:

\- perform broad renaming across the whole repo without first listing impact

\- rewrite architecture unless explicitly asked

\- change protocol semantics casually

\- remove advanced features without identifying where they are wired



\## Preferred Development Sequence

When asked to transform the app, prefer this order:

1\. mapping and structure analysis

2\. branding replacement

3\. iOS build validation

4\. product layer isolation

5\. menu/page simplification

6\. onboarding improvements

7\. hardware preset integration

8\. visual polish

9\. release preparation



\## Code Change Philosophy

\- Small patches over huge rewrites

\- Safe incremental improvements

\- Preserve buildability

\- Preserve debuggability

\- Preserve the option to compare against upstream



\## If Uncertain

If uncertain, do not guess silently.

State the uncertainty and propose the smallest inspectable next step.



\## Project Memory Workflow

This repository uses persistent project memory so important context survives across conversations.

At the start of every user turn:

1\. Read `PROJECT_MEMORY.md` before analyzing or changing the project.

2\. If `PROJECT_MEMORY_PRIVATE.md` exists, read it as local confidential context.

3\. Treat newer entries as authoritative when they explicitly replace older decisions.

Before the final response of every user turn:

1\. Append one concise entry to `PROJECT_MEMORY.md` using its required template.

2\. Record the user request, relevant context, confirmed decisions or preferences, actions and results, unresolved items, and whether sensitive information was involved.

3\. Do not repeat unchanged facts already recorded. Reference the earlier entry or write only the new information.

4\. Never rewrite or delete historical entries. If a decision changes, append a new entry that identifies the superseded decision and its replacement.

5\. Use the current date and timezone from the environment. Use a clear topic name for each entry.

\### Public and Private Memory

\- `PROJECT_MEMORY.md` is tracked by Git and may be read by the team. Never place passwords, tokens, private keys, certificates, recovery codes, personal identifiers, or other secret values in it.

\- `PROJECT_MEMORY_PRIVATE.md` is local-only and ignored by Git. Store a sensitive value there only when it has a clear future project use.

\- In public memory, record only the sensitive item's purpose, where it is expected to be used, and a reference label matching the private entry. Never copy the value itself.

\- Do not echo private values in summaries, patches, logs, or final responses unless the user explicitly requires the value for the immediate task.

\- If no sensitive value was provided, leave the private file unchanged.

\### Memory Boundaries

\- Keep stable product background in `PROJECT_CONTEXT.md`; keep chronological conversation and task outcomes in `PROJECT_MEMORY.md`.

\- Memory is project-scoped to this `BMESC APP` repository.

\- A memory entry is a summary, not a full transcript. Preserve decisions and outcomes while omitting conversational filler.

\- If a user explicitly asks not to remember a specific item, do not write that item to either memory file.
