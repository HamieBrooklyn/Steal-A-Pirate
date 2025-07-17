local function formatTime(
	seconds: number,
	config: {
		mode: "digital" | "text" | "milliseconds",
		showDays: boolean?,
		showHours: boolean?,
		showMinutes: boolean?,
		showSeconds: boolean?,
		showMilliseconds: boolean?,
	}?
): string
	config = config or {}
	local mode = config.mode or "digital"
	local showDays = config.showDays
	local showHours = config.showHours
	local showMinutes = config.showMinutes
	local showSeconds = config.showSeconds
	local showMilliseconds = config.showMilliseconds

	local totalMilliseconds = math.max(0, seconds * 1000)
	seconds = math.max(0, math.floor(seconds))
	local milliseconds = math.floor(totalMilliseconds % 1000)

	local days = math.floor(seconds / 86400)
	local hrs = math.floor((seconds % 86400) / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if
		showDays == nil
		and showHours == nil
		and showMinutes == nil
		and showSeconds == nil
		and showMilliseconds == nil
	then
		if mode == "digital" then
			showDays = false
			showHours = false
			showMinutes = true
			showSeconds = true
			showMilliseconds = false
		elseif mode == "milliseconds" then
			showDays = false
			showHours = false
			showMinutes = false
			showSeconds = true
			showMilliseconds = true
		else
			showDays = true
			showHours = true
			showMinutes = true
			showSeconds = true
			showMilliseconds = false
		end
	end

	if mode == "digital" then
		local parts = {}

		if showHours then
			table.insert(parts, string.format("%02d", hrs + days * 24))
		end
		if showMinutes then
			table.insert(parts, string.format("%02d", mins))
		end
		if showSeconds then
			table.insert(parts, string.format("%02d", secs))
		end
		if showMilliseconds then
			table.insert(parts, string.format("%03d", milliseconds))
		end

		return table.concat(parts, ":")
	elseif mode == "text" then
		local parts = {}

		if showDays and days > 0 then
			table.insert(parts, string.format("%dd", days))
		end
		if showHours and hrs > 0 then
			table.insert(parts, string.format("%dh", hrs))
		end
		if showMinutes and mins > 0 then
			table.insert(parts, string.format("%dm", mins))
		end

		local hasTimeParts = #parts > 0

		if showSeconds then
			if showMilliseconds then
				local totalSec = (secs + milliseconds / 1000)
				local rounded = math.floor(totalSec * 10 + 0.5) / 10
				table.insert(parts, string.format("%.1fs", rounded))
			elseif secs > 0 or not hasTimeParts then
				table.insert(parts, string.format("%ds", secs))
			end
		elseif showMilliseconds and not showSeconds then
			local msRounded = math.floor(milliseconds / 100 + 0.5) / 10
			table.insert(parts, string.format("%.1fms", msRounded * 1000))
		end

		return table.concat(parts, " ")
	elseif mode == "milliseconds" then
		return string.format("%dms", math.floor(totalMilliseconds))
	else
		error("Invalid mode: " .. tostring(mode))
	end
end

return formatTime
