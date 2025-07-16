local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = ReplicatedStorage.Assets.Models.Characters

local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ViewportFitter = require(ReplicatedStorage.Packages.ViewportFitter)

local atom, subscribe = Charm.atom, Charm.subscribe

local CharacterViewport = {}
CharacterViewport.__index = CharacterViewport

type self = {
	trove: Trove.Trove,
	tempTrove: Trove.Trove,

	characterNameAtom: Charm.Atom<string>,

	fitter: ViewportFitter.ViewportModel,
	camera: Camera,
	model: Model?,
}
export type CharacterViewport = typeof(setmetatable({} :: self, CharacterViewport))

function CharacterViewport.new(viewportFrame: ViewportFrame): CharacterViewport
	local self = setmetatable({}, CharacterViewport) :: CharacterViewport

	self.trove = Trove.new()
	self.tempTrove = self.trove:Add(Trove.new())

	self.characterNameAtom = atom("")

	self.camera = self.trove:Add(Instance.new("Camera"))
	self.camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = self.camera

	self.fitter = ViewportFitter.new(viewportFrame, self.camera)
	self.trove:Add(subscribe(self.characterNameAtom, function(state)
		self.tempTrove:Clean()
		if not state then
			return
		end

		self.model = self.tempTrove:Add(Characters:FindFirstChild(state):Clone())
		self.model:PivotTo(CFrame.new())
		self.model.Parent = viewportFrame
		self.fitter:SetModel(self.model)
		self.fitter:Calibrate()
		self.camera.CFrame = self.fitter:GetMinimumFitCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
	end))

	return self
end

function CharacterViewport.Destroy(self: CharacterViewport): ()
	self.trove:Destroy()
end

return CharacterViewport
