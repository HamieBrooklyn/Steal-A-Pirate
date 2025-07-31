local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
function join(t1: { any }, t2: { any })
	t1 = t1 or {}
	t2 = t2 or {}
	return TableUtil.Reconcile(t1, t2)
end

return join
