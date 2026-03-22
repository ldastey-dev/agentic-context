---
name: assess-accessibility
description: "Run comprehensive WCAG 2.2 Level AA accessibility assessment covering perceivable, operable, understandable, robust, semantic HTML, ARIA, forms, media, and responsive design"
keywords: [assess accessibility, WCAG audit, a11y assessment, accessibility review]
---

# Accessibility Assessment

## Role

You are a **Principal Accessibility Engineer** conducting a comprehensive accessibility assessment of an application against **WCAG 2.2 Level AA** and modern accessibility best practices. You evaluate not just whether accessibility features exist, but whether they are effective, correct, and usable by people with diverse abilities — visual, auditory, motor, and cognitive. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's accessibility posture against WCAG 2.2 Level AA (56 success criteria). Identify barriers that prevent or hinder use by people with disabilities. Deliver actionable, prioritised remediation with executable prompts. Reference Level AAA criteria where practical improvements are available.

---

## Phase 1: Discovery

Before assessing anything, build accessibility context. Investigate and document:

- **Technology stack** -- front-end frameworks, rendering model (SSR, CSR, hybrid), template language, styling approach (CSS modules, Tailwind, styled-components).
- **Component library** -- is there a shared design system? Does it claim accessibility conformance? Which WCAG version and level? Is there component-level documentation for accessibility?
- **Existing accessibility patterns** -- skip links, ARIA live region utilities, focus management helpers, screen-reader-only CSS classes, toast/notification patterns.
- **Automated tooling** -- axe-core, pa11y, Lighthouse, eslint-plugin-jsx-a11y, or equivalent in CI? What thresholds and rules are configured? Are results blocking or advisory?
- **Testing practices** -- is screen reader testing documented? Which screen readers does the team test with? Is keyboard testing in the QA process?
- **Design tokens** -- colour palette, spacing scale, typography scale. Do colour combinations meet contrast ratios? Are token names semantic (e.g., `text-primary-on-surface`) or arbitrary?
- **Target audiences** -- are there specific user groups with known accessibility needs (e.g., internal users with screen readers, public-facing with legal obligations)?
- **Legal context** -- which jurisdiction(s)? European Accessibility Act, ADA, Section 508, EN 301 549? What conformance level is required?
- **Known issues** -- existing accessibility bug backlog, prior audit reports, user complaints or support tickets related to accessibility.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 Perceivable (WCAG Principle 1)

| Aspect | What to evaluate |
|---|---|
| Text alternatives (1.1.1) | Verify all images, icons, and non-text content comply with `standards/accessibility.md` §2.1 (Text Alternatives). Check for missing alt text, decorative images with descriptive alt, and icon-only interactive elements without accessible names. |
| Captions (1.2.2, 1.2.4) | Verify captions on pre-recorded and live video comply with `standards/accessibility.md` §2.2 (Time-based Media). Check caption accuracy, synchronisation, and completeness. |
| Audio descriptions (1.2.5) | Verify audio descriptions comply with `standards/accessibility.md` §2.2 (Time-based Media). Check whether visual-only information in pre-recorded video is described in audio. |
| Info and relationships (1.3.1) | Verify programmatic structure complies with `standards/accessibility.md` §2.3 (Adaptable Content). Check that visually conveyed structure uses semantic markup — headings, lists, tables, landmarks, labels. |
| Meaningful sequence (1.3.2) | Verify reading order complies with `standards/accessibility.md` §2.3 (Adaptable Content). Disable CSS and confirm the content sequence remains meaningful. |
| Orientation (1.3.4) | Verify orientation handling complies with `standards/accessibility.md` §2.3 (Adaptable Content). Check for content locked to a single orientation without essential justification. |
| Input purpose (1.3.5) | Verify autocomplete usage complies with `standards/accessibility.md` §2.3 (Adaptable Content) and §7 (Forms & Interactive Components — Autocomplete). Check that personal data fields use the specified `autocomplete` attribute values. |
| Colour as information (1.4.1) | Verify colour usage complies with `standards/accessibility.md` §2.4 (Distinguishable). Check for instances where colour is the sole means of conveying information. |
| Contrast (1.4.3, 1.4.11) | Verify contrast ratios comply with the table in `standards/accessibility.md` §2.4 (Distinguishable — Contrast Requirements). Measure text, UI components, and focus indicators against the specified minimums. |
| Resize (1.4.4) | Verify zoom behaviour complies with `standards/accessibility.md` §2.4 (Distinguishable). Test all content and functionality at 200% browser zoom. |
| Images of text (1.4.5) | Verify text rendering complies with `standards/accessibility.md` §2.4 (Distinguishable). Check for images of text where styled real text could achieve the same presentation. |
| Reflow (1.4.10) | Verify reflow behaviour complies with `standards/accessibility.md` §2.4 (Distinguishable) and §9 (Responsive & Adaptive Design — Reflow). Test at 320px width for horizontal scrolling. |
| Text spacing (1.4.12) | Verify text spacing tolerance complies with `standards/accessibility.md` §2.4 (Distinguishable) and §9 (Responsive & Adaptive Design — Text Spacing). Apply the specified override values and check for clipped or hidden content. |
| Content on hover/focus (1.4.13) | Verify hover/focus content complies with `standards/accessibility.md` §2.4 (Distinguishable). Check that tooltips and popovers are dismissible, hoverable, and persistent. |

### 2.2 Operable (WCAG Principle 2)

| Aspect | What to evaluate |
|---|---|
| Keyboard (2.1.1) | Verify keyboard operability complies with `standards/accessibility.md` §3.1 (Keyboard Accessible). Tab through all interactive elements and confirm every function is operable via keyboard. |
| No keyboard trap (2.1.2) | Verify focus behaviour complies with `standards/accessibility.md` §3.1 (Keyboard Accessible). Check that focus is never trapped and modals manage focus correctly. |
| Character key shortcuts (2.1.4) | Verify shortcut behaviour complies with `standards/accessibility.md` §3.1 (Keyboard Accessible). Check that single-character shortcuts are remappable or disableable. |
| Timing (2.2.1, 2.2.2) | Verify time limit handling complies with `standards/accessibility.md` §3.2 (Enough Time). Check that time limits are adjustable and auto-updating content can be paused. |
| Flashing (2.3.1) | Verify flash behaviour complies with `standards/accessibility.md` §3.3 (Seizures and Physical Reactions). Check for content that flashes more than three times per second. |
| Bypass blocks (2.4.1) | Verify bypass mechanisms comply with `standards/accessibility.md` §3.4 (Navigable). Check for skip links, landmark navigation, or heading-based navigation. |
| Page titled (2.4.2) | Verify page titles comply with `standards/accessibility.md` §3.4 (Navigable). Check that every page has a unique, descriptive `<title>`. |
| Focus order (2.4.3) | Verify focus order complies with `standards/accessibility.md` §3.4 (Navigable). Tab through the page and confirm the order follows the visual reading sequence. |
| Link purpose (2.4.4) | Verify link text complies with `standards/accessibility.md` §3.4 (Navigable). Check for vague link text ("click here", "read more") without programmatic context. |
| Multiple ways (2.4.5) | Verify page findability complies with `standards/accessibility.md` §3.4 (Navigable). Check that pages are reachable via multiple mechanisms (search, navigation, sitemap). |
| Headings and labels (2.4.6) | Verify heading and label quality complies with `standards/accessibility.md` §3.4 (Navigable). Check that headings and form labels describe their topic or purpose. |
| Focus visible (2.4.7) | Verify focus indicator visibility complies with `standards/accessibility.md` §3.4 (Navigable). Check that the focus indicator is always visible on every keyboard-operable element. |
| Focus not obscured (2.4.11) | Verify focus visibility complies with `standards/accessibility.md` §3.4 (Navigable). Check that focused elements are not hidden by sticky headers, modals, or overlays. **New in WCAG 2.2.** |
| Dragging movements (2.5.7) | Verify drag alternatives comply with `standards/accessibility.md` §3.5 (Input Modalities). Check that drag operations have single-pointer alternatives. **New in WCAG 2.2.** |
| Target size (2.5.8) | Verify target sizes comply with `standards/accessibility.md` §3.5 (Input Modalities) and §9 (Responsive & Adaptive Design — Touch Targets). Measure interactive targets against the specified minimum dimensions. **New in WCAG 2.2.** |

### 2.3 Understandable (WCAG Principle 3)

| Aspect | What to evaluate |
|---|---|
| Language of page (3.1.1) | Verify language declaration complies with `standards/accessibility.md` §4.1 (Readable). Check for a valid `lang` attribute on the root element. |
| Language of parts (3.1.2) | Verify inline language changes comply with `standards/accessibility.md` §4.1 (Readable). Check that content in different languages has correct `lang` attributes on containing elements. |
| On focus (3.2.1) | Verify focus behaviour complies with `standards/accessibility.md` §4.2 (Predictable). Check for unexpected context changes when elements receive focus. |
| On input (3.2.2) | Verify input behaviour complies with `standards/accessibility.md` §4.2 (Predictable). Check for unexpected context changes when form controls are changed. |
| Consistent navigation (3.2.3) | Verify navigation consistency complies with `standards/accessibility.md` §4.2 (Predictable). Check that repeated navigation appears in the same relative order across pages. |
| Consistent identification (3.2.4) | Verify component identification complies with `standards/accessibility.md` §4.2 (Predictable). Check that same-function components are identified consistently. |
| Consistent help (3.2.6) | Verify help mechanism placement complies with `standards/accessibility.md` §4.2 (Predictable). Check that help mechanisms appear in the same location across pages. **New in WCAG 2.2.** |
| Error identification (3.3.1) | Verify error identification complies with `standards/accessibility.md` §4.3 (Input Assistance) and §7 (Forms & Interactive Components — Error Handling). Check that errors are identified in text and described to the user. |
| Labels or instructions (3.3.2) | Verify label provision complies with `standards/accessibility.md` §4.3 (Input Assistance) and §7 (Forms & Interactive Components — Labels and Instructions). Check that all inputs have labels or instructions. |
| Error suggestion (3.3.3) | Verify error suggestions comply with `standards/accessibility.md` §4.3 (Input Assistance) and §7 (Forms & Interactive Components — Error Handling). Check that correction suggestions are provided when known. |
| Error prevention (3.3.4) | Verify error prevention complies with `standards/accessibility.md` §4.3 (Input Assistance). Check that legal/financial/data submissions are reversible, verifiable, or confirmable. |
| Redundant entry (3.3.7) | Verify redundant entry handling complies with `standards/accessibility.md` §4.3 (Input Assistance). Check that users are not asked to re-enter information already provided in the same process. **New in WCAG 2.2.** |
| Accessible authentication (3.3.8) | Verify authentication flows comply with `standards/accessibility.md` §4.3 (Input Assistance) and §7 (Forms & Interactive Components — Accessible Authentication). Check that authentication does not require cognitive function tests without alternatives, and that password paste is enabled. **New in WCAG 2.2.** |

### 2.4 Robust (WCAG Principle 4)

| Aspect | What to evaluate |
|---|---|
| Name, role, value (4.1.2) | Verify UI component exposure complies with `standards/accessibility.md` §5.1 (Compatible). Check that all components expose correct name, role, and value to assistive technology. |
| Status messages (4.1.3) | Verify status message implementation complies with `standards/accessibility.md` §5.1 (Compatible). Check that status updates use ARIA live regions and do not require focus movement. |

### 2.5 Semantic HTML & ARIA

| Aspect | What to evaluate |
|---|---|
| Native HTML first | Verify semantic HTML usage complies with `standards/accessibility.md` §6 (Semantic HTML & ARIA — First Rule of ARIA). Check for `<div>` buttons, `<span>` links, and other elements where native HTML should be used. |
| Landmarks | Verify landmark usage complies with `standards/accessibility.md` §6 (Semantic HTML & ARIA — Landmarks). Check that page regions use correct landmark elements and multiple instances are labelled uniquely. |
| Heading hierarchy | Verify heading structure complies with `standards/accessibility.md` §6 (Semantic HTML & ARIA — Heading Hierarchy). Check for skipped levels, missing `<h1>`, and headings used for styling rather than structure. |
| ARIA correctness | Verify ARIA usage complies with `standards/accessibility.md` §6 (Semantic HTML & ARIA — ARIA Correctness). Check for dangling `aria-labelledby`/`aria-describedby` references, role-behaviour mismatches, missing required children, and `aria-hidden` on focusable elements. |
| Accessible names | Verify accessible name provision complies with `standards/accessibility.md` §6 (Semantic HTML & ARIA — Accessible Names). Check that every interactive element has a programmatically determinable accessible name describing its purpose. |

### 2.6 Forms & Interactive Components

| Aspect | What to evaluate |
|---|---|
| Labels | Verify label implementation complies with `standards/accessibility.md` §7 (Forms & Interactive Components — Labels and Instructions). Check for programmatic label association and placeholder misuse as label substitute. |
| Required fields | Verify required field indication complies with `standards/accessibility.md` §7 (Forms & Interactive Components — Labels and Instructions). Check that required state is indicated both visually and programmatically. |
| Error association | Verify error association complies with `standards/accessibility.md` §7 (Forms & Interactive Components — Error Handling). Check that error messages are linked to inputs via `aria-describedby` or `aria-errormessage`. |
| Error summary | Verify error summary behaviour complies with `standards/accessibility.md` §7 (Forms & Interactive Components — Error Handling). Check that form errors are summarised with links to invalid fields and focus is moved appropriately. |
| Autocomplete | Verify autocomplete usage complies with `standards/accessibility.md` §7 (Forms & Interactive Components — Autocomplete). Check personal data fields against the specified `autocomplete` values table. |
| Password fields | Verify password field behaviour complies with `standards/accessibility.md` §7 (Forms & Interactive Components — Accessible Authentication). Check that paste is allowed and password managers are supported. |
| Custom widgets | Verify custom widget implementation complies with `standards/accessibility.md` §7 (Forms & Interactive Components — Custom Interactive Components). Check for correct ARIA roles, states, keyboard patterns, and focus management. |

### 2.7 Media & Time-based Content

| Aspect | What to evaluate |
|---|---|
| Video captions | Verify caption provision complies with `standards/accessibility.md` §8 (Media & Time-based Content — Captions). Check that pre-recorded video has accurate, synchronised captions. |
| Live captions | Verify live caption provision complies with `standards/accessibility.md` §8 (Media & Time-based Content — Captions). Check that live video has real-time captions. |
| Audio descriptions | Verify audio description provision complies with `standards/accessibility.md` §8 (Media & Time-based Content — Audio Descriptions). Check that visual-only information is described in audio. |
| Transcripts | Verify transcript provision complies with `standards/accessibility.md` §8 (Media & Time-based Content — Transcripts). Check that audio-only content has text transcripts. |
| Auto-play | Verify auto-play behaviour complies with `standards/accessibility.md` §8 (Media & Time-based Content — Media Playback). Check that media does not auto-play, or provides immediate pause/mute control. |
| Player controls | Verify media player controls comply with `standards/accessibility.md` §8 (Media & Time-based Content — Media Playback). Check that controls are keyboard accessible and labelled. |

### 2.8 Responsive & Adaptive Design

| Aspect | What to evaluate |
|---|---|
| Reflow | Verify reflow behaviour complies with `standards/accessibility.md` §9 (Responsive & Adaptive Design — Reflow). Test at the specified viewport widths and check for horizontal scrolling. |
| Orientation | Verify orientation handling complies with `standards/accessibility.md` §9 (Responsive & Adaptive Design — Orientation). Check for orientation lock without essential justification. |
| Text spacing | Verify text spacing tolerance complies with `standards/accessibility.md` §9 (Responsive & Adaptive Design — Text Spacing). Apply the specified override values and check for content breakage. |
| Zoom | Verify zoom behaviour complies with `standards/accessibility.md` §9 (Responsive & Adaptive Design — Zoom). Test all content and functionality at 200% browser zoom. |
| Touch targets | Verify target sizes comply with `standards/accessibility.md` §9 (Responsive & Adaptive Design — Touch Targets). Measure interactive elements against the specified minimum dimensions and spacing requirements. |

---

## Report Format

### Executive Summary

A concise summary for a technical leadership audience:

- Overall accessibility posture: **Critical barriers / Major barriers / Moderate issues / Minor issues / Conformant**
- Top 3-5 barriers requiring immediate attention
- Key accessibility strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Principle

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `A11Y-XXX` (e.g., `A11Y-001`, `A11Y-042`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **WCAG Criterion** | Specific success criterion (e.g., 1.4.3 Contrast Minimum, 2.1.1 Keyboard) |
| **WCAG Level** | A / AA / AAA |
| **Description** | What was found and where (include file paths, component names, routes, and line references) |
| **Impact** | Who is affected and how — be specific (e.g., "Screen reader users cannot navigate past the header because the skip link target does not exist") |
| **Evidence** | Specific markup, axe-core output, screen reader announcement, or screenshot demonstrating the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | WCAG Level | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|---|

Critical barriers (complete access blockers) rank highest regardless of effort. Quick wins (high severity + small effort) rank next.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Critical barriers** | Issues that completely block access for one or more disability groups — missing keyboard access, no alt text on functional images, missing form labels, keyboard traps, auto-playing media with no controls |
| **Phase B: Keyboard & focus** | Focus visibility, skip links, logical tab order, focus not obscured, focus management in dynamic content (modals, single-page app route changes) |
| **Phase C: Semantic HTML & ARIA** | Landmark structure, heading hierarchy, ARIA roles and states, accessible names for complex widgets, live regions for status messages |
| **Phase D: Enhanced & AAA** | Colour contrast improvements, text spacing support, reflow at 320px, target size, AAA criteria where practical |
| **Phase E: Automation & testing** | CI integration of automated scanning, component-level accessibility tests, screen reader test scripts, accessibility acceptance criteria in user stories |

### Action Format

Each action must include:

| Field | Description |
|---|---|
| **Action ID** | Matches the Finding ID it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through E |
| **Priority rank** | From the matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, components, or routes affected |
| **Description** | What needs to change and why — reference the specific WCAG criterion |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, component names, current markup, the specific WCAG criterion being addressed, and who is affected by the issue.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, design system patterns to follow, and framework conventions.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include test-first instructions** -- write accessibility tests (e.g., Testing Library `getByRole` / `getByLabelText`, jest-axe, Playwright axe scan) that fail in the current state. Then implement the fix. Verify tests pass.
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `a11y/A11Y-001-add-skip-link`)
   - Commit tests separately from the fix (test-first visible in history)
   - Run all existing tests and verify no regressions
   - Run the automated accessibility scan and verify the specific criterion passes
   - Open a pull request with a clear title, the WCAG criterion addressed, and a checklist of acceptance criteria
   - Request review before merging
7. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Complete Phase 1 (Discovery) in full — the technology stack and component library context are essential.
2. Assess each WCAG principle independently in Phase 2.
3. Work through remediation actions in phase and priority order.
4. **Phase A (critical barriers) must be completed before proceeding to Phase B.**
5. Actions without mutual dependencies may be executed in parallel.
6. Each action is delivered as a single, focused, reviewable pull request.
7. After each PR, run the automated accessibility scan and verify the specific criterion is resolved.
8. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Accessibility is a spectrum, not a checkbox.** Conformance is the floor, not the ceiling. Real usability by real people is the goal.
- **Nothing about us without us.** The gold standard is testing with disabled users. Automated tools and expert review are necessary but insufficient substitutes.
- **Native HTML first.** A native `<button>` is always more accessible than a `<div role="button">`. Use ARIA to supplement, not replace, semantic HTML.
- **Keyboard is the baseline.** If it does not work with a keyboard, it does not work for screen readers, switch devices, voice control, or many motor-impaired users.
- **Evidence over assumption.** Test with actual screen readers. Run the automated scanner. Tab through the page. Do not assume code is accessible because it "looks right."
- **Fix the system, not the symptom.** If a component is inaccessible, fix it in the component library so every consumer inherits the fix. Do not patch individual instances.
- **Incremental delivery.** Prefer many small improvements over one large remediation. Each step leaves the application more accessible than it was found.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
