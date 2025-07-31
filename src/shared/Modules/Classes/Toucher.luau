local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Charm = require(ReplicatedStorage.Packages.Charm)

local atom, peek, observe = Charm.atom, Charm.peek, Charm.observe

local Toucher = {}
Toucher.__index = Toucher

type self = {
	_trove: Trove.Trove,
	_eventsTrove: Trove.Trove,

	PlayerTouched: Signal.Signal<Player>,
	PlayerTouchEnded: Signal.Signal<Player>,

	Cooldown: number?,

	GetGetPartsTouching: Atom<{ BasePart }>,
	GetGetPlayersTouching: Atom<{ Player }>,
	GetGetPlayerPartsTouching: Atom<{ BasePart }>,
}
export type Toucher = typeof(setmetatable({} :: self, Toucher))

function Toucher.new(container: BasePart | Instance): Toucher
	local self = setmetatable({}, Toucher) :: Toucher

	self._trove = Trove.new()
	self._eventsTrove = Trove.new()

	self.PlayerTouched = Signal.new()
	self._eventsTrove:Add(self.PlayerTouched)

	self.PlayerTouchEnded = Signal.new()
	self._eventsTrove:Add(self.PlayerTouchEnded)

	local parts: { BasePart } = {}
	for _, v in container:GetDescendants() do
		if v:IsA("BasePart") then
			table.insert(parts, v)
		end
	end
	if container:IsA("BasePart") then
		table.insert(parts, container)
	end

	local playersOnCooldown = atom({})
	local cooldownConnection: RBXScriptConnection?
	local function disconnectCooldown()
		if cooldownConnection then
			cooldownConnection:Disconnect()
			cooldownConnection = nil
		end
	end
	self._trove:Add(disconnectCooldown)
	self._trove:Add(observe(playersOnCooldown, function(cooldownStartedTime: number, player: Player)
		disconnectCooldown()
		cooldownConnection = RunService.Heartbeat:Connect(function()
			if os.time() - cooldownStartedTime < self.Cooldown then
				return
			end
			playersOnCooldown(function(state)
				state = table.clone(state)
				state[player] = nil
				return state
			end)
		end)
		return function()
			if #peek(playersOnCooldown) == 0 then
				disconnectCooldown()
			end
		end
	end))

	self.GetPlayerPartsTouching = atom({})
	self.GetPlayersTouching = atom({})
	self.GetPartsTouching = atom({})
	self._trove:Add(observe(self.GetPartsTouching, function(part: BasePart)
		local player = Players:GetPlayerFromCharacter(part.Parent)
		if player and not table.find(peek(self.GetPlayersTouching), player) and not peek(playersOnCooldown)[player] then
			self.GetPlayersTouching(function(state)
				state = table.clone(state)
				table.insert(state, player)
				return state
			end)
			self.GetPlayerPartsTouching(function(state)
				state = table.clone(state)
				state[part] = player
				return state
			end)
			if self.Cooldown then
				playersOnCooldown(function(state)
					state = table.clone(state)
					state[player] = os.time()
					return state
				end)
			end
			self.PlayerTouched:Fire(player)
		end
		return function()
			self.GetPlayerPartsTouching(function(state)
				state = table.clone(state)
				state[part] = nil
				return state
			end)
		end
	end))
	self._trove:Add(observe(self.GetPlayerPartsTouching, function(player: Player)
		return function()
			local stillTouching = false
			for _, v in peek(self.GetPlayerPartsTouching) do
				if v == player then
					stillTouching = true
				end
			end
			if stillTouching == false then
				self.GetPlayersTouching(function(state)
					state = table.clone(state)
					local index = table.find(state, player)
					if index then
						table.remove(state, index)
					end
					return state
				end)
				self.PlayerTouchEnded:Fire(player)
			end
		end
	end))

	for _, v in parts do
		self._trove:Add(v.Touched:Connect(function(otherPart)
			self.GetPartsTouching(function(state)
				state = table.clone(state)
				table.insert(state, otherPart)
				return state
			end)
		end))
		self._trove:Add(v.TouchEnded:Connect(function(otherPart)
			self.GetPartsTouching(function(state)
				state = table.clone(state)
				table.remove(state, table.find(state, otherPart))
				return state
			end)
		end))
	end

	return self
end

function Toucher.Destroy(self: Toucher): ()
	self._trove:Destroy()
	self._eventsTrove:Destroy()
end

return Toucher
