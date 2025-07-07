local function observeCharacter(player: Player, callback: (char: Model) -> (() -> ())?): () -> ()
	local removedCallback: (() -> ())?

	if player.Character then
		removedCallback = callback(player.Character)
	end

	local addedCon = player.CharacterAdded:Connect(function(character)
		removedCallback = callback(character)
	end)
	local removedCon = player.CharacterRemoving:Connect(function(character)
		if removedCallback then
			removedCallback()
		end
	end)

	return function()
		addedCon:Disconnect()
		removedCon:Disconnect()
	end
end

return observeCharacter
