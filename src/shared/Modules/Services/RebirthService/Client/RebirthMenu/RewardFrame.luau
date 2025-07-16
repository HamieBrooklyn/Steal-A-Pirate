local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RewardTemp = ReplicatedStorage.Assets.Templates.Gui.Rebirth.Reward

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Gradiented = require(ReplicatedStorage.Shared.Modules.Classes.Gradiented)

type UsedAs<T> = Fusion.UsedAs<T>

local function RewardFrame(
	scope: Fusion.Scope<any>,
	props: {
		shown: UsedAs<boolean>?,

		titleText: UsedAs<string>?,
		infoText: UsedAs<string>?,

		titleGradient: UsedAs<UIGradient?>,
		infoTextColor: UsedAs<Color3>?,

		image: UsedAs<string>?,
	}
)
	local frame: typeof(RewardTemp) = scope:Hydrate(RewardTemp:Clone())({
		Visible = props.shown,
	})

	local titleLabel = frame:WaitForChild("Title")
	scope:Hydrate(titleLabel)({
		Visible = props.titleText ~= nil,
		Text = props.titleText,
	})
	if props.titleGradient then
		local gradiented = Gradiented.new(titleLabel, props.titleGradient)
		table.insert(scope, gradiented)
	end

	local infoLabel = frame:WaitForChild("Info")
	scope:Hydrate(infoLabel)({
		Visible = props.infoText ~= nil,
		Text = props.infoText,
		TextColor3 = props.infoTextColor,
	})

	scope:Hydrate(frame:WaitForChild("Icon"))({
		Image = scope:Computed(function(use)
			return use(props.image) and use(props.image) or ""
		end),
	})

	return frame
end

return RewardFrame
