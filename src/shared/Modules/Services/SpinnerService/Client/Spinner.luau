local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpinnerFrame = require(script.Parent.SpinMenu.Spinner)
local Slot = require(script.Parent.SpinMenu.Slot)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Streamable = require(ReplicatedStorage.Packages.Streamable)
local Trove = require(ReplicatedStorage.Packages.Trove)
local TextBoard = require(ReplicatedStorage.Shared.Modules.Components.UI.TextBoard)

local Spinner = {}
Spinner.__index = Spinner

type self = {
	_scope: Fusion.Scope,
	_trove: Trove.Trove,
}

export type Spinner = typeof(setmetatable({} :: self, Spinner)) & Spinner

function Spinner.new(
	spinner: Model,
	countdownText: Fusion.Computed<string>,
	rotation: Fusion.Value<number>,
	slots: Fusion.Value<{ Slot.SlotInfo }>,
	detectorZRotation: Fusion.Spring<number>
): Spinner
	local self = setmetatable({} :: Spinner, Spinner)

	self._scope = Fusion.scoped(Fusion) :: Fusion.Scope
	self._trove = Trove.new() :: Trove.Trove

	TextBoard(self._scope, {
		adornee = spinner,
		text = countdownText,
		textColor = Color3.fromRGB(30, 99, 79),
		native = {
			Name = "FreeSpinCountdown",
			StudsOffset = Vector3.new(0, 17, 0),
			Size = UDim2.fromScale(15, 5),
		},
	}).Parent =
		spinner

	local primaryStream = Streamable.Streamable.primary(spinner)
	self._trove:Add(primaryStream)

	local detectorStream = Streamable.Streamable.new(spinner, "Detector")
	self._trove:Add(detectorStream)

	self._trove:Add(primaryStream:Observe(function(wheel: BasePart, trove)
		local gui = self._scope:New("SurfaceGui")({
			Face = "Right",
			[Fusion.Children] = SpinnerFrame(self._scope, {
				rotation = rotation,
				slots = slots,
				native = {
					Size = UDim2.fromScale(0.9, 0.9),
				},
			}),
		})
		gui.Parent = wheel
		trove:Add(gui)
	end))

	local detectorIsHydrated = false
	self._trove:Add(detectorStream:Observe(function(detector: BasePart)
		if not detectorIsHydrated then
			detectorIsHydrated = true

			self._scope:Hydrate(detector)({
				Orientation = self._scope:Computed(function(use: Fusion.Use)
					return Vector3.new(-use(detectorZRotation), 90, 90)
				end),
			})
		end
	end))

	return self
end

function Spinner.Destroy(self: Spinner): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Spinner
