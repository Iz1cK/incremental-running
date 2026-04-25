# Shop Package

This package exports the current shop UI and offer config so you can reuse the same store across projects.

## Included Source

- `src/client/ShopUi.local.lua`
- `src/shared/ShopConfig.lua`
- `src/shared/UiAssetConfig.lua`

## What You Override

- offer catalog
- Robux prices
- marketplace ids
- featured bundle composition
- icon ids and artwork

The main file you change is `src/shared/ShopConfig.lua`.

## What The Host Game Must Already Have

- `React` and `ReactRoblox`
- `Zap`
- `PlayerStateStore`
- a server authority that owns:
  - purchase validation
  - receipt processing
  - entitlement persistence
  - player state snapshots

## Transfer Flow

1. Copy the files into the target project.
2. Replace marketplace ids in `ShopConfig`.
3. Port the backend contract from `docs/BACKEND_CONTRACT.md`.
4. Keep the UI file as-is if you want the same watermark look.
