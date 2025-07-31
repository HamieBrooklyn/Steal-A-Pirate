local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SharedMonitizationData = require(script.Parent.Parent.Data)

local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Packages.Trove)

local atom, subscribe = Charm.atom, Charm.subscribe

local LikeGoalCounter = {}
LikeGoalCounter.__index = LikeGoalCounter

type self = {
	_trove: Trove.Trove,
}
export type LikeGoalCounter = typeof(setmetatable({} :: self, LikeGoalCounter))

local function GetLikes()
	local Success, Result = pcall(HttpService.RequestAsync, HttpService, {
		Url = string.format("https://games.roproxy.com/v1/games/%d/votes", 107402379414263),
		Method = "GET",
	})
	if Success then
		return HttpService:JSONDecode(Result.Body).upVotes or 0
	else
		return 0
	end
end

function LikeGoalCounter.new(model: Model): LikeGoalCounter
	local self = setmetatable({}, LikeGoalCounter) :: LikeGoalCounter

	local containerFrame = model.Inside.LikesSurfaceGui.Container

	local descLabel = containerFrame.LikeDesc
	local progressLabel = containerFrame.LikeProgress
	local fillFrame = containerFrame.LoadingBar.Fill

	self._trove = Trove.new()

	local currentLikes = atom(-1)
	self._trove:Add(subscribe(currentLikes, function(likes: number)
		local likesGoal = SharedMonitizationData.LikeGoal

		progressLabel.Text = tostring(likes) .. "/" .. tostring(likesGoal)
		fillFrame.Size = UDim2.fromScale(math.clamp(likes / likesGoal, 0, 1), 1)

		if likes >= likesGoal then
			workspace:SetAttribute("LikesGoalReached", true)
		end
	end))

	local lastUpdate = 0
	self._trove:Add(RunService.Heartbeat:Connect(function()
		if os.time() - lastUpdate < 120 then
			return
		end
		lastUpdate = os.time()

		currentLikes(GetLikes())
	end))

	return self
end

function LikeGoalCounter.Destroy(self: LikeGoalCounter): ()
	self._trove:Destroy()
end

return LikeGoalCounter
