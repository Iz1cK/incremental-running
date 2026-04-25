**Purpose**
This file turns the progression design into a concrete rollout plan tied to the current codebase.

**New Shared Configs**
- `src/shared/WorldConfig.lua`
- `src/shared/PrestigeConfig.lua`
- `src/shared/BannerConfig.lua`
- `src/shared/PetAbilityConfig.lua`
- `src/shared/AchievementConfig.lua`
- `src/shared/DailyRewardConfig.lua`
- `src/shared/OfflineProgressConfig.lua`

**Phase 1: World State**
- Add `currentWorldId` to player state and default it to `StarterTrack`.
- Add `worldCurrencies`, `worldUnlocks`, and `worldUpgradeLevels` using the helper constructors from `WorldConfig`.
- Save and load these fields in `FootyenService.legacy.lua`.
- Add helpers:
  - `getCurrentWorld(state)`
  - `getWorldCurrency(state, worldId)`
  - `grantWorldCurrency(state, worldId, amount)`
  - `spendWorldCurrency(state, worldId, amount)`
  - `isWorldUnlocked(state, worldId)`
  - `canUnlockWorld(state, worldId)`

**Phase 2: World Mechanics**
- `StarterTrack`
  - Add combo state on the server.
  - Apply combo multiplier to active running rewards only.
- `MarathonGrove`
  - Add idle zone parts and zone tick payout logic.
  - Scale rewards with `PassivePetWorldBoost` and offline modifiers.
- `BlitzDistrict`
  - Add gate checkpoints and a chain timer.
  - Reward `Charge Sparks` on successful chain extensions.
- `StormArena`
  - Add risk zone parts that apply debuffs plus amplified reward output.
- `CelestialCircuit`
  - Add a timer-driven rotating modifier table and replicate the active modifier to the client.

**Phase 3: Banner Migration**
- Move summon costs from `SummonConfig.Altars` into `BannerConfig`.
- Keep altar proximity UI, but resolve the active banner from the current world.
- Save pity counters in player data.
- Add helpers:
  - `getBannerForCurrentWorld(state)`
  - `getPityState(state, bannerId)`
  - `advancePity(state, bannerId, resultRarity)`
  - `resolveGuaranteedRarity(state, bannerId)`

**Phase 4: Pet Abilities**
- Keep current multiplier and passive logic as the base layer.
- Add `PetAbilityConfig` evaluation on top.
- Start with 4 implemented ability types:
  - `ActiveDistanceBoost`
  - `OfflineGainBoost`
  - `WorldCurrencyBoost`
  - `SprintGainBoost`
- Add synergy calculation after `recalculatePetBonuses(state)`.

**Phase 5: Rebirth**
- Add `lifetimeFootyens`, `footcores`, `rebirthCount`, and `prestigeUpgradeLevels`.
- Track `lifetimeFootyens` whenever Footyens are awarded.
- Add `tryRebirth(player)` callback in Zap.
- On rebirth:
  - award `Footcores`
  - reset the fields listed in `PrestigeConfig.Resets`
  - preserve those in `PrestigeConfig.Persists`

**Phase 6: Retention**
- Offline:
  - save `lastOnlineUnix`
  - compute offline rewards on join
- Daily rewards:
  - save daily reward claim state
  - expose a claim callback through Zap
- Achievements:
  - track progress counters
  - expose claim callbacks through Zap

**Phase 7: UI Surfaces Needed Later**
- world selector / portal interface
- prestige panel
- banner pity indicator
- daily reward popup
- achievements panel
- world currency HUD chip

**Recommended Data Additions**
```lua
currentWorldId = "StarterTrack"
worldCurrencies = {}
worldUnlocks = {}
worldUpgradeLevels = {}
lifetimeFootyens = 0
footcores = 0
rebirthCount = 0
prestigeUpgradeLevels = {}
bannerPity = {}
achievementClaims = {}
dailyRewardState = {}
lastOnlineUnix = 0
petShardInventory = {}
petStars = {}
petEvolutionState = {}
```

**Recommended Build Sequence**
1. `WorldConfig` integration
2. `BannerConfig` + pity
3. `PrestigeConfig`
4. `PetAbilityConfig`
5. offline rewards
6. daily rewards
7. achievements

**Why This Order**
- Worlds and banners are the foundation for progression pacing.
- Rebirth depends on stable long-term earning.
- Pet abilities become more interesting once worlds exist.
- Retention layers are best added after the main loop is stable.
