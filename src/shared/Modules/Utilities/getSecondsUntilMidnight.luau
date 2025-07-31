local function getSecondsUntilMidnight()
	local now = os.time()
	local currentDate = os.date("*t", now)

	-- Set time to midnight (00:00) of the next day
	local midnight = os.time({
		year = currentDate.year,
		month = currentDate.month,
		day = currentDate.day + 1,
		hour = 0,
		min = 0,
		sec = 0,
	})

	return midnight - now
end

return getSecondsUntilMidnight
