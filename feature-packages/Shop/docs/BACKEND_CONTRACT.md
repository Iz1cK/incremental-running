# Shop Backend Contract

The exported `ShopUi.local.lua` is already reusable, but the backend in this project currently lives inside the host server authority.

## Required Saved State

Persist these fields:

- `shop.permanentEntitlements`
- `shop.gamePassOwnership`
- `shop.stackableCounts`
- `shop.recordedGamePasses`
- `shop.processedReceipts`
- `shop.processedReceiptOrder`
- `shop.purchaseHistory`

## Required Client Snapshot Fields

Expose these through your player snapshot/store:

- `footyens`
- `footgems`
- `shopHasFootyenGain10x`
- `shopHasMovementSpeed5x`
- `shopHasTripleSummon`
- `shopHasExtraEquipTwo`
- `shopHasLuckySummon`
- `shopHasBootMagnet`
- `shopHasPetPassiveAura`
- `shopExtraPetSlotsCount`
- `shopPetPassiveOverclockCount`
- `shopBootValueCoreCount`

## Required Host Responsibilities

- `MarketplaceService.ProcessReceipt`
- `PromptGamePassPurchaseFinished` sync
- ownership refresh for gamepasses
- purchase history creation for refund/audit purposes
- stackable offer grants
- bundle grants
- entitlement checks used by gameplay systems

## Recommended Extraction Point

In this project, the working reference implementation is the shop section inside `src/server/FootyenService.legacy.lua`. Port those helpers into your target host authority rather than rewriting them.
