local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuaranteeBoard = require(script.GuaranteeBoard)

local SharedTypes = require(script.Parent.Parent.Types)
local SharedData = require(script.Parent.Parent.Data)

local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)

local scoped = Fusion.scoped

local getGuaranteedSpawnsInfo = Net:RemoteFunction("GetGuaranteedSpawnsInfo")

local Spawner = {}
Spawner.__index = Spawner

type self = {
	id: string,

	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	data: SharedTypes.SpawnerData,

	guaranteeSpawnTexts: { [string]: Fusion.Value<string, any> },
	guaranteeSpawnInfo: { [string]: number },
}
export type Spawner = typeof(setmetatable({} :: self, Spawner))

function Spawner.new(folder: Folder): Spawner
	local self = setmetatable({}, Spawner) :: Spawner

	self.id = folder:GetAttribute("SpawnerId")

	self.scope = scoped(Fusion)
	self.trove = Trove.new()

	self.data = SharedData.Spawning.Spawners[folder.Name]

	self.guaranteeSpawnTexts = {}
	self.guaranteeSpawnInfo = getGuaranteedSpawnsInfo:InvokeServer(self.id)
	for i, v in self.guaranteeSpawnInfo do
		self.guaranteeSpawnInfo[i] = tonumber(v)
		self.guaranteeSpawnTexts[i] = self.scope:Value("")
	end

	local function doSide(side)
		local portalStream = self.trove:Add(Streamable.new(folder, side))
		self.trove:Add(portalStream:Observe(function(startPortal: Model, portalTrove: Trove.Trove)
			local portalPartStream = portalTrove:Add(Streamable.new(startPortal, "Portal"))
			portalTrove:Add(portalPartStream:Observe(function(portalPart: BasePart, portalPartTrove: Trove.Trove)
				portalPartTrove:Add(GuaranteeBoard(self.scope, {
					parent = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Billboards"),
					adornee = portalPart,
					rarityTexts = self.guaranteeSpawnTexts,
				}))
			end))
		end))
	end
	doSide("Start")
	doSide("Finish")

	return self
end

function Spawner.Heartbeat(self: Spawner): ()
	for i, v in self.guaranteeSpawnInfo do
		local timeElapsed = os.time() - v
		if timeElapsed > self.data.RarityGuaranteeCooldowns[i] then
			self.guaranteeSpawnInfo[i] = os.time()
		end

		self.guaranteeSpawnTexts[i]:set(
			`Guranteed {i} In: {formatTime(self.data.RarityGuaranteeCooldowns[i] - timeElapsed)}`
		)
	end
end

function Spawner.Destroy(self: Spawner): ()
	self.scope:doCleanup()
end

return Spawner
