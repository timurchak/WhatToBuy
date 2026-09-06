# WhatToBuy

Small WoW Retail addon for shopping for enchants, gems and consumables. Read `TODO.md` for the next session's work. Keep the addon focused and the documentation short.

## Working conventions

- Use Lua 5.1, two-space indentation, local variables and the `local _, ns = ...` namespace pattern. Access WoW globals through `_G`.
- Use Python 3 for data collection, validation, deployment and packaging.
- Do not add comments to project code or large test suites. Preserve third-party library notices and source files.
- Keep player-facing strings in `Locales.lua` (English and Russian). Keep repository documentation in English.
- Verify current WoW APIs with the WoW API tools and Blizzard UI source. Do not invent APIs or item IDs.
- Edit this repository, then deploy. Never edit the installed addon directly.

## Behavior to preserve

- Native-looking opaque dark panels, warm accents, collapsible item groups and scrolling. The user approved the current styling.
- No unsupported Unicode separators or symbols used as icons; use WoW textures.
- Browsing works without an auction house through `/wtb`, the LibDataBroker/LibDBIcon minimap button and the addon compartment. Keep the window open when the auction house closes.
- The specialization menu selects shopping data for another spec of the player's class. Every window opening resets it to the active spec. Never save this selection or change the character's actual spec.
- Auto search uses Auctionator's public API when available, otherwise native auction search. WoW forces native search. Auctionator is optional; purchase confirmation stays in the auction house.
- Load item names asynchronously by item ID in the client's locale. Preserve stable item identities when reusing rows.

## Data and files

- `Core.lua`: UI, grouping, specialization selection and events.
- `Shopping.lua`: search providers. `Minimap.lua`: standard minimap launcher.
- `Data.lua`: generated from the reviewed one-off `data/wowhead.json` snapshot, collected 2026-09-06; 40 specs, shared PvE recommendations. No mode split or popularity. Preserve all listed alternatives and exact item ranks.
- `scripts/import_data.py`: imports JSON, validates a temporary Lua output, then replaces `Data.lua`. Never execute downloaded Lua. Collection scripts are manual one-off tools, not scheduled jobs.
- `scripts/project.py`: runtime file list for local deployment and ZIP packaging. `.pkgmeta` controls BigWigs release packaging. Keep both consistent.
- `Libs/`: bundled libraries and notices; no runtime dependency on PopularSlotsAndChants.

## Checks and deployment

Install development dependencies with `python -m pip install -r scripts/requirements.txt`.

- `python scripts/validate.py`: Lua 5.1 syntax, manifest and data shape.
- `python scripts/deploy.py`: validate and deploy to `F:\G\World of Warcraft\_retail_`; override with `--wow-root` or `WOW_RETAIL_PATH`.
- `python scripts/package.py`: validate and build `dist/WhatToBuy-<version>.zip`.
- PowerShell wrappers: `scripts/Validate.ps1`, `Deploy.ps1`, `Watch.ps1`, `Package.ps1`.

Run relevant checks after changes; deploy runtime changes and inspect the ZIP after packaging changes. Keep testing proportional. Distinguish simulated checks from in-game verification.

## Git and releases

- Repository: `git@github.com:timurchak/WhatToBuy.git`. Development branch: `dev`; release branch: `main`.
- Published baseline: `v0.1.0`. Never move or overwrite a published tag.
- CurseForge project ID: `1684345`, stored in the TOC. GitHub secret: `CF_API_KEY`; never read or print its value.
- `Check` runs on main/dev pushes and pull requests. `Release` runs on `v*` tags using BigWigs Packager and publishes to GitHub and CurseForge.
- A tag `vX.Y.Z` must match the TOC version. Validate with `python scripts/validate.py --expected-version vX.Y.Z`.
- Pushes, release tags and publishing require authorization for that work; the first-release request does not authorize future releases.
