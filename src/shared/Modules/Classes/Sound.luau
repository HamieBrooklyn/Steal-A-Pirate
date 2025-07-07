local Sound = {}
Sound.__index = Sound

type self = {
	Instance: Sound,
}
export type Sound = typeof(setmetatable({} :: self, Sound))

function Sound.new(sound: Sound | string, parent: Instance?, properties: { [string]: any }?)
	local self = setmetatable({}, Sound)

	self.Instance = self:CreateInstance(sound, properties)
	self.Instance.Parent = parent or workspace
	self.Instance.Ended:Once(function()
		self:Destroy()
	end)

	return self
end

function Sound:CreateInstance(sound: Sound | string, properties: { [string]: any }?)
	local soundInstance: Sound

	if typeof(sound) == "string" then
		soundInstance = Instance.new("Sound")
		soundInstance.SoundId = sound
	elseif typeof(sound) == "Instance" and sound:IsA("Sound") then
		soundInstance = sound:Clone()
	end

	if properties then
		for key, value in pairs(properties) do
			soundInstance[key] = value
		end
	end

	return soundInstance
end

function Sound.Play(self: Sound)
	if self.Instance then
		self.Instance:Play()
	end
end
function Sound.Stop(self: Sound)
	if self.Instance then
		self.Instance:Stop()
	end
end
function Sound.Pause(self: Sound)
	if self.Instance then
		self.Instance:Pause()
	end
end
function Sound.Resume(self: Sound)
	if self.Instance then
		self.Instance:Resume()
	end
end

function Sound.IsPlaying(self: Sound): boolean
	if self.Instance then
		return self.Instance.IsPlaying
	end
	return false
end

function Sound.SetVolume(self: Sound, volume: number)
	if self.Instance then
		self.Instance.Volume = volume
	end
end
function Sound.SetLooping(self: Sound, looping: boolean)
	if self.Instance then
		self.Instance.Looped = looping
	end
end
function Sound.SetPitch(self: Sound, pitch: number)
	if self.Instance then
		self.Instance.PlaybackSpeed = pitch
	end
end

function Sound.SetParent(self: Sound, parent: Instance)
	if self.Instance then
		self.Instance.Parent = parent
	end
end

function Sound.Destroy(self: Sound)
	self.Instance:Destroy()
end

return Sound
