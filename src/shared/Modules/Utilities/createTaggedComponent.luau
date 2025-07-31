local CollectionService = game:GetService("CollectionService")

export type Component = {
	new: (instance: Instance, ...any) -> Component,
	Destroy: (self: Component) -> (),
}

function createTaggedComponent(
	tag: string,
	component: Component,
	added: ((instance: Instance, component: Component) -> (() -> ())?)?,
	...
): () -> ()
	local connections: { RBXScriptConnection } = {}
	local data = { ... }
	local activeComponents: { any } = {}

	local function instanceAdded(addedInstance: Instance)
		local newComponent = component.new(addedInstance, table.unpack(data))
		activeComponents[addedInstance] = newComponent
		if added then
			local cleanup: (() -> ())? = added(addedInstance, newComponent)
			if cleanup then
				local removeConnection: RBXScriptConnection
				removeConnection = CollectionService:GetInstanceRemovedSignal(tag)
					:Connect(function(removedInstance: Instance)
						if removedInstance == addedInstance then
							activeComponents[removedInstance] = nil
							removeConnection:Disconnect()
							cleanup()
							if newComponent.Destroy then
								newComponent:Destroy()
							end
						end
					end)
				table.insert(connections, removeConnection)
			end
		end
	end

	table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(instanceAdded))
	for _, v in CollectionService:GetTagged(tag) do
		instanceAdded(v)
	end

	return activeComponents, function()
		for _, v in connections do
			v:Disconnect()
		end
	end
end

return createTaggedComponent
