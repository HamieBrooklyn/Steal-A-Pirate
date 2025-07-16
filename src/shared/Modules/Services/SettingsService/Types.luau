local SharedSettingsTypes = {}

export type SettingData = {
	SettingType: string,

	Title: string,
	Description: string?,

	ServerFunctionality: string?,
	ClientFunctionality: string?,

	ServerConditions: { string }?,
	ClientConditions: { string }?,

	GamepassKeys: { string }?,

	Default: any?,

	Weight: number,
}

return SharedSettingsTypes
