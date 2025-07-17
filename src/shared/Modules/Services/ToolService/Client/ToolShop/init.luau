local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Shared.Modules
local Services = Modules.Services

local MenuClient = require(Services.MenuService.Client)

local observeChildren = require(Modules.Utilities.observeChildren)

local SharedData = require(script.Parent.Parent.Data)

local ToolFrame = require(script.ToolFrame)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children = Fusion.Children
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function ToolShopMenu(
	scope: Fusion.Scope<any>,
	props: {
		buyToolAttempt: any,
	}
)
	local menu = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ToolShop")
	local mainFrame = menu:WaitForChild("Main")
	local contentsFrame = mainFrame:WaitForChild("Contents")

	local toolsData = {}
	for i, v: SharedData.ShopToolData in SharedData.ShopTools do
		toolsData[v.Order] = i
	end
	toolsData = scope:Value(toolsData) :: Fusion.Value<{ string }, any>

	local starterGear: StarterGear = Players.LocalPlayer:WaitForChild("StarterGear")

	local toolLimitsReaced = {} :: { [string]: Fusion.Value<boolean, any> }
	for i, _ in SharedData.ShopTools do
		toolLimitsReaced[i] = scope:Value(false)
	end
	table.insert(
		scope,
		observeChildren(starterGear, function(tool: Tool?)
			if not tool:IsA("Tool") then
				return
			end

			local function check()
				if not SharedData.ShopTools[tool.Name] then
					return
				end
				local limitReached = false
				local count = 0
				for _, v in starterGear:GetChildren() do
					if v.Name == tool.Name then
						count += 1
						if count >= SharedData.ShopTools[tool.Name].Limit then
							limitReached = true
							break
						end
					end
				end
				toolLimitsReaced[tool.Name]:set(limitReached)
			end
			check()

			return check
		end)
	)

	local shownVals: { Fusion.Value<boolean, any> } = {}
	scope:Hydrate(contentsFrame)({
		[Children] = scope:ForPairs(
			toolsData,
			function(_, toolScope: Fusion.Scope<any>, index: number, toolName: string)
				local shown = toolScope:Value(false)
				shownVals[index] = shown
				return index,
					ToolFrame(toolScope, {
						toolName = toolName,

						interacted = function()
							props.buyToolAttempt:FireServer(toolName)
						end,

						limitReached = toolLimitsReaced[toolName],
						shown = shown,
					})
			end
		),
	})
	local opened = MenuClient.menus["ToolShop"].opened
	scope:Observer(opened):onBind(function()
		local openedState = peek(opened)
		for _, v in shownVals do
			v:set(openedState)
		end
	end)
end

return ToolShopMenu
