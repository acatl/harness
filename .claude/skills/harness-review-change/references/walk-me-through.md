# Fork format — single-pick decisions (pure text)

How to present a **single-pick fork** (one decision, pick one — reasoning matters). Pure text —
**never** a native picker (`AskUserQuestion` or similar). One fork per turn; reply by typing a letter.

Minimize text at decision time; preserve full signal. A recommendation is mandatory — never leave the
person to weigh blind.

> **Scope:** this governs **single-pick forks** only. A **multi-select opt-in menu** (check
> any / all / none) is a different interaction — for that, a checkbox / `multiSelect` picker is the right
> tool. Forks ≠ checklists.

## Admissibility — what earns a row (runs BEFORE the shape)

Options are **derived per decision, from this decision's evidence**. Never filled from a pre-written
option set — a set written in advance cannot know whether its rows are live here.

An option earns a lettered row only if **all four** hold:

| Test | Passes when |
|---|---|
| **Live** | a real path the operator could defensibly pick *on this decision, today* |
| **Non-dominated** | best on *some* axis — correctness, risk, cost, reversibility, blast radius. Worse than another row on **every** axis → drop it |
| **Value-positive** | leaves the codebase better or equal, and the card tells the truth about it |
| **Terminal** | resolves the decision *this turn* |

**Never a row — no exceptions.** Shipping a known defect · weakening/deleting a test to make a check
pass · a workaround for a cause that is diagnosable now · any option whose stated pro the card knows to
be false.

**Standing bans** (each has one narrow carve-out; absent it, the row does not exist):

| Banned row | Only when |
|---|---|
| `Defer` · `Later` · `Separate PR` · `Track it` · `Open a ticket` | either (a) a **concrete blocker** makes it genuinely unreachable this session — external decision, blocking upstream, separate spec — **or** (b) it is a **recorded terminal disposition**: the option's whole content is *writing the decision down somewhere durable and proceeding deliberately* (`log + defer` on a spec-worthiness escalation, `leave as a recorded spec gap`). That resolves the finding this turn — the record **is** the outcome — so it is terminal, unlike an open-ended "later". **Not** "out of scope", "big change", "keeps the PR focused", "adds noise to the diff" |
| `Ignore` · `Accept risk` · `Do nothing` · `Leave as-is` | it is defensible **on the merits** — the finding is wrong, or current behavior is correct. Then label it for what it is (`Decline — <why the finding is wrong>`), never as a scope trade |
| `Revert the change` | the finding indicts the change's **premise**, not a fixable part of it — undoing the work is a path the operator might really take |
| `Explain more` · `Discuss` · `Show me X first` | never — that is the escape, already on every card |

**< 2 admissible options → there is no fork.** State the call in one line, do it, advance. Padding a
lone live option with a throwaway B to fill the table is the failure this gate exists to kill: it costs
a turn, teaches the operator the table is decoration, and buys nothing.

**One admissible option on a must-stop finding → consent gate, not a table.** The skill's own rules
decide whether it stops. They say stop + only one resolution is admissible → no menu to weigh: emit the
consent-gate ask below (one line, apply-or-not). Never a one-row table, never a padded second row. This
is **the** path for that case — a skill that can stop must route it here.

**Scope of that rule: it removes a CARD, never a STOP.** This gate governs **what a card offers** — it
does not classify findings, pick verdicts, or decide whether the surrounding skill stops. Collapsing to
one option means *don't render a table*; the skill's own rules (its verdict taxonomy, its gates, its
must-stop invariants) decide what happens next, unchanged. Never read "< 2 → no fork" as license to
downgrade a verdict, auto-apply, or skip a guard.

**Never a fork at all** — the answer is always the same, so the stop has no decision in it: permission
to proceed · queue scope (`all` / `blockers only`) · "ready?" · "shall I show you X first" · confirming
a step the invocation already authorized.

**A consent gate is not a fork — don't force it into a card.** Some stops are a *permission boundary*,
not a choice between paths: one action, already known to be correct, that must not happen without
explicit say-so (a Hard Gate — load-bearing config, a destructive or irreversible step, anything with
external effect). There is no menu to gate, so admissibility does not apply. Render it as a **one-line
`👉` ask naming the exact action and its blast radius** — never a two-row table, and above all never by
inventing a second row (`leave it to me`, `skip it`, `decide later`) to make a consent gate look like a
fork. That invented row is a filler row wearing a guard's uniform: it is not terminal (nothing is
resolved), it is the banned do-nothing runner-up, and it makes a permission question read as a
weighing of options. Distinguish it from the ceremony stops above by asking **what the answer would
be**: if it is always yes, it is ceremony — don't ask. If a reasonable operator could say no *and the
work must not proceed without their yes*, it is a consent gate — ask, in one line.

**Scope of the gate: rows YOU offer, never what the operator decides.** The bans exist to stop the
card manufacturing choices, not to overrule the human. An operator who takes the escape and writes
"defer this" or "leave it" has made a call the gate has no standing to refuse — record it and move on;
**re-rendering the card to make them answer again is itself a ceremony fork.** Record it *as what it
is*, though: a non-terminal or do-nothing decision is named in the run's report/summary (finding still
open, nothing changed) so nothing closes silently. Only re-render when their reply is genuinely
undecidable — it names no resolution at all.

## Per-fork card (render exactly this shape — every labeled line is MANDATORY)

Reproduce the counter, `Cost if <letter>:` line, `Escape:` line, and `Pick:` line **verbatim** — they are
not optional and not substitutable by prose. The shape below is the contract, not a loose guide.
Verbatim means the **line's form**, not a fixed option count: `Pick:` enumerates the letters this card
actually carries (`Pick: A / B / C?` for two options + escape), never an ellipsis or a count the rows
don't match. `Cost if <letter>:` names the **recommended** letter — if the recommendation is
conditional, the cost line is conditional with it, never pinned to one branch. The table below shows
`A`/`B` as the **minimum, not a cap**: emit **one row per admissible option**, lettered consecutively;
`Pick:` lists exactly those letters plus the escape. Four admissible options → four rows.

**The `text` code fence below is presentational — it delimits the template for reading. Emit the card as
live markdown (rendered table), NEVER wrapped in a code fence. A fenced card shows raw `|` pipes to the
operator and breaks the interaction.**

```text
**<Q-counter>: <short fork title>**

**TLDR:** <one-sentence framing of the decision>
**Why it matters:** <one sentence — what it locks in / costs to reverse>

| # | Option | Pros | Cons |
|---|--------|------|------|
| A | <name> | <terse> | <terse> |
| B | <name> | <terse> | <terse> |

**Recommendation:** **<letter>** — <name>. <1–2 sentences citing the concrete signal driving it
(a documented constraint, adjacent code, a prior decision).>
**Cost if <letter>:** <concrete — files/lines/effort, not "some work">

**Escape:** `<next-letter>` discuss / propose other.

Pick: <each lettered option, slash-separated> / <escape-letter>?
```

## Rules

- **Every option states its concrete outcome — no ambiguity, no exceptions.** Hold **all** options to this
  bar equally — A, B, …, and the escape alike; the default is not exempt and gets no special treatment. For
  each, you must predict the result from the label alone: spell out exactly what it writes / creates /
  discards and **where**. Ban vague words that hide the effect — "notes", "handle it", "etc.",
  "as appropriate". If an option discards or drops something, say so plainly (e.g. "not saved anywhere —
  lost after this turn"), never imply a phantom save.
- **One fork per turn.** Wait for the answer before the next. No wall of forks.
- **Counter (mandatory):** open every card with `Q<N> of <total>` — even a lone fork is `Q1 of 1`. Never omit it.
- **Index by letter** (A, B, …); always add one extra letter as the escape hatch (`discuss / propose other`).
- **Pros/cons terse** — fragments, one short phrase per cell, no filler.
- **Recommendation always**, grounded in a named signal, with a **concrete** cost ("one migration, ~15
  lines" beats "small change"; "locks the vendor for 2 years" beats "long-term commitment").
- **Two-option forks still use the table** — consistency over saving three lines. Two *admissible*
  options; the table never justifies inventing a second one.
- **Lock tight:** one line `Locked: **<choice>**.` then the next fork. No re-summarizing prior picks.
- **Escape → drop the table**, engage in prose, then re-enter for the same fork (or skip if resolved).
- **A resolved fork does not end the turn.** Recording a pick (lettered or via the escape) is ordinary
  completion — continue in the **same message**: next fork, or the work the answers unblocked. Only a
  terminal `👉` ask or an explicit **`stopped: <fork>`** outcome hands the turn back — that sentinel is
  the protocol marker, so a nested caller has a deterministic test, not a judgement call. A caller must
  not treat a resolved escape as a stop, nor emit a second operator turn for one decision.

## Anti-patterns

- Native picker / `AskUserQuestion` of any kind.
- Wrapping the whole card in a code fence — the table must render, not show raw `|` pipes.
- Ad-hoc prose options (`(a)/(b)/(c)…`) instead of the card.
- Omitting the counter on a single fork (still `Q1 of 1`).
- Merging the cost into the table's Cons column instead of the dedicated `Cost if <letter>:` line.
- Folding the escape into a table row, or replacing the `Escape:` / `Pick: …?` lines with "reply with a letter".
- All forks dumped upfront.
- Recommendation without reasoning or with a vague cost ("some refactoring").
- Missing escape hatch.
- Re-asking a locked fork.
- **Filler row** — a second option added to fill the table when only one is admissible.
- **Pre-written option set** applied to a decision instead of options derived from it.
- **Dominated row** left in ("considered, rejected: X (worse on all axes)" is one line above the card, not a row).
- **Ceremony fork** — permission / queue-scope / "ready?" rendered as a card.
