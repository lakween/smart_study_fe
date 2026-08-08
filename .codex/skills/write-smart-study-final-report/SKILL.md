---
name: write-smart-study-final-report
description: Produce, revise, audit, or plan the Smart Study CIS017-3 Undergraduate Thesis Report using the project repository, final-report guidelines, sample thesis, proposal, contextual report, reflective report, and screenshots. Use for thesis chapters, report structure, evidence gathering, Harvard-style citation planning, objective evaluation, test/result reporting, appendices, plagiarism-safe synthesis, simple natural student English, and DOCX-ready final-report content for this Smart Study Flutter/FastAPI project.
---

# Write the Smart Study Final Report

Create an academically defensible report from verified project evidence. Treat earlier student reports as historical inputs, never as text to paraphrase mechanically.

## Start every report task

1. Work from the Flutter root containing `pubspec.yaml` and `lib/main.dart`.
2. Read [source-priority.md](references/source-priority.md) before drafting or reviewing any substantive section.
3. Read [report-blueprint.md](references/report-blueprint.md) for structure, lengths, formatting, and section-specific requirements.
4. Run `python .codex/skills/write-smart-study-final-report/scripts/check_report_sources.py` when source coverage may have changed.
5. Inspect relevant live source, tests, repository documentation, backend code, screenshots, and Git evidence before describing implementation or results.
6. Create a claim ledger for the requested section: claim, evidence path, evidence date/status, citation required, and confidence.

## Resolve evidence conflicts

Apply this order:

1. Current 2026 lecturer guidelines and assignment requirements govern the submission.
2. Live Flutter/FastAPI repositories, tests, deployed configuration, and current screenshots govern what was actually built.
3. The approved proposal governs the original aim, objectives, deliverables, and planned risks.
4. Contextual and reflective reports provide research context, survey results, design history, challenges, and earlier decisions.
5. The sample thesis demonstrates presentation depth and organization only; it is not a factual source for Smart Study.

Flag contradictions instead of blending them. Do not repeat historical Flask, Provider, partial-implementation, speculative load-balancing, or planned-feature claims when current evidence shows FastAPI, Riverpod, completed functionality, a changed implementation, or no implementation.

## Draft with academic integrity

- Build a fresh outline around Smart Study's research problem, objectives, artefact, evidence, and results.
- Extract facts into short notes, set the source aside, then write new analysis from those notes. Change argument structure and synthesis, not only vocabulary.
- Cite the original scholarly or authoritative source for external claims. Do not cite the sample report as authority.
- Use direct quotations only when necessary, keep them short, use quotation marks, and cite them.
- Never invent references, participant counts, survey results, test outcomes, performance values, dates, diagrams, screenshots, supervisor feedback, or deployed capabilities.
- Preserve exact technical names, API paths, algorithms, measured values, objective wording, and attributed quotations where accuracy requires them.
- Distinguish `planned`, `implemented`, `tested`, `observed`, and `recommended`.
- Maintain a citation ledger and a reuse ledger for content derived from the student's earlier reports. Self-authored prior work may still require disclosure or citation under institutional policy.
- Include an accurate AI-use declaration if required. Never claim the work was written without AI assistance when it was not.

## Match the student's writing voice

- Write in clear, simple English that a Sri Lankan undergraduate student can understand, explain, and defend during the viva.
- Prefer common words, direct sentences, and moderately short paragraphs. Use technical terms only when the project requires them, and explain unfamiliar terms briefly.
- Keep the tone formal enough for an undergraduate thesis, but do not make it sound like a journal written by a senior researcher.
- Avoid inflated vocabulary, repetitive transitions, generic academic filler, exaggerated claims, and overly polished marketing language.
- Vary sentence and paragraph length naturally while keeping the argument easy to follow.
- Preserve the student's meaning and project experience. Ask for personal details when a reflective or decision-based statement cannot be established from evidence.
- Keep grammar readable and consistent. Do not introduce deliberate grammar, spelling, punctuation, or factual mistakes to imitate a person.
- Do not optimize prose to bypass AI detectors or promise that a detector will classify it as human. Focus on original reasoning, project-specific evidence, accurate citations, transparent AI disclosure, and the student's final review.
- Draft one manageable section at a time and allow the student to rewrite phrases into their own everyday wording before final submission.

## Describe completion and testing honestly

- Describe the application as complete only after checking the agreed scope against the live Flutter and FastAPI repositories.
- State that testing is complete only when the relevant test suites and required manual scenarios have evidence. Report the commands, environment, date when available, scope, actual result, and any excluded or blocked checks.
- Use qualified wording such as `completed within the defined project scope` when optional production-scale capabilities remain outside the project.
- Do not convert a passing automated test suite into unsupported claims about usability, learning improvement, AI accuracy, high concurrency, security, or production reliability.
- Record known limitations and unresolved defects even when the main artefact and planned tests are complete.

## Write the report as an argument

- Make the Introduction a forward view: problem, motivation, research questions, aim, objectives, scope, contribution, and report map.
- Make the Literature Review critical and thematic. Compare evidence, limitations, and applicability; end with the research gap.
- Explain design decisions and rejected alternatives. Link choices to requirements, research, constraints, or tests.
- Describe development by coherent modules and architectural flows, not as a diary.
- Report test conditions, inputs, expected results, actual results, and status. Relate tests to requirements.
- Separate Results from Evaluation where practical. Results state what happened; Evaluation explains significance, limitations, implications, success against each objective, and improvements.
- Make the Conclusion a backward view that answers the aim and objectives using earlier evidence. Introduce no new results.

## Use visuals purposefully

- Give every figure, table, listing, and screenshot a number, descriptive caption, and explicit reference in the text.
- Explain what the reader should notice and why it matters.
- Use the seven images in `docs/final_report/project screenshots/` as candidate evidence for the dashboard, subject/topic hierarchy, revision state, exams, and friends flows. Verify current UI before asserting completeness.
- Prefer architecture, ER, sequence, use-case, traceability, test-result, and objective-evaluation tables when clearer than prose.
- Put large evidence sets in appendices and cite each appendix from the main body.

## Review before delivery

Check that every objective traces to implementation, tests, evaluation, and conclusion; every number and completion claim has a source; technologies match the repository; results and feedback are not fabricated; limitations receive proper analysis; citations and references match; captions and terminology are consistent; and prose is substantially original rather than sentence-by-sentence paraphrasing.

Do not promise that text will evade plagiarism detection. Report similarity risk honestly and recommend an institutional similarity check plus human review.
