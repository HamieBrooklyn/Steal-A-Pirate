local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local SpinnerPrompt = ReplicatedStorage.Assets.Templates.Spinner

local Hydrate, OnEvent = Fusion.Hydrate, Fusion.OnEvent
local scoped, doCleanup = Fusion.scoped, Fusion.doCleanup

local SpinWheel = {}
SpinWheel.__index = SpinWheel

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	prompt: ProximityPrompt,
}
export type SpinWheel = typeof(setmetatable({} :: self, SpinWheel))

function SpinWheel.new(model: Model): SpinWheel
	local self = setmetatable({}, SpinWheel) :: SpinWheel

	self.scope = scoped(Fusion)
	self.trove = Trove.new()

	self.prompt = Hydrate(self.scope, SpinnerPrompt:Clone())({
		Parent = model:FindFirstChild("PromptPoint"),
		[OnEvent("Triggered")] = function(player: Player) end,
	})
	self.prompt:AddTag("CustomPrompt")

	return self
end

function SpinWheel.Destroy(self: SpinWheel): ()
	doCleanup(self.scope)
	self.trove:Destroy()
end

return SpinWheel
