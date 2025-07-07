local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestLabelTemp = ReplicatedStorage.Assets.Templates.Gui.QuestLabel

local typewrite = require(ReplicatedStorage.Shared.Modules.Utilities.typewrite)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function QuestLabel(
	scope: Fusion.Scope<any>,
	props: {
		text: UsedAs<string>,
	}
)
	local startTextColor = QuestLabelTemp.TextColor3
	local startPos = QuestLabelTemp.Position
	local hiddenPos = startPos - UDim2.fromScale(0, 0.1)

	local position = scope:Value(hiddenPos)
	local transparency = scope:Value(1)
	local textColor = scope:Value(startTextColor)

	local ti = TweenInfo.new(0.2)

	local transTween = scope:Tween(transparency, ti)

	local text = scope:Value("")
	scope:Observer(props.text):onBind(function()
		local newText = peek(props.text)
		if newText == "" then
			position:set(hiddenPos)
			transparency:set(1)
			textColor:set(Color3.new(0, 1, 0))
		else
			textColor:set(startTextColor)
			typewrite(newText, function(textUpdate)
				text:set(textUpdate)
			end)
			position:set(startPos)
			transparency:set(0)
		end
	end)
	textColor:set(startTextColor)

	local label: TextLabel = scope:Hydrate(QuestLabelTemp:Clone())({
		Text = text,
		Position = scope:Spring(position, 15, 0.5),
		TextTransparency = transTween,
		TextColor3 = scope:Tween(textColor, ti),
	})

	scope:Hydrate(label:FindFirstChildOfClass("UIStroke"))({
		Transparency = transTween,
	})

	return label
end

return QuestLabel
