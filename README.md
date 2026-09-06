# What To Buy

![What To Buy](Media/Logo.png)

Small WoW Retail shopping helper for enchants, gems and consumables. Open `/wtb`, the addon menu beside the minimap, or the button above the auction house. Browse without an auction house; searching requires one. Items are grouped into collapsible sections with a scrollbar. Choose a category, then search an item. Auto uses Auctionator when available; WoW uses the default auction house. English and Russian UI.

A one-off Wowhead guide snapshot collected on 2026-09-06 covers 40 specializations. PvE recommendations share one list, with all selected alternatives and item ranks; no popularity percentages. Purchase confirmation stays in the auction house.

Source URLs, guide dates, exclusions and shopping substitutions are stored in `data/wowhead.json`; see [SOURCE_RESEARCH.md](SOURCE_RESEARCH.md). There are no automatic data updates.

- Setup: `python -m pip install -r scripts/requirements.txt`.
- Deploy: `python scripts/deploy.py` (defaults to the local F: WoW installation). Override with `--wow-root` or `WOW_RETAIL_PATH`; add `--watch` for automatic deployment.
- Validate: `python scripts/validate.py`.
- Package: `python scripts/package.py`.
- Rebuild the reviewed snapshot offline: `python scripts/import_data.py` (JSON input; validates before replacement).

The draggable minimap button opens the list anywhere and remembers its position. LibDataBroker and LibDBIcon are bundled; no other addon is required.

Click the specialization name in the header to shop for another specialization of your class. Every time the window opens, it defaults to your active specialization. The selection is not saved and does not change your character's specialization.

Runtime: `Core.lua`, `Shopping.lua`, `Minimap.lua`, `Locales.lua`, `Data.lua`, `Media/Icon.tga`, `Libs/`.

CI validates and packages. Tags `vX.Y.Z` must match the TOC version. Releases publish to GitHub and CurseForge project `1684345` through BigWigs Packager using the repository secret `CF_API_KEY`. The project ID is stored in the TOC.
