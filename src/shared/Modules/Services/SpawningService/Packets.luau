local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNetMax = require(ReplicatedStorage.Packages.ByteNetMax)

return ByteNetMax.defineNamespace("Spawning", function()
	return {
		packets = {
			CharacterMovingTo = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					destination = ByteNetMax.string,
					character = ByteNetMax.inst,
				}),
			}),
		},
		queries = {},
	}
end)
