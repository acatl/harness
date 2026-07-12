---
name: walk-me-through
description: Convert multi-question or multi-decision responses into a one-question-at-a-time interactive flow. Use this skill whenever you are about to send the user a response that contains ≥3 distinct questions, OR ≥2 questions where any one has ≥3 options, OR a wall of text presenting multiple decisions the user needs to make in sequence. Also triggers on user phrases like "walk me through", "one at a time", "step through these", "ask me one by one", "don't wall me", or when the user pushes back on a batched question set. Replaces the wall with a queue drained one question per turn, each rendered as a tight TLDR + why-it-matters line + indexed options table (Pros/Cons) + recommendation with reasoning and cost + an escape hatch for the user to propose alternatives or discuss. Minimizes text-at-decision-time while preserving full signal.
metadata:
  author: acatl
  version: "1.2.0" # x-release-please-version
---

# walk-me-through

Drain multi-question / multi-decision responses one at a time. Minimize text the user reads at decision
time; preserve full signal.

Working with an agent, the human's job concentrates on **deciding** — steering, approving, choosing. This
skill makes each decision crisp instead of buried in prose: one at a time, options with real tradeoffs, a
grounded recommendation, and an escape hatch. General-purpose — useful in any project, with or without the
rest of a pipeline.

## When to use

Trigger BEFORE sending a wall. Apply when about to draft any of:

- **≥3 distinct questions** in one response
- **≥2 questions** where any one has **≥3 options**
- Multiple sequential decisions the user must make (e.g., "what name? where to host? which trigger?")
- User explicitly says "walk me through", "one at a time", "step through", "ask one by one"
- User pushes back on a batched question (e.g., "too much", "ask me one by one")

Do NOT trigger for:

- Single question with 2 options (just ask it inline)
- Clarifications that fit on one line
- Pure information requests (no decision involved)

Calibration is the whole game: fire on the decisions that deserve it, stay one-line on the ones that don't.
Over-applying the full card to trivial choices is ceremony, not help.

## Format

Render **every** decision exactly per the fork card in [`references/walk-me-through.md`](references/walk-me-through.md)
— the card shape, the mandatory lines (counter · recommendation + concrete cost · escape · pick), the rules,
and the anti-patterns are the contract, not a loose guide.

## Flow

- **One fork per turn.** Wait for the pick before showing the next.
- **Lock tight:** one line `Locked: **<choice>**.` then straight to the next fork — no re-summarizing prior picks.
- **Escape** → drop the table, engage in prose, then re-enter the card for the same decision (or skip if resolved).

## Completion

When the queue is drained: one line — `All decisions locked. Proceeding with: <choice 1>, <choice 2>, …` —
then act on the decisions (or ask for the next batch of approvals if action needs further confirmation).

## Example

User: "I want to add auth — what library, where to store sessions, and how to handle refresh?"

→ Three decisions. Render Q1 (library) only. Wait. Render Q2 (session store). Wait. Render Q3 (refresh
strategy). Wait. Summarize. Proceed.
