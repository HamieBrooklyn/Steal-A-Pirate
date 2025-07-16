local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Services = ReplicatedStorage.Shared.Modules.Services

local MonitizationClient = require(Services.MonitizationService.Client)
local BaseClient = require(Services.BaseService.Client)
local Base = require(Services.BaseService.Client.Base)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local CharacterViewport = require(ReplicatedStorage.Shared.Modules.Classes.CharacterViewport)

local Hydrate = Fusion.Hydrate
local peek = Fusion.peek

local function ShopMenu(scope: Fusion.Scope<any>, props: {})
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local shopMenuGui = playerGui:WaitForChild("Shop")
	local contents = shopMenuGui:WaitForChild("Main"):WaitForChild("Contents")

	BaseClient.GetBase():andThen(function(base: Base.Base)
		for _, v: GuiButton? in contents:GetChildren() do
			local id = v:GetAttribute("Id")
			if id then
				id = tonumber(id)
				if id == nil then
					continue
				end

				local checkFullBase = v:GetAttribute("CheckFullBase") == true

				table.insert(
					scope,
					v.MouseButton1Click:Connect(function()
						if checkFullBase and peek(base.isFull) == true then
							return
						end
						MonitizationClient.SetPrompting(id)
						MarketplaceService:PromptProductPurchase(player, id)
					end)
				)

				if checkFullBase then
					local fullBaseNoticeLabel = v:WaitForChild("FullBaseNotice")
					if fullBaseNoticeLabel then
						Hydrate(scope, fullBaseNoticeLabel)({
							Visible = base.isFull,
						})
					end
					for _, viewport in v:GetChildren() do
						local characterName = viewport:GetAttribute("CharacterView")
						if characterName then
							local cv = CharacterViewport.new(viewport)
							cv.characterNameAtom(characterName)
						end
					end
				end
			end
		end
	end)
end

return ShopMenu
