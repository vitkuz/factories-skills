# factories-skills

The Claude Code skills of the **factories** kit: `any-factory` (the runner), `create-any-factory`,
`draw-factory`, one wrapper skill per factory, and a few shareable skills that are not factories.
Mounted as a git submodule at `factories-skills/` in every project that uses the kit, beside
`factories/` (the pipelines) and `factories-tools/` (the validator, the recorder, the runners).

```
factories-skills/                this repository, as a project sees it
├── any-factory/                 SKILL.md + runner.md: runs any factory by id with the shared validator and recorder
├── create-any-factory/          drafts, writes and validates a new factory (shared or local)
├── draw-factory/                draws a factory's pipeline.json as an SVG, through factories-tools/factory-diagram
├── <id>/SKILL.md                one wrapper per factory: /<id> hands off to any-factory
├── pishi-sokrashchay/           editing texts by the "Пиши, сокращай" method (not a factory)
├── install.sh                   links every skill folder into the project's .claude/skills/
└── scripts/check-secrets.sh     run before every push
```

The wrappers: `adaptive-research-factory`, `aws-architecture-factory`, `consulting-research-factory`,
`feature-factory`, `mckinsey-research-factory`, `quick-research-factory`, `repurpose-factory`,
`sdlc-factory`, `strategy-research-factory`, `write-articles-factory`. Each wrapper's description says
what its factory does; `/<id> name=value …` runs it.

## The contract between the three repositories

The mount names at the project root are the contract, the same in every project:

| Mount | Repository | Holds |
|---|---|---|
| `factories/` | `vitkuz/factories` | `<id>/pipeline.json` and knowledge, `pipeline.schema.json`, `state.schema.json`, hook scripts |
| `factories-tools/` | `vitkuz/factories-tools` | `bin/validate.mjs`, `bin/state.mjs`, `bin/xstate-runner.mjs`, the runners, the diagram CLI, the Studio, ai-usage |
| `factories-skills/` | `vitkuz/factories-skills` | this repository |

The skills call `node factories-tools/bin/validate.mjs` and `node factories-tools/bin/state.mjs`,
read `factories/<id>/pipeline.json` (or the project's own `factories.local/<id>/pipeline.json`),
and never reach into a repository by any other path. `install.sh` checks that all three mounts are
there and says exactly what is missing.

## Add to a project

From the project root (the folder holding `.claude/`):

```sh
git submodule add git@github-personal:vitkuz/factories.git factories
git submodule add git@github-personal:vitkuz/factories-tools.git factories-tools
git submodule add git@github-personal:vitkuz/factories-skills.git factories-skills
bash factories-skills/install.sh        # .claude/skills/<name> -> ../../factories-skills/<name>
node factories-tools/bin/validate.mjs   # lists the ids
git add .gitmodules factories factories-tools factories-skills .claude/skills
git commit -m "Add the factories kit"
```

A fresh clone of the project: `git clone --recurse-submodules …` and `bash factories-skills/install.sh`
once. `install.sh` is idempotent: it never overwrites a `.claude/skills/<name>` that is not already
its own symlink (a project's own skill, a local factory's wrapper — it lists those and goes on), and
it replaces a link from the old layout (`../../factories/skills/<name>`). `--dry-run` shows what it
would do.

`feature-factory` takes the project's `tenant`, `project`, `awsAccount`, `awsProfile` as params;
a project usually keeps a real `.claude/skills/feature-factory/SKILL.md` of its own that passes
them, and `install.sh` leaves it alone.

## Update in a project

```sh
git submodule update --remote factories factories-tools factories-skills
bash factories-skills/install.sh        # new wrapper skills, if any
git add factories factories-tools factories-skills .claude/skills && git commit -m "Bump the factories kit"
```

## Add a factory

`/create-any-factory <description of the steps>` drafts, writes and validates it. A **shared**
factory takes two commits: the graph `factories/<id>/` in the kit and the wrapper
`factories-skills/<id>/SKILL.md` here (then the two submodule pointers and the symlink in the project).
A **local** factory (`local=true`) is `factories.local/<id>/` plus a real `.claude/skills/<id>/` in the
project only. The rules a pipeline follows: `create-any-factory/SKILL.md`; how a run is walked:
`any-factory/runner.md`.

Before every push: `bash scripts/check-secrets.sh`. This repository is public: a skill names no
project, no account, no person.

## License

MIT, see `LICENSE`.
