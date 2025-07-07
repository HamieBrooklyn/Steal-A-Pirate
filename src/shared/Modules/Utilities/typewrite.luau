local function typewrite(fullText: string, onStep: (partialText: string) -> (), onComplete: () -> (), speed: number?)
	speed = speed or 0.02

	local punctuationPause = {
		[","] = 0.2,
		["."] = 0.4,
		["!"] = 0.4,
		["?"] = 0.4,
		[";"] = 0.2,
		[":"] = 0.2,
	}

	coroutine.wrap(function()
		local current = ""
		for i = 1, #fullText do
			local char = fullText:sub(i, i)
			current ..= char
			onStep(current)

			local pause = punctuationPause[char] or speed
			task.wait(pause)
		end

		if onComplete then
			onComplete()
		end
	end)()
end

return typewrite
