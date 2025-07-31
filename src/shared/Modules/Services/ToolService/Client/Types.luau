local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local ClientToolTypes = {}

export type InventoryToolData = {
	Stock: Fusion.Value<number>,
	Equipped: Fusion.Value<boolean>,
}

return ClientToolTypes
