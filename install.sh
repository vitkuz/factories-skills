#!/usr/bin/env bash
# Links the shared skills into the project's .claude/skills/, one relative symlink per skill:
#   .claude/skills/<name> -> ../../factories-skills/<name>
# Run it from the project root (the folder holding .claude/ and the three mounts
# factories/, factories-tools/ and factories-skills/):
#   bash factories-skills/install.sh [--dry-run]
# Idempotent. A .claude/skills/<name> that exists and is not that symlink (a project's own
# skill, a local factory's wrapper) is left alone and listed. A link from the old layout
# (-> ../../factories/skills/<name>) is replaced.
set -u

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "install.sh: unknown argument: $arg" >&2; exit 2 ;;
  esac
done

SKILLS_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SKILLS_SRC}/.." && pwd)"
MOUNT_NAME="$(basename "${SKILLS_SRC}")"
SKILLS_DIR="${PROJECT_DIR}/.claude/skills"

if [ ! -d "${PROJECT_DIR}/.claude" ]; then
  echo "install.sh: no .claude/ in ${PROJECT_DIR}: the skills must sit at <project>/factories-skills" >&2
  exit 1
fi

# The three mounts are the contract between the repositories; say exactly what is missing.
missing=""
[ -f "${PROJECT_DIR}/factories/pipeline.schema.json" ] || missing="${missing} factories/ (vitkuz/factories: the pipelines, pipeline.schema.json)"
[ -f "${PROJECT_DIR}/factories-tools/bin/validate.mjs" ] || missing="${missing} factories-tools/ (vitkuz/factories-tools: bin/validate.mjs, bin/state.mjs)"
[ "${MOUNT_NAME}" = "factories-skills" ] || missing="${missing} factories-skills/ (this repository is mounted as ${MOUNT_NAME}/, the skills expect factories-skills/)"
if [ -n "${missing}" ]; then
  echo "install.sh: missing at ${PROJECT_DIR}:" >&2
  for m in ${missing}; do case "$m" in */) echo "  - $m" >&2 ;; esac; done
  echo "  add them with: git submodule add git@github-personal:vitkuz/<name>.git <name>  (factories, factories-tools, factories-skills)" >&2
  [ "${DRY_RUN}" -eq 1 ] || exit 1
fi
if [ "${DRY_RUN}" -eq 0 ]; then mkdir -p "${SKILLS_DIR}"; fi

OLD_PREFIX="../../factories/skills/"
linked=0; relinked=0; kept=0; skipped=0
for skill in "${SKILLS_SRC}"/*/; do
  name="$(basename "${skill}")"
  [ -f "${skill}SKILL.md" ] || continue
  target="../../${MOUNT_NAME}/${name}"
  link="${SKILLS_DIR}/${name}"
  if [ -L "${link}" ] && [ "$(readlink "${link}")" = "${target}" ]; then
    kept=$((kept + 1))
    continue
  fi
  if [ -L "${link}" ] && [ "$(readlink "${link}")" = "${OLD_PREFIX}${name}" ]; then
    if [ "${DRY_RUN}" -eq 1 ]; then
      echo "would relink .claude/skills/${name} -> ${target} (was ${OLD_PREFIX}${name})"
    else
      rm "${link}" && ln -s "${target}" "${link}"
      echo "relink .claude/skills/${name} -> ${target} (was ${OLD_PREFIX}${name})"
    fi
    relinked=$((relinked + 1))
    continue
  fi
  if [ -e "${link}" ] || [ -L "${link}" ]; then
    echo "skip   .claude/skills/${name}: exists and is not this repository's symlink (left as is)"
    skipped=$((skipped + 1))
    continue
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    echo "would link .claude/skills/${name} -> ${target}"
  else
    ln -s "${target}" "${link}"
    echo "link   .claude/skills/${name} -> ${target}"
  fi
  linked=$((linked + 1))
done

if [ "${DRY_RUN}" -eq 1 ]; then
  echo "install.sh (dry run): ${linked} to link, ${relinked} to relink, ${kept} already linked, ${skipped} skipped"
else
  echo "install.sh: ${linked} linked, ${relinked} relinked, ${kept} already linked, ${skipped} skipped"
fi
