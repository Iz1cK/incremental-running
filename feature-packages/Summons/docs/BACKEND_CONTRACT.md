# Summons Backend Contract

The current summon UI and altar service are portable, but the summon backend still needs a host authority that owns player state and DataStore writes.

## Required Saved State

- `footgems` or your summon currency
- `pets`
- `nextPetSerial`
- `totalSummons`

Optional but recommended:

- pity counters per banner
- auto-delete preferences per banner

## Required Zap Endpoints

- `SummonPets`
- `GetPlayerState`
- `GetPetInventory`
- `PlayerStateSnapshot`
- `PetInventorySnapshot`

## Required Host Responsibilities

- validate summon request
- validate enough open inventory slots
- validate enough currency
- roll weighted entries
- grant created pets
- apply auto-delete filters
- increment `totalSummons`
- mark state dirty and save

## Current Working Reference

Use the summon flow inside `src/server/FootyenService.legacy.lua` as the known-good backend when porting this package.
