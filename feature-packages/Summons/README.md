# Summons Package

This package exports the current summon altar UI, banner config, and altar world builder.

## Included Source

- `src/client/PetSummonUi.local.lua`
- `src/server/SummonAltarService.legacy.lua`
- `src/shared/SummonConfig.lua`
- `src/shared/BannerConfig.lua`
- `src/shared/UiAssetConfig.lua`

## What You Override

- altar definitions
- banner pools
- summon costs
- rarity weights
- pity values if your target project adds them
- summon artwork

The primary config files are:

- `src/shared/SummonConfig.lua`
- `src/shared/BannerConfig.lua`

## What The Host Game Must Already Have

- a pet catalog
- pet inventory persistence
- Footgem or local-currency spend logic
- Zap summon calls
- player state snapshots

## Transfer Flow

1. Copy the source files into the target project.
2. Adjust banner and altar config.
3. Port the summon backend contract from `docs/BACKEND_CONTRACT.md`.
4. If the target game uses a different premium currency, change the spend/grant text and backend spend function together.
