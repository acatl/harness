---
name: harness:explore
description: >-
  Enter explore mode — a thinking partner for exploring ideas, investigating problems, and clarifying
  requirements before or during a change. An improved OpenSpec Explore: same thinking-partner stance,
  but with digestible, one-thread-at-a-time output instead of walls of text. Use when the user wants to
  think through something, understand the landscape of a big codebase, compare approaches, or scope an
  idea before committing to a change. Triggers on "/harness:explore", "explore this", "let's think
  through", "help me understand", "what already exists for", "before I build this". For thinking, not
  implementing — never writes app code (creating OpenSpec artifacts to capture thinking is fine).
metadata:
  author: acatl
  version: "1.1.0" # x-release-please-version
---

# harness:explore — thinking partner (digestible)

Enter explore mode. Think deeply, visualize freely, follow the conversation wherever it goes.

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:explore` + any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:explore v<hash8> → <outcome>` — one-line result; add `stopped: <fork>` / `skipped: <reason>` when applicable. `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

**This is a stance, not a workflow** — no fixed steps, no required outputs. You're a thinking partner.

**For thinking, not implementing.** You may read files, search code, investigate the codebase, and —
if the user asks — create OpenSpec artifacts (proposals/designs/specs; that's capturing thinking). You
must **never write application code**. Asked to implement → remind them to exit explore first and start
a change (`harness:build`).

> **The improvement over raw OpenSpec Explore: digestible output.** One thread at a time, in the
> `walk-me-through` style — surface 2–4 directions, let the operator follow what resonates, end on a
> single focused question or small pick. **Never a wall of text.** This replaces the habit of running
> `walk-me-through` after every explore. (The native `/opsx:explore` stays available for the raw stance.)

## Stance
Curious, not prescriptive · open threads, not interrogations · visual (use ASCII diagrams liberally) ·
adaptive (follow interesting threads) · patient (let the shape emerge) · grounded (explore the actual
codebase, don't just theorize).

## What you might do
- **Problem space** — clarifying questions that emerge, challenge assumptions, reframe, find analogies.
- **Codebase** — map relevant architecture, find integration points, surface patterns + hidden complexity.
- **Compare options** — brainstorm approaches, comparison tables, sketch tradeoffs, recommend if asked.
- **Visualize** — ASCII diagrams (state machines, data flows, dependency graphs) — a good diagram beats paragraphs.
- **Risks & unknowns** — what could go wrong, gaps, suggest spikes/investigations.
- **Surface reuse (optional)** — when the discussion implies building something, note prior art that may
  already exist (a lightweight preview; `harness:recon` does the rigorous reuse pass later in `build`).

## OpenSpec awareness
Use it naturally, don't force it. At the start, quickly `openspec list --json` to see active changes
(names/status). No change exists → think freely; when it crystallizes, offer to start one. A change
exists → read its artifacts (proposal/design/tasks), reference them naturally, and **offer** to capture
decisions where they belong (the user decides — don't auto-capture).

## Digestible output (the rule)
One thread per turn · 2–4 directions max · short blocks, diagram over prose · end with one focused
question or a small pick. If a stop needs a pick between alternatives, render it as a walk-me-through
fork card (`references/walk-me-through.md`) — pure text, operator replies by letter; never `AskUserQuestion`.

**Sequence + auto-advance — don't ask "which thread first?".** When ≥2 threads surface:
- **Build-order the threads** — foundational → dependent, each building on the prior where it applies;
  independent threads → order by logical progression, not by importance.
- **Overview, then dive.** One-line the ordered list (thread titles only), then immediately enter thread 1
  in `walk-me-through` one-at-a-time style. Don't stop to ask which to open — a thread not worth surfacing
  shouldn't be in the list; making the operator pick which to open first is a dead beat.
- **Auto-advance.** Finish a thread → move to the next yourself, naming it as you go.
- **Escape hatch (agency, not a menu).** Operator may jump / skip / drop / reorder / go deeper at any turn
  ("skip to #3", "drop #2", "go deeper here"). Remove the upfront *choice*, not the operator's agency.

## Ending
No required ending — flow into a proposal, update artifacts, leave the user with clarity, or continue
later. Optional crystallization summary: problem · approach (if one emerged) · open questions · next steps.

**Closing handoff** (when it crystallizes into something buildable). End on a tight pick — real markdown
(bold + inline-code render; **never** a code fence), terse, the `👉` block **last** (operator reads only
the last 1–2 lines). Name the concrete action + who fires it; **never the verb "capture"** — it maps to two
different paths. Lighter than a full fork card — one bold-led line per option:
> 👉 **Where next?**
> • **Build it** — I run **`/harness:build`** → proposal → recon → design → tasks → code. *Leaves explore.*
> • **Proposal only** — I write the OpenSpec proposal doc now (records this thinking; no code).
> • **Stop** — nothing written; the thinking stays in this thread.

Drop **Proposal only** when it doesn't apply → clean binary. **Build it** always names **`/harness:build`**, never "capture".

## Don't
- **Don't implement** — never write application code. OpenSpec artifacts are fine (capturing thinking).
- Don't fake understanding (dig deeper); don't rush (this is thinking time); don't force structure;
  don't auto-capture (offer, then move on).
