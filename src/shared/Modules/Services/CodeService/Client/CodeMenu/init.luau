local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Charm = require(ReplicatedStorage.Packages.Charm)

local Hydrate, OnChange, Value = Fusion.Hydrate, Fusion.OnChange, Fusion.Value

local atom = Charm.atom

local function CodeMenu(
	scope: Fusion.Scope<any>,
	props: {
		redeemCodeAttempt: (code: string) -> string,
	}
)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local codesGui = playerGui:WaitForChild("Codes")
	local mainFrame = codesGui:WaitForChild("Main")
	local textBox = mainFrame:WaitForChild("Text"):WaitForChild("TextBox")
	local redeemButton = mainFrame:WaitForChild("Redeem")

	local code = atom("")

	local startPlaceholderText = textBox.PlaceholderText
	local placeholderText = Value(scope, startPlaceholderText)
	Hydrate(scope, textBox)({
		PlaceholderText = placeholderText,
		[OnChange("Text")] = function(newText)
			code(newText)
		end,
	})

	local lastRedeemAttempt = time()
	redeemButton.MouseButton1Click:Connect(function()
		local codeState = code()
		if codeState ~= "" then
			lastRedeemAttempt = time()
			local result = props.redeemCodeAttempt(codeState)
			placeholderText:set(result)
			textBox.Text = ""
		end
	end)

	RunService.Heartbeat:Connect(function()
		if time() - lastRedeemAttempt > 2 then
			placeholderText:set(startPlaceholderText)
		end
	end)
end

return CodeMenu
