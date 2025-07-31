local function getSecondsUntilDate(targetYear, targetMonth, targetDay, targetHour, targetMinute, targetSecond)
	local now = os.time()
	local target = os.time({
		year = targetYear,
		month = targetMonth,
		day = targetDay,
		hour = targetHour or 0,
		min = targetMinute or 0,
		sec = targetSecond or 0,
	})
	return target - now
end

return getSecondsUntilDate
