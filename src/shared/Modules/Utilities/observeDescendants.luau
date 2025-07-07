local function observeDescendants(parent: Instance, callback: (Instance) -> ()): RBXScriptConnection
	for _, v in parent:GetDescendants() do
		callback(v)
	end
	return parent.DescendantAdded:Connect(callback)
end

return observeDescendants
