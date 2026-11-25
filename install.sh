#!/usr/bin/env bash
# Installs skills from this index. Each skill is downloaded from its original
# GitHub repo at the pinned commit in manifest.tsv. Nothing is copied here.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$ROOT/manifest.tsv"
BASE="${SKILLS_GIT_BASE:-https://github.com/}"

# Prefer a working Python interpreter over command-name presence alone. On
# Windows, python3 may resolve to a Microsoft Store alias that exists but
# cannot be launched from Git Bash.
PYTHON_CMD=()
if [ -n "${SKILLS_PYTHON:-}" ] && "$SKILLS_PYTHON" -c 'import zipfile' >/dev/null 2>&1; then
  PYTHON_CMD=("$SKILLS_PYTHON")
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import zipfile' >/dev/null 2>&1; then
  PYTHON_CMD=(python3)
elif command -v python >/dev/null 2>&1 && python -c 'import zipfile' >/dev/null 2>&1; then
  PYTHON_CMD=(python)
elif command -v py >/dev/null 2>&1 && py -3 -c 'import zipfile' >/dev/null 2>&1; then
  PYTHON_CMD=(py -3)
fi

usage() {
cat <<'EOF'
Usage: ./install.sh <target> (--bundle NAME | --skill ID [--skill ID ...] | --all) [options]

Targets:
  gemini       Gemini CLI       -> ~/.gemini/skills        (project: .agents/skills)
  antigravity  Google Antigravity -> ~/.gemini/config/skills (project: .agents/skills)
  claude-code  Claude Code      -> ~/.claude/skills        (project: .claude/skills)
  codex        OpenAI Codex     -> ~/.agents/skills        (project: .agents/skills)
  cursor       Cursor           -> ~/.cursor/skills        (project: .cursor/skills)
  claude-ai    Claude.ai        -> builds dist/<id>.zip, you upload them in Settings > Skills
  smart        DEFAULT. Installs only the small smart-router skill (+ on-demand loader) for all five local tools
  everything   all five local tools plus Claude.ai zips; installs all 200 skills everywhere

Options:
  --bundle NAME   one of the files in bundles/ (frontend, backend, security, web-fullstack, cloud, ...)
  --skill ID      install one skill (repeatable)
  --all           install all 200 (uses a lot of context, see README)
  everything --all install all 200 for every target above in one command
  --project       install into the current project instead of your home folder
  --force         overwrite a skill that is already installed
  --dry-run       show what would be installed, change nothing
  --list          list bundles and exit
EOF
}

[ $# -ge 1 ] || set -- smart
if [ "$1" = "--list" ]; then
  for f in "$ROOT"/bundles/*.txt; do printf '%-16s %s skills\n' "$(basename "$f" .txt)" "$(wc -l <"$f" | tr -d ' ')"; done; exit 0
fi
case "$1" in -h|--help) usage; exit 0;; esac

case "$1" in --project|--force|--dry-run|--tool) set -- smart "$@";; esac
TARGET="$1"; shift
# smart: install only the router. Other skills are fetched on demand by router/load.sh.
if [ "$TARGET" = "smart" ]; then
  PROJECT=0; FORCE=0; DRY=0; ONLY=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --project) PROJECT=1; shift;;
      --force) FORCE=1; shift;;
      --dry-run) DRY=1; shift;;
      --tool) ONLY="${2:-}"; shift 2;;
      *) echo "Unknown option for smart: $1" >&2; usage; exit 1;;
    esac
  done
  [ -f "$ROOT/router/SKILL.md" ] || { echo "router/ folder missing" >&2; exit 1; }
  for t in gemini antigravity claude-code codex cursor; do
    [ -z "$ONLY" ] || [ "$ONLY" = "$t" ] || continue
    case "$t" in
      gemini)      H="$HOME/.gemini/skills";        P=".agents/skills";;
      antigravity) H="$HOME/.gemini/config/skills"; P=".agents/skills";;
      claude-code) H="$HOME/.claude/skills";        P=".claude/skills";;
      codex)       H="$HOME/.agents/skills";        P=".agents/skills";;
      cursor)      H="$HOME/.cursor/skills";        P=".cursor/skills";;
    esac
    D="$H"; [ "$PROJECT" = 1 ] && D="$P"
    if [ -d "$D/smart-router" ] && [ "$FORCE" = 0 ]; then echo "- $t: smart-router already installed (use --force)"; continue; fi
    if [ "$DRY" = 1 ]; then echo "would install smart-router -> $D/smart-router"; continue; fi
    rm -rf "$D/smart-router"; mkdir -p "$D/smart-router"; cp -R "$ROOT/router/." "$D/smart-router/"; chmod +x "$D/smart-router/load.sh"
    echo "+ $t: smart-router -> $D/smart-router"
  done
  if [ "$DRY" = 0 ] && [ -z "$ONLY" ]; then
    mkdir -p dist/.r/smart-router; cp -R "$ROOT/router/." dist/.r/smart-router/
    rm -f dist/smart-router.zip
    if command -v zip >/dev/null; then (cd dist/.r && zip -qr ../smart-router.zip smart-router)
    elif [ ${#PYTHON_CMD[@]} -gt 0 ]; then "${PYTHON_CMD[@]}" -c "import zipfile,os;os.chdir('dist/.r');z=zipfile.ZipFile('../smart-router.zip','w',zipfile.ZIP_DEFLATED);[z.write(os.path.join(r,f)) for r,_,fs in os.walk('smart-router') for f in fs]"
    else echo "Python with zipfile or the zip utility is required to build the Claude.ai archive." >&2; exit 1; fi
    rm -rf dist/.r
    echo "+ claude-ai: dist/smart-router.zip (upload in Settings > Skills; claude.ai cannot run load.sh, so it can only use the index)"
  fi
  echo
  echo "Done. If smart-router is not visible yet: Gemini CLI: /skills reload; Antigravity CLI: /skills reload or start a new conversation; Antigravity App/IDE: check the Customizations menu. Other tools may need a new session."
  echo "The router fetches other skills on demand into ~/.cache/skill-router (needs git + network); fetched skills are usable from the cache without refreshing the tool."
  exit 0
fi
# Convenience dispatcher for the complete collection on every supported tool.
# Each target still runs through the same installer path and flags.
if [ "$TARGET" = "everything" ]; then
  PROJECT=0; FORCE=0; DRY=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --all) shift;;
      --project) PROJECT=1; shift;;
      --force) FORCE=1; shift;;
      --dry-run) DRY=1; shift;;
      *) echo "Unknown option for everything: $1" >&2; usage; exit 1;;
    esac
  done
  echo "Installing all 200 skills for every target. This can use substantial disk/network and adds many skill descriptions to each tool's context, increasing token use and potentially making skill selection less reliable."
  args=(--all)
  [ "$PROJECT" = 1 ] && args+=(--project)
  [ "$FORCE" = 1 ] && args+=(--force)
  [ "$DRY" = 1 ] && args+=(--dry-run)
  status=0
  for target in gemini antigravity claude-code codex cursor claude-ai; do
    echo
    echo "===== $target ====="
    bash "$0" "$target" "${args[@]}" || status=$?
  done
  exit "$status"
fi
IDS=(); PROJECT=0; FORCE=0; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --bundle) f="$ROOT/bundles/${2:-}.txt"; [ -f "$f" ] || { echo "Unknown bundle: ${2:-}" >&2; exit 1; }
              while IFS= read -r l; do [ -n "$l" ] && IDS+=("$l"); done <"$f"; shift 2;;
    --skill)  IDS+=("${2:-}"); shift 2;;
    --all)    while IFS= read -r l; do [ -n "$l" ] && IDS+=("$l"); done <"$ROOT/bundles/all.txt"; shift;;
    --project) PROJECT=1; shift;;
    --force) FORCE=1; shift;;
    --dry-run) DRY=1; shift;;
    --list) bash "$0" --list; exit 0;;
    *) echo "Unknown option: $1" >&2; usage; exit 1;;
  esac
done
[ ${#IDS[@]} -gt 0 ] || { echo "Pick --bundle, --skill or --all" >&2; exit 1; }

case "$TARGET" in
  gemini)      HOME_DIR="$HOME/.gemini/skills";        PROJ_DIR=".agents/skills";;
  antigravity) HOME_DIR="$HOME/.gemini/config/skills"; PROJ_DIR=".agents/skills";;
  claude-code) HOME_DIR="$HOME/.claude/skills";        PROJ_DIR=".claude/skills";;
  codex)       HOME_DIR="$HOME/.agents/skills";        PROJ_DIR=".agents/skills";;
  cursor)      HOME_DIR="$HOME/.cursor/skills";        PROJ_DIR=".cursor/skills";;
  claude-ai)   HOME_DIR="$PWD/dist";                   PROJ_DIR="$PWD/dist";;
  *) echo "Unknown target: $TARGET" >&2; usage; exit 1;;
esac
if [ "$PROJECT" = 1 ]; then DEST="$PROJ_DIR"; else DEST="$HOME_DIR"; fi
command -v git >/dev/null || { echo "git is required" >&2; exit 1; }

# unique ids, keep order
declare -A SEEN; UNIQ=()
for i in "${IDS[@]}"; do [ -z "${SEEN[$i]:-}" ] && { SEEN[$i]=1; UNIQ+=("$i"); }; done

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
[ "$DRY" = 1 ] || mkdir -p "$DEST"
ok=0; skipped=0; failed=0

make_zip() { # dir name -> dist/name.zip with the folder as top level
  if command -v zip >/dev/null; then (cd "$1" && zip -qr "$DEST/$2.zip" "$2")
  elif [ ${#PYTHON_CMD[@]} -gt 0 ]; then "${PYTHON_CMD[@]}" - "$1" "$2" "$DEST/$2.zip" <<'PY'
import sys,os,zipfile
base,name,out=sys.argv[1:4]
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    for r,_,fs in os.walk(os.path.join(base,name)):
        for f in fs:
            p=os.path.join(r,f); z.write(p,os.path.relpath(p,base))
PY
  else echo "Python with zipfile or the zip utility is required to build skill archives." >&2; return 1
  fi
}

for id in "${UNIQ[@]}"; do
  line="$(awk -F'\t' -v id="$id" '$1==id{print; exit}' "$MANIFEST")"
  if [ -z "$line" ]; then echo "! $id: not in manifest" >&2; failed=$((failed+1)); continue; fi
  IFS=$'\t' read -r _ domain repo path commit license _ <<<"$line"
  if [ "$TARGET" != "claude-ai" ] && [ -d "$DEST/$id" ] && [ "$FORCE" = 0 ]; then
    echo "- $id: already installed (use --force)"; skipped=$((skipped+1)); continue
  fi
  if [ "$DRY" = 1 ]; then echo "would install $id  <- $repo@${commit:0:10}  [$license]"; ok=$((ok+1)); continue; fi
  cache="$WORK/${repo//\//__}"
  if [ ! -d "$cache" ]; then
    git init -q "$cache"
    if ! git -C "$cache" fetch -q --depth 1 "${BASE}${repo}.git" "$commit" 2>"$WORK/err"; then
      echo "! $repo: could not fetch pinned commit ${commit:0:10} ($(head -1 "$WORK/err"))" >&2
      rm -rf "$cache"; mkdir -p "$cache.failed"; failed=$((failed+1)); continue
    fi
  fi
  [ -d "$cache.failed" ] && { failed=$((failed+1)); continue; }
  stage="$WORK/stage_$id"; mkdir -p "$stage"
  if ! git -C "$cache" archive --format=tar "$commit" "$path" | tar -x -C "$stage" 2>/dev/null; then
    echo "! $id: path $path not found at pinned commit" >&2; failed=$((failed+1)); continue
  fi
  src="$stage/$path"; [ "$path" = "." ] && src="$stage"
  if [ "$TARGET" = "claude-ai" ]; then
    mkdir -p "$WORK/zip/$id"; cp -R "$src/." "$WORK/zip/$id/"; rm -f "$DEST/$id.zip"; make_zip "$WORK/zip" "$id"
    echo "+ $id -> $DEST/$id.zip"
  else
    rm -rf "$DEST/$id"; mkdir -p "$DEST/$id"; cp -R "$src/." "$DEST/$id/"
    echo "+ $id -> $DEST/$id  [$license]"
  fi
  ok=$((ok+1))
done
echo
echo "Done: $ok installed, $skipped skipped, $failed failed. Target: $TARGET ($DEST)"
case "$TARGET" in
  gemini)      echo "Restart Gemini CLI or run /skills reload. Gemini asks before activating a skill.";;
  antigravity) echo "Antigravity CLI: run /skills reload or start a new conversation. App/IDE: check the Customizations menu.";;
  claude-code) echo "Start a new Claude Code session; run /skills to check.";;
  codex)       echo "Start a new Codex session.";;
  cursor)      echo "Restart Cursor. Cursor also reads .claude/.agents folders, so installing for several tools can show duplicates.";;
  claude-ai)   echo "Upload each zip in Claude.ai: Settings > Capabilities/Skills. Check manifest notes for size limits.";;
esac
[ "$failed" -eq 0 ] || exit 2
