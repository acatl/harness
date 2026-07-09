# Pipeline trail — "you are here"

A one-line, human-facing orientation trail emitted at the **end of a pipeline skill**, on the line
**immediately before its `Next:` pointer**. It shows the operator what's done, where they are, and the
single next move. Distinct from the machine `■ harness:<skill> → …` breadcrumb (that's for transcript
grep; this is for the human).

## Canonical stages
`refine → spec → review → implement → verify → ship → (address comments) → finish`

- **spec** — proposal + recon + design + tasks authored.
- **review** — architecture + design reviews (pre-apply gate).
- **implement** — code + grouped local commits.
- **verify** — sensors + behavioral-verify + openspec-verify + code-review → verified-not-shipped.
- **(address comments)** — conditional; only when the PR has review comments.
- **finish** — sync specs + archive + close + (two-merge) chore PR.

## Render rule
- **Done (left of "here"):** show **every** completed stage, each marked `✓`. "Completed" = its artifact
  actually exists (proposal.md / reviews/*.md / commits / PR url / …), not merely "a stage upstream of
  me". Honest, not assumed — a skipped or failed stage is not `✓`.
- **Here:** the operator's current position, marked `▸ <operator action> (you are here)`. Phrase it as
  what the *operator* does now, not a skill name.
- **Next:** exactly **ONE** upcoming stage, marked `◦ <stage>`. **Never show the full downstream** — one
  next step keeps focus.
- Join with ` → `. One line. Conditional stages in (parens). The `◦ next` is the trail-level echo of the
  concrete command in the `Next:` line that follows.

## One runnable command (no premature commands)
**Show a runnable `/harness:<cmd>` ONLY for the immediately-executable next step.** Critical foot-gun rule:
an operator reflexively runs a command they see — even one tagged "later" / "after merge". So:
- If the next step is a **human action** (review + merge the PR, test the app), the `Next:` line names the
  **action**, not a command — show **no** `/harness:` token.
- A stage **gated behind** that action (e.g. `finish` after a merge) appears **only** as the trail's
  `◦ <stage>` label — **never** as a `/harness:` command and **never** as "then run X after Y". The label
  keeps the handoff non-silent without inviting a misfire; the command surfaces when that stage is actually next.
- Net: every `/harness:<cmd>` shown must be runnable **right now**; a step gated behind a future action
  never appears as a command. (Multiple genuinely-runnable-now alternatives — e.g. `fine-tune` vs `ship` at
  verified — are fine; the ban is only on premature/gated commands.)

Example (build at the spec-review gate):
```text
✓ refine → ✓ spec → ✓ review → ▸ read the review docs (you are here) → ◦ implement
```

## Position table (which row each skill stop renders)
| Stop | Done (✓, all) | ▸ Here — operator action | ◦ Next (one) |
|------|---------------|--------------------------|--------------|
| `refine` end | refine | task ready — your move | build |
| `build` · spec-review gate | refine · spec · review | read the review docs | implement |
| `build` · verified-not-shipped | refine · spec · review · implement · verify | test it yourself | ship |
| `fine-tune` · loop pause | … · verify | polishing — approve or continue | ship |
| `review-change` (operator) end · tree clean | … · verify | branch clean — ready to ship | ship |
| `review-change` (operator) end · fixes uncommitted | … · verify | fixes applied — commit before shipping | ship |
| `ship` end · two-merge (no comments) | … · verify · ship | review + merge the PR | finish |
| `ship` end · single-merge (no comments) | … · verify · ship | run `/harness:finish` (rides the open PR) | finish |
| `ship` end (PR has comments) | … · verify · ship | address the comments | address comments |
| `address-pr-comments` end · two-merge | … · ship | comments handled — merge the PR | finish |
| `address-pr-comments` end · single-merge | … · ship | comments handled — run `/harness:finish` | finish |
| `finish` end · two-merge | … · finish | merge the chore PR | done |
| `finish` end · single-merge | … · finish | review + merge the PR | done |

- Trim the left side to fit one line if it gets long (e.g. start from the most recent 4–5 `✓`); never
  drop the `▸ here` or the `◦ next`.
