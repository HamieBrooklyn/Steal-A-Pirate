local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(script.Parent.Types)

local Net = require(ReplicatedStorage.Packages.Net)

local sendPopupTo = Net:RemoteEvent("SendPopupTo")

local PopupServer = {}

function PopupServer.SendServerPopup(props: SharedTypes.PopupProps)
	sendPopupTo:FireAllClients(props)
end

function PopupServer.SendPopupTo(player: Player, props: SharedTypes.PopupProps)
	sendPopupTo:FireClient(player, props)
end

return PopupServer
