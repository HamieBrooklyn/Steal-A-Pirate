local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local ClickSound = ReplicatedStorage.Assets.Sounds.SoundEffects.Gui.Click

local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local AnimatedObject = require(Services.GuiAnimationService.Client.AnimatedObject)
local GuiAnimationClient = require(Services.GuiAnimationService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Trove = require(ReplicatedStorage.Packages.Trove)

local OnEvent = Fusion.OnEvent
local scoped, peek = Fusion.scoped, Fusion.peek

local AnimatedButton = {}
AnimatedButton.__index = AnimatedButton

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	hovering: Fusion.Value<boolean, any>,
	holding: Fusion.Value<boolean, any>,
	locked: Fusion.Value<boolean, any>,

	tweenInfo: Fusion.Value<TweenInfo, any>,

	startSize: Fusion.Value<UDim2, any>,
	startPosition: Fusion.Value<UDim2, any>,

	imageColor: Fusion.Value<Color3, any>?,
}
export type AnimatedButton = typeof(setmetatable({} :: self, AnimatedButton))

function AnimatedButton.new(button: GuiButton): AnimatedButton
	local self = setmetatable({}, AnimatedButton) :: AnimatedButton

	self.scope = scoped(Fusion) :: Fusion.Scope<any>
	self.trove = Trove.new()

	self.hovering = self.scope:Value(false) :: Fusion.Value<boolean, any>
	self.holding = self.scope:Value(false) :: Fusion.Value<boolean, any>

	self.tweenInfo = self.scope:Value(TweenInfo.new(0.5)) :: Fusion.Value<TweenInfo, any>

	local isImageButton = button:IsA("ImageButton")
	if isImageButton then
		self.imageColor = self.scope:Value(button.ImageColor3) :: Fusion.Value<Color3, any>
	end

	local objToAnimate = button
	local animateObjVal: ObjectValue? = button:FindFirstChild("Animate")
	if animateObjVal and animateObjVal:IsA("ObjectValue") then
		objToAnimate = animateObjVal.Value or button
	end

	self.startSize = self.scope:Value(objToAnimate.Size) :: Fusion.Value<UDim2, any>
	self.startPosition = self.scope:Value(objToAnimate.Position) :: Fusion.Value<UDim2, any>

	if not objToAnimate:HasTag("AnimatedObject") then
		objToAnimate:AddTag("AnimatedObject")
	end
	self.trove:Add(CollectionService:GetInstanceRemovedSignal("AnimatedObject"):Connect(function(objRemoved)
		if objRemoved == button then
			self:Destroy()
		end
	end))

	local function animate(animated: AnimatedObject.AnimatedObject)
		local animatedObj = GuiAnimationClient.animatedObjects[objToAnimate]
		local sizing = self.scope:Computed(function(use)
			local startSize = use(self.startSize)
			animatedObj.Size:set(
				(use(self.hovering) and not use(self.holding)) and startSize + UDim2.fromOffset(10, 10) or startSize
			)
		end)

		self.locked = self.scope:Value(false) :: Fusion.Value<boolean, any>
		self.trove:Add(Observers.observeAttribute(objToAnimate, "Locked", function(value)
			self.locked:set(value == true)
		end))

		self.scope:Hydrate(button)({
			[OnEvent("MouseEnter")] = function()
				if peek(self.locked) then
					return
				end
				self.hovering:set(true)
				peek(sizing)
			end,
			[OnEvent("MouseLeave")] = function()
				self.hovering:set(false)
				peek(sizing)
			end,

			[OnEvent("MouseButton1Down")] = function()
				Sound.new(ClickSound):Play()
				self.holding:set(true)
				peek(sizing)
			end,
			[OnEvent("MouseButton1Up")] = function()
				self.holding:set(false)
				peek(sizing)
			end,

			--[if isImageButton then "ImageColor3" else nil] = self.scope:Tween(self.imageColor, self.tweenInfo),
		})
	end

	for obj, animated in GuiAnimationClient.animatedObjects do
		if obj == objToAnimate then
			animate(animated)
			break
		end
	end
	local addedCon: RBXScriptConnection?
	addedCon = self.trove:Add(
		GuiAnimationClient.AnimatedObjectAdded:Connect(function(obj: Instance, animated: AnimatedObject.AnimatedObject)
			if obj ~= objToAnimate then
				return
			end
			if addedCon then
				addedCon:Disconnect()
				addedCon = nil
			end
			animate(animated)
		end)
	)

	return self
end

function AnimatedButton.Destroy(self: AnimatedButton): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return AnimatedButton
