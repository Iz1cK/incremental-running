opt server_output = "shared/ZapServer.lua"
opt client_output = "shared/ZapClient.lua"
opt casing = "PascalCase"
opt remote_scope = "FOOTYEN"
opt remote_folder = "FootyenZap"

event PlayerStateSnapshot = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		footyens: u32,
		footgems: u32,
		totalDistance: f64,
		bootsCollected: u32,
		activeBoots: u8,
		movementSpeedLevel: u8,
		studsPerCurrencyLevel: u8,
		currencyMultiplierLevel: u8,
		bootValueLevel: u8,
		spawnRateLevel: u8,
		maxActiveBootsLevel: u8,
		pickupRadiusLevel: u8,
		bootLifetimeLevel: u8,
		goldenChanceLevel: u8,
		goldenMultiplierLevel: u8,
		movementSpeed: f64,
		studsPerCurrency: f64,
		currencyMultiplier: f64,
		bootValue: f64,
		bootSpawnInterval: f64,
		bootMaxActive: u8,
		bootPickupRadius: f64,
		bootLifetime: f64,
		bootGoldenChance: f64,
		bootGoldenMultiplier: f64,
		petInventoryLimit: u8,
		petEmptySlots: u8,
		petInventoryCount: u8,
		petEquipLimit: u8,
		equippedPetCount: u8,
		petFootyenMultiplier: f64,
		petPassivePerSecond: f64,
		shopHasFootyenGain10x: boolean,
		shopHasMovementSpeed5x: boolean,
		shopHasTripleSummon: boolean,
		shopHasExtraEquipTwo: boolean,
		shopHasLuckySummon: boolean,
		shopHasBootMagnet: boolean,
		shopHasPetPassiveAura: boolean,
		shopExtraPetSlotsCount: u16,
		shopPetPassiveOverclockCount: u8,
		shopBootValueCoreCount: u8,
		isSprinting: boolean,
		sprintEndsAt: f64,
		cooldownEndsAt: f64,
	},
}

event PetInventorySnapshot = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		petInventoryLimit: u8,
		petEmptySlots: u8,
		petInventoryCount: u8,
		petEquipLimit: u8,
		equippedPetCount: u8,
		pets: struct {
			uid: string.utf8(..48),
			petId: string.utf8(..32),
			level: u8(1..5),
			isEquipped: boolean,
		}[..45],
	},
}

event AchievementSnapshot = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		achievementCount: u8,
		completedAchievementCount: u8,
		claimedAchievementCount: u8,
		achievements: struct {
			id: string.utf8(..32),
			displayName: string.utf8(..64),
			description: string.utf8(..160),
			type: string.utf8(..32),
			progress: f64,
			target: f64,
			isComplete: boolean,
			isClaimed: boolean,
			rewardFootgems: u32,
			rewardFootcores: u32,
		}[..32],
	},
}

event LiveConfigSnapshot = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		key: string.utf8(..64),
		payloadJson: string.utf8(..65535),
	},
}

event RequestSprint = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
}

funct GetPlayerState = {
	call: Async,
	rets: struct {
		footyens: u32,
		footgems: u32,
		totalDistance: f64,
		bootsCollected: u32,
		activeBoots: u8,
		movementSpeedLevel: u8,
		studsPerCurrencyLevel: u8,
		currencyMultiplierLevel: u8,
		bootValueLevel: u8,
		spawnRateLevel: u8,
		maxActiveBootsLevel: u8,
		pickupRadiusLevel: u8,
		bootLifetimeLevel: u8,
		goldenChanceLevel: u8,
		goldenMultiplierLevel: u8,
		movementSpeed: f64,
		studsPerCurrency: f64,
		currencyMultiplier: f64,
		bootValue: f64,
		bootSpawnInterval: f64,
		bootMaxActive: u8,
		bootPickupRadius: f64,
		bootLifetime: f64,
		bootGoldenChance: f64,
		bootGoldenMultiplier: f64,
		petInventoryLimit: u8,
		petEmptySlots: u8,
		petInventoryCount: u8,
		petEquipLimit: u8,
		equippedPetCount: u8,
		petFootyenMultiplier: f64,
		petPassivePerSecond: f64,
		shopHasFootyenGain10x: boolean,
		shopHasMovementSpeed5x: boolean,
		shopHasTripleSummon: boolean,
		shopHasExtraEquipTwo: boolean,
		shopHasLuckySummon: boolean,
		shopHasBootMagnet: boolean,
		shopHasPetPassiveAura: boolean,
		shopExtraPetSlotsCount: u16,
		shopPetPassiveOverclockCount: u8,
		shopBootValueCoreCount: u8,
		isSprinting: boolean,
		sprintEndsAt: f64,
		cooldownEndsAt: f64,
	},
}

funct GetPetInventory = {
	call: Async,
	rets: struct {
		petInventoryLimit: u8,
		petEmptySlots: u8,
		petInventoryCount: u8,
		petEquipLimit: u8,
		equippedPetCount: u8,
		pets: struct {
			uid: string.utf8(..48),
			petId: string.utf8(..32),
			level: u8(1..5),
			isEquipped: boolean,
		}[..45],
	},
}

funct GetAchievements = {
	call: Async,
	rets: struct {
		achievementCount: u8,
		completedAchievementCount: u8,
		claimedAchievementCount: u8,
		achievements: struct {
			id: string.utf8(..32),
			displayName: string.utf8(..64),
			description: string.utf8(..160),
			type: string.utf8(..32),
			progress: f64,
			target: f64,
			isComplete: boolean,
			isClaimed: boolean,
			rewardFootgems: u32,
			rewardFootcores: u32,
		}[..32],
	},
}

funct GetLiveConfigSnapshot = {
	call: Async,
	args: string.utf8(..64),
	rets: struct {
		found: boolean,
		payloadJson: string.utf8(..65535),
	},
}

funct SummonPets = {
	call: Async,
	args: struct {
		altarId: string.utf8(..32),
		amount: u8(1..3),
		autoDeletePetIds: string.utf8(..32)[..6],
	},
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
		spentFootgems: u32,
		remainingFootgems: u32,
		results: struct {
			uid: string.utf8(..48),
			petId: string.utf8(..32),
			rarity: string.utf8(..16),
			level: u8(1..5),
			autoDeleted: boolean,
		}[..3],
	},
}

funct PurchaseUpgrade = {
	call: Async,
	args: string.utf8(..32),
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
	},
}

funct PurchaseBootUpgrade = {
	call: Async,
	args: string.utf8(..32),
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
	},
}

funct SetPetEquipped = {
	call: Async,
	args: struct {
		uid: string.utf8(..48),
		equipped: boolean,
	},
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
	},
}

funct DeletePet = {
	call: Async,
	args: string.utf8(..48),
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
	},
}

funct DeletePets = {
	call: Async,
	args: string.utf8(..48)[..45],
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
	},
}

funct UpgradePet = {
	call: Async,
	args: string.utf8(..48),
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
	},
}

funct EquipBestPets = {
	call: Async,
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
	},
}

funct ClaimAchievement = {
	call: Async,
	args: string.utf8(..32),
	rets: struct {
		success: boolean,
		message: string.utf8(..160),
		awardedFootgems: u32,
		awardedFootcores: u32,
	},
}
