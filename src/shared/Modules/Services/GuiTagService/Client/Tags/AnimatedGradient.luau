local AnimatedGradient = {}
AnimatedGradient.__index = AnimatedGradient

type self = {}
export type AnimatedGradient = typeof(setmetatable({} :: self, AnimatedGradient))

function AnimatedGradient.new(gradient: UIGradient): AnimatedGradient
	local self = setmetatable({}, AnimatedGradient) :: AnimatedGradient

	--//VARIABLES:
	local ts = game:GetService("TweenService")
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	local offset1 = { Offset = Vector2.new(0.75, 0) }
	local create = ts:Create(gradient, ti, offset1)
	local startingPos = Vector2.new(-1, 0)
	local addWait = 0

	--//ANIMATIONS:
	local function animate()
		create:Play()
		create.Completed:Wait() --wait for the tween to stop
		gradient.Offset = startingPos --resets offset
		create:Play() -- repeats anim
		create.Completed:Wait() -- waits for the tween to stop
		gradient.Offset = startingPos
		wait(addWait) --waits some time for the tween to stop
		animate() -- calls itself (for looping)
	end
	animate() -- calls the all funcions!!

	return self
end

function AnimatedGradient.Destroy(self: AnimatedGradient): () end

return AnimatedGradient
