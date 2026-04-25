# Pets Package

This package exports the pet catalog and pet ability definitions.

## Included Source

- `src/shared/PetConfig.lua`
- `src/shared/PetAbilityConfig.lua`

## What You Override

- pet roster
- rarity
- display colors
- multiplier/passive tuning
- the export-only `custom` field on each pet definition

## `custom` Field

Each pet definition in this export can include:

```lua
custom = {
	projectTag = "Anything",
	skillId = "StormDash",
	onEquipEffect = "SpawnLightningTrail",
}
```

The package does not interpret `custom`; it exists so future projects can attach pet-specific behavior without changing the common schema.

## Transfer Flow

1. Copy the files into the target project.
2. Replace the sample roster with your project roster.
3. Keep the same base keys so inventory/summon packages continue to work.
