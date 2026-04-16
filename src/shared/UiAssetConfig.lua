local UiAssetConfig = {}

-- Local file-backed UI art for Script Sync development. Update this base URI if the workspace moves.
UiAssetConfig.FOOTYEN_ICON_URI = "rbxassetid://134840159099471"
UiAssetConfig.FOOTGEM_ICON_URI = "rbxassetid://94766963945790"
UiAssetConfig.PETS_ICON_URI = "rbxassetid://111647636583085"
UiAssetConfig.AUTO_ICON_URI = "rbxassetid://102376239929767"
UiAssetConfig.SUMMON_EGG_URI = "rbxassetid://78469894182138"

UiAssetConfig.PET_IMAGE_URIS = {
	Common = "rbxassetid://94699072162342",
	Angel = "rbxassetid://72979320737957",
	Demonic = "rbxassetid://125536777513127",
	Snowy = "rbxassetid://111647636583085",
	Emerald = "rbxassetid://140229918172296",
	Galactic = "rbxassetid://112596930995681",
}

function UiAssetConfig.getPetImageUri(petId)
	local imageUri = UiAssetConfig.PET_IMAGE_URIS[petId]

	if imageUri == nil then
		error(string.format("Unknown pet image for pet id '%s'", tostring(petId)))
	end

	return imageUri
end

return UiAssetConfig
