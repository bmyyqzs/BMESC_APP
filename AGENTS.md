\# AGENTS.md



\## Project Identity

This repository is a fork/adaptation of vesc\_tool and is being turned into our own branded app for our own hardware/product ecosystem.



\## Main Goal

Transform the codebase into a maintainable branded application with:

\- our own branding

\- simplified user flows

\- Android-first MVP

\- support for our own hardware defaults and onboarding

\- reduced engineering-only complexity for end users



\## Product Strategy

This is not a generic developer tool.

This app should gradually evolve from an engineering-heavy control tool into a productized app for real users.



Priorities:

1\. Rebrand the app completely

2\. Keep Android build usable first

3\. Simplify the UI for target users

4\. Preserve core communication/protocol behavior unless explicitly changed

5\. Add our own hardware presets, onboarding, and product-facing flows

6\. Prefer maintainability over quick hacks



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

3\. Android build validation

4\. menu/page simplification

5\. onboarding improvements

6\. hardware preset integration

7\. visual polish

8\. release preparation



\## Code Change Philosophy

\- Small patches over huge rewrites

\- Safe incremental improvements

\- Preserve buildability

\- Preserve debuggability

\- Preserve the option to compare against upstream



\## If Uncertain

If uncertain, do not guess silently.

State the uncertainty and propose the smallest inspectable next step.

