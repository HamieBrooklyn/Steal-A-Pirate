local function getMutationsString(mutations: { string })
	local finalString = ""
	for i, v in mutations do
		finalString = `{finalString}{v}{i < #mutations and "," or ""}`
	end
	return finalString
end

return getMutationsString
