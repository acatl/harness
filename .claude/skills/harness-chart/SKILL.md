---
name: harness:chart
description: >-
  Chart the *how* of a change whose *what* is already settled — survey the space of approaches, lay out
  the genuinely-live candidate routes, weigh them one at a time, and converge on a chosen route to hand
  to build. A focused thinking partner for the technical approach: it plans the *how* (options →
  tradeoffs → pick a route), it does not re-settle requirements (that's
  harness:refine) or write code (that's harness:build). Decomposes a change into decision areas when it
  genuinely has several, and charts each. Use when the user asks how to build something, wants to compare
  approaches or technologies, weigh options and tradeoffs, pick an architecture or pattern, or plan the
  route before building. Triggers on "/harness:chart", "chart this", "chart the approach", "how should we
  build", "how do we approach this", "what's the approach", "compare approaches", "weigh the options",
  "which pattern", "which tech", "plan the how", "options for building this". For thinking, not
  implementing — never writes app code (capturing the chosen route as an OpenSpec proposal is fine). For
  broad pre-task ideation with no settled destination, that's /opsx:explore or harness:refine.
metadata:
  author: acatl
  version: "1.2.2" # x-release-please-version
---

# harness:chart — chart the *how*

Destination is settled (`harness:refine`, or a clear stated goal). Chart plots the route there: survey →
lay out the live routes → weigh convergently → converge on one → hand to `build`. **A stance with a
heading** — thinking-partner tone, but it drives toward a chosen route. Not a step machine.

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:chart` + any mode/target this run has (e.g. ` · <task-id>`, ` · <change>`).
- **end:** `■ harness:chart v<hash8> → <outcome>` — one-line result; add `stopped: <fork>` / `skipped: <reason>` when applicable. `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

**Every pick is a walk-me-through fork card** (`references/walk-me-through.md`) — pure text: counter, indexed options (pros/cons), a grounded recommendation, `Cost if …`, `Escape:`, and the `Pick:` line, reproduced **verbatim**; operator replies by letter. **Never `AskUserQuestion` or any native picker.** A fork card *is* the terminal block — don't `👉`-prefix it; `👉` is only for a **bare inline ask** (e.g. the refine bounce), not a fork card. One fork per turn. (The closing handoff is the one deliberate exception — a lighter bold-led pick, below.)

## Stance
Grounded (chart the real codebase, not theory) · visual (tables for comparisons · ASCII sketches for
flows — see Digestible output) · convergent (drive to a chosen route) · light (do the least the situation needs).

## Digestible output
Short blocks · **never a wall of text** — every turn, not just picks. One decision area (or one route) per
turn; end on the turn's single pick or `👉`. Survey and compose included — a chart run reads like a
conversation, not a report.
**Match form to shape** — comparison / option×axis matrix / two-column mapping → **markdown table**;
flow / sequence / dependency / state / tree → **fenced ASCII sketch**. Both beat prose — but never
hand-align tabular data inside a code fence (that's a table).

## What chart is / isn't
- **Charts the *how*** — technologies, patterns, architecture, integration approach, light prior-art. Converges to a chosen route + the ones rejected.
- **Not the *what*** — the destination comes from `harness:refine` (or a clear operator goal). Unsettled/contested *what* → soft-bounce: ask `refine` first (operator can override by stating the goal).
- **Not implementing** — read / search / investigate freely; **never write application code**. Capturing the chosen route as an OpenSpec proposal is fine (thinking, not code).
- **Not the rigorous reuse pass** — light prior-art only; `harness:recon` does the deep reuse hunt inside `build`.
- **Not a spec audit** — `harness:design` / `harness:architecture` audit the spec *after* it exists; chart decides the route that *becomes* the spec.

## Seam (the pipeline metaphor)
`refine` fixes the destination · **chart** plots the route · `build` sails it · `ship` makes port.
So: **refine (what) → chart (how) → build → ship.**

## The spine — least the situation needs
`anchor → survey (light) → decompose (earned) → sequence → per-area triage → compose → handoff`.
It short-circuits hard: a single-area, one-obvious-route change collapses to ~one turn ("route is X →
build it"). Depth is **earned, never performed**.

1. **Anchor** — restate the fixed destination in one line, so charting has a target. Destination unclear/contested → 👉 bounce to `refine` (operator may override with a stated goal).
2. **Survey (light)** — map only enough of the real codebase to *see* the decision areas and count live routes. Not a full map.
3. **Decompose (earned)** — split into **decision areas** only when they're *separable AND non-obvious*; else **one area** (the whole change) — the default. Coupled or obvious → don't split. Over-decomposition adds exactly the load we're cutting.
4. **Sequence** — order areas by dependency: the **root area** (its pick prunes the most) first; independents in logical order. Each converged area shrinks the next area's option space.
5. **Per area → triage** (below).
6. **Compose + handoff** (below).

Escape hatch, any turn: operator may reorder / skip ("that area's obvious, I'll decide") / merge / drill
an area. Remove the upfront *choice*, not the agency.

## Per-area triage (necessity + quality)
Each area, do the least it needs:
- **One obvious route** → state it in a line. No fork. Advance.
- **Direction weak** → improve it (that's the value) → converge.
- **≥2 live, non-dominated routes** → **weigh** (below) → converge.

**Route quality bar — what reaches the operator's eyes:**
- **Live** (real, viable) **and non-dominated** — best on *some* axis, a different *bet*, not a worse one.
- **Drop dominated routes before showing** — one-line "considered, rejected: X (worse on all axes)" at most; never walk it.
- **Never manufacture contrast** — options represent real forks, not menu padding. Collapses to one → present one.
- Filter is on **output, not thinking** — evaluate enough to *know* what to drop; the operator reads only the conclusion.

## Weigh (a forked area)
Digestible + convergent — the machinery is on-purpose here (picking a route), not decoration.
- Surface only the live, non-dominated routes. **One line each** (the overview).
- **Dive one at a time** (auto-advance): tradeoff · risk · cost · reversibility. ASCII sketch over prose.
- **Auto-advance** — route wraps → open the next in the *following* turn, naming it. One-per-turn holds — don't stack routes in one message, and don't advance past an open `👉`.
- **Recommend one + why**, then render the pick as a **fork card** (`references/walk-me-through.md`) — options = the live routes; escape = discuss / merge / ask for another. Operator replies by letter → converge. **Never `AskUserQuestion`.**

## Termination — pick, don't know
Chart **picks**, it doesn't *know*. Stop at the first point a route is defensibly best; surface it; the
operator's escape hatch pulls deeper. **Depth is operator-*pulled*, never skill-*pushed*.**
- **Survey** stops when the areas + live routes are enumerable — not when the codebase is "understood".
- **Weigh** stops when more detail wouldn't move the pick — once one route is clearly best on the axes that matter, name it; don't gold-plate the comparison.
- **Dominated route** → a glance, not an analysis; drop on sight. (Proving an obvious loser is a rabbit hole.)

## Composed chart (the output)
When charting resolves, emit a tight chart — real markdown, terse:
- **chosen route per area** · how they compose (one line) · **rejected per area** (one line + why) · open risks / spikes.

The rejected-routes record is the payoff: `build` (proposal / design / architecture) stops
re-litigating what chart already killed.

## Advisory, not binding (the output contract)
Chart is **light on purpose and can be wrong** — its output is a **recommendation**, a starting prior
for `build`, **never a mandate**. Same status as a spike or an architecture review: time-boxed, informs
the next step, doesn't contract it.
- **`build` implements the right approach.** The charted route doesn't hold up in the code → build **deviates** — it does **not** ask permission and does **not** force the route — and **logs why** (decision log): "charted A; impl found X; went B". A silent drop loses the thread; a logged deviation keeps the value.
- **Freedom is the *how*, not the *what*.** The route (approach) is build's to override; `refine`'s task/AC + any spec still **bind** — deviating from *those* is a scope change (→ `refine`), not chart's license.
- **Flag soft spots.** Mark low-confidence picks + open spikes explicitly ("thin survey here — verify during build"), so build knows which recommendations are firm and which to pressure-test first.

This is *why* chart can stop early: advisory output means **roughly-right beats exhaustively-right** —
build corrects what charting got wrong. Termination + advisory are a matched pair: the brake makes chart
light, the contract makes light safe.

## Spec-mode (echo, don't own)
`harness:refine` owns the full-vs-spec-less triage (its §5b) and carries it to `build` via `--spec-less`.
Chart doesn't re-run it — but chart now *knows the real complexity*, so:
- **Echo** the incoming mode in the handoff (when a `refine` pointer set one).
- **Flag only on contradiction** — the charted route adds a behavior/contract surface a `spec-less` call missed → "route A adds a behavior contract → bump to **full**" (or the reverse). A flag, not a re-triage.

## Closing handoff (when a route is chosen)
End on a tight pick — real markdown (bold + inline-code render; **never** a code fence), terse, the `👉`
block **last** (operator reads only the last 1–2 lines). Name the concrete action + who fires it;
**never the verb "capture"** (it maps to two different paths). One bold-led line per option:
> 👉 **Where next?**
> • **Build it** — I run **`/harness:build`** (carries the chart + spec-mode) → proposal → recon → design → tasks → code. *Leaves chart.*
> • **Proposal only** — I write the OpenSpec proposal now from the chart (records it; no code).
> • **Stop** — nothing written; the chart stays in this thread.

Drop **Proposal only** when it doesn't apply → clean binary. **Build it** always names **`/harness:build`**, never "capture".

## OpenSpec awareness
`openspec list --json` at the start to see active changes. A change exists → read its artifacts, reference
them naturally, and **offer** to fold the chart where it belongs (operator decides — don't auto-capture).

## Don't
- **Don't implement** — never write application code (OpenSpec artifacts are fine — capturing thinking). Asked to implement → chart is thinking-only; remind them to exit and run `harness:build`.
- **Don't settle the *what*** — bounce to `refine`; charting a contested destination wastes the run.
