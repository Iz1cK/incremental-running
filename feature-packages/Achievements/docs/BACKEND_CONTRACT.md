# Achievements Backend Contract

The achievement UI is portable, but achievement progress and claiming are server-authoritative.

## Required Saved State

- `achievementClaims`
- `footcores`
- `totalSummons`
- `rebirthCount`
- `worldUnlocks`

Already useful if tracked elsewhere:

- `totalDistance`
- `bootsCollected`
- `pets`

## Required Zap Endpoints

- `AchievementSnapshot`
- `GetAchievements`
- `ClaimAchievement`

## Required Store Fields

- `achievementCount`
- `completedAchievementCount`
- `claimedAchievementCount`
- `achievements`

Each achievement entry must contain:

- `id`
- `displayName`
- `description`
- `type`
- `progress`
- `target`
- `isComplete`
- `isClaimed`
- `rewardFootgems`
- `rewardFootcores`

## Required Host Behaviors

- compute progress from real runtime state
- validate that claim is complete
- prevent double claim
- award rewards server-side
- mark state dirty and save after claim

## Current Working Reference

The known-good implementation is the achievement section inside `src/server/FootyenService.legacy.lua`.
