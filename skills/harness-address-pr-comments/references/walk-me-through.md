# Fork format — walk-me-through (pure text)

How every harness skill presents a **fork** (a decision it needs the operator to make). Pure text —
**never** `AskUserQuestion` or any native picker. One fork per turn; operator replies by typing a letter.

Minimize text at decision time; preserve full signal. Recommendation is mandatory — never leave the
operator to weigh blind.

## Per-fork card (render exactly this shape — every labeled line is MANDATORY)

Reproduce the counter, `Cost if <letter>:` line, `Escape:` line, and `Pick:` line **verbatim** — they are
not optional and not substitutable by prose. The shape below is the contract, not a loose guide.

```text
**<Q-counter>: <short fork title>**

**TLDR:** <one-sentence framing of the decision>
**Why it matters:** <one sentence — what it locks in / costs to reverse>

| # | Option | Pros | Cons |
|---|--------|------|------|
| A | <name> | <terse> | <terse> |
| B | <name> | <terse> | <terse> |

**Recommendation:** **<letter>** — <name>. <1–2 sentences citing the concrete signal driving it
(documented constraint, adjacent code, charter line, prior decision).>
**Cost if <letter>:** <concrete — files/lines/effort, not "some work">

**Escape:** `<next-letter>` discuss / propose other.

Pick: A / B / <escape-letter>?
```

## Rules
- **Every option states its concrete outcome — no ambiguity, no exceptions.** Hold **all** options to this
  bar equally — A, B, …, and the escape alike; the default is not exempt and gets no special treatment. For
  each, the operator must predict the result from the label alone: spell out exactly what it writes /
  creates / discards and **where**. Ban vague words that hide the effect — "notes", "handle it", "etc.",
  "as appropriate". If an option discards or drops something, say so plainly (e.g. "not saved anywhere —
  lost after this turn"), never imply a phantom save.
- **One fork per turn.** Wait for the answer before the next. No wall of forks.
- **Counter (mandatory):** open every card with `Q<N> of <total>` — even a lone fork is `Q1 of 1`. Never omit it.
- **Index by letter** (A, B, …); always add one extra letter as the escape hatch (`discuss / propose other`).
- **Pros/cons terse** — fragments, one short phrase per cell, no filler.
- **Recommendation always**, grounded in a named signal, with a **concrete** cost.
- **Two-option forks still use the table** — consistency over saving three lines.
- **Lock tight:** one line `Locked: **<choice>**.` then the next fork. No re-summarizing prior picks.
- **Escape → drop the table**, engage in prose, then re-enter for the same fork (or skip if resolved).

## Anti-patterns
- Native picker / `AskUserQuestion` of any kind.
- Ad-hoc prose options (`(a)/(b)/(c)…`) instead of the card.
- Omitting the counter on a single fork (still `Q1 of 1`).
- Merging the cost into the table's Cons column instead of the dedicated `Cost if <letter>:` line.
- Folding the escape into a table row, or replacing the `Escape:` / `Pick: …?` lines with "reply with a letter".
- All forks dumped upfront.
- Recommendation without reasoning or with a vague cost ("some refactoring").
- Missing escape hatch.
- Re-asking a locked fork.
