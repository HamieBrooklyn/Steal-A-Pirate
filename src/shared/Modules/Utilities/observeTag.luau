local CollectionService = game:GetService("CollectionService")

local function observeTag(
	tag: string,
	added: ((instance: Instance) -> ())?,
	removed: ((instance: Instance) -> ())?
): () -> ()
	local cons = {}

	if added then
		for _, v in CollectionService:GetTagged(tag) do
			added(v)
		end
		table.insert(cons, CollectionService:GetInstanceAddedSignal(tag):Connect(added))
	end
	if removed then
		table.insert(cons, CollectionService:GetInstanceRemovedSignal(tag):Connect(removed))
	end

	return function()
		for _, con in cons do
			con:Disconnect()
		end
	end
end

return observeTag
