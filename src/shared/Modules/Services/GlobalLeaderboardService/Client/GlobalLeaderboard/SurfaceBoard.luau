local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalLeaderboardTemp = ReplicatedStorage.Assets.Templates.Gui.GlobalLeaderboard

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local RankFrame = require(script.Parent.RankFrame)
local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

local Hydrate, Children, ForPairs, Value, Observer =
	Fusion.Hydrate, Fusion.Children, Fusion.ForPairs, Fusion.Value, Fusion.Observer

type UsedAs<T> = Fusion.UsedAs<T>

local function Board(
	scope: Fusion.Scope<any>,
	props: {
		listedItems: UsedAs<{ SharedTypes.ListItem }>,
		stringFormat: UsedAs<string>,
		abbreviate: UsedAs<boolean>,
	}
): SurfaceGui
	local surfaceBoard: typeof(GlobalLeaderboardTemp) = Hydrate(scope, GlobalLeaderboardTemp:Clone())({})

	Hydrate(scope, surfaceBoard:WaitForChild("Contents"))({
		[Children] = ForPairs(
			scope,
			props.listedItems,
			function(_, itemScope: Fusion.Scope<any>, index: number, data: SharedTypes.ListItem)
				local username = "Failed to load"
				pcall(function()
					username = Players:GetNameFromUserIdAsync(data.key)
				end)

				local _, image = pcall(function()
					return Players:GetUserThumbnailAsync(
						data.key,
						Enum.ThumbnailType.AvatarBust,
						Enum.ThumbnailSize.Size48x48
					)
				end)

				local shown = Value(itemScope, false)
				local frame = RankFrame(itemScope, {
					order = index,

					name = username,
					score = if props.abbreviate
						then abbreviateNumber(data.value)
						else props.stringFormat:format(tostring(data.value)),
					image = image or "",

					shown = shown,
				})

				task.delay(0.1 * index - 1, function()
					shown:set(true)
				end)

				return index, frame
			end
		),
	})

	return surfaceBoard
end

return Board
