# One-off Wowhead snapshot

Collected on 2026-09-06 at the user's explicit request for a single manual script run. No scheduled collection or live updates. `data/wowhead.json` contains 40 source URLs, guide update dates (2026-08-12 through 2026-09-05), retrieval timestamps, page hashes, exact recommended item IDs/ranks and editorial substitutions. All guides identify Midnight Season 2. This describes the source content, not an independent live-client patch check.

The Restoration Shaman pilot was compared against its guide before expansion. Tables, including alternate columns and rowspan continuations, were reviewed for all specs. Explicit alternatives from prose are recorded in `scripts/prepare_wowhead.py`; negative comparisons, equipment examples and cauldrons are not shopping recommendations. Choices share one PvE list. Recommendation order is not popularity. Conditions still belong to the linked guides.

## Shopping adaptations

- Class runeforges and weapon imbues are spells, not purchasable enchant scrolls. Healthstones and the bound socket item 275707 are excluded.
- Conjured flasks 245933/245931 become their normal rank-2 counterparts 241322/241324.
- Warband-bound food 266996/266985/242744/242747/268679 becomes normal food 255846/255845/242272/242275/255847. Normal food does not preserve the hearty buff through death. These substitutions are explicit per spec in the snapshot.
- All 97 final item IDs have item-page name/rank and binding checks in `data/wowhead_item_checks.json`. No rank families or percentages were invented. Contradictory table/prose health-potion variants remain separate choices.

## Reproduction

`python scripts/import_data.py` rebuilds the checked-in JSON offline and validates temporary Lua before replacing `Data.lua`. It never executes source Lua. The manual collection/preparation/item-check scripts preserve the one-off process; raw cache files are ignored by Git and excluded from packages. Re-running them is not needed to use or build the addon. No API contract or request quota was established, and HTTP 200 does not establish reuse rights. [Wowhead's terms](https://www.wowhead.com/tos) link to [Fanbyte's terms](https://corp.fanbyte.com/legal/terms); the earlier access/reuse findings remain relevant to any future collection or publication.

Runtime changes use existing WoW APIs only. Item names, auction search and the active-spec reset retain their existing behavior. Verification results are in TODO.md.
