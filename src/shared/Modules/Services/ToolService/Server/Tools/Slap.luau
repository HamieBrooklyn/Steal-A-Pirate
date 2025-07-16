local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SlapSounds = ReplicatedStorage.Assets.Sounds.SoundEffects.Slap
local Modules = ReplicatedStorage.Shared.Modules

local SlapAnimation = ReplicatedStorage.Assets.Animation.SlapSwing

local PlayerServer = require(Modules.Services.PlayerService.Server)

local Toucher = require(Modules.Classes.Toucher)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Sound = require(Modules.Classes.Sound)

local OnEvent = Fusion.OnEvent
local scoped, peek = Fusion.scoped, Fusion.peek

local Slap = {}
Slap.__index = Slap

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,
	hitTrove: Trove.Trove,

	lastSlappedTime: Fusion.Value<number, any>,

	slapAnimationTrack: Fusion.Value<AnimationTrack, any>,
	root: Fusion.Value<BasePart?, any>,

	toucher: Toucher.Toucher,

	playerHitCooldown: { Player },
}
export type Slap = typeof(setmetatable({} :: self, Slap))

function Slap.new(player: Player, tool: Tool): Slap
	local self = setmetatable({}, Slap) :: Slap

	self.scope = scoped(Fusion)
	self.trove = Trove.new()

	self.lastSlappedTime = self.scope:Value(time())

	self.slapAnimationTrack = self.scope:Value(nil)
	self.root = self.scope:Value(nil)

	local handle: BasePart = tool:FindFirstChild("Handle")
	self.toucher = Toucher.new(handle)

	self.hitTrove = Trove.new()
	self.trove:Add(self.hitTrove)

	self.playerHitCooldown = {}

	self.scope:Hydrate(tool)({
		[OnEvent("Activated")] = function()
			local track: AnimationTrack? = peek(self.slapAnimationTrack)
			if not track then
				return
			end
			if time() - peek(self.lastSlappedTime) > 1 then
				self.lastSlappedTime:set(time())

				Sound.new(SlapSounds.Swing, handle):Play()

				self.hitTrove:Clean()
				self.hitTrove:Add(self.toucher.PlayerTouched:Connect(function(playerHit: Player)
					if playerHit == player or table.find(self.playerHitCooldown, playerHit) then
						return
					end
					table.insert(self.playerHitCooldown, playerHit)
					task.delay(1, function()
						table.remove(self.playerHitCooldown, table.find(self.playerHitCooldown, playerHit))
					end)

					local stealing = PlayerServer.players[tostring(playerHit.UserId)].Stealing
					if peek(stealing.isStealing) then
						stealing:RetrieveCurrentStolenItem()
					end

					local root: BasePart? = peek(self.root)

					local otherChar = playerHit.Character
					if not otherChar or not root then
						return
					end
					local otherRoot = otherChar.PrimaryPart
					if not otherRoot then
						return
					end
					local otherHum = otherChar:FindFirstChildOfClass("Humanoid")
					if not otherHum then
						return
					end

					local delta = otherRoot.Position - root.Position

					local bv = Instance.new("BodyVelocity")
					bv.maxForce = Vector3.new(1e9, 1e9, 1e9)
					bv.velocity = (delta.Unit * 40) + Vector3.yAxis * 10
					bv.Parent = otherRoot
					Debris:AddItem(bv, 0.05)

					Sound.new(SlapSounds.Slap, otherRoot):Play()

					otherHum.Sit = true
				end))
				self.hitTrove:Add(track.Ended:Once(function()
					self.hitTrove:Clean()
				end))

				track:Play()
			end
		end,
		[OnEvent("AncestryChanged")] = function(_, parent: Instance)
			if parent == player.Character and player.Parent and parent ~= nil then
				self.slapAnimationTrack:set(
					parent
						:FindFirstChildOfClass("Humanoid")
						:FindFirstChildOfClass("Animator")
						:LoadAnimation(SlapAnimation)
				)
				self.root:set(player.Character.PrimaryPart)
			end
		end,
	})

	return self
end

function Slap.Destroy(self: Slap): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return Slap
