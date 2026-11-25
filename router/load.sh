#!/usr/bin/env bash
# smart-router loader. Fetches skills from their original repos at pinned commits.
# Usage: load.sh <id>...        fetch and print SKILL.md paths
#        load.sh --find <word>  search the index
#        load.sh --domain <d>   print one domain section of INDEX.md
#        load.sh --list-loaded  show cached skills
#        load.sh --all          fallback: fetch all 200 into the cache (usable now, no restart)
#        load.sh --install-all  also copy all 200 into this tool's skills folder (needs restart)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TSV="$HERE/index.tsv"; IDX="$HERE/INDEX.md"
CACHE="${SKILL_ROUTER_CACHE:-$HOME/.cache/skill-router}"
BASE="${SKILLS_GIT_BASE:-https://github.com/}"
if [ "${1:-}" = "--all" ] || [ "${1:-}" = "--install-all" ]; then
  mode="$1"; ids=$(awk -F'\t' 'NR>1{print $1}' "$TSV")
  if ! bash "$HERE/load.sh" $ids; then
    echo "! one or more skills failed to load; see the errors above. Nothing was copied into the tool's skills folder." >&2
    exit 2
  fi
  if [ "$mode" = "--install-all" ]; then
    D="$(dirname "$HERE")"
    for id in $ids; do [ -d "$D/$id" ] || { [ -d "$CACHE/skills/$id" ] && cp -R "$CACHE/skills/$id" "$D/$id"; }; done
    echo "Copied cached skills into $D. They are not registered in the running session yet."
    echo "To register them: Gemini CLI: /skills reload | Claude Code: /reload-skills | Codex, Cursor, Antigravity: start a new session/chat or restart the app."
    echo "Nothing was closed or restarted. Until then, read skills from $CACHE/skills/<id>/SKILL.md."
  fi
  exit 0
fi
case "${1:-}" in
  ""|-h|--help) sed -n 2,7p "$0"; exit 0;;
  --find) shift; [ $# -ge 1 ] || { echo "need a word" >&2; exit 1; }; grep -i -- "$*" "$IDX" | grep -v '^#' || echo "no match"; exit 0;;
  --domain) awk -v d="[$2]" 'index($0,"## "d)==1{p=1;print;next} /^## /{p=0} p' "$IDX"; exit 0;;
  --list-loaded) ls "$CACHE/skills" 2>/dev/null || echo "none"; exit 0;;
esac
command -v git >/dev/null || { echo "git is required" >&2; exit 1; }
mkdir -p "$CACHE/skills"; WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
rc=0
for id in "$@"; do
  line="$(awk -F'\t' -v id="$id" '$1==id{print; exit}' "$TSV")"
  [ -n "$line" ] || { echo "! $id: not in index" >&2; rc=2; continue; }
  IFS=$'\t' read -r _ domain repo path commit license flags <<<"$line"
  dest="$CACHE/skills/$id"
  if [ ! -f "$dest/SKILL.md" ]; then
    cache="$WORK/${repo//\//__}"
    if [ ! -d "$cache" ]; then
      git init -q "$cache"
      git -C "$cache" fetch -q --depth 1 "${BASE}${repo}.git" "$commit" 2>"$WORK/err" || { echo "! $id: fetch failed ($(head -1 "$WORK/err"))" >&2; rm -rf "$cache"; rc=2; continue; }
    fi
    stage="$WORK/s_$id"; mkdir -p "$stage"
    git -C "$cache" archive --format=tar "$commit" "$path" | tar -x -C "$stage" 2>/dev/null || { echo "! $id: path missing at pinned commit" >&2; rc=2; continue; }
    src="$stage/$path"; [ "$path" = "." ] && src="$stage"
    mkdir -p "$dest"; cp -R "$src/." "$dest/"
  fi
  echo "$id  [$license]  $dest/SKILL.md"
  [ "${flags:-0}" = "0" ] || echo "  WARNING: $id had $flags automated scan hit(s). Tell the user and ask before running its scripts."
done
exit $rc
