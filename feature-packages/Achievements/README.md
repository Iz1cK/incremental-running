# Achievements Package

This package exports the current React achievement screen and the achievement config.

## Included Source

- `src/client/AchievementUi.local.lua`
- `src/shared/AchievementConfig.lua`

## What You Override

- achievement ids
- descriptions
- target values
- reward values
- milestone order

## Transfer Flow

1. Copy the files into the target project.
2. Update the config with your milestone list.
3. Port the backend/save/Zap contract from `docs/BACKEND_CONTRACT.md`.
4. Mount the opener where you want on the left side or keep it unchanged for the same look.
