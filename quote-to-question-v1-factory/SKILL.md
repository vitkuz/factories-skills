---
name: quote-to-question-v1-factory
description: "Turns one quote into the short living questions it answers (Reverse Q&A): classifies the quote into a semantic core, researches its historical context and the author's underlying question, then in parallel writes the obvious questions and everyday scenes where the quote is the reply, merges the three question lists, judges every question with its own subagent (is the quote a direct answer, and how good), filters by verdict and score and adds short dialogue versions, saves the result into the results repository under the quote id, harness and pipeline id under a three-digit run number, appends lessons for the next run, then syncs the results folder to S3 and records the run on the quote (a top-level processing object keyed by the factory id, step folder to S3 keys, plus category and tags from the semantic core) with the factory's own tools. Only run it when the user invokes it by name, never on your own initiative."
allowed-tools: Read, Write, Glob, Task, AskUserQuestion, Bash, Skill
---

# quote-to-question-v1-factory

This factory is a decoration of the universal `any-factory` skill. Its graph
lives at `factories/quote-to-question-v1-factory/pipeline.json`; nothing here is run
directly.

## No quote given: pick one first

When `$ARGUMENTS` has no `quote=`, pick the quote before the run opens (the quote
and its id name the run folder and the results path), following
`factories/quote-to-question-v1-factory/knowledge/steps/pick-quote.md`:

1. Take the search URL from the arguments (`url=<console /search URL>`, or a bare
   `https://…/search?…` link); none → the tool's `DEFAULT_SEARCH_URL`.
2. From the project root run
   `node factories/quote-to-question-v1-factory/tools/pick-quote/dist/index.js [--url "<url>"]`
   (build it first with `npm ci && npm run build` in its folder if `dist/` is missing).
3. Exit 0 → add `quote=… quoteId=… author=…` from its STDOUT JSON to the
   arguments (drop `url=`), and tell the user which quote was picked. Exit 2 → no
   quote matches: say so and stop. Exit 1 → report the error and stop.

## Run

Invoke the `any-factory` skill (Skill tool) with args:

    quote-to-question-v1-factory $ARGUMENTS

(with the picked quote's params when step "No quote given" ran).

If the Skill tool is unavailable, read `.claude/skills/any-factory/SKILL.md`
and follow it with pipeline id `quote-to-question-v1-factory`.
