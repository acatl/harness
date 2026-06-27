# Design Review Lenses

Detailed criteria for each review area. Apply the lenses relevant to what's being built — don't force all of them onto every spec.

**Project voice & design system come from the bindings.** Where a criterion references the product's
voice, brand posture, palette, narrow-width target, or component library, resolve it from the
project's **design references** (HARNESS.md › Context docs) and design-system doc. Examples below name
a "calm/precise" voice and a narrow sidebar target as illustrations — apply the project's actual
stance, not these literals. Where the product has multiple actors (a human plus an agent via MCP/CLI),
the agent-attribution criteria apply; skip them for single-actor products.

---

## 1. Form UX

Forms are the most common source of spec gaps. A spec can describe what fields exist without describing how they behave, which creates a gap between "it submits data" and "it's usable."

**Field labeling:**

- Every field must have an explicit label element — not just a placeholder. Placeholders disappear when the user starts typing and cannot serve as labels. A spec describing a field without mentioning its label is underspecified.
- Required fields must be marked. If asterisks are used, there must be a legend explaining what they mean (e.g., "\* Required").
- Helper text (hints, format guidance, max values) should be specified where it adds value: "Markdown supported, 10,000 character limit" positioned below the field, not as a placeholder.

**Field ordering and grouping:**

- Does the order match the user's mental model of what they're filling in? (Identity fields first, then classification, then specifics — not the order the database schema was designed.)
- Related fields should be visually grouped. Unrelated fields should have visual separation. A spec that lists fields without indicating grouping will produce an implementation that looks like a spreadsheet.
- Grouped fields (e.g., a date range: start × end) should be specified to appear in a horizontal row when semantically related, stacked when not.

**Validation behavior:**

- When does validation trigger? On blur (leaving a field), on change (while typing), or only on submit? Each has different UX tradeoffs. On-submit is simplest but surprises users. On-blur is the standard balanced approach. On-change can feel aggressive. The spec should choose.
- Required field validation: does an empty required field show an error immediately on blur, or only on submit attempt? Specify.
- Error messages must be actionable and specific: "Title is required" is acceptable, "Invalid input" is not. "Title must be 1–200 characters" is better than "Title is invalid."
- Error messages should be positioned adjacent to their field, not only at the top of the form.

**Submission behavior:**

- What happens to the submit/save button while a mutation is in-flight? It should be disabled and show a loading indicator (button spinner). A spec that doesn't address this will get inconsistent implementations.
- What happens on success? Redirect? Inline success state? Toast? Specify the destination and the feedback mechanism.
- What happens on failure? Is the form preserved so the user doesn't lose their work? Is the error actionable?

**Unsaved changes:**

- If a user partially fills a form and navigates away (browser back, sidebar link, accidental close), are they warned? An "unsaved changes" guard is a standard browser pattern (`beforeunload` event + confirmation dialog). Its absence means users will lose work and not understand why. Flag if unspecified.

**Character counters:**

- For any field with a character limit, a counter should be visible. Show it from the start (e.g., "0 / 200"), not only when approaching the limit. Approaching-limit-only counters surprise users who write long content.

**Multi-select and toggle patterns:**

- Multi-select with many options (8+) as toggle buttons/chips can become unwieldy on narrow widths. The spec should consider how many options are expected and what the interaction pattern is at scale. A searchable dropdown or grouped chips may be more appropriate at higher counts.
- The selected state must be visually distinct in a way that doesn't rely on color alone (shape, fill, border change — not just a color shift).

**File and media upload UX:**

- Upload fields are commonly underspecified. The spec should define: accepted file types and sizes (surfaced to the user before and on error — not just server-side validation), drag-and-drop affordance (not just a "Browse" button), upload progress state (progress bar or percentage for large files), preview state (show the uploaded file before form submit), error handling (rejected file type, file too large, network failure mid-upload), and replace/remove behavior (can the user swap or clear the uploaded file?).
- Multi-file upload needs additional consideration: does upload happen immediately on file select, or on form submit? What happens if one file fails while others succeed? Is there a per-file or aggregate error state?

---

## 2. Navigation and Wayfinding

**Breadcrumbs and back navigation:**

- For any view more than 2 levels deep in a URL hierarchy, users need a visible way back. Relying on the browser back button is fragile. The spec should indicate how users navigate up the hierarchy.
- Page-level titles should be specific, not generic. "Edit Task" is acceptable; "Edit: PROJ-47 — Ship auth migration" is better because it confirms the user is editing the right thing.

**Post-mutation navigation:**

- After creating a record, where does the user go? After saving an edit? After deleting? These should be specified. Default behavior (stay on the same page) is often wrong.
- When a user is redirected after a mutation, is there contextual confirmation? A toast ("Task saved") that fires on the destination page is better than a silent redirect.

**Error and 404 states:**

- If a user navigates to a resource that doesn't exist or they don't have access to, what do they see? A generic 404 is the minimum; a contextual message ("This task doesn't exist or has been deleted") is better.
- What's the recovery path from a 404? "Go back" or "Return to board" — specify this.

**Navigation active state:**

- In any sidebar or nav component, the current page/section should be visually indicated. This is often assumed and not specified, leading to implementations that don't show it.

**URL and deep-linking:**

- Is every meaningful view accessible by a stable, shareable URL? Filtered list views, drawers in an open state, specific board columns, and detail records should each have a canonical URL. Specs that route through client-side state (no URL change) make bookmarking, sharing, browser navigation, and LLM-driven navigation fragile.
- Deep-linking matters acutely for an LLM-in-the-loop tool: an agent or user pasting a URL into chat (e.g. `/projects/PROJ/tasks/PROJ-47`) needs that URL to land directly on the resource. A URL that only works in context ("navigate to the project, open the board, find the task") breaks both human sharing and agent workflows.
- If the spec doesn't mention URL structure, ask whether it's been considered. It's cheap to add at spec time and expensive to retrofit.

---

## 3. State Coverage

Every view that fetches data needs to handle four states. A spec that only describes the happy (data loaded) state is underspecified.

**Loading state:**

- Should use a skeleton that matches the content shape (not a generic spinner). A task row skeleton should look like a task row with grayed-out blocks. This avoids layout shift and sets expectations.
- For mutations in-flight, the triggering button should be disabled and show a spinner. The rest of the page can remain interactive.

**Empty state:**

- "No items yet" is not a UX pattern — it's an absence of UX. Empty states should include:
  - What is missing and why (context)
  - What the user can do about it (a CTA or a next step)
  - A tone that matches the product's voice (per design references — e.g. calm and practical, not cheerful or apologetic)
- Different empty contexts need different empty states: "no tasks yet" (first time) vs. "no tasks match your filter" vs. "all tasks in this column are done." These are different situations requiring different copy and CTAs.

**Error state:**

- Error messages should use plain language: what failed, what the user can do, and an escape hatch if the action can't be retried.
- No technical language exposed to users: no error codes, no exception names, no HTTP status in the message.
- The tone should be calm and factual. Avoid "oops!" and faux-apologetic language — it reads as hollow and conflicts with a precise/disciplined product voice.
- Provide a "Try again" action where retrying makes sense (transient errors). For permanent errors, provide a path forward.

**Partial failure:**

- If a page loads partially (some data fetched, some failed), what does the user see? A blank section? An inline error for just the failed section? Specify if the change involves multiple independent data fetches.

**Status vocabulary:**

- Entities with state machines have status values that are implementation terms (`TODO`, `IN_PROGRESS`, `DONE`, `BLOCKED`, `ARCHIVED`). These should never be shown to users as raw enum strings. The spec should define the user-facing label for each status the user can encounter.
- Status indicators should use icon + label — never color alone. Color blindness, low-contrast environments, and cultural differences in color meaning make color-only status unreliable. If the project's design/brand doc states this, treat it as a hard rule.

---

## 4. Destructive Actions and Data Safety

**Confirmation pattern:**

- Every destructive action (delete, permanent status change, irreversible transition) requires explicit confirmation.
- The confirmation dialog should explain _what will happen_, not just ask "Are you sure?" Users often click "confirm" without reading. "Delete this task? This cannot be undone." is better than "Are you sure?"
- The spec should define the exact wording of the confirmation, not leave it to the implementer.
- The confirmation pattern should be consistent across the product. If a Dialog is used in one place, it should be used everywhere — not a Dialog here and inline two-step text there.

**Visual treatment of destructive controls:**

- Destructive buttons should use the destructive/danger variant of the button component.
- Destructive controls should be visually separated from primary actions so they can't be accidentally clicked.
- Primary and destructive actions should never be adjacent without a clear visual hierarchy.

**Irreversibility communication:**

- If an action truly cannot be undone, say so explicitly in the confirmation, before the user commits. "This cannot be undone" is the minimum. "This will permanently delete the task and cannot be reversed" is better.
- If data will be lost (sub-tasks, attachments, dependency edges), name it: "Deleting this feature will also remove its 12 child tasks."

**Soft delete vs. hard delete:**

- The spec should explicitly distinguish soft delete (recoverable, record is hidden but retained) from hard delete (permanent, data is gone). The UX implications are entirely different: soft delete allows a recovery window, should communicate that recovery is possible ("Task archived. Undo?"), and may need an archive view. Hard delete is permanent and requires stronger confirmation copy and a clear "this cannot be undone" warning.
- If the spec is ambiguous, flag it — the choice affects data model, confirmation copy, and recovery flows.

**Bulk destructive actions:**

- If the spec includes any bulk selection UI (checkboxes, "select all"), the destructive confirmation must scale appropriately. "Delete 47 tasks?" with a count is different UX from single-item delete. The confirmation should name what will be affected: "You are about to permanently delete 47 tasks. This cannot be undone." Vague bulk confirmation ("Delete selected items?") leaves users uncertain about scope.
- Bulk actions carry higher risk of accidental data loss. Consider requiring the user to type a number or phrase to confirm deletions at large scale.
- If the product has agent clients (MCP/CLI), bulk actions issued by an agent should be subject to the same per-mutation attribution recording — flag if the spec hides the agent-vs-human distinction in bulk paths.

**Dirty state / unsaved changes:**

- If a user has unsaved changes in a form and navigates away, they should be warned. This is separate from the form submission flow — it's the accidental navigation case.
- The warning should explain what will be lost: "You have unsaved changes to this task. Leave without saving?"

---

## 5. Feedback and System Status

**Mutation feedback:**

- Every mutation (create, update, delete, submit, status change) needs feedback on completion. The user should always know if their action succeeded or failed.
- Success: typically a toast notification. The copy should confirm the specific action ("Task saved" not "Success").
- Failure: toast or inline error. Must be specific and actionable ("Couldn't save the task — please try again" not "Error").
- If the product has agent clients, agent-driven mutations (those originating from MCP / CLI / LLM clients) may not have a foreground UI to receive a toast. The spec should describe how the human user discovers out-of-band changes — typically a board re-render with the changed item highlighted, or a quiet activity indicator. Silent agent changes erode trust.

**Toast/notification strategy:**

- If a toast component is available in the design system, its use should be consistent across all mutations. Inconsistent use (toast for some things, redirect for others, silent for others) creates a confusing pattern.
- The spec should define: what triggers a toast, what the copy says, and whether errors are auto-dismissing or require manual dismissal. Success toasts are typically auto-dismissing (3–5 seconds). Error toasts should not auto-dismiss — the user needs time to read and act on them.
- Toast placement should be consistent (typically bottom-right or top-right, never overlapping primary content).

**In-flight states:**

- While a mutation is pending, the triggering button should be visually disabled and show a loading indicator. This prevents double-submission and communicates that something is happening.
- If a mutation takes noticeable time (>500ms), consider whether any optimistic UI is appropriate. If so, specify it — and specify the rollback path on failure.

**Focus management:**

- After a dialog closes, focus should return to the element that opened it (or a logical alternative if that element no longer exists).
- After a form submits and redirects, focus should land at the top of the new page or on a specific element (e.g., the task title on the detail drawer).
- After an inline action completes (e.g., the delete two-step reverts to "Delete" after cancel), focus should return to the Delete button.
- After a route-level delete (user deleted the current record and is redirected), focus should land somewhere sensible on the list/board page.
- These are often entirely missing from specs. An implementation without focus management is accessible in name only.

---

## 6. Accessibility

Don't do a full WCAG audit here — that's a separate concern. Flag structural accessibility gaps that specs commonly miss.

**Color as the sole signal:**

- Status indicators, form validation states, and any other state that communicates meaning must never rely on color alone. A second channel — icon, label, shape, pattern — must carry the same meaning. This applies to status badges, error states, success states, and disabled states.
- This is especially important in a low-chroma or intentionally subtle palette where color differentiation is slight.

**Form field accessibility:**

- Error messages must be programmatically associated with their field via `aria-describedby`, not just visually positioned near it. A screen reader user should hear the error when they focus the field.
- Required field indicators (asterisks) are visual — they must also be communicated programmatically (`aria-required="true"` on the input, or `required` attribute).
- Labels must be explicit `<label>` elements pointing to their field via `htmlFor` — not just visually positioned text.

**Interactive element labeling:**

- Icon-only buttons require an accessible label (`aria-label` on the button, or `aria-hidden="true"` on the icon with visible text nearby).
- If a spec describes an icon-only action without mentioning accessible labeling, flag it.

**Focus trapping in dialogs:**

- Any Dialog, Modal, or Sheet component must trap keyboard focus while open. Users navigating by keyboard must not be able to tab to content behind the dialog.
- Focus should move to the dialog when it opens, and return to the trigger when it closes.

**Keyboard navigation:**

- Multi-select toggle buttons and custom interactive components need to be keyboard-navigable. If the project states a keyboard-parity principle ("keyboard is equal to mouse"), every interactive surface must have a keyboard path. If a spec introduces a custom interactive pattern, ask whether keyboard behavior is defined.

**Touch targets:**

- Interactive elements (buttons, links, toggles) should meet the minimum touch target size of 44×44px (WCAG 2.5.5) or at minimum 24×24px for chrome controls (WCAG 2.5.8). Small icon buttons in dense UIs are the most common failure point.

**Dynamic content announcements:**

- When content updates without a page navigation — after a mutation, a filter change, a search, a status update, an agent-driven change pushed in — screen readers do not automatically announce the change. An `aria-live` region is required. Without it, a screen reader user submits a form, nothing audible happens, and they don't know if it worked.
- Common cases: toast notifications, inline status changes, form validation summaries, list updates after filtering, board column updates after agent action. The spec should acknowledge these if it involves dynamic content updates.
- Specs that specify toast notifications or inline success/error states without mentioning `aria-live` are underspecified for accessibility.

---

## 7. Design System Alignment

**Component reuse:**

- Does the spec describe UI using existing design system components (the project's component library), or does it describe custom implementations? Custom patterns create inconsistency, maintenance overhead, and divergence from the established design language.
- When a spec says "a multi-select toggle group" — is this an existing component? A new one? The answer affects implementation complexity and product consistency.

**Pattern consistency:**

- If an interaction pattern already exists in the product (e.g., two-step confirmation, inline error display, status badges, the drawer-over-modal default), the new spec should use the same pattern — not invent a variant.
- Inconsistency accumulates. Each small deviation from an established pattern makes the product feel slightly less coherent. Review whether the spec's proposed patterns match established ones.

**Token usage:**

- Specs that describe visual properties (colors, spacing, typography) should reference design tokens — not raw values. "Use the destructive button variant" is better than "red button." "Use `--color-text-muted`" is better than "gray text." If the project layers tokens (semantic over primitive), components should consume the semantic layer only.
- If a spec introduces new visual treatments not covered by existing tokens, that's a design system gap worth flagging.

**Icon usage:**

- Icons should accompany labels — not replace them. Icon-only actions require accessible labels and should be reserved for genuinely universal affordances (close ✕, external link ↗, expand/collapse chevron).
- Decorative icons that don't add meaning are visual noise. If a spec describes icons on elements where they're ornamental, flag it.

---

## 8. Microcopy and Content

Specs often define _what_ to show but not _what to say_. This is consistently one of the highest-value gaps to catch because the words users see have a direct, measurable effect on comprehension, trust, and task completion.

If the project's design/brand doc states a tone (e.g. precise over friendly, the technical word over the marketing word, no exclamation marks, no "great job!"), apply that lens here.

**Button labels:**

- Button labels should be specific action verbs, not generic ones. "Save Task" is better than "Save." "Mark Done" is better than "Submit." "Archive" is better than "Delete" when soft-delete is the actual behavior.
- The label should describe what will happen, not just acknowledge the click.

**Empty state copy:**

- "No tasks yet" is a dead end. "No tasks in this project. Create the first one to start tracking work." is a beginning. Empty states with copy that explains the situation and provides a next step perform significantly better.
- Avoid pep-talk language ("You've got this!", "Nice and tidy!") unless the product voice calls for it — an instrumental tool teaches the interface in empty states, it does not cheer.

**Error messages:**

- Must be specific and actionable: "Title must be 1–200 characters" not "Invalid title."
- Must be in plain language: no technical terms, no HTTP status codes, no exception names.
- Should guide the user toward a solution, not just describe the problem.

**Status explanations:**

- Any entity status that a user can see needs a plain-language explanation. `BLOCKED` should become "Blocked — waiting on a dependency or external input." `ARCHIVED` should become "Archived — hidden from the board but retained."
- The explanation should answer the user's next question: "What should I do now?"

**Disabled controls:**

- A disabled button without explanation is a UX wall. Users who encounter a disabled button without understanding why will try the same action repeatedly or give up. Tooltips on disabled controls are the minimum; an inline explanation is better.
- The copy for why a button is disabled should name the specific missing requirement: "Add a title to save this task" not "Requirements not met."

**Confirmation dialog copy:**

- The title should state the action: "Delete this task?" not "Confirm action."
- The body should explain the consequence: "This task will be permanently deleted and cannot be recovered."
- The confirm button should label the action: "Delete" or "Delete Task" — not "Yes" or "OK."
- The cancel button should be clearly labeled: "Cancel" or "Keep Task."

**Placeholder text:**

- Placeholders should provide a concrete example of expected input, not repeat the label. "e.g., Ship the auth migration" is a good placeholder for a task title field. "Title" as a placeholder where "Title" is already the label adds nothing.
- Placeholders must never be the only labeling mechanism for a field (they disappear on focus).

---

## 9. Edge Cases and Scalability

**List views at scale:**

- How many items does the list view handle before pagination or virtual scrolling is needed? The spec should define the pagination strategy. A list that renders all items works at 10; it breaks at 1,000.
- Can items be sorted? Filtered by status? Searched? These are commonly missing from initial specs and become immediately wanted features after first use.
- What does the list look like with items in different status states mixed together? Are statuses visually distinct enough to scan?

**Long content:**

- What happens to a 200-character task title in a board card designed for 50 characters? Truncation must be specified: where, with what indicator (ellipsis?), and whether full content is accessible on hover or tap.
- Specifications that set character limits without specifying truncation behavior will produce inconsistent implementations.

**Single-option selects:**

- If a select field has only one valid option (e.g., only one project exists), should it be a select at all? A select with one option forces an unnecessary interaction. Consider making it a static display or a hidden field.
- This is a common "works in development but looks wrong in production" issue because development configs often have multiple options.

**Narrow-width form layouts:**

- Multi-column form fields (date range side by side) need to specify how they behave at narrow viewports. A row of three inputs that looks fine at 1200px may be cramped at 320px.
- Toggle button groups with many options (8+) that wrap into multiple rows on narrow widths create usability problems — small touch targets, visual clutter, difficulty seeing what's selected.
- If the project declares a narrow-width target (per design references — e.g. a sidebar-embedding width), treat it as a first-class layout, not a responsive afterthought. If the spec doesn't address narrow-width behavior, flag it.

**Image / media placeholders:**

- For any view that displays media that might not exist (avatars, attachments, thumbnails), what is the placeholder? An empty gray box? A monogram fallback? An icon?
- The placeholder should communicate "missing" without looking broken — and should respect the product's aesthetic (e.g. no illustrated mascots if the brand is restrained).

---

## 10. Missing Journeys

The most impactful findings are often flows that aren't in the spec at all — implied by the change but never written down.

**Common patterns to look for:**

**Orphaned API endpoints (no corresponding frontend journey).** Scan the spec for every API endpoint, mutation, or backend action defined. For each one, ask: is there a frontend journey that lets a user invoke this? In a multi-client product, the CLI and MCP clients are equally valid frontends — but if the only way to trigger an action is a direct curl call, the action won't happen consistently. Flag orphaned endpoints explicitly under Missing Journeys with which client (web / CLI / MCP) needs the missing surface and what the impact is.

**Agent-driven views.** If a state can be set by either the human user or an agent (via MCP / CLI), both attribution paths need to be visible to the user. A spec that only describes the human-driven view leaves the agent-attribution surface unspecced. The user must always be able to tell at a glance which mutations were theirs and which came from an agent session.

**First-run / onboarding states.** The first time a user encounters a feature is different from the nth time. Is there a specific empty state, explainer, or guided action for the very first use? "Create your first project" is a different UX than "Create another project."

**Recovery flows.** What happens when the user's session expires mid-form? What if a network error occurs during a multi-step flow? What if an agent updates the entity the user is currently editing (concurrent-edit collision)? These are often entirely missing from specs.

**Out-of-band agent notification.** If an agent takes an action that affects the current view (e.g., the LLM moves a task to `IN_PROGRESS` while the user is looking at the board), how does the human user find out? A live re-render? A subtle "updated" indicator? A toast? If the spec doesn't address this, the user will see stale state and wonder if they did something.

---

## 11. Flow Mapping

Specs describe features in isolation. This lens asks: does the spec tell the complete story of how a user gets through this feature, start to finish? A feature can be internally correct but still be unreachable, unexitable, or broken at the seams where it hands off to another feature.

**Entry points:**

- How does the user arrive at this feature? Is there a nav link, a CTA, a notification, a redirect from another flow, a CLI command, an MCP tool? Specs almost always describe the feature itself without specifying how a user — or an agent — discovers or reaches it. If the entry point is unspecced, the implementer invents it — and it may not match what users or agents expect.
- If multiple clients can access this feature (web, CLI, MCP), do they all enter the same way? Each client has its own entry-point conventions; the spec should name them.

**Task flow completeness:**

- For each primary task this spec introduces, map the step sequence: what does the user do first, second, third? Is each step actually specced? A spec that describes steps 1, 3, and 4 in detail while step 2 is a vague sentence is a flow gap — even if no steps are entirely missing.
- Multi-step flows (wizards, funnels, multi-page forms) need to specify: how does the user know where they are in the sequence? Can they go back? What is preserved if they navigate backward? What happens if they exit mid-flow and return later?

**Decision points within a flow:**

- When a user hits a fork — two or more possible actions with different outcomes — are both branches fully specced? The spec might describe the buttons without speccing what happens down each path.
- If a gate or prerequisite blocks progression (e.g., "you must resolve dependencies before marking a task done"), is the blocked state specced? What does the user see, and what can they do from there?

**Exit points:**

- Beyond post-mutation navigation (Lens 2), consider all the ways a user can leave this flow: completion, cancellation, error, timeout, permission loss, external navigation. Each exit should have a defined destination and a clear user state on arrival.
- Abandonment is an exit too. If a user starts but doesn't finish, what happens to their partial data? Is it saved as a draft? Discarded? Do they get a recovery prompt on return?

**Cross-feature handoffs:**

- When this feature's success state is another feature's entry point (task created → now appears on the board → can be opened in the drawer), is that transition specced? The seam between features is where gaps most often hide — each spec treats itself as a standalone unit and leaves the handoff to the other spec, which may also leave it unspecced.
- Notifications, CLI output, MCP tool responses, or in-app prompts that result from this flow and drive users (or agents) into other flows should be identified here, even if not fully specced.
