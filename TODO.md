# Next session: independent shopping data source

## Handoff

The addon is working and the user approved the UI. Version `v0.1.0` was published on GitHub; Check and Release workflows succeeded. Development continues on `dev`.

The next task is to investigate Wowhead as a replacement data source and build a Python collector if it provides suitable data. Wowhead is a candidate, not a confirmed source. Research and collector implementation were explicitly deferred to the next session; neither has started.

## Work to do

- [ ] Inspect current Retail Wowhead specialization guides for enchants, gems and consumables. Record actual source URLs, patch/season, update dates and coverage of Mythic+ versus Raid.
- [ ] Determine a supported, accessible way to retrieve the data, including applicable access/reuse terms, structured data and request limits. If access or coverage is insufficient, document the limitation and propose an alternative; do not bypass access controls.
- [ ] Check the distinction between recommended guide choices and measured popularity. Do not invent percentages or portray recommendation order as popularity.
- [ ] Resolve purchasable item IDs, including enchant scrolls rather than spell IDs, gem quality/ranks and consumable variants. Identify any non-auctionable recommendations.
- [ ] Start with one spec as a pilot and compare the extracted choices to its guide before expanding to all supported specs.
- [ ] Implement a small Python collection script under `scripts/`, with spec/mode filters, timeouts, bounded retries, caching and a clear summary of missing data. Keep dependencies and checks minimal.
- [ ] Generate deterministic Lua data with source URLs and timestamps. Validate a temporary output before replacing `Data.lua`; a failed or partial fetch must not erase the working snapshot.
- [ ] Preserve the current schema where practical, or update the UI, importer and validator together. Explicitly represent unavailable modes or categories rather than silently substituting another mode's recommendations.
- [ ] If popularity is unavailable, remove or hide its percentage in rows and tooltips. Update source attribution, snapshot dates, README and CURSE.md to reflect the new source accurately.
- [ ] Validate Lua/data, package, deploy, and check item names, groups, specialization switching and searches with and without Auctionator. Record which checks were performed in game.

## Existing data contract

`Data.lua` assigns `ns.Data` with `source`, `generatedAtUtc` and `specs[specID]`.

Each spec currently has `mythicplus` and `raid`. Each mode contains:

- `enchants[slot]`: ordered item arrays.
- `epicGems` and `gems`: ordered item arrays.
- `consumables[category]`: a single item (the UI also accepts an array).

Items currently contain `id`, fallback `name` and `popularity`. The UI uses localized item names from WoW by ID. The current validator requires 40 specs and all four categories in both modes; review this requirement against verified source coverage.

Keep the working Archon snapshot until the replacement is validated. Do not start a new release or modify the published `v0.1.0` tag as part of research.
