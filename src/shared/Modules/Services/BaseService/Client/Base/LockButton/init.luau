local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedData = require(script.Parent.Parent.Parent.Data)

local LockedBoard = require(script.LockedBoard)

local Toucher = require(ReplicatedStorage.Shared.Modules.Classes.Toucher)
local Events = require(script.Parent.Parent.Events)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)

local peek, scoped = Fusion.peek, Fusion.scoped

local player = Players.LocalPlayer

local LockButton = {}
LockButton.__index = LockButton

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	secondsLeft: Fusion.Value<number, any>,
}
export type LockButton = typeof(setmetatable({} :: self, LockButton))

function LockButton.new(
	button: BasePart,
	props: {
		lastLocked: Fusion.Value<number, any>,

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

	local toucher = Toucher.new(button)
	self.trove:Add(toucher)

	local touchCon: RBXScriptConnection?
	self.scope:Observer(props.owner):onBind(function()
		if touchCon then
			touchCon:Disconnect()
			touchCon = nil
		end
		if player.UserId ~= peek(props.owner) then
			return
		end

		touchCon = toucher.PlayerTouched:Connect(function(playerTouched: Player)
			if peek(props.owner) ~= playerTouched.UserId then
				return
			end
			Events.LockBaseAttempt:FireServer(props.baseId)
		end)
	end)

	self.trove:Add(observeCharacter(player, function()
		local playerGui = player:WaitForChild("PlayerGui")
		local container = playerGui:FindFirstChild("LockedBoardsContainer")
			or self.scope:New("Folder")({
				Name = "LockedBoardsContainer",
				Parent = playerGui,
			})
		self.scope:LockedBoard({
			parent = container,
			adornee = button,

			secondsLeft = self.secondsLeft,
		})
	end))

	return self
end

function LockButton:Heartbeat()
	self.secondsLeft:set(
		math.clamp(SharedData.LockedDuration - (tick() - peek(self.lastLocked)), 0, SharedData.LockedDuration)
	)
end

function LockButton.Destroy(self: LockButton): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return LockButton
