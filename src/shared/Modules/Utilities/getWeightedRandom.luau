local function getWeightedRandom(items: { [string]: number }, multiplier: number)
	multiplier = multiplier or 1

	local totalWeight = 0

	local rarities = {}
	for item, weight in items do
		totalWeight += weight
		rarities[item] = weight
	end

	local randomValue = math.random() * totalWeight
	local current = 0

	for item, weight in rarities do
		current += weight * (if weight < 0.1 then multiplier else 1)
		if randomValue <= current then
			return item
		end
	end
end

return getWeightedRandom
