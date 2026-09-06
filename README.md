# What To Buy

![What To Buy](Media/Logo.png)

Small WoW Retail shopping helper for enchants, gems and consumables. Open `/wtb` or use the button above the auction house. Select Mythic+ or Raid, then search an item. Auto uses Auctionator when available; WoW uses the default auction house. English and Russian UI.

Temporary Archon.gg shopping data is copied from the author's PopularSlotsAndChants addon, dated 2026-08-29. No dependency on that addon. Purchase confirmation stays in the auction house.

- Setup: `python -m pip install -r scripts/requirements.txt`.
- Deploy: `python scripts/deploy.py` (defaults to the local F: WoW installation). Override with `--wow-root` or `WOW_RETAIL_PATH`; add `--watch` for automatic deployment.
- Validate: `python scripts/validate.py`.
- Package: `python scripts/package.py`.
- Replace data: `python scripts/import_data.py PATH_TO_DATA.lua`.

Runtime: `Core.lua`, `Shopping.lua`, `Locales.lua`, `Data.lua`, `Media/Icon.tga`.

CI validates and packages. Tags `vX.Y.Z` must match the TOC version. CurseForge placeholder: set repository variable `CF_PROJECT_ID` and secret `CF_API_KEY` to enable publishing through BigWigs Packager. No remote or public release is configured yet.
