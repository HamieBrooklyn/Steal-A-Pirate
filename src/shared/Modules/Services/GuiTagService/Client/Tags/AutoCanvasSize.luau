local ReplicatedStorage = game:GetService("ReplicatedStorage")
local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)
local AutoCanvasSize = {}
AutoCanvasSize.__index = AutoCanvasSize

type self = {
	obsConnection: RBXScriptConnection,
}
export type AutoCanvasSize = typeof(setmetatable({} :: self, AutoCanvasSize))

local function UpdateCanvasSizeY(scrollingFrame: ScrollingFrame)
	local layout: UIListLayout | UIGridLayout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
		or scrollingFrame:FindFirstChildOfClass("UIGridLayout")
	local totalYSize = 30
	if layout:IsA("UIListLayout") then
		scrollingFrame.CanvasSize =
			UDim2.fromOffset(0, totalYSize + layout.AbsoluteContentSize.Y + layout.Padding.Offset)
	elseif layout:IsA("UIGridLayout") then
		scrollingFrame.CanvasSize =
			UDim2.fromOffset(0, totalYSize + layout.AbsoluteContentSize.Y + layout.CellPadding.Y.Offset)
	end
end

function AutoCanvasSize.new(scrollingFrame: ScrollingFrame): AutoCanvasSize
	local self = setmetatable({}, AutoCanvasSize) :: AutoCanvasSize

	self.obsConnection = observeChildren(scrollingFrame, function()
		UpdateCanvasSizeY(scrollingFrame)
	end)

	return self
end

function AutoCanvasSize.Destroy(self: AutoCanvasSize): ()
	self.obsConnection:Disconnect()
end

return AutoCanvasSize
