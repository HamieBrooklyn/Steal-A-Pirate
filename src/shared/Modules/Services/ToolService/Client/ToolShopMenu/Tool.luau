local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gradients = ReplicatedStorage.Assets.Templates.Gui.Gradients

local ToolItemTemplate = ReplicatedStorage.Assets.Templates.Gui.ToolShopItem

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Gradiented = require(ReplicatedStorage.Shared.Modules.Classes.Gradiented)

local Children = Fusion.Children
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function Tool(
	scope: Fusion.Scope<any>,
	props: {
		order: UsedAs<number>,

		toolName: UsedAs<string>,

		unlocked: UsedAs<booelean>,
		unlockText: UsedAs<string>,

		canInteract: UsedAs<boolean>,
		statusText: UsedAs<string>,

		title: UsedAs<string>,
		description: UsedAs<string>,

		image: UsedAs<string>,

		titleGradient: UsedAs<UIGradient>,
		descriptionGradient: UsedAs<UIGradient>,

		interact: () -> (),
	}
): Fusion.Child
	local frame: typeof(ToolItemTemplate) = scope:Hydrate(ToolItemTemplate:Clone())({
		LayoutOrder = props.order,
		Name = props.toolName,
	})

	scope:Hydrate(frame:WaitForChild("Interact"))({
		Interactable = props.canInteract,
		[Fusion.OnEvent("MouseButton1Click")] = props.interact,
	})
	scope:Hydrate(frame:WaitForChild("Status"))({
		Text = props.statusText,
	})

	scope:Hydrate(frame:WaitForChild("Title"))({
		Text = props.title,
		[Children] = props.titleGradient:Clone(),
	})
	scope:Hydrate(frame:WaitForChild("Description"))({
		Text = props.description,
		[Children] = props.descriptionGradient:Clone(),
	})
	frame:WaitForChild("Icon").Image = props.image

	scope:Hydrate(frame:WaitForChild("RebirthLock"))({
		Visible = scope:Computed(function(use)
			return not use(props.unlocked)
		end),
		Text = props.unlockText,
	})

	local backdropGradient = Gradiented.new(frame:WaitForChild("Backdrop"))
	local statusGradient = Gradiented.new(frame:WaitForChild("Status"))

	scope:Observer(props.canInteract):onBind(function()
		local canInteractState = peek(props.canInteract)
		backdropGradient.gradient:set(canInteractState and Gradients.Banana or Gradients.Rock)
		statusGradient.gradient:set(canInteractState and Gradients.Apple or Gradients.RedApple)
	end)

	return frame
end

return Tool
