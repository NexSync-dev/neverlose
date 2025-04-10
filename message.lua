--// Skeet-Style Notification System

local NotificationSystem = {}

--// Services
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

--// Setup the main GUI
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

--// Function to create and show notifications
function NotificationSystem:CreateNotification(text, color, duration)
	color = color or Color3.fromRGB(0, 162, 255)  -- Default blue accent
	duration = duration or 3

	-- Create notification frame
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(1, 0, 0, 40)
	notif.Position = UDim2.new(0, 0, 0, 0)
	notif.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	notif.BorderColor3 = color
	notif.BorderSizePixel = 2
	notif.ClipsDescendants = true
	notif.BackgroundTransparency = 1
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

	-- Create subtle UI stroke effect for sharpness
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

--// Example usage of the system (This is just for testing, you can remove it)
NotificationSystem:CreateNotification("Loading", Color3.fromRGB(0, 255, 140), 3)

return NotificationSystem
loadstring(game:HttpGet("https://raw.githubusercontent.com/NexSync-dev/neverlosegui/refs/heads/main/test.lua", true))()
