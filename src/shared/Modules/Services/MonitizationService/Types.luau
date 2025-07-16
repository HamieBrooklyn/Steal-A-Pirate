local SharedMonitizationTypes = {}

export type ProductInfo = {
	Id: number,
	ProductType: "Product" | "Gamepass",
	ServerFunctionTypes: { string },
	ClientFunctionTypes: { string },

	StatNames: { string }?,
	CharacterNames: { string }?,
	Portals: { string }?,
	Durations: { number }?,
	Amounts: { number }?,
	ToggleableSettings: { [string]: boolean },
}

export type RecieptInfo = {
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType,

	PlaceIdWherePurchased: string,
	ProductPurchaseChannel: string,

	PlayerId: number,
	ProductId: number,
	PurchaseId: string,
}

return SharedMonitizationTypes
