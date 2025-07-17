local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseClient = require(Services.BaseService.Client)

local AnimatedHighlight = require(ReplicatedStorage.Shared.Modules.Classes.AnimatedHighlight)
local Base = require(Services.BaseService.Client.Base)
local Platform = require(Services.BaseService.Client.Base.Platform)
local Path = require(script.Parent.Parent.Path)

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Charm = require(ReplicatedStorage.Packages.Charm)

local scoped, peek = Fusion.scoped, Fusion.peek
local atom, subscribe = Charm.atom, Charm.subscribe

local Step = {}
Step.__index = Step

type self = {
	currentText: Fusion.Value<string, any>,

	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,
}
export type Step = typeof(setmetatable({} :: self, Step))

function Step.new(currentText: Fusion.Value<string, any>, texts: { [string]: string }, ...): Step
	local self = setmetatable({}, Step) :: Step

	self._scope = scoped(Fusion)
	self._trove = Trove.new()

	self.currentText = currentText

	return self
end

function Step.Start(self: Step, texts: { [string]: string }, characterName: string): ()
	self.currentText:set(texts["Main"])

	local path = self._trove:Add(Path.new())
	self._trove:Add(observeCharacter(Players.LocalPlayer, function(char)
		path.fromAtom(char:WaitForChild("HumanoidRootPart"))
	end))

	BaseClient.GetBase():andThen(function(base: Base.Base)
		local platformAtom: Charm.Atom<Platform.Platform> = atom()

		local collectPartStream
		local hl: AnimatedHighlight.AnimatedHighlight?
		subscribe(platformAtom, function(state: Platform.Platform?)
			if collectPartStream then
				collectPartStream:Destroy()
				collectPartStream = nil
			end
			if not state then
				return
			end

			collectPartStream = self._trove:Add(Streamable.new(state.model, "Collect"))
			self._trove:Add(collectPartStream:Observe(function(collectPart: Part, collectPartTrove: Trove.Trove)
				path.toAtom(collectPart)

				hl = collectPartTrove:Add(AnimatedHighlight.new({ FillColor = Color3.new(1, 1, 1) }, collectPart))
				hl = hl.pulseLooping:set(true)
			end))
		end)
		for _, v in base.Platforms do
			self._trove:Add(self._scope:Observer(v.CharacterName):onBind(function()
				if peek(v.CharacterName) == characterName and not platformAtom() then
					platformAtom(v)
				else
					if platformAtom() == v then
						platformAtom(nil)
					end
				end
			end))
		end
	end)
end

function Step.Clean(self: Step): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Step
