--// Skeet-Style Notification System (custom sound ready)

local NotificationSystem = {}

--// Services
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

--// Setup GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CheatNotificationUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotificationHolder"
NotificationHolder.Size = UDim2.new(0, 300, 1, -20)
NotificationHolder.Position = UDim2.new(1, -310, 0, 10)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = ScreenGui

--// Add a single sound instance
local Sound = Instance.new("Sound")
Sound.Name = "NotificationSound"
Sound.SoundId = "rbxassetid://70850789408719" -- << Replace this with your sound ID
Sound.Volume = 1
Sound.PlayOnRemove = true
Sound.Parent = ScreenGui

--// Function to create notifications
function NotificationSystem:CreateNotification(text, color, duration)
	color = color or Color3.fromRGB(0, 162, 255)
	duration = duration or 3

	-- Clone and play the sound (play-on-remove method = instant + no delays)
	local notificationSound = Sound:Clone()
	notificationSound:Play()  -- Play the sound immediately when creating the notification

	-- Create notification frame
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(1, 0, 0, 40)
	notif.Position = UDim2.new(0, 0, 0, 0)
	notif.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	notif.BorderColor3 = color
	notif.BorderSizePixel = 2
	notif.BackgroundTransparency = 1
	notif.ClipsDescendants = true
	notif.Parent = NotificationHolder

	-- Create text label for the notification
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Font = Enum.Font.Code
	label.TextSize = 16
	label.Parent = notif

	-- Add UI stroke for the border
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = color
	stroke.Parent = notif

	-- Move older notifications down
	for _, child in ipairs(NotificationHolder:GetChildren()) do
		if child:IsA("Frame") and child ~= notif then
			child:TweenPosition(child.Position + UDim2.new(0, 0, 0, 45), "Out", "Quad", 0.2, true)
		end
	end

	-- Fade-in effect
	local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	})
	tweenIn:Play()

	-- Fade-out effect after the specified duration
	task.delay(duration, function()
		local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		notif:Destroy()
	end)
end

return NotificationSystem
