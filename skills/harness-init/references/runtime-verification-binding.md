# Runtime-Verification Binding Contract

The hardest thing to make stack-agnostic: **behavioral verification** — actually running the system,
exercising the change, and observing whether it works. The blueprint calls this the *Behavior
Harness*. This file defines the generic contract, the per-project declaration, and the escape hatch
for complex topologies.

It is the generalization of MermaidLens's `run` skill (build → launch → drive → read log → check
liveness/crash) into something that also serves a web app, an API server, or a two-server layout.

---

## 1. The contract (stack-independent — owned by the skill)

Every implementing skill (for example, `harness:build`) runs the same four steps. The skill knows the
*shape*; the project supplies the *recipe* (§2).

1. **Bring up** — start whatever must run, per the project's launch declaration. Wait for each
   declared readiness signal before proceeding.
2. **Exercise** — drive the system to trigger the changed behavior, using the project's declared
   driver.
3. **Observe** — collect signals across the tiers below (logs, screenshots, liveness — everything the
   verdict needs).
4. **Release — hand the machine back.** The **instant** the signals are captured, tear down per the
   project's `teardown` declaration: quit the launched app + stop any launched processes, and drop the
   screen/computer-use focus. Do this **before computing the verdict and before any further
   (non-visual) work** — the operator's machine is borrowed only for bring-up→observe, never held
   through the build's tail (openspec-verify, code-review, run-log, report all run with the machine
   free). A fail→fix→re-run brings the system up fresh.
5. **Verdict** — from the captured signals (machine already released): pass only if no liveness
   failure, no error-level log line during the exercise, and (when checkable) the expected behavioral
   observations occurred. Otherwise fail → fix the cause → re-run. A failure not caused by this change
   → STOP and surface (no patching around it).

**Skip condition:** pure-logic-only changes (fully covered by unit tests, no runtime surface) skip
this entirely — same rule as MermaidLens (`docs/RELIABILITY.md` "green" definition).

### Signal tiers (cheapest-first, decreasing availability)

| Tier | Question | Availability | Example (Swift) | Example (web/API) |
|------|----------|--------------|-----------------|-------------------|
| **Liveness** | Did it stay up / not crash? | **Always** — file/process reads, no UI access | `pgrep` + new `.ips` crash report | process exit code; health endpoint 200 |
| **Logs** | Any runtime error? Expected events present? | When a log sink is declared | `MERMAIDLENS_LOG_FILE` JSON-lines; `error` line = fail | server log; browser console errors |
| **Behavioral** | Did it do the *right* thing? | **Best-effort** — needs a driver + access | computer-use screenshot/drive | Chrome DevTools MCP nav / curl assertions |

**Liveness is never best-effort.** It needs no screen/UI access, so it runs even when the behavioral
driver is unavailable (e.g. no Screen Recording grant). "No driver access" downgrades only the
behavioral tier, never the crash gate. This is the MermaidLens lesson: a green build + clean log is
**not** proof the app lived (a Swift trap aborts before any log line is written).

---

## 2. The declaration (per-project — owned by `docs/HARNESS.md`)

A `Runtime verification` section the project fills in. The agent reads it, doesn't parse it.

```markdown
## Runtime verification

| Key | Value |
|-----|-------|
| applies-when | <surfaces that need a launch; e.g. "any view/WebView/FSEvents change"> |
| skip-when    | <pure-logic-only changes fully covered by unit tests> |
| launch       | <command(s) or a project script that brings the system up> |
| readiness    | <how to know each process is up before exercising> |
| driver       | <how to exercise: computer-use | chrome-devtools MCP | HTTP client | CC preview> |
| liveness     | <how to detect alive / crashed> |
| log source   | <where runtime logs go + what an error looks like> |
| expected     | <events/observations that SHOULD appear when exercised> |
| teardown     | <how to bring it down + release the screen, run right after Observe; e.g. `pkill -x OneShot` / the launch script's stop / close the browser tab> |
```

### Worked examples

**Swift macOS app (MermaidLens):**
- launch: `./run.sh` (build + ad-hoc sign + launch; sets `MERMAIDLENS_LOG_FILE`)
- readiness: process spawned (run.sh returns at spawn)
- driver: computer-use MCP (screenshot + click/type)
- liveness: `pgrep -x MermaidLens` alive **and** no `*.ips` newer than a spawn-marker file
- log source: `MERMAIDLENS_LOG_FILE` JSON-lines; any `error`-level line = failure
- expected: e.g. "page rendered", "parse error cleared"

**Web app (single):**
- launch: `<dev server cmd>`
- readiness: dev server reachable (HTTP 200 on root)
- driver: chrome-devtools MCP (navigate, interact) or Claude Code preview
- liveness: server process alive; no uncaught page error
- log source: server log + browser console; console `error` = failure
- expected: route renders, target element present, no 4xx/5xx in network panel

**API server (single):**
- launch: `<serve cmd>`
- readiness: health endpoint 200
- driver: HTTP client (curl/httpie) hitting the changed endpoints
- liveness: process alive; health stays 200 after exercise
- log source: server log; `error` level = failure
- expected: changed endpoints return expected status/shape

### Swift backend — full mechanism (ported from the `run` skill)

The Swift example's liveness check has load-bearing timing details (learned from a real crash, MERM-2 /
PR #5 — a debounced off-main write trapped ~500ms after each edit; a green build + clean log missed it):

- **Spawn-marker timing.** Drop the marker the instant the app is spawned — `m=$(mktemp)` **right after
  `./run.sh` returns** (it launches async and returns at spawn). Place it *after* run.sh's build/sign,
  never before — else build time folds into the window and a late `.ips` from the *previous* run looks
  new and false-fails a healthy run.
- **Settle window.** Check liveness **after exercising the change AND a short settle window** — debounced
  / async off-main work must have run (the MERM-2 trap fired ~500ms late, so an immediate check misses it).
- **Two signals.** `pgrep -x <App>` is the fast primary signal (gone = crash, even on green build + clean
  log); a `<App>-*.ips` newer than the marker corroborates (`.ips` is written asynchronously, a second+
  after the abort). On macOS use BSD `find … -newer "$m"` (a marker file) — **not** GNU `-newermt "@epoch"`,
  which BSD `find` won't parse.
- **Visual is best-effort; liveness + log are not.** The screenshot/drive needs Screen Recording /
  computer-use access; if ungranted, note the on-screen check was skipped and rely on log + liveness
  (file/process reads, always available). "No screen recording" downgrades only the visual tier.

This is the Swift instance of the binding — there is no standalone `run` skill; `harness:build`'s Step F
behavioral-verify invokes the launch recipe declared in HARNESS.md, which for a Swift app is `run.sh` +
this liveness procedure.

---

## 3. Escape hatch for complex topologies (the load-bearing move)

For anything beyond a single process (e.g. **web + API two-server**), do **not** try to orchestrate
arbitrary topologies inside the skill. Instead:

- The project supplies a **single launch/verify script** (the `run.sh` model) that owns the
  orchestration — start the API, wait for health, start the web server, wait for ready, optionally
  seed state. The binding just **calls that script** and reads the declared signals.
- HARNESS.md still declares the **driver** and **signal sources** so the skill knows how to exercise
  and observe — but the *bring-up complexity lives in the project's script*, where it belongs and can
  be tested independently.

Division of labor:

| Concern | Owner |
|---------|-------|
| The 4-step contract + signal interpretation + verdict | **the skill** (generic) |
| Launch recipe / topology / readiness orchestration | **the project** (a script for complex cases) |
| Which driver + where signals live | **HARNESS.md declaration** |

This keeps the skill stack-agnostic while letting a two-server (or N-server) project be as complex
as it needs — the complexity is quarantined in a project-owned artifact.

---

## 4. Open edges (validate in Phase 6)

- **Multi-server stress test** — prove the script escape hatch against a real web+API layout; confirm
  the binding's driver/signal declaration is enough to exercise cross-service behavior.
- **Driver portability** — computer-use (native) vs chrome-devtools MCP (web) vs HTTP (API): confirm
  the contract's "exercise" step reads cleanly regardless of which driver a project declares.
- **Headless/CI** — behavioral tier is best-effort; confirm liveness + logs still produce a usable
  verdict when no interactive driver is available (mirrors MermaidLens's "no Screen Recording"
  degradation).
