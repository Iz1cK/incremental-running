# Pets Backend Contract

The pet package defines the data shape the rest of the systems expect.

## Required Saved State

- `pets`
- `nextPetSerial`

Each saved pet should contain:

- `uid`
- `petId`
- `level`
- `isEquipped`

## Recommended Derived Runtime Fields

- `equippedPetCount`
- `totalPetMultiplier`
- `totalPetPassivePerSecond`

## Required Host Behaviors

- create pets with unique ids
- clamp level to configured max
- sort pets consistently
- recalculate bonuses after equip/delete/summon/load
- preserve unknown custom pet metadata at the catalog layer, not the save layer

## Notes

The exported package keeps the same schema used by inventory and summons, so those features will continue to work if you swap in a different roster.
