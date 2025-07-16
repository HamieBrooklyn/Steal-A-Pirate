local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardRankTemp = ReplicatedStorage.Assets.Templates.Gui.LeaderboardRank

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Hydrate, Spring, Computed, Tween = Fusion.Hydrate, Fusion.Spring, Fusion.Computed, Fusion.Tween

type UsedAs<T> = Fusion.UsedAs<T>

local function RankFrame(
	scope: Fusion.Scope<any>,
	props: {
		order: UsedAs<number>,

		name: UsedAs<string>,
		score: UsedAs<string>,
		image: UsedAs<string>,

		shown: UsedAs<boolean>,
	}
)
	local frame: typeof(LeaderboardRankTemp) = Hydrate(scope, LeaderboardRankTemp:Clone())({
		Size = Spring(
			scope,
			Computed(scope, function(use)
				return use(props.shown) and LeaderboardRankTemp.Size
					or UDim2.fromScale(0, LeaderboardRankTemp.Size.Y.Scale)
			end),
			15,
			0.9
		),
	})

	local transparencyTween = Tween(
		scope,
		Computed(scope, function(use)
			return use(props.shown) and 0 or 1
		end),
		TweenInfo.new(2)
	)

	local function Label(label: TextLabel, text: UsedAs<string>)
		Hydrate(scope, label)({
			TextTransparency = transparencyTween,
			Text = text,
		})
		Hydrate(scope, label:FindFirstChildOfClass("UIStroke"))({
			Transparency = transparencyTween,
		})
	end
	Label(frame:WaitForChild("Name"), props.name)
	Label(frame:WaitForChild("Score"), props.score)

	frame.LayoutOrder = props.order

	return frame
end

return RankFrame
