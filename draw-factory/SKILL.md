---
name: draw-factory
description: "Draws a factory's pipeline.json as an SVG diagram, headless, from the terminal: /draw-factory <id|all> [out=<dir|file>]. Writes ./<id>.svg in the repository root by default; `all` draws every factory into ./diagrams/. Only run it when the user invokes it by name or another skill hands off to it, never on your own initiative."
allowed-tools: Read, Glob, Bash
---

# draw-factory

One command in, one `.svg` out. The drawing logic lives in the CLI at
`factories-tools/factory-diagram`; this skill only maps the arguments and reports the file.

    /draw-factory <id|all> [out=<dir|file>] [renderer=native] [view=compact] [theme=light]
                           [format=svg|json] [hide=loops,max,legend,title] [highlight=<slug,…>]
                           [strict] [open]

    /draw-factory sdlc-factory                      → ./sdlc-factory.svg            (repository root)
    /draw-factory sdlc-factory out=docs/diagrams    → ./docs/diagrams/sdlc-factory.svg
    /draw-factory sdlc-factory out=ideas/sdlc.svg   → ./ideas/sdlc.svg
    /draw-factory all                               → ./diagrams/<id>.svg for every factory, plus index.md

## Steps

1. **Resolve the id.** The first word of `$ARGUMENTS` is the factory id, `all`, or a path to a
   `pipeline.json`. If it is missing, list `factories/*/pipeline.json` (Glob) and ask which one —
   never guess.
2. **Make sure the CLI is built.** From the repository root:

       test -f factories-tools/factory-diagram/dist/cli/index.js || (npm --prefix factories-tools/factory-diagram install && npm --prefix factories-tools/factory-diagram run build)

3. **Run it from the repository root**, mapping `name=value` arguments to flags one to one
   (`out=` → `--out`, `renderer=` → `--renderer`, `view=` → `--view`, `theme=` → `--theme`,
   `format=` → `--format`, `hide=` → `--hide`, `highlight=` → `--highlight`; bare `strict` →
   `--strict`, bare `open` → `--open`; `all` → `--all`):

       node factories-tools/factory-diagram/bin/factory-diagram.js <id> [--out <dir|file>] [flags]
       node factories-tools/factory-diagram/bin/factory-diagram.js --all [--out <dir>] [flags]

   The CLI prints the path of every file it wrote on stdout; warnings and errors go to stderr.
4. **Report.** Give the written path(s) back verbatim. If the user asked for `open` and the CLI
   warned that no opener (`wslview`, `xdg-open`) was found, say where the file is instead.
   Pass validator errors and warnings through as printed — they come from the shared
   validator (`factories-tools/bin/validate.mjs`) and name the field at fault.

## Rules

- Never edit a `pipeline.json`. An invalid pipeline is reported, not fixed here.
- Never write outside `out=` or the root default; never pick an output folder yourself.
- The CLI runs with no browser and no network, in well under two seconds per factory. If it
  takes a flag the skill does not know (`--list`, `--root`), pass it through unchanged.
- Not in v1 (the CLI refuses them and says so): `renderer=graphviz|mermaid`, `view=detailed|minimal`,
  `theme=dark|mono`, `format=png|dot|mmd`, `direction=TB`, `run=<runDir>`.
