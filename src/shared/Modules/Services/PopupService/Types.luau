local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local SharedPopupTypes = {}

export type PopupProps = {
	message: UsedAs<string>,
	duration: number?,
	gradient: UIGradient?,
}

return SharedPopupTypes
