# OS-Readiness Tracking

Working doc for the company-port / open-source-readiness pass. Two lists:

- **Confirmed gaps** — real, worth doing. No pushback needed to start, but each still needs a
  scope decision (do it now vs. later) before acting.
- **Needs confirmation** — raised during audit/comparison, but applicability is unclear. Do NOT
  act on these until the corresponding question is answered.

Source: secrets/quality audit + comparison against
[Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) (CLI-tool peer) and
[obra/superpowers](https://github.com/obra/superpowers) (skill-only peer — 243,465★, 21,599 forks,
verified live via GitHub API, created 2025-10-09) (2026-07-01/02 session).

---

## Confirmed gaps

| # | Gap | Why it's real | Effort |
|---|-----|----------------|--------|
| 1 | No `CODE_OF_CONDUCT.md` | Expected minimum for a company-associated or public OSS repo. Confirmed by both peers: OpenSpec lacks it too, but superpowers (the closer, skill-only comp) has one | trivial (template) |
| 2 | No `SECURITY.md` | No disclosure process if a vuln is found in a skill/script. Note: neither peer has this either (OpenSpec no, superpowers no even at 243K★) — cheap regardless, but not a "everyone else has it" gap | trivial (template) |
| 3 | No release/version discipline | `package.json` pinned at `0.1.0` since inception; no changesets or semver bump process. superpowers runs `.version-bump.json` + `scripts/bump-version.sh` syncing version across manifests, with a hand-maintained `RELEASE-NOTES.md` | **Resolved (2026-07-02):** automated via release-please (shared version across `package.json` + every `SKILL.md` `metadata.version`); commit format enforced by husky/commitlint. See resolution log. |
| 4 | `docs/PORTING-PLAN.md` fate undecided before port | Contains personal local paths (`/Users/acatl/workspace/...`) and other project names (one-shot, kino, ONEST/HSTES tickets). Not secret, but noise in a company repo | **Resolved (2026-07-02):** dropped. Open threads filed as [#4](https://github.com/acatl/harness/issues/4), [#5](https://github.com/acatl/harness/issues/5), [#6](https://github.com/acatl/harness/issues/6), [#7](https://github.com/acatl/harness/issues/7), [#8](https://github.com/acatl/harness/issues/8). |
| 5 | OpenSpec CLI is a hard dependency with bus-factor risk | `MAINTAINERS.md` lists one lead maintainer; young project | no code change — a risk to flag to whoever owns the adopt decision |
| 6 | No skill-trigger eval tests | superpowers runs 51 test files, incl. `tests/explicit-skill-requests/run-haiku-test.sh` and `run-multiturn-test.sh` — real model calls asserting a skill actually fires on a given prompt. This is the genre's real test-maturity bar, not unit tests. Resolves former item A: dogfooding alone is not the ceiling | **Deferred (2026-07-02)** → tracked in [acatl/harness#3](https://github.com/acatl/harness/issues/3). 15 skills, low churn, dogfood evidence sufficient today. |
| 7 | `scripts/*.sh` unlinted | superpowers runs `scripts/lint-shell.sh` (shellcheck-style) over its scripts in CI/tests. harness-pipeline has `scripts/check-skill-frontmatter.sh` + `scripts/sync-skill-resources.sh` with no lint gate | trivial — add shellcheck to `quality.yml` |
| 8 | No GitHub issue templates | PR template already existed (`.github/pull_request_template.md`); issue templates did not. Surfaced in the superpowers comparison but was not carried into this doc during the audit (tracking miss). More relevant now that GitHub Issues is this repo's declared tracker (item #3 / CLAUDE.md) | **Resolved (2026-07-02):** added bug / skill-or-feature / design-idea markdown templates + `config.yml` (blank issues off, security contact link). |

---

## Needs confirmation (do not act yet)

| # | Item | Why it might NOT apply | Question to resolve |
|---|------|--------------------------|----------------------|
| B | No OS test matrix (linux/mac/windows) | OpenSpec matrix-tests a compiled CLI binary; harness has no compiled/executed artifact, only markdown lint. superpowers (closer peer) also runs **no** OS matrix | Treat as resolved not-applicable — flagging only in case `scripts/*.sh` portability becomes a real concern later. |
| E | No community signals (Discord, stars/downloads/contributors badges, AI-review bot) | Requires public visibility; repo is currently private. superpowers proves this genre *can* reach massive adoption (243K★) — so this isn't a stage-gate to dismiss, it's the actual ceiling if you go public | Confirm: is a public release imminent, or is company-internal the target for now? Determines whether to even track these. |
| F | No `CODEOWNERS` / `MAINTAINERS.md` | OpenSpec has both; superpowers has **neither**, even at 243K★ (single-owner attribution scales fine in this genre) | Confirm intent — internal company tool (owner = team lead, informal) vs. public OSS. Weight toward "skip" given the closer peer skips it too. |
| G | `docs/pipeline.md` and `docs/build-source-map.md` reference "kino" as a source project (provenance notes) | Not secret, describes where logic was ported from | **Resolved (2026-07-06):** publishing this repo in place (not a curated snapshot — see log). `build-source-map.md` dropped (repo-only dead weight); `pipeline.md` provenance line degenericized. Remaining name refs (kino/one-shot/ONEST/HSTES) are the author's own personal projects — no NDA surface — kept as history where they appear. |
| H | Single-platform (Claude Code only) vs. superpowers' 7-platform plugin structure (Claude/Codex/Cursor/Kimi/OpenCode/Gemini/pi) with a version-sync script across manifests | Only relevant if the company uses more than one coding agent. Building multi-platform packaging speculatively would be a premature abstraction | Does the company standardize on Claude Code only, or is multi-agent support a real near-term need? |

**Resolved, no longer open:**
- ~~C — no Nix flake~~: not-applicable, confirmed by two peer comparisons (CLI-tool-specific practice, absent in the skill-only peer too).
- ~~D — no npm publish/OIDC~~: not-applicable, same reasoning — superpowers doesn't publish to the npm registry as its primary distribution either.

---

## Resolution log

*(append decisions here as each row above is settled — date, decision, why)*

- **2026-07-02 — items #1, #2, #7 (CODE_OF_CONDUCT, SECURITY.md, shellcheck):** shipped as-is
  (no-brainers, no walk-through needed).
- **2026-07-02 — item #3 (release/version discipline):** initially lightweight manual semver
  (option B) + husky/commitlint. **Upgraded same day to full automation** at the user's request:
  release-please cuts a shared version across `package.json` + every `SKILL.md` `metadata.version`
  on merge of its standing Release PR. Chose release-please over semantic-release specifically
  because it routes the bump through a PR (respects this repo's "never commit to `main`" rule) and
  gives a human release gate; no npm publish (`package.json` is `private`). husky/commitlint stays —
  it's the prerequisite that makes release-please's bump detection trustworthy.
- **2026-07-02 — item #6 (skill-trigger eval tests):** deferred (option C) → tracked in
  [acatl/harness#3](https://github.com/acatl/harness/issues/3).
- **2026-07-02 — item #8 (issue templates):** added in the same readiness PR. Kept deliberately
  minimal/standard (not mirroring the verbose PR-template house style).
- **2026-07-06 — public-release decision (supersedes issue #5's "curated snapshot" plan):** publish
  `acatl/harness` **in place**, full history retained. Rationale: the only internal refs are the
  author's **own** personal project names (kino / one-shot / ONEST / HSTES) and local paths — no
  client/employer confidentiality surface, and negligible security value (paths expose only the
  already-public `acatl` handle). Full sweep found no secrets/tokens/PII, `private: true` blocks npm
  publish, CI has no `pull_request_target` or custom secrets. Working-tree tidy done same day:
  dropped `docs/build-source-map.md`, degenericized the `pipeline.md` provenance line, resolved item
  G. Issues [#5](https://github.com/acatl/harness/issues/5) (scrub) and
  [#4](https://github.com/acatl/harness/issues/4) (live-run validation) closed.
