# Accessibility Standards — WCAG 2.2 Level AA & Beyond

> Include this file in any project that delivers web content, web applications,
> or native applications to end users. Accessibility is a legal obligation in
> many jurisdictions (European Accessibility Act, ADA, Section 508, EN 301 549)
> and a quality imperative everywhere. Level AA is the mandatory baseline;
> Level AAA criteria are adopted where practical.

> Based on **WCAG 2.2** (W3C Recommendation, October 2023; ISO/IEC 40500:2025).
> WCAG 3.0 (W3C Working Draft) is referenced for forward-looking context only.

---

## 1 · Core Principle — Accessibility as a First-Class Concern

Accessibility must be addressed at the design phase of every feature, not
retrofitted after implementation. Every user interface component must be usable
by people with diverse abilities — visual, auditory, motor, and cognitive.

Accessibility debt compounds faster than technical debt. Fixing a component
library's accessibility after fifty consumers adopt it costs orders of magnitude
more than building it correctly from the start.

The four WCAG principles (POUR) structure all accessibility requirements:

| Principle | Meaning | Disability groups served |
|---|---|---|
| **Perceivable** | Information and UI must be presentable in ways users can perceive | Blind, low-vision, deaf, hard-of-hearing, cognitive |
| **Operable** | UI components and navigation must be operable by all users | Motor, blind (keyboard/screen reader), cognitive, vestibular |
| **Understandable** | Information and UI operation must be understandable | Cognitive, learning disabilities, non-native language speakers |
| **Robust** | Content must be robust enough for diverse user agents and assistive technologies | All — ensures interoperability with current and future tools |

Accessibility testing is part of the definition of done, not a separate phase.

---

## 2 · Perceivable

Content must be presentable in ways every user can perceive, regardless of
sensory ability.

### 2.1 · Text Alternatives (Guideline 1.1)

- Every meaningful image must have descriptive `alt` text that conveys the same
  information as the image (1.1.1 Non-text Content, Level A).
- Decorative images must use empty `alt` text (`alt=""`) or be rendered as CSS
  background images. They must never have descriptive alt text that adds noise
  for screen reader users.
- Complex images (charts, diagrams, infographics) must have a short `alt`
  summary and a long description (via `aria-describedby`, `<details>`, or a
  linked page).
- Icons used as the sole content of interactive elements (buttons, links) must
  have an accessible name via `aria-label`, `aria-labelledby`, or visually
  hidden text.

### 2.2 · Time-based Media (Guideline 1.2)

| Requirement | WCAG Criterion | Level |
|---|---|---|
| Pre-recorded audio has a text transcript | 1.2.1 Audio-only and Video-only | A |
| Pre-recorded video with audio has synchronised captions | 1.2.2 Captions (Pre-recorded) | A |
| Pre-recorded video has audio description or full text alternative | 1.2.3 Audio Description or Media Alternative | A |
| Live audio has real-time captions | 1.2.4 Captions (Live) | AA |
| Pre-recorded video has audio descriptions for visual-only information | 1.2.5 Audio Description (Pre-recorded) | AA |

### 2.3 · Adaptable Content (Guideline 1.3)

- Information, structure, and relationships conveyed through presentation must
  be programmatically determinable via semantic markup (1.3.1, Level A). Use
  headings, lists, tables, landmarks, and labels — not just visual styling.
- Reading order must be meaningful when CSS is disabled or linearised (1.3.2,
  Level A).
- Instructions must not rely solely on sensory characteristics — shape, colour,
  size, visual location, orientation, or sound (1.3.3, Level A).
- Content must not restrict display to a single orientation (portrait or
  landscape) unless a specific orientation is essential (1.3.4, Level AA).
- Form fields that collect personal information must use appropriate
  `autocomplete` attributes (1.3.5, Level AA).

<!-- PROJECT: List your component library's autocomplete-enabled fields. -->

### 2.4 · Distinguishable (Guideline 1.4)

- Colour must not be the sole means of conveying information, indicating an
  action, prompting a response, or distinguishing a visual element (1.4.1,
  Level A). Provide text labels, patterns, shapes, or icons alongside colour.
- Audio that plays automatically for more than three seconds must have a
  mechanism to pause, stop, or control volume independently of the system
  volume (1.4.2, Level A).
- Images of text must not be used when the same visual presentation can be
  achieved with styled text (1.4.5, Level AA).

#### Contrast Requirements

| Element type | AA minimum ratio | AAA target ratio |
|---|---|---|
| Normal text (< 18pt / < 14pt bold) | 4.5:1 | 7:1 |
| Large text (≥ 18pt / ≥ 14pt bold) | 3:1 | 4.5:1 |
| UI components and graphical objects | 3:1 | — |
| Focus indicators | 3:1 | — |

- Text must meet the minimum contrast ratio against its background (1.4.3
  Contrast Minimum, Level AA).
- Non-text UI components (borders, icons, graphical objects) must maintain a
  3:1 contrast ratio against adjacent colours (1.4.11 Non-text Contrast,
  Level AA).
- Text must be resizable to 200% without loss of content or functionality
  (1.4.4 Resize Text, Level AA).
- Content must reflow at 320 CSS pixels width (vertical scrolling content) and
  256 CSS pixels height (horizontal scrolling content) without requiring
  two-dimensional scrolling (1.4.10 Reflow, Level AA).
- Content must remain functional and visible when users override text spacing:
  line height to at least 1.5 times the font size, paragraph spacing to at
  least 2 times the font size, letter spacing to at least 0.12 times the font
  size, and word spacing to at least 0.16 times the font size (1.4.12 Text
  Spacing, Level AA).
- Content that appears on hover or focus must be dismissible (e.g., via
  Escape), hoverable (the user can move the pointer over the new content
  without it disappearing), and persistent (it remains visible until the user
  dismisses it or the trigger is removed) (1.4.13 Content on Hover or Focus,
  Level AA).

<!-- PROJECT: Document your design token colour palette and confirm all
     combinations meet the contrast ratios above. -->

---

## 3 · Operable

User interface components and navigation must be operable by every user,
regardless of input method or motor ability.

### 3.1 · Keyboard Accessible (Guideline 2.1)

- All functionality must be operable through a keyboard interface without
  requiring specific timings for individual keystrokes (2.1.1 Keyboard,
  Level A).
- If keyboard focus can be moved to a component, focus must be movable away
  from that component using only the keyboard. If escape from a component
  requires more than standard arrow or tab keys, the user must be informed of
  the method (2.1.2 No Keyboard Trap, Level A).
- If a keyboard shortcut uses only a single printable character key (letter,
  number, punctuation, or symbol), the shortcut must be remappable or
  disableable, or active only when the relevant component has focus (2.1.4
  Character Key Shortcuts, Level A).

### 3.2 · Enough Time (Guideline 2.2)

- Time limits must be adjustable: the user can turn off, adjust to at least
  ten times the default, or extend the limit with a simple action at least
  twenty seconds before expiry (2.2.1 Timing Adjustable, Level A). Exceptions
  exist for real-time events and essential time limits.
- Moving, blinking, scrolling, or auto-updating content that starts
  automatically and lasts more than five seconds must have a mechanism to
  pause, stop, or hide it (2.2.2 Pause, Stop, Hide, Level A).

### 3.3 · Seizures and Physical Reactions (Guideline 2.3)

- No content may flash more than three times per second, or the flash must be
  below the general flash and red flash thresholds (2.3.1 Three Flashes or
  Below Threshold, Level A).

### 3.4 · Navigable (Guideline 2.4)

- A mechanism must exist to bypass blocks of content that are repeated on
  multiple pages (skip links, landmarks, or heading navigation) (2.4.1 Bypass
  Blocks, Level A).
- Every page must have a descriptive, unique `<title>` (2.4.2 Page Titled,
  Level A).
- Focus order must be meaningful and follow visual reading sequence (2.4.3
  Focus Order, Level A).
- The purpose of each link must be determinable from the link text alone or from
  the link text together with its programmatically determined context (2.4.4
  Link Purpose in Context, Level A).
- More than one way must be available to locate a page within a set of pages
  (search, navigation, sitemap) (2.4.5 Multiple Ways, Level AA).
- Headings and labels must describe their topic or purpose (2.4.6 Headings and
  Labels, Level AA).
- Any keyboard-operable interface must have a visible focus indicator (2.4.7
  Focus Visible, Level AA).
- **New in WCAG 2.2:** When a user interface component receives keyboard focus,
  the component must not be entirely hidden by author-created content (2.4.11
  Focus Not Obscured Minimum, Level AA).

### 3.5 · Input Modalities (Guideline 2.5)

- All functionality that uses multipoint or path-based gestures must be
  operable with a single pointer without a path-based gesture (2.5.1 Pointer
  Gestures, Level A).
- For functionality operated with a single pointer, at least one of the
  following is true: the down-event is not used; completion is on the up-event
  with the ability to abort or undo (2.5.2 Pointer Cancellation, Level A).
- For components with visible text labels, the accessible name must include the
  visible text (2.5.3 Label in Name, Level A).
- Functionality triggered by device motion (tilting, shaking) must have an
  alternative UI control, and motion actuation must be disableable (2.5.4
  Motion Actuation, Level A).
- **New in WCAG 2.2:** All functionality that uses dragging movements must be
  operable via a single pointer without dragging (2.5.7 Dragging Movements,
  Level AA).
- **New in WCAG 2.2:** Interactive targets must be at least 24×24 CSS pixels,
  or have sufficient spacing from adjacent targets (2.5.8 Target Size Minimum,
  Level AA).

### New Criteria in WCAG 2.2

| Criterion | Level | Section |
|---|---|---|
| 2.4.11 Focus Not Obscured (Minimum) | AA | Operable |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Operable |
| 2.4.13 Focus Appearance | AAA | Operable |
| 2.5.7 Dragging Movements | AA | Operable |
| 2.5.8 Target Size (Minimum) | AA | Operable |
| 3.2.6 Consistent Help | A | Understandable |
| 3.3.7 Redundant Entry | A | Understandable |
| 3.3.8 Accessible Authentication (Minimum) | AA | Understandable |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Understandable |

Note: 4.1.1 Parsing was removed in WCAG 2.2 — modern browsers and assistive
technologies handle HTML parsing errors consistently.

---

## 4 · Understandable

Information and the operation of the user interface must be understandable to
all users.

### 4.1 · Readable (Guideline 3.1)

- The default human language of each page must be programmatically determinable
  via the `lang` attribute on the root element (3.1.1 Language of Page,
  Level A).
- The language of each passage or phrase that differs from the page's default
  language must be programmatically determinable via the `lang` attribute on
  the containing element (3.1.2 Language of Parts, Level AA).

### 4.2 · Predictable (Guideline 3.2)

- Receiving focus must not trigger a change of context (page navigation, form
  submission, focus shift) (3.2.1 On Focus, Level A).
- Changing the setting of a user interface component must not automatically
  trigger a change of context unless the user has been advised beforehand
  (3.2.2 On Input, Level A).
- Navigation mechanisms repeated across multiple pages must appear in the same
  relative order each time (3.2.3 Consistent Navigation, Level AA).
- Components with the same functionality must be identified consistently across
  pages (3.2.4 Consistent Identification, Level AA).
- **New in WCAG 2.2:** Help mechanisms (contact information, self-help options,
  chat) must appear in the same relative location across pages (3.2.6
  Consistent Help, Level A).

### 4.3 · Input Assistance (Guideline 3.3)

- Input errors must be automatically detected and described to the user in text
  (3.3.1 Error Identification, Level A).
- Labels or instructions must be provided when content requires user input
  (3.3.2 Labels or Instructions, Level A).
- If an input error is detected and suggestions for correction are known, the
  suggestions must be provided to the user (3.3.3 Error Suggestion, Level AA).
- For pages that cause legal commitments, financial transactions, or data
  modification: submissions must be reversible, verified, or confirmed (3.3.4
  Error Prevention, Level AA).
- **New in WCAG 2.2:** Information previously entered by or provided to the user
  in the same process must be auto-populated or available for selection — users
  must not be required to re-enter it (3.3.7 Redundant Entry, Level A).
- **New in WCAG 2.2:** Authentication processes must not require cognitive
  function tests (memory, transcription, calculation, puzzle-solving) unless
  an accessible alternative is provided. Password fields must allow paste and
  support password managers. Passkeys and WebAuthn are strongly preferred
  (3.3.8 Accessible Authentication Minimum, Level AA).

---

## 5 · Robust

Content must be robust enough to be interpreted reliably by a wide variety of
user agents and assistive technologies.

### 5.1 · Compatible (Guideline 4.1)

- **4.1.1 Parsing** was removed in WCAG 2.2. Modern browsers and assistive
  technologies handle HTML parsing errors consistently. Valid markup remains a
  best practice but is no longer a conformance requirement.
- All user interface components must have a programmatically determinable
  name, role, and value. States, properties, and values that can be set by the
  user must be programmatically settable. Notification of changes must be
  available to user agents and assistive technologies (4.1.2 Name, Role, Value,
  Level A).
- Status messages (success notifications, error counts, progress updates) must
  be programmatically determinable through role or properties so they can be
  presented to the user by assistive technologies without receiving focus
  (4.1.3 Status Messages, Level AA). Use ARIA live regions (`role="status"`,
  `role="alert"`, `aria-live="polite"`, `aria-live="assertive"`).

---

## 6 · Semantic HTML & ARIA

### First Rule of ARIA

Use native HTML elements and attributes before reaching for ARIA. A native
`<button>` is always more accessible than `<div role="button" tabindex="0">`.
ARIA supplements semantic HTML — it never replaces it.

### Landmarks

Use HTML5 landmark elements to define page regions:

| Landmark element | ARIA role equivalent | Usage |
|---|---|---|
| `<main>` | `role="main"` | Primary content area — exactly one per page |
| `<nav>` | `role="navigation"` | Navigation blocks — label each when multiple exist |
| `<header>` (page-level) | `role="banner"` | Site header — exactly one per page |
| `<footer>` (page-level) | `role="contentinfo"` | Site footer — exactly one per page |
| `<aside>` | `role="complementary"` | Supporting content related to the main content |
| `<section>` | `role="region"` | Thematic grouping — must have an accessible name |
| `<form>` | `role="form"` | Form — must have an accessible name |
| `<search>` | `role="search"` | Search functionality |

When multiple instances of the same landmark exist (e.g., two `<nav>`
elements), each must have a unique accessible name via `aria-label` or
`aria-labelledby`.

### Heading Hierarchy

- Headings must form a logical hierarchy with no skipped levels (`<h1>` →
  `<h2>` → `<h3>`, never `<h1>` → `<h3>`).
- Every page must have exactly one `<h1>` describing the page's primary
  content.
- Headings must be used for structure, not for visual styling. Use CSS for
  styling; use headings for semantics.

### ARIA Correctness

- Every `aria-labelledby` and `aria-describedby` must reference an existing
  element ID. Dangling references are silent failures.
- `role` must match the component's actual behaviour. A `role="button"` must
  respond to Enter and Space key presses. A `role="tab"` must be part of a
  `role="tablist"` with correct `aria-selected` management.
- Required ARIA children must be present (e.g., `role="list"` requires
  `role="listitem"` children).
- `aria-hidden="true"` must never be set on focusable elements or their
  ancestors. This creates a disconnect where a screen reader cannot announce
  an element that the user can focus.

### Accessible Names

Every interactive element must have a programmatically determinable accessible
name. The name must describe the element's purpose, not its appearance.

```
# Pseudocode — adapt to your language / framework

# ✅ CORRECT — meaningful accessible name
<button aria-label="Close dialog">×</button>

# ✅ CORRECT — label association
<label for="email">Email address</label>
<input id="email" type="email" autocomplete="email">

# ❌ NEVER — no accessible name
<button>×</button>

# ❌ NEVER — placeholder is not a label
<input type="email" placeholder="Email address">
```

---

## 7 · Forms & Interactive Components

### Labels and Instructions

- Every form input must have a programmatically associated `<label>` element.
  Placeholder text is not a substitute for a label — it disappears on input
  and is not reliably exposed to all assistive technologies.
- Required fields must be indicated both visually (asterisk, "required" text)
  and programmatically (`required` attribute or `aria-required="true"`).
- Groups of related inputs (radio buttons, checkboxes) must be wrapped in a
  `<fieldset>` with a `<legend>` describing the group.

### Error Handling

- Error messages must identify the specific field and describe the error in
  text (3.3.1).
- Error messages must be programmatically associated with the input via
  `aria-describedby` or `aria-errormessage`.
- When a form submission produces errors, focus must move to the first error
  or to an error summary that links to each invalid field.
- Error suggestions must be provided when the correction is known (3.3.3).

### Autocomplete

Form fields that collect the following personal information must use the
corresponding `autocomplete` attribute values (1.3.5):

| Data type | `autocomplete` value |
|---|---|
| Full name | `name` |
| Given name | `given-name` |
| Family name | `family-name` |
| Email | `email` |
| Telephone | `tel` |
| Street address | `street-address` |
| Postal code | `postal-code` |
| Country | `country` |
| Credit card number | `cc-number` |
| Username | `username` |
| New password | `new-password` |
| Current password | `current-password` |

<!-- PROJECT: Document which autocomplete values your forms use and any
     custom field mappings. -->

### Accessible Authentication

- Password fields must allow paste. Never disable paste on password inputs —
  this blocks password managers and passkey autofill (3.3.8).
- Authentication flows must not require cognitive function tests (CAPTCHA,
  puzzle-solving, transcription) as the sole mechanism. Provide accessible
  alternatives such as email/SMS verification, passkeys, or WebAuthn.
- Where CAPTCHA is required, provide an audio alternative and support for
  third-party accessibility CAPTCHA providers.

### Custom Interactive Components

If a custom widget is built (dropdown, date picker, dialog, carousel, tab
panel, tree view, accordion), it must:

1. Expose the correct ARIA role, states, and properties.
2. Implement the keyboard interaction pattern defined in the
   [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/).
3. Manage focus correctly (e.g., arrow keys within a tab list, Escape to
   close a dialog, focus trap inside a modal).
4. Have a programmatically determinable accessible name.

<!-- PROJECT: Document your component library and which custom widgets it
     provides. Reference the component library's accessibility documentation
     or conformance claims. -->

---

## 8 · Media & Time-based Content

### Captions

- All pre-recorded video with audio must have synchronised captions (1.2.2,
  Level A). Captions must include dialogue, speaker identification, and
  significant sound effects.
- Live video with audio must have real-time captions (1.2.4, Level AA).
- Captions must be accurate, synchronised, and complete. Auto-generated
  captions must be reviewed and corrected before publication.

### Audio Descriptions

- Pre-recorded video must have audio descriptions for visual information not
  conveyed via dialogue (1.2.5, Level AA). Descriptions are inserted during
  natural pauses in dialogue.

### Transcripts

- Pre-recorded audio-only content must have a text transcript (1.2.1, Level A).
- Transcripts must include all spoken content, speaker identification, and
  descriptions of relevant non-speech audio.

### Media Playback

- Media must not auto-play. If media auto-plays, provide a mechanism to pause,
  stop, or mute within three seconds of page load.
- Media player controls must be keyboard accessible and have accessible names
  (play, pause, mute, volume, captions toggle, full screen).
- Provide a visible captions toggle control on all video players.

---

## 9 · Responsive & Adaptive Design

### Reflow

Content must be presentable without loss of information or functionality and
without requiring two-dimensional scrolling at:

| Scroll direction | Viewport dimension | CSS pixel width |
|---|---|---|
| Vertical scrolling content | Width | 320 CSS pixels |
| Horizontal scrolling content | Height | 256 CSS pixels |

This is equivalent to 400% zoom at a 1280px viewport (1.4.10, Level AA).
Exceptions exist for content where two-dimensional layout is essential (data
tables, maps, diagrams, toolbars).

### Orientation

Content must not be locked to a single display orientation (portrait or
landscape) unless a specific orientation is essential to the content (1.3.4,
Level AA).

### Text Spacing

Content must remain functional and visible when users override the following
text spacing properties (1.4.12, Level AA):

| Property | Override value |
|---|---|
| Line height | ≥ 1.5× font size |
| Paragraph spacing | ≥ 2× font size |
| Letter spacing | ≥ 0.12× font size |
| Word spacing | ≥ 0.16× font size |

Do not use fixed-height containers that clip text when spacing is increased.

### Zoom

All content and functionality must remain usable when the browser is zoomed to
200% (1.4.4, Level AA). No content may be clipped, truncated, or overlapped.

### Touch Targets

Interactive targets must be at least 24×24 CSS pixels, with sufficient spacing
from adjacent targets to prevent accidental activation (2.5.8, Level AA).
Inline links within text are exempt. The target size requirement applies to the
clickable/tappable area, not the visual size of the element.

---

## 10 · Testing & Tooling [CONFIGURE]

Automated testing catches roughly 30–40% of accessibility issues. Manual
testing is mandatory for the remainder.

### Testing Layers

| Layer | Purpose | Tools / approach |
|---|---|---|
| Automated linting | Catch static HTML and ARIA issues in CI | axe-core, eslint-plugin-jsx-a11y, pa11y, Lighthouse |
| Component-level tests | Verify accessible names, roles, and states | Testing Library (`getByRole`, `getByLabelText`), jest-axe |
| Integration / E2E | Test keyboard navigation, focus management, dynamic content | Playwright or Cypress with axe integration |
| Manual keyboard testing | Verify full keyboard operability | Tab through every interactive element; test Enter, Space, Escape, Arrow keys |
| Screen reader testing | Verify announcement, navigation, and interaction | NVDA (Windows), VoiceOver (macOS/iOS), TalkBack (Android) |
| Colour contrast audit | Verify contrast ratios across the palette | Browser dev tools, contrast checker tools, automated scanning |
| Zoom and reflow testing | Verify content at 200% zoom and 320px width | Browser zoom, responsive design mode |

### CI Requirements

- An automated accessibility scan (axe-core or equivalent) must run on every
  pull request and block merge on new violations.
- Component-level accessibility tests must be included in the unit test suite
  and run on every CI build.
- Accessibility scan results must be visible in the PR review interface.

<!-- PROJECT: Specify which automated tools are in your CI pipeline, the
     screen readers your team tests with, and any accessibility testing
     cadence (e.g., full manual audit quarterly). -->

---

## 11 · WCAG 3.0 Forward Look

WCAG 3.0 (W3C Accessibility Guidelines 3.0) is a Working Draft as of
September 2025. It is not expected to reach W3C Recommendation status before
2028. WCAG 2.2 will not be deprecated for several years after WCAG 3.0 is
finalised.

Key changes under development:

| Area | WCAG 2.2 approach | WCAG 3.0 direction |
|---|---|---|
| Conformance model | A / AA / AAA levels (binary pass/fail) | Bronze / Silver / Gold with graduated scoring (0–4 per outcome) |
| Contrast algorithm | Relative luminance formula | APCA (Accessible Perceptual Contrast Algorithm) — perceptually uniform |
| Scope | Web content primarily | Web content, apps, tools, publishing, XR, voice, wearables |
| Structure | 4 principles (POUR), 13 guidelines, 87 success criteria | 12+ functional categories, outcomes-based with technology-specific methods |
| Cognitive accessibility | Limited coverage | Significantly expanded |

**Action:** Monitor WCAG 3.0 progress but do not wait for it. Everything in
this standard remains valid and actionable. Content that meets WCAG 2.2 Level
AA is expected to satisfy most of WCAG 3.0's minimum conformance level
(Bronze).

---

## Non-Negotiables

These rules are absolute and must never be overridden, regardless of
convenience or time pressure:

| # | Rule |
|---|---|
| 1 | **No interactive element without an accessible name.** Every button, link, input, and custom widget must have a programmatically determinable name that describes its purpose. |
| 2 | **No keyboard trap.** Every focusable element must be reachable and escapable via keyboard alone. Focus must never become stuck. |
| 3 | **No colour as sole indicator.** Information conveyed by colour must also be conveyed by text, shape, pattern, or programmatic means. |
| 4 | **No image without a text alternative.** Every `<img>` has meaningful `alt` text, or `alt=""` for decorative images. No missing `alt` attributes. |
| 5 | **No form input without a label.** Every input has a programmatically associated `<label>`, `aria-label`, or `aria-labelledby`. Placeholder text is not a label. |
| 6 | **No custom widget without ARIA and keyboard support.** If you build a custom interactive component, it must expose the correct ARIA role, states, and properties, and implement the expected keyboard interaction pattern. |
| 7 | **No deploy without automated accessibility scan.** CI must include an axe-core (or equivalent) scan that blocks merge on new violations. |

---

## Decision Checklist

Before merging any change that introduces or modifies user interface:

- [ ] **Semantic HTML** — native HTML elements used before ARIA; landmarks,
      headings, and lists structured correctly
- [ ] **Keyboard** — all new interactive elements reachable and operable via
      keyboard; focus order logical; no keyboard traps
- [ ] **Accessible names** — all interactive elements have programmatically
      determinable names (labels, `aria-label`, `aria-labelledby`)
- [ ] **Colour contrast** — text meets 4.5:1 (normal) or 3:1 (large); UI
      components and focus indicators meet 3:1
- [ ] **Focus management** — focus visible at all times; focus not obscured;
      focus moved appropriately after dynamic content changes
- [ ] **Forms** — inputs labelled, errors identified and described, required
      fields indicated, `autocomplete` attributes present on personal data
      fields
- [ ] **Images and media** — `alt` text on images, captions on video,
      transcripts for audio, no auto-playing media
- [ ] **Responsive** — content reflows at 320px width; no horizontal
      scrolling; text spacing overridable
- [ ] **Touch targets** — interactive elements at least 24×24 CSS pixels with
      adequate spacing
- [ ] **Automated scan** — axe-core (or equivalent) passes with no new
      violations
- [ ] **Screen reader spot check** — critical flows verified with at least one
      screen reader
