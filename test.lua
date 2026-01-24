-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Global State
local features = {
    autoBlock = { enabled = false, range = 10, bubble = nil, looking = false },
    aimbot = { mode = "closest to player", trackConnection = nil },
    esp = { enabled = false, boxEnabled = false, boxColor = Color3.new(1,0,0), healthEnabled = false, tracersEnabled = false, skeletonEnabled = false, chamsEnabled = false },
    lighting = { enabled = false, color = Color3.fromRGB(255, 182, 193) },
    noStun = false,
    antiFling = { enabled = false },
    antiVoid = { enabled = false, platform = nil },
    stopAnims = false,
    bootyClap = { following = false, target = nil, loop = nil },
    antiDeath = { enabled = false, originalPos = nil },
    infJump = false
}

-- Library Initialization
local Library, Notifications = loadstring(game:HttpGet("https://raw.githubusercontent.com/l1l1l1l1l11l1l1l1l11/Neverlose-Main/refs/heads/main/nssso.luau"))()

-- Window
local Window = Library:window({
    name = "femboys.pub",
    size = UDim2.new(0, 650, 0, 450)
})

-- ====================
-- TAB: DEFINITIONS
-- ====================
local LegitTab = Window:Tab({ name = "Legit" })
local BlatantTab = Window:Tab({ name = "Blatant" })
local VisualsTab = Window:Tab({ name = "Visuals" })
local MiscTab = Window:Tab({ name = "Misc" })

-- ====================
-- TAB: LEGIT
-- ====================
local LegitMain = LegitTab:Section({ name = "Main", side = "left" })
local LegitExtra = LegitTab:Section({ name = "Extra", side = "right" })

-- Soft Aim Lock
RunService.BindToRenderStep(RunService, "SoftAim", Enum.RenderPriority.Camera.Value + 1, function()
    if not features.autoBlock.enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local closestTarget = nil; local closestDist = features.autoBlock.range
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= LocalPlayer and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
            local tHrp = other.Character.HumanoidRootPart
            local dist = (hrp.Position - tHrp.Position).Magnitude
            if dist <= features.autoBlock.range and dist < closestDist then closestDist = dist; closestTarget = tHrp end
        end
    end
    if closestTarget then
        local dir = (closestTarget.Position - hrp.Position).Unit
        local lookCf = CFrame.new(hrp.Position, hrp.Position + Vector3.new(dir.X, 0, dir.Z))
        hrp.CFrame = lookCf
    end
end)
LegitMain:Toggle({ name = "Soft Aim Lock", callback = function(bool) features.autoBlock.enabled = bool end })
LegitMain:Slider({ name = "Range", min = 10, max = 100, default = 10, suffix = " studs", callback = function(val) features.autoBlock.range = val end })
LegitExtra:Button({ name = "M1 reset script(keybind c)", callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NexSync-dev/neverlosegui/refs/heads/main/m1reset.lua"))() end })

-- ====================
-- TAB: VISUALS
-- ====================
local EspSection = VisualsTab:Section({ name = "ESP Configuration", side = "left" })
local WorldSection = VisualsTab:Section({ name = "World Settings", side = "right" })

-- Variables
local espConfig = {
    boxStyle = "Corner", 
    healthStyle = "Bar",
    tracerOrigin = "Bottom",
    tsbClass = true,
    deathCounter = true,
    fillTransparency = 0.5
}

-- TSB Detection
local function getTSBClass(player)
    if not player then return "None" end
    local backpack = player.Backpack; local char = player.Character
    local function has(name) return (backpack and backpack:FindFirstChild(name)) or (char and char:FindFirstChild(name)) end
    if has("Normal Punch") then return "Saitama" end
    if has("Table Flip") or has("Death Counter") then return "Saitama Ult" end 
    if has("Flowing Water") then return "Garou" end
    if has("The Final Hunt") then return "Garou Ult" end
    if has("Incinerate") then return "Genos" end
    if has("Jet Dive") then return "Genos Ult" end
    if has("Whirlwind") then return "Tatsumaki" end
    return "Unknown"
end

-- ESP Drawing
local espCache = {}
local dcCache = {} 

local function createDrawing(type, props)
    local d = Drawing.new(type)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local function removeEsp(p)
    if espCache[p] then 
        for k, d in pairs(espCache[p]) do 
            if type(d) == "table" then for _, l in pairs(d) do l:Remove() end else d:Remove() end
        end 
        espCache[p] = nil 
    end
    -- Remove Chams
    if p.Character then
        local hl = p.Character:FindFirstChild("TSB_Highlight")
        if hl then hl:Destroy() end
    end
end

RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Head") then
             if not features.esp.enabled then removeEsp(p) continue end
             local char = p.Character; local hrp = char.HumanoidRootPart; local head = char.Head; local hum = char.Humanoid
             local vec, onScreen = cam:WorldToViewportPoint(hrp.Position)
             
             -- Chams Logic
             local hl = char:FindFirstChild("TSB_Highlight")
             if features.esp.chamsEnabled then
                 if not hl then
                     hl = Instance.new("Highlight", char)
                     hl.Name = "TSB_Highlight"
                     hl.FillTransparency = 0.5
                     hl.OutlineTransparency = 0
                 end
                 hl.FillColor = features.esp.boxColor
                 hl.OutlineColor = Color3.new(1,1,1)
                 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
             else
                 if hl then hl:Destroy() end
             end

             if onScreen and hum.Health > 0 then
                  if not espCache[p] then
                      espCache[p] = {
                          box = createDrawing("Square", {Thickness=1, Color=Color3.new(1,0,0), Filled=false, Transparency=1}),
                          filledBox = createDrawing("Square", {Thickness=0, Filled=true, Transparency=0.5}),
                          corners = {}, -- Table for corner lines
                          name = createDrawing("Text", {Size=16, Center=true, Outline=true, Color=Color3.new(1,1,1)}),
                          dist = createDrawing("Text", {Size=14, Center=true, Outline=true, Color=Color3.new(1,1,1)}),
                          hpText = createDrawing("Text", {Size=14, Center=true, Outline=true, Color=Color3.new(0,1,0)}),
                          healthBar = createDrawing("Square", {Filled=true, Thickness=1, Transparency=1}),
                          healthOutline = createDrawing("Square", {Filled=false, Thickness=1, Color=Color3.new(0,0,0), Transparency=1}),
                          tracer = createDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1), Transparency=1}),
                          classText = createDrawing("Text", {Size=14, Center=true, Outline=true, Color=Color3.fromRGB(255, 215, 0)}),
                          headDot = createDrawing("Circle", {Radius=3, Filled=true, Color=Color3.new(1,1,1), Visible=false}),
                          skeleton = {}
                      }
                      -- Init Corners (8 lines)
                      for i=1,8 do table.insert(espCache[p].corners, createDrawing("Line", {Thickness=3, Color=Color3.new(1,0,0), Transparency=1})) end -- Thicker
                      -- Init Skeleton (10 lines)
                      for i=1,12 do table.insert(espCache[p].skeleton, createDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1), Transparency=1})) end -- More lines just in case
                  end
                  local cache = espCache[p]
                  local headPos = cam:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                  local legPos = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
                  local height = legPos.Y - headPos.Y
                  local width = height / 2
                  
                  local mainColor = Color3.new(1,1,1)
                  if espConfig.deathCounter then
                      local hasDC = (p.Backpack and p.Backpack:FindFirstChild("Death Counter")) or (char and char:FindFirstChild("Death Counter"))
                      if hasDC then mainColor = Color3.fromRGB(255, 0, 0); dcCache[p]=0 elseif dcCache[p] and dcCache[p]>tick() then mainColor = Color3.fromRGB(255, 255, 0) else if dcCache[p]==0 then dcCache[p]=tick()+10 end end
                  end
                  
                  -- Box Styles
                  cache.box.Visible = false; cache.filledBox.Visible = false; for _,l in pairs(cache.corners) do l.Visible = false end
                  if features.esp.boxEnabled then
                      if espConfig.boxStyle == "Corner" then
                           local tl, tr, bl, br = Vector2.new(vec.X - width/2, vec.Y - height/2), Vector2.new(vec.X + width/2, vec.Y - height/2), Vector2.new(vec.X - width/2, vec.Y + height/2), Vector2.new(vec.X + width/2, vec.Y + height/2)
                           local len = width / 2 -- Longer lines
                           local c = cache.corners
                           c[1].Visible=true; c[1].From=tl; c[1].To=tl+Vector2.new(len,0); c[1].Color=features.esp.boxColor
                           c[2].Visible=true; c[2].From=tl; c[2].To=tl+Vector2.new(0,len); c[2].Color=features.esp.boxColor
                           c[3].Visible=true; c[3].From=tr; c[3].To=tr-Vector2.new(len,0); c[3].Color=features.esp.boxColor
                           c[4].Visible=true; c[4].From=tr; c[4].To=tr+Vector2.new(0,len); c[4].Color=features.esp.boxColor
                           c[5].Visible=true; c[5].From=bl; c[5].To=bl+Vector2.new(len,0); c[5].Color=features.esp.boxColor
                           c[6].Visible=true; c[6].From=bl; c[6].To=bl-Vector2.new(0,len); c[6].Color=features.esp.boxColor
                           c[7].Visible=true; c[7].From=br; c[7].To=br-Vector2.new(len,0); c[7].Color=features.esp.boxColor
                           c[8].Visible=true; c[8].From=br; c[8].To=br-Vector2.new(0,len); c[8].Color=features.esp.boxColor
                      elseif espConfig.boxStyle == "Filled" then
                           cache.filledBox.Visible = true; cache.filledBox.Size = Vector2.new(width, height); cache.filledBox.Position = Vector2.new(vec.X - width/2, vec.Y - height/2); cache.filledBox.Color = features.esp.boxColor; cache.filledBox.Transparency = espConfig.fillTransparency
                           cache.box.Visible = true; cache.box.Size = Vector2.new(width, height); cache.box.Position = Vector2.new(vec.X - width/2, vec.Y - height/2); cache.box.Color = features.esp.boxColor
                      else
                           cache.box.Visible = true; cache.box.Size = Vector2.new(width, height); cache.box.Position = Vector2.new(vec.X - width/2, vec.Y - height/2); cache.box.Color = features.esp.boxColor
                      end
                  end
                  
                  -- Name/Dist (Info) - ALWAYS UPDATE if Enabled, independent of Box
                  if features.esp.infoEnabled then -- Now checks flag
                      cache.name.Visible = true; cache.name.Text = p.Name; cache.name.Position = Vector2.new(vec.X, headPos.Y - 18); cache.name.Color = mainColor
                      cache.dist.Visible = true; cache.dist.Text = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) .. "m"; cache.dist.Position = Vector2.new(vec.X, vec.Y + height/2 + 2); cache.dist.Color = mainColor
                  else
                      cache.name.Visible = false; cache.dist.Visible = false
                  end
                  
                  -- Health
                  if features.esp.healthEnabled then
                      local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                      local barHeight = height * healthPct
                      if espConfig.healthStyle == "Bar" or espConfig.healthStyle == "Both" then
                          cache.healthOutline.Visible = true; cache.healthOutline.Size = Vector2.new(4, height); cache.healthOutline.Position = Vector2.new(vec.X - width/2 - 6, vec.Y - height/2)
                          cache.healthBar.Visible = true; cache.healthBar.Color = Color3.fromHSV(healthPct * 0.3, 1, 1); cache.healthBar.Size = Vector2.new(2, barHeight); cache.healthBar.Position = Vector2.new(vec.X - width/2 - 5, (vec.Y - height/2) + (height - barHeight))
                      else cache.healthOutline.Visible=false; cache.healthBar.Visible=false end
                      
                      if espConfig.healthStyle == "Text" or espConfig.healthStyle == "Both" then
                          cache.hpText.Visible = true; cache.hpText.Text = math.floor(hum.Health); cache.hpText.Position = Vector2.new(vec.X - width/2 - 20, vec.Y - height/2)
                      else cache.hpText.Visible = false end
                  else cache.healthOutline.Visible=false; cache.healthBar.Visible=false; cache.hpText.Visible=false end

                  if espConfig.tsbClass then cache.classText.Visible = true; cache.classText.Text = getTSBClass(p); cache.classText.Position = Vector2.new(vec.X, headPos.Y - 32) else cache.classText.Visible = false end

                  if features.esp.tracersEnabled then
                      cache.tracer.Visible = true; cache.tracer.To = Vector2.new(vec.X, vec.Y)
                      if espConfig.tracerOrigin == "Bottom" then cache.tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                      elseif espConfig.tracerOrigin == "Center" then cache.tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                      else local m = UserInputService:GetMouseLocation(); cache.tracer.From = m end
                  else cache.tracer.Visible = false end

                  if features.esp.skeletonEnabled then
                      local function line(idx, p1, p2)
                          if not p1 or not p2 then return end -- Safety check
                          local l = cache.skeleton[idx]; if not l then return end
                          local v1, os1 = cam:WorldToViewportPoint(p1.Position); local v2, os2 = cam:WorldToViewportPoint(p2.Position)
                          if os1 and os2 then l.Visible = true; l.From = Vector2.new(v1.X, v1.Y); l.To = Vector2.new(v2.X, v2.Y) else l.Visible = false end
                      end
                      if char:FindFirstChild("UpperTorso") then
                          line(1, char:FindFirstChild("Head"), char:FindFirstChild("UpperTorso")); line(2, char:FindFirstChild("UpperTorso"), char:FindFirstChild("LeftUpperArm")); line(3, char:FindFirstChild("UpperTorso"), char:FindFirstChild("RightUpperArm"))
                          line(4, char:FindFirstChild("LeftUpperArm"), char:FindFirstChild("LeftLowerArm")); line(5, char:FindFirstChild("RightUpperArm"), char:FindFirstChild("RightLowerArm"))
                          line(6, char:FindFirstChild("UpperTorso"), char:FindFirstChild("LowerTorso")); line(7, char:FindFirstChild("LowerTorso"), char:FindFirstChild("LeftUpperLeg"))
                          line(8, char:FindFirstChild("LowerTorso"), char:FindFirstChild("RightUpperLeg"))
                          line(9, char:FindFirstChild("LeftUpperLeg"), char:FindFirstChild("LeftLowerLeg")); line(10, char:FindFirstChild("RightUpperLeg"), char:FindFirstChild("RightLowerLeg"))
                      else -- TSB often uses R15 but if R6 fallback
                             for _,l in pairs(cache.skeleton) do l.Visible=false end 
                      end
                  else for _,l in pairs(cache.skeleton) do l.Visible=false end end
             else removeEsp(p) end
        else removeEsp(p) end
    end
end)
Players.PlayerRemoving:Connect(removeEsp)

-- ESP UI
local masterToggle = EspSection:Toggle({ name = "ESP Enabled", callback = function(bool) features.esp.enabled = bool; if not bool then for p,_ in pairs(espCache) do removeEsp(p) end end end })
masterToggle:Toggle({ name = "Show TSB Class", callback = function(bool) espConfig.tsbClass = bool end })
masterToggle:Toggle({ name = "Death Counter Highlight", callback = function(bool) espConfig.deathCounter = bool end })
masterToggle:Toggle({ name = "Show Info (Name/Dist)", callback = function(bool) features.esp.infoEnabled = bool end }) -- NEW BUTTON

local boxToggle = EspSection:Toggle({ name = "Boxes", callback = function(bool) features.esp.boxEnabled = bool end })
boxToggle:Dropdown({ name = "Style", items = {"Full", "Filled", "Corner"}, default = "Corner", callback = function(val) espConfig.boxStyle = val end })
boxToggle:Colorpicker({ name = "Color", default = Color3.new(1,0,0), callback = function(col) features.esp.boxColor = col end })
boxToggle:Slider({ name = "Fill Transparency", min = 0, max = 1, default = 0.5, callback = function(val) espConfig.fillTransparency = val end })

local healthToggle = EspSection:Toggle({ name = "Health", callback = function(bool) features.esp.healthEnabled = bool end })
healthToggle:Dropdown({ name = "Style", items = {"Bar", "Text", "Both"}, default = "Bar", callback = function(val) espConfig.healthStyle = val end })

local tracerToggle = EspSection:Toggle({ name = "Tracers", callback = function(bool) features.esp.tracersEnabled = bool end })
tracerToggle:Dropdown({ name = "Origin", items = {"Bottom", "Center", "Mouse"}, default = "Bottom", callback = function(val) espConfig.tracerOrigin = val end })

EspSection:Toggle({ name = "Skeleton", callback = function(bool) features.esp.skeletonEnabled = bool end })
EspSection:Toggle({ name = "Chams", callback = function(bool) features.esp.chamsEnabled = bool end })

-- World UI
local cc = Lighting:FindFirstChild("TSB_CC") or Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "TSB_CC"; cc.Enabled = false
local blur = Lighting:FindFirstChild("TSB_Blur") or Instance.new("BlurEffect", Lighting); blur.Name = "TSB_Blur"; blur.Size = 0; blur.Enabled = false

local function uiToggleWorld(bool) if bool then cc.Enabled=true else cc.Enabled=false; blur.Enabled=false end end -- Helper

local worldToggle = WorldSection:Toggle({ name = "World Modifications", callback = function(bool) features.lighting.enabled = bool; uiToggleWorld(bool) end }) 
worldToggle:Colorpicker({ name = "Fog Color", default = Color3.new(0.5,0.5,0.5), callback = function(col) Lighting.FogColor = col end })
worldToggle:Slider({ name = "Time", min=0, max=24, default=14, callback = function(val) Lighting.TimeOfDay = tostring(val)..":00:00" end })
worldToggle:Slider({ name = "Brightness", min=0, max=10, default=2, callback = function(val) Lighting.Brightness = val end })
worldToggle:Slider({ name = "Saturation", min=0, max=2, default=1, callback = function(val) cc.Saturation = val end })
worldToggle:Slider({ name = "Contrast", min=0, max=2, default=1, callback = function(val) cc.Contrast = val end })
worldToggle:Slider({ name = "Blur Size", min=0, max=30, default=0, callback = function(val) blur.Size = val; blur.Enabled = (val > 0) end })


-- ====================
-- TAB: BLATANT
-- ====================
local BlatantCombat = BlatantTab:Section({ name = "Combat", side = "left" })
local BlatantChar = BlatantTab:Section({ name = "Character & TP", side = "right" })

BlatantCombat:Dropdown({ name = "Target Mode", items = {"closest to player", "closest to mouse"}, default = "closest to player", callback = function(val) features.aimbot.mode = val end })
BlatantCombat:Toggle({
    name = "Garou Insta Kill",
    callback = function(bool)
         getgenv().instaKillActive = bool 
         if bool then
            getgenv().instaKillLoop = coroutine.create(function()
                local animations = {["rbxassetid://12273188754"] = 1.31, ["rbxassetid://12296113986"] = 1.2}
                while true do
                    task.wait()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then
                         local animator = char.Humanoid:FindFirstChild("Animator")
                         if animator then
                             for _, v in pairs(animator:GetPlayingAnimationTracks()) do
                                if animations[v.Animation.AnimationId] then
                                    task.wait(animations[v.Animation.AnimationId])
                                    local dothetech = true
                                    local lastcf = char.HumanoidRootPart.CFrame
                                    v.Stopped:Connect(function() dothetech = false end)
                                    repeat
                                        task.wait()
                                        Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                                        char.HumanoidRootPart.CFrame = CFrame.new(0, -300, 0)
                                        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                                        char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                                    until not dothetech
                                    task.wait(0.1)
                                    char.HumanoidRootPart.CFrame = lastcf
                                    Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                                    Workspace.CurrentCamera.CameraSubject = char.Humanoid
                                    task.wait(1)
                                end
                             end
                         end
                    end
                end
            end)
            coroutine.resume(getgenv().instaKillLoop)
        else
            if getgenv().instaKillLoop then coroutine.close(getgenv().instaKillLoop) end
        end
    end
})
BlatantCombat:Button({ name = "Fling All (External)", callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/zqyDSUWX"))() end })

BlatantChar:Toggle({ name = "No Stun", callback = function(bool) features.noStun = bool end })
BlatantChar:Toggle({ name = "Anti Fling", callback = function(bool) features.antiFling.enabled = bool end })
BlatantChar:Toggle({ name = "Anti Death", callback = function(bool) features.antiDeath.enabled = bool end })
BlatantChar:Toggle({ name = "No Animations", callback = function(bool) features.stopAnims = bool end })
BlatantChar:Toggle({ name = "Noclip", callback = function(bool) features.noclip = bool end })
BlatantChar:Toggle({ name = "Infinite Jump", callback = function(bool) features.infJump = bool end })

-- TPs
local tpTarget = "None"
local tpNames = {"None", "Safe Zone", "Mid", "Void"}
BlatantChar:Dropdown({ name = "Select TP Target", items = tpNames, default = "None", callback = function(val) tpTarget = val end })
BlatantChar:Button({ name = "Teleport Now", callback = function()
    local char = LocalPlayer.Character
    if not char then return end
    if tpTarget == "Safe Zone" then char.HumanoidRootPart.CFrame = CFrame.new(-10, 808, -378)
    elseif tpTarget == "Mid" then char.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
    elseif tpTarget == "Void" then char.HumanoidRootPart.CFrame = CFrame.new(0, -490, 0)
    else 
        local tPlayer = Players:FindFirstChild(tpTarget)
        if tPlayer and tPlayer.Character then char.HumanoidRootPart.CFrame = tPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end
    end
end})
BlatantChar:Button({ name = "Give Click TP Tool", callback = function()
    local mouse = LocalPlayer:GetMouse()
    local tool = Instance.new("Tool"); tool.RequiresHandle = false; tool.Name = "Click TP"
    tool.Activated:Connect(function()
        local pos = mouse.Hit.Position + Vector3.new(0, 2.5, 0)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y, pos.Z) end
    end)
    tool.Parent = LocalPlayer.Backpack
end })

-- Flight Logic (LinearVelocity)
local flySpeed = 1
local flying = false
local flyBV, flyAtt

local function startFly()
     if not LocalPlayer.Character then return end
     local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
     local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
     if not hrp or not hum then return end
     
     if flyBV then flyBV:Destroy() end
     if flyAtt then flyAtt:Destroy() end

     flyAtt = Instance.new("Attachment", hrp)
     flyBV = Instance.new("LinearVelocity", hrp)
     flyBV.Attachment0 = flyAtt
     flyBV.MaxForce = math.huge
     flyBV.VectorVelocity = Vector3.zero
     flyBV.RelativeTo = Enum.ActuatorRelativeTo.World
     
     hum.PlatformStand = true
     
     RunService:BindToRenderStep("FlyStep", Enum.RenderPriority.Camera.Value, function()
        if not flying or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then 
            RunService:UnbindFromRenderStep("FlyStep")
            if flyBV then flyBV:Destroy() end; if flyAtt then flyAtt:Destroy() end
            if hum then hum.PlatformStand = false end
            return
        end
        
        local cam = Workspace.CurrentCamera
        local ctrl = {f=0, b=0, l=0, r=0}
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then ctrl.f = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then ctrl.b = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then ctrl.l = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then ctrl.r = 1 end
        
        local speed = flySpeed * 50
        local dir = Vector3.zero
        dir = dir + cam.CFrame.LookVector * (ctrl.f - ctrl.b)
        dir = dir + cam.CFrame.RightVector * (ctrl.r - ctrl.l)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        
        flyBV.VectorVelocity = dir * speed
        hum.PlatformStand = true
     end)
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if features.infJump then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Aggressive Loops
RunService.Stepped:Connect(function()
    -- No Stun: Clear Attributes AND Children
    if features.noStun and LocalPlayer.Character then
        local char = LocalPlayer.Character
        char:SetAttribute("Stunned", false)
        char:SetAttribute("Ragdoll", false)
        char:SetAttribute("Freeze", false)
        for _, v in pairs(char:GetChildren()) do
            if v.Name == "Ragdoll" or v.Name == "Stun" or v.Name == "Freeze" or v.Name=="Stunned" then v:Destroy() end
        end
    end
    -- Noclip
    if features.noclip and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide == true then v.CanCollide = false end
        end
    end
    -- No Anim: Hook
    if features.stopAnims and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
             for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
             if hum.Animator and not animPlayedConnection then
                 animPlayedConnection = hum.Animator.AnimationPlayed:Connect(function(t) t:Stop() end)
             end
        end
    elseif animPlayedConnection then
        animPlayedConnection:Disconnect()
        animPlayedConnection = nil
    end
end)

RunService.Heartbeat:Connect(function()
    -- Anti Fling: BaseParts
    if features.antiFling.enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false; v.Velocity = Vector3.zero end
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function() if flying then task.wait(0.5); startFly() end end)

-- ====================
-- TAB: MISC
-- ====================
local MiscLeft = MiscTab:Section({ name = "Main Settings", side = "left" })
local MiscRight = MiscTab:Section({ name = "Helper & Fun", side = "right" })

MiscLeft:Toggle({
    name = "Flight",
    callback = function(bool)
        flying = bool
        if bool then 
            startFly() 
        else 
            RunService:UnbindFromRenderStep("FlyStep")
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hum then hum.PlatformStand = false end
                if hrp then 
                    hrp.Anchored = false 
                    hrp.AssemblyLinearVelocity = Vector3.zero -- Stop momentum
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
            if flyBV then flyBV:Destroy(); flyBV = nil end
            if flyAtt then flyAtt:Destroy(); flyAtt = nil end
        end
    end
})
MiscLeft:Slider({ name = "Flight Speed", min = 1, max = 10, default = 1, suffix = "x", callback = function(val) flySpeed = val end })

-- Speed Mod (Aggressive Property Signal)
local currentWs, currentJp, moveEnabled = 16, 50, false
MiscLeft:Toggle({ name = "Enable Speed/Jump", callback = function(bool) moveEnabled = bool 
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum and bool then hum.WalkSpeed = currentWs; hum.JumpPower = currentJp end
end })
MiscLeft:Slider({ name = "Walk Speed", min = 16, max = 200, default = 16, suffix = " spd", callback = function(val) currentWs = val end })
MiscLeft:Slider({ name = "Jump Power", min = 50, max = 300, default = 50, suffix = " pwr", callback = function(val) currentJp = val end })

-- Character Connected Logic
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if moveEnabled and hum.WalkSpeed ~= currentWs then hum.WalkSpeed = currentWs end
    end)
    hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if moveEnabled and hum.JumpPower ~= currentJp then hum.JumpPower = currentJp end
    end)
end)

-- Initial Hook
if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function() if moveEnabled and hum.WalkSpeed ~= currentWs then hum.WalkSpeed = currentWs end end)
        hum:GetPropertyChangedSignal("JumpPower"):Connect(function() if moveEnabled and hum.JumpPower ~= currentJp then hum.JumpPower = currentJp end end)
    end
end

-- Anti Void Re-Implementation
MiscRight:Toggle({ name = "Anti Void", callback = function(bool) 
    if bool then
        if features.antiVoid.platform then features.antiVoid.platform:Destroy() end -- Reset
        local p = Instance.new("Part", Workspace)
        p.Size = Vector3.new(9999, 10, 9999) -- Huge
        p.Position = Vector3.new(0, -300, 0)
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 0.5
        p.BrickColor = BrickColor.new("Royal purple")
        p.Name = "AntiVoidPlatform"
        features.antiVoid.platform = p
    else
        if features.antiVoid.platform then features.antiVoid.platform:Destroy() end
    end
end })
MiscRight:Toggle({ name = "Anti DC", callback = function(bool) if bool then local c = Workspace:FindFirstChild("Cutscenes"); if c and c:FindFirstChild("Death Cutscene") then c["Death Cutscene"]:Destroy() end end end })

local playerNames = {"None"} 
for _, p in ipairs(Players:GetPlayers()) do table.insert(playerNames, p.Name) end
MiscRight:Dropdown({ name = "Emote Follow", items = playerNames, default = "None", callback = function(val)
    features.bootyClap.target = Players:FindFirstChild(val or "")
    features.bootyClap.following = (val ~= "None" and features.bootyClap.target)
    if features.bootyClap.following and not features.bootyClap.loop then
         local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://120789866363939"
         local track = LocalPlayer.Character.Humanoid.Animator:LoadAnimation(anim); track:Play()
         features.bootyClap.loop = RunService.Heartbeat:Connect(function()
             if not features.bootyClap.following or not features.bootyClap.target then track:Stop(); if features.bootyClap.loop then features.bootyClap.loop:Disconnect(); features.bootyClap.loop = nil end return end
             local tChar = features.bootyClap.target.Character
             if tChar and tChar:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = tChar.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end
         end)
    end
end })

-- Watermark (Ported from example.lua)
local gamesense = Instance.new("ScreenGui")
local Watermark2 = Instance.new("Frame")
local _1 = Instance.new("Frame")
local A = Instance.new("TextLabel")
local T = Instance.new("TextLabel")
local E = Instance.new("TextLabel")
local B = Instance.new("TextLabel")
local back1 = Instance.new("TextLabel")
local FPS = Instance.new("TextLabel")
local Femboysense = Instance.new("TextLabel")

gamesense.Name = "gamesense"
gamesense.Parent = game:GetService("CoreGui")
gamesense.DisplayOrder = 99999999
gamesense.ResetOnSpawn = false
gamesense.IgnoreGuiInset = true

Watermark2.Name = "Watermark2"
Watermark2.Parent = gamesense
Watermark2.Active = true
Watermark2.AnchorPoint = Vector2.new(1, 0)
Watermark2.BackgroundColor3 = Color3.new(0.0862745, 0.0862745, 0.0862745)
Watermark2.BorderColor3 = Color3.new(0.262745, 0.262745, 0.262745)
Watermark2.BorderSizePixel = 0
Watermark2.Draggable = true
Watermark2.Position = UDim2.new(1, -10, 0, 10)
Watermark2.Selectable = true
Watermark2.Size = UDim2.new(0, 200, 0, 18)
Watermark2.ZIndex = 999999998

_1.Name = "1"
_1.Parent = Watermark2
_1.BackgroundColor3 = Color3.new(0.25098, 0.25098, 0.25098)
_1.BorderColor3 = Color3.new(0.262745, 0.262745, 0.262745)
_1.BorderSizePixel = 0
_1.Position = UDim2.new(0, -1, 0, -1)
_1.Size = UDim2.new(1, 2, 1, 2)
_1.ZIndex = -1

Femboysense.Name = "Femboysense"
Femboysense.Parent = Watermark2
Femboysense.BackgroundColor3 = Color3.new(1, 1, 1)
Femboysense.BackgroundTransparency = 1
Femboysense.BorderSizePixel = 0
Femboysense.Position = UDim2.new(0, 6, 0, 0)
Femboysense.Size = UDim2.new(0, 90, 1, 0)
Femboysense.ZIndex = 999999999
Femboysense.Font = Enum.Font.Code
Femboysense.Text = "[femboy.sense]"
Femboysense.TextColor3 = Color3.new(1, 1, 1)
Femboysense.TextSize = 12
Femboysense.TextXAlignment = Enum.TextXAlignment.Left

B.Name = "B"
B.Parent = Watermark2
B.BackgroundColor3 = Color3.new(0.00784314, 0.00784314, 0.00784314)
B.BackgroundTransparency = 1
B.BorderSizePixel = 0
B.Position = UDim2.new(0, 96, 0, 0)
B.Size = UDim2.new(0, 10, 1, 0)
B.ZIndex = 999999999
B.Font = Enum.Font.Ubuntu
B.Text = "B"
B.TextColor3 = Color3.new(1, 1, 1)
B.TextSize = 12
B.TextXAlignment = Enum.TextXAlignment.Center

E.Name = "E"
E.Parent = Watermark2
E.BackgroundColor3 = Color3.new(0, 0, 0)
E.BackgroundTransparency = 1
E.BorderSizePixel = 0
E.Position = UDim2.new(0, 106, 0, 0)
E.Size = UDim2.new(0, 10, 1, 0)
E.ZIndex = 999999999
E.Font = Enum.Font.Ubuntu
E.Text = "E"
E.TextColor3 = Color3.new(1, 1, 1)
E.TextSize = 12
E.TextXAlignment = Enum.TextXAlignment.Center

T.Name = "T"
T.Parent = Watermark2
T.BackgroundColor3 = Color3.new(0.00784314, 0.00784314, 0.00784314)
T.BackgroundTransparency = 1
T.BorderSizePixel = 0
T.Position = UDim2.new(0, 116, 0, 0)
T.Size = UDim2.new(0, 10, 1, 0)
T.ZIndex = 999999999
T.Font = Enum.Font.Ubuntu
T.Text = "T"
T.TextColor3 = Color3.new(1, 1, 1)
T.TextSize = 12
T.TextXAlignment = Enum.TextXAlignment.Center

A.Name = "A"
A.Parent = Watermark2
A.BackgroundColor3 = Color3.new(0.00784314, 0.00784314, 0.00784314)
A.BackgroundTransparency = 1
A.BorderSizePixel = 0
A.Position = UDim2.new(0, 126, 0, 0)
A.Size = UDim2.new(0, 10, 1, 0)
A.ZIndex = 999999999
A.Font = Enum.Font.Ubuntu
A.Text = "A"
A.TextColor3 = Color3.new(1, 1, 1)
A.TextSize = 12
A.TextXAlignment = Enum.TextXAlignment.Center

back1.Name = "back1"
back1.Parent = Watermark2
back1.BackgroundColor3 = Color3.new(1, 1, 1)
back1.BackgroundTransparency = 1
back1.BorderSizePixel = 0
back1.Position = UDim2.new(0, 138, 0, 0)
back1.Size = UDim2.new(0, 12, 1, 0)
back1.ZIndex = 999999999
back1.Font = Enum.Font.Code
back1.Text = "|"
back1.TextColor3 = Color3.new(1, 1, 1)
back1.TextSize = 12
back1.TextXAlignment = Enum.TextXAlignment.Center

FPS.Name = "FPS"
FPS.Parent = Watermark2
FPS.BackgroundColor3 = Color3.new(1, 1, 1)
FPS.BackgroundTransparency = 1
FPS.BorderSizePixel = 0
FPS.Position = UDim2.new(0, 152, 0, 0)
FPS.Size = UDim2.new(0, 50, 1, 0)
FPS.ZIndex = 999999999
FPS.Font = Enum.Font.Code
FPS.Text = "0 fps"
FPS.TextColor3 = Color3.new(1, 1, 1)
FPS.TextSize = 12
FPS.TextXAlignment = Enum.TextXAlignment.Left

local function vrksq_fake_script() 
    local script = Instance.new('LocalScript', Watermark2)
    local wm = script.Parent
    local fpsText = wm:WaitForChild("FPS")
    local b = wm:WaitForChild("B")
    local e = wm:WaitForChild("E")
    local t = wm:WaitForChild("T")
    local a = wm:WaitForChild("A")
    local frames = 0
    local lastTick = tick()
    local curFPS = 0
    local function animletters()
        local tm = tick() * 1.5
        local colors = {Color3.fromRGB(100, 200, 255), Color3.fromRGB(0, 100, 255), Color3.fromRGB(255, 100, 200), Color3.fromRGB(100, 255, 100)}
        local wave = (math.sin(tm) + 1) / 2
        local idx = math.floor(wave * 3) + 1
        local nextIdx = idx < 4 and idx + 1 or 1
        local blend = (wave * 3) % 1
        local col1 = colors[idx]
        local col2 = colors[nextIdx]
        local color = Color3.new(col1.R + (col2.R - col1.R) * blend, col1.G + (col2.G - col1.G) * blend, col1.B + (col2.B - col1.B) * blend)
        b.TextColor3 = color
        e.TextColor3 = color
        t.TextColor3 = color
        a.TextColor3 = color
    end
    local function updfps()
        frames = frames + 1
        local curTime = tick()
        if curTime - lastTick >= 0.5 then
            curFPS = math.floor(frames / (curTime - lastTick))
            frames = 0
            lastTick = curTime
            fpsText.Text = curFPS .. " fps"
        end
    end
    game:GetService("RunService").RenderStepped:Connect(function() updfps(); animletters() end)
end
coroutine.wrap(vrksq_fake_script)()

-- Keybind to Toggle GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local toggleKey = getgenv().MenuKey or Enum.KeyCode.Insert
    if not gameProcessed and (input.KeyCode == toggleKey or input.KeyCode == Enum.KeyCode.KeypadTwo) then
        Window.toggle_menu(not Library.menu_open)
    end
end)

-- Init
task.delay(1, function()
    Window.toggle_menu(true)
    if Library.init_config then
        Library:init_config(Window)
    end
end)
