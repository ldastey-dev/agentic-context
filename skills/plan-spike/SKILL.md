---
name: plan-spike
description: "Run a timeboxed technical investigation producing findings, proof of concept recommendations, and go/no-go decision framework"
allowed-tools: "Read, Grep, Glob, Bash(git *), Write, Agent"
---

# Spike / Technical Research

## Role

You are a **Senior Engineer** conducting a timeboxed technical spike to reduce uncertainty. Your output is a structured research report with findings, proof-of-concept results, and a clear recommendation -- enabling the team to make an informed build decision.

---

## Objective

Investigate a specific technical question or uncertainty that is blocking a design or implementation decision. The spike is timeboxed, hypothesis-driven, and produces evidence -- not production code. The goal is to reduce risk by turning unknowns into knowns before the team commits effort to an approach.

---

## Phase 1: Discovery

Before investigating anything, establish the boundaries of the spike. Clarify and document:

- **Research question** -- what specific question must this spike answer? State it as a testable hypothesis.
- **Context** -- why does this question matter now? What decision is blocked? What is the cost of choosing wrong?
- **Constraints** -- technology boundaries, team skills, budget, compliance requirements, existing architecture commitments.
- **Success criteria** -- what evidence would constitute a satisfactory answer? What level of confidence is needed?
- **Timebox** -- how much time is allocated? A spike without a timebox is not a spike -- it is unbounded research.
- **Scope boundaries** -- what is explicitly out of scope? What rabbit holes must be avoided?
- **Stakeholders** -- who needs the output and what format do they expect?

Do not begin investigation until the research question and timebox are clearly defined. A vague question produces vague answers.

---

## Phase 2: Investigation

Work through each step methodically. Document findings as you go -- do not rely on memory.

### 2.1 Research Question

State the specific question(s) this spike must answer as testable hypotheses. Good research questions are:

- **Falsifiable** -- there must be a way to prove the hypothesis wrong.
- **Scoped** -- narrow enough to answer within the timebox.
- **Decision-relevant** -- the answer directly unblocks a specific decision.

| Aspect | What to investigate |
|---|---|
| Primary hypothesis | The core claim to validate or refute |
| Secondary questions | Related questions that may be answered along the way |
| Null hypothesis | What would it mean if the hypothesis is false? What is the fallback? |
| Decision impact | Which design/implementation decision does this unblock? |

### 2.2 Prior Art

Before building anything, survey what already exists. Investigate and document:

| Aspect | What to investigate |
|---|---|
| Existing solutions | Libraries, frameworks, managed services, or SaaS products that solve this problem |
| Community patterns | Blog posts, conference talks, GitHub repositories, Stack Overflow discussions |
| Official documentation | Vendor docs, RFCs, specifications, API references |
| Internal precedent | Has this team or organisation solved a similar problem before? What was the outcome? |
| Known pitfalls | Documented failure modes, performance caveats, version incompatibilities |

Capture sources with links. Do not trust summaries -- verify claims against primary sources.

### 2.3 Options Identification

Enumerate the candidate approaches. For each option, provide:

| Aspect | What to investigate |
|---|---|
| Option name | A short, descriptive label |
| Description | What the approach involves at a high level |
| Key dependencies | Libraries, services, or infrastructure required |
| Theoretical fit | Why this option might work based on prior art |
| Known concerns | Red flags or risks identified before testing |

Aim for three to five viable options. If fewer than two exist, the spike may be premature. If more than five exist, narrow before proceeding.

### 2.4 Proof of Concept

For each viable option, build the minimum experiment needed to answer the research question. Document:

| Aspect | What to investigate |
|---|---|
| What was built | Describe the PoC -- what it does, how it was set up |
| Environment | Runtime, versions, hardware, configuration |
| Test scenario | The specific scenario exercised and why it is representative |
| Results | Observed behaviour, performance data, error rates, resource consumption |
| Code snippets | Key implementation fragments (not full listings -- enough to evaluate the approach) |
| Surprises | Anything unexpected -- positive or negative |
| Time spent | How much of the timebox this option consumed |

Keep proof-of-concept code disposable. Its purpose is to produce evidence, not to be promoted to production. If you find yourself polishing PoC code, you have left the spike.

### 2.5 Evaluation Criteria

Score each option against a consistent set of criteria. Use a 1-5 scale (1 = poor, 5 = excellent):

| Criterion | Description |
|---|---|
| Complexity | Implementation effort and cognitive overhead |
| Performance | Throughput, latency, resource efficiency under expected load |
| Maintainability | Long-term cost of ownership, readability, testability |
| Team familiarity | How well the team knows this technology or pattern |
| Ecosystem maturity | Community size, release cadence, documentation quality, long-term viability |
| Cost | Licensing, infrastructure, and operational cost |
| Risk | Probability and impact of failure, lock-in, migration difficulty |

Produce a scored comparison matrix in the report (see Report Format below).

### 2.6 Constraints Discovered

During investigation, unknowns become knowns and new constraints emerge. Document:

| Aspect | What to investigate |
|---|---|
| Resolved unknowns | Questions that were open before the spike and are now answered |
| New constraints | Limitations discovered during investigation that were not anticipated |
| Invalidated assumptions | Assumptions from the original brief that turned out to be incorrect |
| Dependency risks | External dependencies that introduce risk (version pinning, vendor lock-in, deprecation) |
| Regulatory or compliance findings | Any data-handling, licensing, or compliance concerns surfaced |

This section is as valuable as the recommendation itself. Constraints discovered late in a project are expensive -- constraints discovered during a spike are cheap.

---

## Report Format

Structure the research report exactly as follows:

### Summary

One paragraph that directly answers the research question. State the recommended approach and confidence level. A senior engineer should be able to read this paragraph alone and understand the conclusion.

### Research Question

Restate the research question as defined in Phase 1 -- including hypotheses and success criteria.

### Timebox

| Field | Value |
|---|---|
| Allocated | Hours or days originally budgeted |
| Spent | Actual time consumed |
| Variance | Over/under and brief explanation |

### Options Evaluated

| Option | Description | Verdict |
|---|---|---|
| Option A | Brief description | Recommended / Viable / Rejected |
| Option B | Brief description | Recommended / Viable / Rejected |
| Option C | Brief description | Recommended / Viable / Rejected |

### Detailed Findings

For each option evaluated, provide:

| Field | Description |
|---|---|
| **Option** | Name and brief description |
| **What was tried** | PoC approach, setup steps, configuration |
| **Results** | Observed behaviour, measurements, outputs |
| **Evidence** | Code snippets, benchmark data, screenshots, logs |
| **Verdict** | Recommended / Viable / Rejected -- with justification |

### Comparison Matrix

| Criterion | Option A | Option B | Option C |
|---|---|---|---|
| Complexity (1-5) | | | |
| Performance (1-5) | | | |
| Maintainability (1-5) | | | |
| Team familiarity (1-5) | | | |
| Ecosystem maturity (1-5) | | | |
| Cost (1-5) | | | |
| Risk (1-5) | | | |
| **Total** | | | |

Higher scores are better. Weight criteria by importance if the team has agreed on priorities.

### Recommendation

| Field | Description |
|---|---|
| **Recommended option** | The approach to proceed with |
| **Confidence level** | High / Medium / Low -- with justification |
| **Key trade-offs** | What is being accepted by choosing this option |
| **Conditions** | Circumstances under which this recommendation would change |

### Open Questions

Bullet list of questions that remain unanswered after the spike. For each, note:

- The question itself
- Why it could not be answered within the timebox
- The risk of proceeding without an answer
- Suggested approach to resolve it

### Next Steps

Ordered list of concrete actions to take if the recommendation is accepted:

1. Immediate actions -- what to do in the next sprint
2. Design work -- what needs to be designed before implementation begins
3. Dependencies -- what must be in place before the team can start
4. Validation -- how to confirm the approach works at production scale

### Artefacts

| Artefact | Location |
|---|---|
| PoC code | Link to branch, repository, or directory |
| Benchmark results | Link to data or report |
| Screenshots / recordings | Link to visual evidence |
| Reference material | Links to key documentation consulted |

All artefacts must be accessible to the team. Do not reference local files that others cannot reach.

---

## Phase 3: Recommendation

Synthesise findings into a clear, actionable recommendation. This phase is the reason the spike exists -- everything prior is in service of this output.

1. **State the recommendation plainly.** One sentence: "We should use X because Y."
2. **Quantify confidence.** High -- strong evidence supports this choice. Medium -- evidence is favourable but gaps remain. Low -- insufficient evidence; further investigation needed.
3. **Acknowledge trade-offs.** Every option has downsides. Name them explicitly so the team is not surprised later.
4. **Define the decision boundary.** Under what conditions should the team revisit this decision? What signals would indicate the chosen approach is failing?
5. **Propose next steps.** If the recommendation is accepted, what are the first three concrete actions?
6. **Identify what to kill.** If options were rejected, state clearly that the team should not revisit them unless circumstances change -- and specify which circumstances.

If the spike did not produce enough evidence to make a recommendation, say so. A spike that honestly reports "we don't know yet" is more valuable than one that guesses.

---

## Execution Protocol

1. Confirm the research question and timebox before starting investigation.
2. Work through Phase 2 sections in order -- do not skip prior art research.
3. Allocate timebox across options proportionally. Do not spend 80% of the timebox on the first option and rush the rest.
4. Document findings continuously. Do not rely on reconstructing results from memory at the end.
5. Stop when the timebox expires. Produce the report with whatever evidence has been gathered.
6. If the timebox is insufficient, report that finding -- do not silently extend the spike.
7. PoC code is disposable. Do not refactor it, do not write tests for it, do not merge it.
8. Present findings to stakeholders within one working day of the timebox expiring.

---

## Guiding Principles

- **Evidence over intuition.** Gut feelings are hypotheses, not conclusions. Every claim in the report is backed by something you built, measured, or read.
- **Timebox is sacred.** A spike that runs indefinitely is not a spike -- it is unplanned work. Respect the boundary and report what you have.
- **Dispose of the PoC.** Proof-of-concept code exists to produce evidence. It is not a head start on implementation -- treat it as throwaway.
- **Unknowns are findings.** Discovering that something cannot be answered within the timebox is a legitimate and valuable result. Report it clearly.
- **Narrow beats broad.** A deep investigation of two options is more useful than a shallow survey of ten. Focus produces evidence; breadth produces opinions.
- **Honesty over advocacy.** Report what you found, not what you hoped to find. If the favoured option performed poorly, say so.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Investigation) and produce the full report.
