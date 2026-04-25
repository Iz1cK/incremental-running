# Inventory Backend Contract

The exported inventory UI expects a store shape and Zap actions, not a specific economy.

## Required Store Fields

- `petInventoryLimit`
- `petEmptySlots`
- `petInventoryCount`
- `petEquipLimit`
- `equippedPetCount`
- `pets`

Each `pets` entry must contain:

- `uid`
- `petId`
- `level`
- `isEquipped`

## Required Zap Actions

- `GetPetInventory`
- `SetPetEquipped`
- `DeletePet`
- `DeletePets`
- `UpgradePet`
- `EquipBestPets`

## Behavioral Expectations

- equipped pets are sorted to the front
- delete mode supports multi-select
- upgrade can be a placeholder if your target project does not support it yet
- equip-best should be server-authoritative

## Best Pairing

This package pairs best with the exported `Pets` package because it already follows the same pet data shape.
