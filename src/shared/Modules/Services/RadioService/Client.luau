local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RadioSongs = ReplicatedStorage.Assets.Sounds.Music.Radio

local Charm = require(ReplicatedStorage.Packages.Charm)
local TopbarPlus = require(ReplicatedStorage.Packages.TopbarPlus)

local atom, subscribe = Charm.atom, Charm.subscribe

local RadioClient = {}

function RadioClient.pickRandomSong(category: string?)
	category = category or RadioClient.categoryAtom()
	local songs = RadioClient.categorizedSongs[category]
	-- local playedSongs = RadioClient.songsPlayedInCategory[category]
	-- if #songs == #playedSongs then
	-- 	RadioClient.songsPlayedInCategory[category] = {}
	-- end
	-- local tries = 0
	local chosenSong = songs[math.random(1, #songs)]
	-- repeat
	-- 	chosenSong = songs[math.random(1, #songs)]
	-- 	tries += 1
	-- until not table.find(playedSongs, chosenSong) or tries > 100
	-- table.insert(RadioClient.songsPlayedInCategory[category], chosenSong)
	RadioClient.songAtom(chosenSong)
end

function RadioClient.init()
	RadioClient.songsPlayedInCategory = {}
	RadioClient.categorizedSongs = {}
	for _, category in RadioSongs:GetChildren() do
		RadioClient.songsPlayedInCategory[category.Name] = {}
		RadioClient.categorizedSongs[category.Name] = {}
		for _, song in category:GetChildren() do
			table.insert(RadioClient.categorizedSongs[category.Name], song)
		end
	end

	RadioClient.categoryAtom = atom("Relaxed") :: Charm.Atom<string>
	RadioClient.songAtom = atom() :: Charm.Atom<Sound?>
	RadioClient.mutedAtom = atom(false) :: Charm.Atom<boolean>

	local function checkMuted()
		local song = RadioClient.songAtom()
		if not song:GetAttribute("StartVolume") then
			song:SetAttribute("StartVolume", song.Volume)
		end
		song.Volume = RadioClient.mutedAtom() and 0 or song:GetAttribute("StartVolume")
	end

	local songPlaying = TopbarPlus.new()
	subscribe(RadioClient.categoryAtom, function(state, prev)
		RadioClient.pickRandomSong()
	end)
	local endConnection: RBXScriptConnection
	subscribe(RadioClient.songAtom, function(state: Sound, prev: Sound?)
		if endConnection then
			endConnection:Disconnect()
		end
		if prev then
			prev:Stop()
		end

		checkMuted()

		endConnection = state.Ended:Once(function()
			RadioClient.pickRandomSong()
		end)
		state:Play()
		songPlaying:setLabel(state.Name)
	end)
	subscribe(RadioClient.mutedAtom, checkMuted)

	local categories = {
		["Relaxed"] = TopbarPlus.new():setLabel("Relaxed"),
		["Hip Hop"] = TopbarPlus.new():setLabel("Hip Hop"),
		["Funk"] = TopbarPlus.new():setLabel("Funk"),
	}
	TopbarPlus.new():setLabel("🎵"):modifyTheme({ "Menu", "MaxIcons", 3 }):setMenu({
		TopbarPlus.new()
			:setLabel("🔇", "Selected")
			:setLabel("🔊", "Deselected")
			:bindEvent("selected", function()
				RadioClient.mutedAtom(true)
			end)
			:bindEvent("deselected", function()
				RadioClient.mutedAtom(false)
			end),
		TopbarPlus.new():setLabel("Category"):setDropdown(categories),
		songPlaying:align("Right"):oneClick(),
	})
	for i, v in categories do
		v.selected:Connect(function()
			RadioClient.categoryAtom(i)
		end)
	end
	RadioClient.pickRandomSong()
end

return RadioClient
