# Fork format — walk-me-through (pure text)

How every harness skill presents a **fork** (a decision it needs the operator to make). Pure text —
**never** `AskUserQuestion` or any native picker. One fork per turn; operator replies by typing a letter.

Minimize text at decision time; preserve full signal. Recommendation is mandatory — never leave the
operator to weigh blind.

## Per-fork card (render exactly this shape)

```
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
- **One fork per turn.** Wait for the answer before the next. No wall of forks.
- **Counter:** open with `Q<N> of <total>` if total known, else `Q<N>`.
- **Index by letter** (A, B, …); always add one extra letter as the escape hatch (`discuss / propose other`).
- **Pros/cons terse** — fragments, one short phrase per cell, no filler.
- **Recommendation always**, grounded in a named signal, with a **concrete** cost.
- **Two-option forks still use the table** — consistency over saving three lines.
- **Lock tight:** one line `Locked: **<choice>**.` then the next fork. No re-summarizing prior picks.
- **Escape → drop the table**, engage in prose, then re-enter for the same fork (or skip if resolved).

## Anti-patterns
- Native picker / `AskUserQuestion` of any kind.
- All forks dumped upfront.
- Recommendation without reasoning or with a vague cost ("some refactoring").
- Missing escape hatch.
- Re-asking a locked fork.
