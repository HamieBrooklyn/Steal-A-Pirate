local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services
local SoundEffects = ReplicatedStorage.Assets.Sounds.SoundEffects

local PopupSound = SoundEffects.Gui.Popup

local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local GuiAnimationClient = require(Services.GuiAnimationService.Client)

local SharedTypes = require(script.Parent.Parent.Types)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New, Children, Value, Observer = Fusion.New, Fusion.Children, Fusion.Value, Fusion.Observer
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function Popup(scope: Fusion.Scope<any>, props: SharedTypes.PopupProps)
	local shown = Value(scope, false)

	Sound.new(PopupSound, workspace):Play()

	local popup = New(scope, "TextLabel")({
		BackgroundTransparency = 1,

		FontFace = Font.new(Font.fromEnum(Enum.Font.DenkOne).Family, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = props.message,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),

		[Children] = {
			New(scope, "UIStroke")({ Thickness = 2 }),
			props.gradient and props.gradient:Clone() or nil,
		},
	})
	local animatedObj = GuiAnimationClient.animatedObject.new(popup)
	Observer(scope, shown):onBind(function()
		animatedObj.Size:set(peek(shown) and UDim2.fromScale(1, 0.1) or UDim2.new())
	end)
	shown:set(true)

	return popup
end

return Popup
