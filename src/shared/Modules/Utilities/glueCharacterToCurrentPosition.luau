local function glueCharacterToCurrentPosition(char: Model)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part:PivotTo(char:GetPivot())
	part.Parent = workspace.Terrain

	local attach0 = Instance.new("Attachment")
	attach0.Parent = char.PrimaryPart
	local attach1 = attach0:Clone()
	attach1.Parent = part

	local ap = Instance.new("AlignPosition")
	ap.RigidityEnabled = true
	ap.Attachment0 = attach0
	ap.Attachment1 = attach1
	ap.Position = char:GetPivot().Position
	ap.Parent = char.PrimaryPart

	local ao = Instance.new("AlignOrientation")
	ao.RigidityEnabled = true
	ao.Attachment0 = attach0
	ao.Attachment1 = attach1
	ap.Parent = char.PrimaryPart
	return function()
		part:Destroy()
	end
end

return glueCharacterToCurrentPosition
