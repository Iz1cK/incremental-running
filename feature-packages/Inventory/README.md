# Inventory Package

This package exports the current pet inventory UI.

It is intentionally UI-first because that is the most reusable part. The backend is already documented so you can plug it into whatever pet runtime you use in future projects.

## Included Source

- `src/client/PetInventoryUi.local.lua`
- `src/shared/PetConfig.lua`
- `src/shared/UiAssetConfig.lua`

## What You Override

- slot counts via `PetConfig`
- pet catalog/images
- button labels and helper copy if you want

## Recommended Use

Use this package together with the exported `Pets` package and, if needed, the `Summons` package.

## Transfer Flow

1. Copy the files into the target project.
2. Port the inventory snapshot/actions from `docs/BACKEND_CONTRACT.md`.
3. Keep the UI if you want the same look, or restyle it while keeping the same data contract.
