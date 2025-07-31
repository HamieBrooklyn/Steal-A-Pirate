local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

function FUNClaimed()
	Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.CashCollect, workspace):Play()
end

return FUNClaimed
