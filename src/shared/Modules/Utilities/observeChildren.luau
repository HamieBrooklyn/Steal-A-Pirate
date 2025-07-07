local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local function observeChildren(parent: Instance, callback: (Instance) -> ()): RBXScriptConnection
	for _, v in parent:GetChildren() do
		local cleanup: (() -> ())? = callback(v)
		if cleanup then
			local trove = Trove.new()
			trove:Add(v.AncestryChanged:Connect(function(_, newParent)
				if newParent == nil then
					trove:Destroy()
				end
			end))
			trove:Add(v.Destroying:Once(function()
				trove:Destroy()
			end))
			trove:Add(cleanup)
		end
	end
	return parent.ChildAdded:Connect(callback)
end

return observeChildren
