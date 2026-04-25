# Feature Packages

These packages are export kits for projects that use the same baseline as this game:

- Roblox Script Sync layout
- `React` / `ReactRoblox`
- `Zap`
- a shared `PlayerStateStore`
- a server authority layer similar to `FootyenService`

Each package preserves the current UI and config style so you can reuse the same presentation across games as your watermark.

## Packages

- `Shop`
  Keeps the current shop UI, offer config, and backend/save contract.
- `Summons`
  Keeps the current summon altar UI, banner config, altar service, and summon backend contract.
- `Inventory`
  Keeps the current pet inventory UI and documents the runtime contract it expects.
- `Pets`
  Exports the pet catalog/ability system with a reusable `custom` payload on each pet definition.
- `Achievements`
  Keeps the current React achievement screen and the save/claim backend contract.

## How To Use

1. Copy the package `src/*` files into the matching `src/` folders in your target project.
2. Read that package's `README.md`.
3. Apply the package's `docs/BACKEND_CONTRACT.md` items inside your host server authority.
4. If the package includes config files, override those first before touching UI.

## Important Note

These are intentionally exported as source packages, not published Wally packages. That matches your current workflow and keeps them easy to customize per project.
