local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Shared.Modules
local Services = Modules.Services
local RebirthService = Services.RebirthService

local RebirthClient = require(RebirthService.Client)
local SharedRebirthData = require(RebirthService.Data)

local SharedData = require(script.Parent.Parent.Parent.Data)

local LockedBoard = require(script.LockedBoard)

local Toucher = require(Modules.Classes.Toucher)
local Events = require(script.Parent.Parent.Events)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local peek, scoped = Fusion.peek, Fusion.scoped

local player = Players.LocalPlayer

local LockButton = {}
LockButton.__index = LockButton

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	secondsLeft: Fusion.Value<number, any>,
	lockDuration: Fusion.Value<number, any>,
	locked: Fusion.Value<boolean, any>,
}
export type LockButton = typeof(setmetatable({} :: self, LockButton))

function LockButton.new(
	button: BasePart,
	props: {
		lastLocked: Fusion.Value<number, any>,
		lockDuration: Fusion.Value<number, any>,
		locked: Fusion.Value<boolean, any>,

		owner: Fusion.Value<string, any>,
		baseId: string,
	}
): LockButton
	local self = setmetatable({}, LockButton) :: LockButton

	self.scope = scoped(Fusion, {
		LockedBoard = LockedBoard,
	})
	self.trove = Trove.new()

	self.secondsLeft = self.scope:Value(0)
	self.lastLocked = props.lastLocked
	self.lockDuration = props.lockDuration
	self.locked = props.locked

	local toucher = Toucher.new(button)
	self.trove:Add(toucher)

	local touchDB = false
	local touchCon: RBXScriptConnection?
	self.scope:Observer(props.owner):onBind(function()
		if touchCon then
			touchCon:Disconnect()
			touchCon = nil
		end
		if player.UserId ~= peek(props.owner) then
			return
		end

		touchCon = self.trove:Add(button.Touched:Connect(function(hit: BasePart)
			local playerTouched = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
			if
				not playerTouched
				or peek(props.owner) ~= playerTouched.UserId
				or peek(self.secondsLeft) > 0
				or touchDB
			then
				return
			end
			touchDB = true
			task.delay(1, function()
				touchDB = false
			end)
			Events.LockBaseAttempt:FireServer(props.baseId)
		end))
	end)

	self.scope:LockedBoard({
		parent = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Billboards"),
		adornee = button,

		secondsLeft = self.secondsLeft,
	})

	return self
end

function LockButton.Heartbeat(self: LockButton)
	-- local duration = SharedData.LockedDuration
	-- 	+ (SharedRebirthData.Constants.LockTimerIncrement * peek(RebirthClient.rebirths))
	local duration = peek(self.lockDuration)
	self.secondsLeft:set(math.clamp(duration - (os.time() - peek(self.lastLocked)), 0, duration))
	--print(peek(self.secondsLeft))
	if peek(self.secondsLeft) == 0 then
		self.locked:set(false)
	else
		self.locked:set(true)
	end
end

function LockButton.Destroy(self: LockButton): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return LockButton
