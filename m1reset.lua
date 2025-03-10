local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
if not character then return end

local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")

if humanoidRootPart and humanoid then
    local userInputService = game:GetService("UserInputService")
    local playerGui = player:WaitForChild("PlayerGui")

    -- Function to create the cooldown UI
    humanoid.AnimationPlayed:Connect(function(track)
        if track.Animation and track.Animation.AnimationId == "rbxassetid://10479335397" then
            
            -- Create GUI
            local cooldownGui = Instance.new("ScreenGui")
            cooldownGui.Parent = playerGui
            
            local cooldownText = Instance.new("TextLabel")
            cooldownText.Size = UDim2.new(0, 200, 0, 50)
            cooldownText.Position = UDim2.new(0.5, -100, 0.8, 0)
            cooldownText.BackgroundTransparency = 1
            cooldownText.TextScaled = true
            cooldownText.TextColor3 = Color3.fromRGB(255, 0, 0)
            cooldownText.Font = Enum.Font.SourceSansBold
            cooldownText.Parent = cooldownGui
            
            -- Countdown loop
            for i = 5, 1, -1 do
                cooldownText.Text = "Dash cooldown - " .. i .. "s"
                task.wait(1)
            end
            
            cooldownGui:Destroy()
        end
    end)

    local function onKeyPress(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.C then
            -- Load and play animation
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://10480793962"
            local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
            local animationTrack = animator:LoadAnimation(animation)
            animationTrack:Play()

            -- Teleport backwards by 27.3 studs
            local teleportOffset = humanoidRootPart.CFrame.LookVector * -27.3
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + teleportOffset

            -- Wait 0.2 seconds after teleport
            task.wait(0.2)

            -- Fire the server with Dash and KeyPress
            local args = {
                [1] = {
                    ["Dash"] = Enum.KeyCode.W,
                    ["Key"] = Enum.KeyCode.Q,
                    ["Goal"] = "KeyPress"
                }
            }

            game:GetService("Players").LocalPlayer.Character.Communicate:FireServer(unpack(args))
        end
    end

    userInputService.InputBegan:Connect(onKeyPress)
end
