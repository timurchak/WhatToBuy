# Next session

## Completed on 2026-09-06

- Replaced the Archon snapshot with the user's requested one-off Wowhead collection: 40 specs, Midnight Season 2, shared PvE lists, all reviewed alternatives and exact ranks.
- Removed Raid/Mythic+ selection and popularity from the UI and data. Cleared the legacy saved mode. Consumables is the first/default tab, followed by Enchants and Gems; Russian label: `Зачарование`.
- Reviewed table and prose variants, excluded non-purchasable spells/items and recorded normal food/flask substitutions. See `SOURCE_RESEARCH.md` and `data/wowhead.json`.
- Converted the importer to JSON, deterministic Lua and validation before replacement. No scheduled updates, new release, push or tag changes.

## Remaining

- Verify in game after `/reload`: Russian/English labels and ranks, item loading, collapsible groups, scrolling, specialization selection/reset, and search with/without Auctionator.
- No further data collection is requested. Keep the snapshot until the user asks for another update.

## Verification

Lua 5.1 syntax, manifest, all 40 specs and 97 item-page name/rank/binding checks passed. Rebuilding twice is byte-identical; a partial input failed without changing Data.lua. A simulated Lua UI check passed for tab order/default, rank display, spec selection/reset, asynchronous item loading, reused-row search identity and staying open when the auction closes. These are simulated checks, not in-game verification. Deployment and packaging passed; ZIP integrity, exact 12-file runtime inventory and repository/archive/installed byte equality passed.

## Data contract

`ns.Data` schema 2 has `source`, `generatedAtUtc`, and all 40 `specs[specID]`. Each spec directly contains `enchants[slot]`, `gems`, `epicGems`, and `consumables[category]`; every group is an ordered item array. Items have `id`, fallback `name`, and `rank` (0 for unranked). Source metadata, intentional exclusions and substitutions live alongside each spec. No mode nesting or popularity.
