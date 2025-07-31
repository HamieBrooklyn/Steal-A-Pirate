local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local InviteButton = {}
InviteButton.__index = InviteButton

type self = {
	_connection: RBXScriptConnection,
}
export type InviteButton = typeof(setmetatable({} :: self, InviteButton))

function InviteButton.new(button: GuiButton): InviteButton
	local self = setmetatable({}, InviteButton) :: InviteButton

	self._connection = button.MouseButton1Click:Connect(function()
		local inviteOptions = Instance.new("ExperienceInviteOptions")
		inviteOptions.PromptMessage = "Invite someone to steal with. Or steal from..."

		local function canSendGameInvite(sendingPlayer)
			local success, canSend = pcall(function()
				return SocialService:CanSendGameInviteAsync(sendingPlayer)
			end)

			return success and canSend
		end

		local canInvite = canSendGameInvite(Players.LocalPlayer)
		if canInvite then
			SocialService:PromptGameInvite(Players.LocalPlayer)
		end
	end)

	return self
end

function InviteButton.Destroy(self: InviteButton): ()
	self._connection:Disconnect()
end

return InviteButton
