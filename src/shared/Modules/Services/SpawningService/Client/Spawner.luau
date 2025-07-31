local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(script.Parent.Parent.Types)
local SharedData = require(script.Parent.Parent.Data)

local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local scoped = Fusion.scoped

local Spawner = {}
Spawner.__index = Spawner

type self = {
	id: string,

	folder: Folder,

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

	self.folder = folder

	self.scope = scoped(Fusion)
	self.trove = Trove.new()

	self.data = SharedData.Spawning.Spawners[folder.Name]

	return self
end

function Spawner.Heartbeat(self: Spawner): () end

function Spawner.Destroy(self: Spawner): ()
	self.scope:doCleanup()
end

return Spawner
