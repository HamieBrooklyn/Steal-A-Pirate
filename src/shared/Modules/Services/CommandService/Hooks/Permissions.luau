local Players = game:GetService("Players")
local userids = {}

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		local rankId = Players:GetPlayerByUserId(context.Executor.UserId):GetRankInGroup(36075879)
		if (rankId ~= 253 and rankId ~= 255) and context.Executor.UserId > 0 then
			return "You don't have permission to run this command"
		end
	end)
end
