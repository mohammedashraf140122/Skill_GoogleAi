# Skill_GoogleAi

An index of 200 agent skills, chosen across web development, design, security, data, databases, DevOps and AWS, with one installer for six tools.

This repo does not contain the skills. Each skill is downloaded from its original author's repo at a pinned commit (see `manifest.tsv`). That keeps licenses and credit with the authors and means nothing changes under you without a deliberate update.

## Quick start (recommended): smart mode

```bash
bash ./install.sh            # same as bash ./install.sh smart
bash ./install.sh smart --project   # into the current project instead
```

This installs one small skill, `smart-router`, for Gemini CLI, Antigravity, Claude Code, Codex and Cursor (and builds `dist/smart-router.zip` for Claude.ai). The other 200 skills are not installed. When a task needs one, the router finds it in its index, downloads it from the original repo at the pinned commit into `~/.cache/skill-router`, reads it, and chains it with others. You type nothing. Before it loads skills it states a short plan, the skills it picked, and one alternative. If it cannot tell which skill fits, it fetches all 200 into the cache (`load.sh --all`) and searches them.

Token cost (estimate, 4 characters per token, not a real tokenizer):

| | Always loaded every turn | Loaded when used |
|---|---|---|
| smart-router | about 95 tokens (name + description) | about 860 (instructions) + about 4,850 if the whole index is read (the router reads only matching lines or one domain, usually a few hundred) |
| all 200 installed | about 19,000 tokens of names and descriptions | each skill body when it triggers |

So the always-on cost drops by roughly 99%.

What each tool can and cannot do. Skills are chosen by the tool's model from the description, so nothing can force the router to run:
- Gemini CLI, Antigravity, Claude Code, Codex, Cursor: the router is matched by description. It may not fire on every task. Say "use smart-router" if it does not.
- Skills fetched on demand are read from the cache path, so they work immediately with no restart. They are not registered with the tool, so the tool does not auto-match them by itself; the router is what reaches them.
- `load.sh --all` returns a failure status if any source cannot be fetched; `--install-all` stops before copying an incomplete set.
- `load.sh --install-all` copies all 200 into the tool's skills folder as a last resort. Those only appear after the tool refreshes or restarts (Gemini: `/skills reload`; others: new session), and they bring back the full token cost.
- The router needs `bash`, `git` and network access, and permission for the tool to run shell commands. If the tool blocks shell commands or is offline, it cannot fetch, and says so.
- Claude.ai cannot run `load.sh`; the zip gives it only the index, so loading skills there is manual (`bash ./install.sh claude-ai --skill ID`).
- Installer checked against a local mirror of every source repo (200 installed, 0 failed) and real GitHub for three skills. The router's on-demand loader was also verified against real GitHub with a pinned skill. It was not activated inside Gemini CLI or Antigravity in this environment.

### Refresh after installing mid-session

The router never closes, kills or restarts your tool or any app, and no script here does. It cannot type slash commands into the host tool either. It does not need a refresh to use a fetched skill, because it reads the skill from `~/.cache/skill-router`. A refresh only matters if you ran `--install-all` and want the tool itself to list the skills. What the tools' docs say (checked 2026-11-25):

| Tool | Register new skills in the running session | Source |
|---|---|---|
| Gemini CLI | type `/skills reload` | geminicli.com/docs/cli/cli-reference |
| Claude Code | usually picks up changes by itself; if not, type `/reload-skills` | code.claude.com/docs/en/commands |
| Codex | start a new session (`codex resume` continues the last one; an open issue reports resumed threads can keep a stale skill list) | github.com/openai/codex/issues/16607 |
| Cursor | skills are found at startup; new ones may not show in an existing chat, so open a new chat or restart | cursor.com/docs/skills |
| Antigravity | CLI: run `/skills reload` or start a new conversation. App/IDE: check the Customizations menu in the agent side panel. | [official Agent Skills docs](https://antigravity.google/docs/skills) |

Automatic close-and-reopen is not implemented. A script running inside the tool cannot safely restart its own host, and doing it would risk unsaved work. If you want it, close and reopen yourself, or use the resume command above.

## Install (manual)

Needs `bash`, `git` (and Python or `zip` for Claude.ai archives). On Windows use WSL or Git Bash.

```bash
git clone https://github.com/mohammedashraf140122/Skill_GoogleAi.git
cd Skill_GoogleAi
bash ./install.sh --list                                 # bundles
bash ./install.sh gemini      --bundle frontend
bash ./install.sh antigravity --bundle web-fullstack
bash ./install.sh claude-code --bundle security
bash ./install.sh codex       --skill supabase --skill playwright
bash ./install.sh cursor      --bundle cloud --project   # into ./.cursor/skills
bash ./install.sh claude-ai   --bundle docs              # builds dist/<skill>.zip to upload
bash ./install.sh everything --all                     # all 200 for every target below
```

| Target | Personal folder | With `--project` |
|---|---|---|
| gemini (Gemini CLI) | `~/.gemini/skills` | `.agents/skills` |
| antigravity | `~/.gemini/config/skills` | `.agents/skills` |
| claude-code | `~/.claude/skills` | `.claude/skills` |
| codex | `~/.agents/skills` | `.agents/skills` |
| cursor | `~/.cursor/skills` | `.cursor/skills` |
| claude-ai | `dist/*.zip` to upload by hand | same |
| smart | router only, all five tools | same paths as above |

Options: `--force` overwrite, `--dry-run` preview, `--all` all 200 for one target. `everything --all` installs all 200 for Gemini CLI, Antigravity, Claude Code, Codex, and Cursor, and builds 200 Claude.ai upload zips. Add `--dry-run` to preview every target or `--force` to overwrite existing installs.

## Bundles

Per domain: frontend, backend, architecture, uiux, a11y, research, data, browser, testing, security, database, devops, aws, tokens, workflow, docs. Combined: `web-fullstack` (113), `cloud` (28), `agent-workflow` (30), `all` (200).

## Context and disk use

`bash ./install.sh everything --all` installs all 200 skills to every listed tool and builds the Claude.ai upload zips. This can use substantial network and disk space. Every installed skill adds its name and description to the model context on each turn, increasing token use; a large catalog can also make skill selection less reliable. Install domain bundles when you do not need the full collection. `agent-workflow` (plan first, explain steps and alternatives, verify before finishing) is a good base for any project.

## Notes

- Selection method and what was and was not reviewed: `SELECTION.md`.
- Licenses and sources: `THIRD_PARTY.md`, `manifest.tsv`. Seven skills have no license file in their source repos and one is under Figma's developer terms. They are listed, never copied.
- Security: `SECURITY.md`. Read a skill before you trust it.
- Cursor also reads `.claude`, `.agents` and `.codex` skill folders, so installing for several tools can show duplicates.
- Claude.ai and Claude Code skills do not sync. Claude.ai may reject a skill whose description is over 1024 characters (`dsql`).
- The installer was tested against a mirror of every source repo (all 200 installed, 0 failed) and against real GitHub for three skills. It was not run inside each tool.
- Tool locations come from each tool's own docs (Gemini CLI, Antigravity, Claude Code, Codex, Cursor), checked 2026-11-25.

Index and installer: MIT. Each skill keeps its own author's license.
