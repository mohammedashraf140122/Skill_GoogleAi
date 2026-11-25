# Security

A skill is instructions plus optional scripts that your agent runs with your access. A bad skill can leak files or run harmful commands.

- Every skill is pinned to a commit. The installer will not pull newer code.
- Before installing a bundle, open the skill's `url` in `manifest.tsv` and read `SKILL.md` and anything in `scripts/`.
- `bundled_scripts` and `scan_flags` in the manifest show which skills ship code or had scan hits.
- Your tool should ask before running scripts. Do not turn that off for third-party skills.
- Skills that fetch web pages can meet prompt injection from page content. Keep file and network access narrow in sensitive projects.
- Report problems to the skill's original repo.
