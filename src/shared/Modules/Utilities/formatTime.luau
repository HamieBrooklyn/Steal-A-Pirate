--[[
	Format a time duration in seconds into a human-readable string.
	
	@param seconds: The number of seconds to format.
	@param config: A table with optional configuration options:
		- mode: "digital" or "text" (default is "digital")
		- showHours: Whether to include hours in the output (default is false for digital, true for text)
		- showMinutes: Whether to include minutes in the output (default is true)
		- showSeconds: Whether to include seconds in the output (default is true)
	
	@return A formatted string representing the time duration.
]]
local function formatTime(seconds: number, config: {
	mode: "digital" | "text",
	showHours: boolean?,
	showMinutes: boolean?,
	showSeconds: boolean?
}?): string
	config = config or {}
	local mode = config.mode or "digital"
	local showHours = config.showHours
	local showMinutes = config.showMinutes
	local showSeconds = config.showSeconds

	seconds = math.max(0, math.floor(seconds))
	local hrs = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	-- Default logic if nothing is specified
	if showHours == nil and showMinutes == nil and showSeconds == nil then
		if mode == "digital" then
			showHours = false
			showMinutes = true
			showSeconds = true
		else
			showHours = true
			showMinutes = true
			showSeconds = true
		end
	end

	if mode == "digital" then
		local parts = {}

		if showHours then
			table.insert(parts, string.format("%02d", hrs))
		end
		if showMinutes then
			table.insert(parts, string.format("%02d", mins))
		end
		if showSeconds then
			table.insert(parts, string.format("%02d", secs))
		end

		return table.concat(parts, ":")
	elseif mode == "text" then
		local parts = {}

		if showHours and hrs > 0 then
			table.insert(parts, string.format("%dh", hrs))
		end
		if showMinutes and mins > 0 then
			table.insert(parts, string.format("%dm", mins))
		end
		if showSeconds and secs > 0 or (#parts == 0) then
			table.insert(parts, string.format("%ds", secs))
		end

		return table.concat(parts, " ")
	else
		error("Invalid mode: " .. tostring(mode))
	end
end

return formatTime