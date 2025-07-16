local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gradients = ReplicatedStorage.Assets.Templates.Gui.Gradients
local Services = ReplicatedStorage.Shared.Modules.Services

local GuiAnimationClient = require(Services.GuiAnimationService.Client)
local PlayerDataClient = require(Services.PlayerDataService.Client)

local ToolShopItemTemp = ReplicatedStorage.Assets.Templates.Gui.ToolShopItem

local SharedData = require(script.Parent.Parent.Parent.Data)

local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

local Gradiented = require(ReplicatedStorage.Shared.Modules.Classes.Gradiented)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function ToolFrame(
	scope: Fusion.Scope<any>,
	props: {
		toolName: string,

		interacted: () -> (),

		limitReached: UsedAs<boolean>,
		shown: UsedAs<boolean>,
	}
)
	local trove = Trove.new()
	table.insert(scope, trove)

	local toolData = SharedData.ShopTools[props.toolName]
	local canBuy = scope:Computed(function(use)
		return use(PlayerDataClient.leaderstats.Rebirths) >= toolData.RebirthsRequired
			and use(PlayerDataClient.leaderstats.Cash) >= toolData.CashCost
			and not use(props.limitReached)
	end)

	local frame: typeof(ToolShopItemTemp) = scope:Hydrate(ToolShopItemTemp:Clone())({
		Name = props.toolName,
		LayoutOrder = scope:Computed(function(use)
			return toolData.Order
		end),
	})
	local con
	con = trove:Add(GuiAnimationClient.AnimatedObjectAdded:Connect(function(obj)
		if obj ~= frame then
			return
		end
		if con then
			con:Disconnect()
			con = nil
		end
		scope:Observer(props.shown):onBind(function()
			GuiAnimationClient.animatedObjects[frame].Size:set(
				peek(props.shown) and ToolShopItemTemp.Size or UDim2.fromScale(1, 0)
			)
		end)
	end))

	local titleLabel = frame:WaitForChild("Title")
	titleLabel.Text = toolData.Title
	local titleGradient = toolData.TitleGradient
	if titleGradient then
		trove:Add(Gradiented.new(titleLabel, titleGradient))
	end

	local descLabel = frame:WaitForChild("Description")
	descLabel.Text = toolData.Description
	local descGradient = toolData.DescriptionGradient
	if descGradient then
		trove:Add(Gradiented.new(descLabel, descGradient))
	end

	local backdrop = frame:WaitForChild("Backdrop")
	local backdropGradient = trove:Add(Gradiented.new(backdrop))

	local moneyLabel = frame:WaitForChild("Money")
	scope:Hydrate(moneyLabel)({
		Text = scope:Computed(function(use)
			return use(props.limitReached) and "MAX" or `${abbreviateNumber(toolData.CashCost)}`
		end),
	})
	local moneyLabelGradient = trove:Add(Gradiented.new(moneyLabel))
	scope:Observer(canBuy):onBind(function()
		backdropGradient.gradient:set(
			if peek(props.limitReached) or not peek(canBuy) then Gradients.RedApple else Gradients.RipeBanana
		)
		moneyLabelGradient.gradient:set(
			if peek(props.limitReached) or not peek(canBuy) then Gradients.RedApple else Gradients.RipeBanana
		)
	end)

	scope:Hydrate(frame:WaitForChild("RebirthLock"))({
		Visible = scope:Computed(function(use)
			return use(PlayerDataClient.leaderstats.Rebirths) < toolData.RebirthsRequired
		end),
		Text = scope:Computed(function(use)
			return `You need {toolData.RebirthsRequired} rebirths`
		end),
	})
	scope:Hydrate(frame:WaitForChild("Icon"))({
		Image = scope:Computed(function(use)
			return toolData.Image
		end),
	})

	scope:Hydrate(frame:WaitForChild("Interact"))({
		Interactable = canBuy,
		[OnEvent("MouseButton1Click")] = function()
			props.interacted()
		end,
	})

	return frame
end

return ToolFrame
