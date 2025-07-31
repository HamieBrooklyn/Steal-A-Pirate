local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Services = ReplicatedStorage.Shared.Modules.Services

local GuiSFX = ReplicatedStorage.Assets.Sounds.SoundEffects.Gui
local DingSound = GuiSFX.Ding
local TickSound = GuiSFX.Tick

local MonitizationClient = require(Services.MonitizationService.Client)

local SharedData = require(script.Parent.Data)

local SpinMenu = require(ReplicatedStorage.Shared.Modules.Services.SpinnerService.Client.SpinMenu)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)
local createTaggedComponent = require(ReplicatedStorage.Shared.Modules.Utilities.createTaggedComponent)
local Spinner = require(script.Spinner)
local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)
local getSecondsUntilMidnight = require(ReplicatedStorage.Shared.Modules.Utilities.getSecondsUntilMidnight)

local peek = Fusion.peek

local SpinnerClient = {}
SpinnerClient.getSpins = Net:RemoteFunction("GetSpins")
SpinnerClient.spinAttempt = Net:RemoteFunction("SpinAttempt")

function SpinnerClient.init()
	local scope = Fusion.scoped(Fusion)
	local slots = scope:Value({
		[1] = {
			Title = "2X Server Luck",
			Image = "rbxassetid://131533975492593",
			BottomText = "2%",
		},
		[2] = {
			Title = "Grandfather Slap",
			Image = "rbxassetid://93283912524413",
			BottomText = "0.5%",
		},
		[3] = {
			Title = "Large Mum",
			Image = "rbxassetid://128261415837741",
			BottomText = "1%",
		},
		[4] = {
			Title = "25K",
			Image = "rbxassetid://131236980041767",
			BottomText = "55%",
		},
		[5] = {
			Title = "1M",
			Image = "rbxassetid://99089127991964",
			BottomText = "7.5%",
		},
		[6] = {
			Title = "100K",
			Image = "rbxassetid://83623157648772",
			BottomText = "34%",
		},
	})
	local spins = scope:Value(SpinnerClient.getSpins:InvokeServer() or 0)
	Net:Connect("SpinsUpdated", function(newSpins: number)
		spins:set(newSpins)
	end)
	local isSpinning = scope:Value(false)
	local canSpin = scope:Computed(function(use: Fusion.Use)
		return use(spins) > 0 and not use(isSpinning)
	end)
	local rotation = scope:Value(0)
	local arrowRotationSpring: Fusion.Spring = scope:Spring(scope:Value(0), 25, 0.9)
	local menu = scope:New("ScreenGui")({
		Name = "Spinner",
		ResetOnSpawn = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
		[Fusion.Children] = SpinMenu(scope, {
			slots = slots,

			spinsText = scope:Computed(function(use: Fusion.Use)
				return `Spin! ({use(spins)})`
			end),
			canSpin = canSpin,
			rotation = rotation,
			arrowRotation = arrowRotationSpring,

			promptSpinPurchase = MonitizationClient.PromptPurchase,
			spinAttempt = function()
				local rewardIndex, angle = SpinnerClient.spinAttempt:InvokeServer()
				if rewardIndex and angle then
					spins:set(peek(spins) - 1)
					isSpinning:set(true)

					rotation:set(0)
					local startAngle = 0
					local targetAngle = math.random(4, 6) * 360 + angle
					local finalAngle = startAngle + targetAngle
					local elapsed = 0
					local lastSlot = math.floor(startAngle / (360 / 6))

					local connection
					connection = RunService.RenderStepped:Connect(function(dt)
						elapsed += dt
						local alpha = math.clamp(elapsed / SharedData.AwardDelay, 0, 1)

						local easedAlpha = alpha < 0.5 and 4 * alpha * alpha * alpha
							or 1 - math.pow(-2 * alpha + 2, 3) / 2
						local currentAngle = startAngle - (finalAngle - startAngle) * easedAlpha
						rotation:set(currentAngle)

						local currentSlot = math.floor((currentAngle % 360) / (360 / 6))
						if currentSlot ~= lastSlot then
							Sound.new(TickSound, workspace):Play()
							arrowRotationSpring:addVelocity(1000)
							lastSlot = currentSlot
						end

						if alpha >= 1 then
							connection:Disconnect()
							Sound.new(DingSound, workspace):Play()
							task.wait(1)
							isSpinning:set(false)
						end
					end)
				end
			end,
		}),
	})
	menu:AddTag("Menu")

	local freeSpinText: Fusion.Value<string> = scope:Value("")
	createTaggedComponent("Spinner", Spinner, nil, freeSpinText, rotation, slots, arrowRotationSpring)
	RunService.Heartbeat:Connect(function()
		freeSpinText:set(`Free Spin in {formatTime(getSecondsUntilMidnight(), {
			mode = "digital",
			showDays = false,
			showHours = true,
			showMinutes = true,
			showSeconds = true,
			showMilliseconds = false,
		})}`)
	end)
end

return SpinnerClient
