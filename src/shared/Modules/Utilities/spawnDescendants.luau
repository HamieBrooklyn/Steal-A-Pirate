local function spawnDescendants(container: Instance, spawnKey: string, matchName: string?): { [string]: any }
	local spawnedModules = {}
	for _, v in container:GetDescendants() do
		if not v:IsA("ModuleScript") or (matchName and not string.find(v.Name, matchName)) then
			continue
		end
		local reqModule = require(v)
		if typeof(reqModule) == "table" and reqModule[spawnKey] then
			task.spawn(reqModule[spawnKey])
		end
		spawnedModules[v.Name] = reqModule
	end
	return spawnedModules
end

return spawnDescendants
