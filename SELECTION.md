# How the 200 were chosen

"Best 200 in the world" cannot be proven. This is a curated 200 with a stated method.

## Method
1. Cloned 24 source repos (official vendor repos, popular community collections, and one aggregator used for discovery only). About 1,900 skills were indexed.
2. Dropped: skills for other stacks (Java, .NET, PHP, Unity, etc.), business and marketing skills, duplicates across repos, and anything in a repo with no license that was not a clear vendor repo.
3. Ranked by: official or well-known source, repo popularity, description clarity, no bundled scripts where possible, no scan hits.
4. Picked per domain by hand to avoid overlap (one best skill per job), with quotas per domain.
5. Pinned every skill to the commit that was current on 2026-11-25.

## Reviewed vs not reviewed
Done for all 200: metadata check (name, description, folder layout), license file detection, an automated scan of SKILL.md and bundled scripts for risky patterns (pipe-to-shell, base64 decode, rm -rf on root paths, prompt-injection phrases, credential paths), and an install test.
Done by hand: the 17 skills that had scan hits. All were documentation examples (security training material, install instructions), not behavior.
NOT done: a line-by-line read of every skill and every script. Quality ranking leans on source reputation and descriptions, not on running each skill. Treat the list as a strong shortlist, not a guarantee.

## Known gaps
- Color, imagery and naming have thin coverage: there are few good open skills for them. They are covered inside the UI/UX and research bundles.
- Removing AI watermarks and provenance marks was left out on purpose.
- Few skills target Nest.js, MongoDB-with-Mongoose or Express specifically. `nestjs-expert` and `nodejs-backend-patterns` cover the Node side.
- Some popular skills are excluded for license reasons (for example claudekit-skills has no license file).

## Updating
Re-run the research, diff the new commits against `manifest.tsv`, read the changes, then update the pinned commit. Do not auto-update.
