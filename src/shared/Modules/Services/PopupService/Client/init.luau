local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Popup = require(script.Popup)
local SharedTypes = require(script.Parent.Types)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)

local Value, New, Children, ForPairs = Fusion.Value, Fusion.New, Fusion.Children, Fusion.ForPairs
local scoped, peek, innerScope, doCleanup = Fusion.scoped, Fusion.peek, Fusion.innerScope, Fusion.doCleanup

local PopupClient = {}

export type PopupProps = SharedTypes.PopupProps

function PopupClient.AddPopup(props: PopupProps)
	local scope = innerScope(PopupClient.scope)
	local popup = Popup(scope, props)

	local popupAddState = table.clone(peek(PopupClient.popupLabels))
	table.insert(popupAddState, popup)
	if #popupAddState > 4 then
		table.remove(popupAddState, 1)
	end
	PopupClient.popupLabels:set(popupAddState)

	task.delay(props.duration or 2, doCleanup, scope)
end

function PopupClient.init()
	PopupClient.scope = scoped(Fusion)
	PopupClient.popupLabels = Value(PopupClient.scope, {})

	New(PopupClient.scope, "ScreenGui")({
		Name = "Popups",
		ResetOnSpawn = false,
		DisplayOrder = 5,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
		[Children] = New(PopupClient.scope, "Frame")({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.8),
			Size = UDim2.fromScale(0.6, 0.6),

			BackgroundTransparency = 1,

			[Children] = {
				New(PopupClient.scope, "UIListLayout")({
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
				}),
				PopupClient.popupLabels,
			},
		}),
	})

	Net:Connect("SendPopupTo", function(props: SharedTypes.PopupProps)
		PopupClient.AddPopup(props)
	end)
end

return PopupClient
