local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpinMenu = require(ReplicatedStorage.Shared.Modules.Services.SpinnerService.Client.SpinMenu)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

return {
	story = function()
		local scope = Fusion.scoped(Fusion)
		local slots = {}
		for i = 1, 6 do
			table.insert(slots, {
				Title = "Test" .. i,
				Image = "rbxassetid://123090185953233",
				BottomText = "10%",
			})
		end
		return SpinMenu(scope, {
			native = {},
			slots = slots,

			freeSpinsText = "Spin! (1)",
			canSpin = true,
		})
	end,
}
