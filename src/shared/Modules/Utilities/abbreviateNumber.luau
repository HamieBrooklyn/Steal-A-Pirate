local suffixes = { "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "O", "N" }

local function abbreviateNumber(number: number)
	if number == nil then
		return "0"
	end

	local negative = (tonumber(number) or 0) < 0

	if negative then
		number = -number
	end
	if not (tonumber(number)) or tonumber(number) <= 999 then
		return number
	end
	local str = number

	if number > 99_999_999 then
		for i = 1, #suffixes do
			if tonumber(number) < 10 ^ (i * 3) then
				str = math.floor(number / ((10 ^ ((i - 1) * 3)) / 100)) / 100 .. suffixes[i - 1]
				break
			end
		end
	else
		local formatted, k = number, nil
		while task.wait() do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
			if k == 0 then
				break
			end
		end

		str = tostring(formatted)
	end

	if str and negative then
		str = "-" .. str
	end
	return str
end

return abbreviateNumber
