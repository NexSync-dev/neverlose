-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- Helper function for notifications
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

local function notify(title, body, col)
    pcall(function()
        if notifications and notifications.create_notification then
            notifications:create_notification({
                name = title .. "\n" .. body,
                color = col or Color3.fromRGB(255, 255, 255)
            })
        end
    end)
end


-- Global State
getgenv().resolutionScale = getgenv().resolutionScale or 1.0
getgenv().resolutionActive = getgenv().resolutionActive or false

local features = {
    autoBlock = { enabled = false, range = 10, bubble = nil, looking = false },
    aimbot = { mode = "closest to player", trackConnection = nil, animeTp = false, shiftlockFix = true },
    esp = { 
        enabled = false, boxEnabled = false, boxColor = Color3.new(1,0,0), 
        healthEnabled = false, tracersEnabled = false, skeletonEnabled = false, 
        chamsEnabled = false, infoEnabled = false, rainbow = false, distanceScale = false, nametags = false
    },
    lighting = { enabled = false, color = Color3.fromRGB(255, 182, 193), fullBright = false, noFog = false },
    performance = { fpsBooster = false, pingBooster = false },
    noStun = { enabled = false, highUNC = false },
    antiFling = { enabled = false },
    antiVoid = { enabled = false, platform = nil },
    stopAnims = false,
    bootyClap = { following = false, target = nil, loop = nil },
    antiDeath = { enabled = false, originalPos = nil },
    hvh = { antiExploit = false, resolver = false, flaggedPlayers = {}, resolvedPositions = {} },
    infJump = false,
    animeTpEnabled = false,
    gimmicks = { upsideDown = false, headless = false, korblox = false, spinbot = false, spinSpeed = 50, orbit = false, chatSpam = false },
    world = { gravity = 196.2, fov = 70, disableShake = false }
}

local Features = features
_G.TSB_Features = features
_G.ScriptLoaded = false

-- Permanent settings on load
Workspace.FallenPartsDestroyHeight = -100000

-- Resolution Helper
local function applyResolution(scale)
    getgenv().resolutionScale = scale
    getgenv().resolutionActive = (scale ~= 1.0)
end

-- Permanent Camera Stabilizer
RunService:BindToRenderStep("PermanentStabilizer", Enum.RenderPriority.Camera.Value + 1, function()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    -- FOV always applies
    camera.FieldOfView = features.world.fov or 70
    
    -- Shake disable is separate (runs BEFORE resolution manipulation)
    if features.world.disableShake and not getgenv().resolutionActive then
        local cf = camera.CFrame
        local x, y, _ = cf:ToEulerAnglesYXZ()
        camera.CFrame = CFrame.new(cf.Position) * CFrame.fromEulerAnglesYXZ(x, y, 0)
    end
end)




-- Advanced NoStun Logic (High UNC)
task.spawn(function()
    task.wait(2) -- Safety delay for first join
    local success, mt = pcall(function() return getrawmetatable(game) end)
    if success and mt then
        local mt_success = pcall(function() setreadonly(mt, false) end)
        if not mt_success then return end
        
        local oldIndex = mt.__newindex
        mt.__newindex = function(self, key, value)
            if features.noStun.enabled and features.noStun.highUNC and (key == "Stunned" or key == "LightStunned" or key == "StunSubject" or key == "DashLock" or key == "Busy" or key == "BusySubject" or key == "StunWalkSpeed") then
                return
            end
            return oldIndex(self, key, value)
        end
    end
end)

-- NoStun Logic (Optimized)
local function handleNoStun(char)
    if not char then return end
    char.ChildAdded:Connect(function(v)
        if features.noStun.enabled then
            if v.Name == "Ragdoll" or v.Name == "Stun" or v.Name == "Freeze" or v.Name == "Stunned" or v.Name == "Busy" or v.Name == "LightStunned" then
                task.defer(function() v:Destroy() end)
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(handleNoStun)
if LocalPlayer.Character then handleNoStun(LocalPlayer.Character) end

task.spawn(function()
    while task.wait(0.1) do
        if features.noStun.enabled then
            local char = LocalPlayer.Character
            if char then
                char:SetAttribute("Stunned", false)
                char:SetAttribute("LightStunned", false)
                char:SetAttribute("DashLock", false)
                char:SetAttribute("Busy", false)
                char:SetAttribute("BusySubject", "")
                char:SetAttribute("StunWalkSpeed", 24)
                char:SetAttribute("CanEvasive", true)
                char:SetAttribute("StunJumpPower", 50)
                char:SetAttribute("Ragdoll", false)
                char:SetAttribute("Freeze", false)
            end
        end
    end
end)

-- Library Initialization
local Library, notifications
local success, err = pcall(function()
    local lib, notif = loadstring(game:HttpGet("https://raw.githubusercontent.com/NexSync-dev/neverlose/refs/heads/main/lib.lua"))()
    Library = lib
    notifications = notif
end)

if not success or not Library then
    warn("Failed to load library: " .. tostring(err))
    return
end

-- Window
local Window = Library:window({
    name = "femboys.pub | tsb",
    size = UDim2.new(0, 650, 0, 450)
})


-- TAB: DEFINITIONS
-- ====================
local LegitTab = Window:Tab({ name = "Legit", Name = "Legit", text = "Legit" })
local BlatantTab = Window:Tab({ name = "Blatant", Name = "Blatant", text = "Blatant" })
local VisualsTab = Window:Tab({ name = "Visual", Name = "Visual", text = "Visual" })
local MiscTab = Window:Tab({ name = "Misc", Name = "Misc", text = "Misc" })
local ConfigTab = Window:Tab({ name = "Config", Name = "Config", text = "Config" }) 

-- Shareable Lists and Dynamic Refresh
local playerNames = {"None"}
local mapNames = {"None"}
local dropdownsToUpdate = {}

local function updatePlayerList()
    local newList = {"None"}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(newList, p.Name) end end
    playerNames = newList
    for _, d in ipairs(dropdownsToUpdate) do pcall(function() d.refresh_options(playerNames) end) end
end

Players.PlayerAdded:Connect(function() task.wait(1); updatePlayerList() end)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

-- REJOIN HELPER
local function rejoin()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end




-- ====================
-- TAB: LEGIT
-- ====================
local LegitMain = LegitTab:Section({ name = "Main", side = "left" })
local LegitExtra = LegitTab:Section({ name = "Extra", side = "right" })


-- Soft Aim Lock High-Priority Loop
local softAimConn = nil
local function updateSoftAim()
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
        local targetPos = closestTarget.Position
        local tPlayer = Players:GetPlayerFromCharacter(closestTarget.Parent)
        if features.hvh.resolver and tPlayer and features.hvh.resolvedPositions[tPlayer.Name] then
            targetPos = features.hvh.resolvedPositions[tPlayer.Name]
        end

        local dir = (targetPos - hrp.Position).Unit
        local lookCf = CFrame.new(hrp.Position, hrp.Position + Vector3.new(dir.X, 0, dir.Z))

        -- Randomized smoothing for anti-detection
        local smoothFactor = 0.4 + (math.random(-5, 5) / 100)

        if features.aimbot.shiftlockFix then
            hrp.CFrame = hrp.CFrame:Lerp(lookCf, smoothFactor)
        else
            hrp.CFrame = lookCf
        end
    end


end

LegitMain:Toggle({ name = "Soft Aim Lock", Name = "Soft Aim Lock", callback = function(bool) features.autoBlock.enabled = bool end })
LegitMain:Toggle({ name = "Shiftlock Smooth Fix", Name = "Shiftlock Smooth Fix", callback = function(bool) features.aimbot.shiftlockFix = bool end })

local rangeSlider = LegitMain:Slider({ name = "Range", Name = "Range", text = "Range", min = 10, max = 100, default = 10, suffix = " studs", callback = function(val) features.autoBlock.range = val end })
if rangeSlider.items and rangeSlider.items.name then rangeSlider.items.name.set("Range") end

local hitboxSize = 2
LegitMain:Toggle({ name = "Legit Hitbox", callback = function(bool)
    getgenv().legitHitbox = bool
    task.spawn(function()
        while getgenv().legitHitbox do
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    p.Character.HumanoidRootPart.Transparency = 0.8
                    p.Character.HumanoidRootPart.CanCollide = false
                end
            end
            task.wait(1)
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                p.Character.HumanoidRootPart.Transparency = 1
            end
        end
    end)
end })

LegitMain:Toggle({ name = "Trigger Bot", callback = function(bool)
    getgenv().triggerBot = bool
    task.spawn(function()
        while getgenv().triggerBot do
            local char = LocalPlayer.Character
            if char then
                local mouse = LocalPlayer:GetMouse()
                local target = mouse.Target
                if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
                    local p = Players:GetPlayerFromCharacter(target.Parent)
                    if p and p.Team ~= LocalPlayer.Team then
                        -- Simulate click/M1 if close enough
                        local dist = (char.HumanoidRootPart.Position - target.Position).Magnitude
                        if dist < 15 then
                             keypress(Enum.KeyCode.ButtonX) -- Adjust based on TSB bindings or use VirtualInputManager
                             task.wait(0.2)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end })

LegitMain:Toggle({ name = "Auto Counter (Safe)", callback = function(bool)
    getgenv().autoCounter = bool
    task.spawn(function()
        while getgenv().autoCounter do
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local anims = p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid:GetPlayingAnimationTracks()
                    if anims then
                        for _, track in ipairs(anims) do
                            -- Detect common TSB attack animation IDs (Simplified example)
                            if track.Animation.AnimationId:find("12273188754") then -- Example attack ID
                                 -- Trigger Counter (Move 4 for Saitama/Garou usually)
                                 keypress(Enum.KeyCode.Four)
                                 task.wait(0.5)
                            end
                        end
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end })

LegitExtra:Button({ name = "M1 reset script(keybind c)", Name = "M1 reset script(keybind c)", text = "M1 reset script(keybind c)", callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NexSync-dev/neverlosegui/refs/heads/main/m1reset.lua"))() end })







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
    fillTransparency = 0.5,
    headDot = false,
    lookLines = false,
    visibleCheck = false,
    teamCheck = false
}

-- TSB Detection with Caching
local tsbClassCache = {}
local function getTSBClass(player)
    if not player then return "None" end
    if tsbClassCache[player] then return tsbClassCache[player] end

    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    local function has(name) return (backpack and backpack:FindFirstChild(name)) or (char and char:FindFirstChild(name)) end

    local class = "Unknown"
    -- Saitama
    if has("Normal Punch") or has("Consecutive Normal Punches") or has("Shove") or has("Upper Cut") then
        class = "Saitama"
        if has("Table Flip") or has("Death Counter") or has("Serious Punch") or has("Omnidirectional Punch") then
            class = "Saitama (ULT)"
        end
    -- Garou
    elseif has("Flowing Water") or has("Hunter's Grasp") or has("Lethal Whirlwind Stream") or has("Awakening") then
        class = "Garou"
        if has("The Final Hunt") or has("God Slayer Robber") or has("God Slayer Mechanical Strike") then
            class = "Garou (ULT)"
        end
    -- Genos
    elseif has("Incinerate") or has("Blitz Shot") or has("Jet Dive") or has("Machine Gun Blows") then
        class = "Genos"
        if has("Ignition Burst") or has("Maximum Output Incinerate") or has("Spiral Incinerate") then
            class = "Genos (ULT)"
        end
    -- Sonic
    elseif has("Explosive Shuriken") or has("Flash Strike") or has("Whirlwind Kick") or has("Twin Blade Slash") then
        class = "Sonic"
        if has("Tenfold Funeral") or has("Afterimage Slash") then
            class = "Sonic (ULT)"
        end
    -- Metal Bat
    elseif has("Home Run") or has("Foul Ball") or has("Beatdown") or has("Dragon Thrash") then
        class = "Metal Bat"
        if has("Death Blow") or has("Savage Tornado") then
            class = "Metal Bat (ULT)"
        end
    -- Tatsumaki
    elseif has("Whirlwind") or has("Telekinetic Thrust") or has("Psychic Grab") or has("Rock Storm") then
        class = "Tatsumaki"
        if has("Psychic Storm") or has("Crushing Tides") then
            class = "Tatsumaki (ULT)"
        end
    -- Atomic Samurai
    elseif has("Atomic Slash") or has("Swift Slice") or has("Hurdle") or has("Pinpoint Cut") then
        class = "Atomic Samurai"
        if has("Sunrise") then -- Sunrise Blade / Atomic Slash (Enhanced)
             class = "Atomic Samurai (ULT)"
        end
    -- Suiryu
    elseif has("Void Fist") or has("Void Kick") or has("Void Step") or has("Void Smash") then
        class = "Suiryu"
        if has("Void Skyward Fist") then
            class = "Suiryu (ULT)"
        end
    end

    tsbClassCache[player] = class
    return class
end

-- Clear cache on character change or backpack change
local function clearTSBCache(player)
    tsbClassCache[player] = nil
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() clearTSBCache(p) end)
    p.ChildAdded:Connect(function(c) if c.Name == "Backpack" then clearTSBCache(p) end end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function() clearTSBCache(p) end)
    p.ChildAdded:Connect(function(c) if c.Name == "Backpack" then clearTSBCache(p) end end)
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
    pcall(function()
        if p and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum then
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
            end
        end
        if espCache[p] then 
            for k, d in pairs(espCache[p]) do 
                if type(d) == "table" then for _, l in pairs(d) do pcall(function() l:Remove() end) end else pcall(function() d:Remove() end) end
            end 
            espCache[p] = nil 
        end
        -- Remove Chams
        if p and p.Character then
            local hl = p.Character:FindFirstChild("TSB_Highlight")
            if hl then hl:Destroy() end
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if not features.esp.enabled then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    local vSize = cam.ViewportSize
    local centerY = vSize.Y / 2
    local resActive = getgenv().resolutionActive
    local resScale = getgenv().resolutionScale
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Head") then
             local char = p.Character; local hrp = char.HumanoidRootPart; local head = char.Head; local hum = char.Humanoid
             
             if espConfig.teamCheck and p.Team == LocalPlayer.Team then removeEsp(p) continue end

             local vec3, onScreen = cam:WorldToViewportPoint(hrp.Position)
             local vec = Vector2.new(vec3.X, vec3.Y)
             
             local cache = espCache[p]
             if onScreen and hum.Health > 0 then
                  if not cache then
                      -- Initialization code (once per player)
                      pcall(function()
                          hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
                          hum.NameDisplayDistance = 1000
                          hum.HealthDisplayDistance = 1000
                      end)
                      cache = {
                          box = createDrawing("Square", {Thickness=1, Color=Color3.new(1,0,0), Filled=false, Transparency=1}),
                          boxOutline = createDrawing("Square", {Thickness=3, Color=Color3.new(0,0,0), Filled=false, Transparency=1}),
                          filledBox = createDrawing("Square", {Thickness=0, Filled=true, Transparency=0.5}),
                          corners = {}, cornerOutlines = {},
                          name = createDrawing("Text", {Size=16, Center=true, Outline=true, Color=Color3.new(1,1,1)}),
                          dist = createDrawing("Text", {Size=14, Center=true, Outline=true, Color=Color3.new(1,1,1)}),
                          hpText = createDrawing("Text", {Size=14, Center=true, Outline=true, Color=Color3.new(0,1,0)}),
                          healthBar = createDrawing("Square", {Filled=true, Thickness=1, Transparency=1}),
                          healthOutline = createDrawing("Square", {Filled=false, Thickness=1, Color=Color3.new(0,0,0), Transparency=1}),
                          tracer = createDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1), Transparency=1}),
                          tracerOutline = createDrawing("Line", {Thickness=3, Color=Color3.new(0,0,0), Transparency=1}),
                          classText = createDrawing("Text", {Size=14, Center=true, Outline=true, Color=Color3.fromRGB(255, 215, 0)}),
                          headDot = createDrawing("Circle", {Radius=4, Filled=true, Color=Color3.new(1,1,1), Visible=false, Thickness=1}),
                          headDotOutline = createDrawing("Circle", {Radius=5, Filled=false, Color=Color3.new(0,0,0), Visible=false, Thickness=2}),
                          lookLine = createDrawing("Line", {Thickness=1, Color=Color3.new(1,0,0), Transparency=1}),
                          lookLineOutline = createDrawing("Line", {Thickness=3, Color=Color3.new(0,0,0), Transparency=1}),
                          skeleton = {}, skeletonOutlines = {},
                          hidden = false
                      }
                      espCache[p] = cache
                      for i=1,8 do 
                          table.insert(cache.cornerOutlines, createDrawing("Line", {Thickness=4, Color=Color3.new(0,0,0), Transparency=1}))
                          table.insert(cache.corners, createDrawing("Line", {Thickness=1.5, Color=Color3.new(1,0,0), Transparency=1})) 
                      end
                      for i=1,12 do 
                          table.insert(cache.skeletonOutlines, createDrawing("Line", {Thickness=3, Color=Color3.new(0,0,0), Transparency=1}))
                          table.insert(cache.skeleton, createDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1), Transparency=1})) 
                      end
                  end
                  
                  cache.hidden = false
                  
                  -- Viewport coordinates are already compensated by Camera CFrame transformation
                  local headPos3, _ = cam:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                  local legPos3, _ = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
                  local headPos = Vector2.new(headPos3.X, headPos3.Y)
                  local legPos = Vector2.new(legPos3.X, legPos3.Y)
                  
                  local height = legPos.Y - headPos.Y
                  local width = height / 2
                  
                  local mainColor = features.esp.rainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or features.esp.boxColor

                  -- Chams Logic (Re-added)
                  local hl = char:FindFirstChild("TSB_Highlight")
                  if features.esp.chamsEnabled then
                      if not hl then
                          hl = Instance.new("Highlight", char)
                          hl.Name = "TSB_Highlight"
                          hl.FillTransparency = 0.5
                          hl.OutlineTransparency = 0
                      end
                      hl.FillColor = mainColor
                      hl.OutlineColor = Color3.new(1,1,1)
                      hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                  else
                      if hl then hl:Destroy() end
                  end

                  if espConfig.deathCounter then
                      local hasDC = (p.Backpack and p.Backpack:FindFirstChild("Death Counter")) or (char and char:FindFirstChild("Death Counter"))
                      if hasDC then 
                          mainColor = Color3.fromRGB(255, 0, 0)
                          dcCache[p] = tick() + 10 
                      elseif dcCache[p] and dcCache[p] > tick() then 
                          mainColor = Color3.fromRGB(255, 255, 0) 
                      end
                  end


                  
                  -- Box Styles
                  cache.box.Visible = false; cache.boxOutline.Visible = false; cache.filledBox.Visible = false; 
                  for _,l in pairs(cache.corners) do l.Visible = false end
                  for _,l in pairs(cache.cornerOutlines) do l.Visible = false end

                  if features.esp.boxEnabled then
                      if espConfig.boxStyle == "Corner" then
                           local tl, tr, bl, br = Vector2.new(vec.X - width/2, vec.Y - height/2), Vector2.new(vec.X + width/2, vec.Y - height/2), Vector2.new(vec.X - width/2, vec.Y + height/2), Vector2.new(vec.X + width/2, vec.Y + height/2)
                           local len = width / 2
                           local c = cache.corners
                           local co = cache.cornerOutlines
                           
                           local function drawCorner(idx, p1, p2)
                               co[idx].Visible=true; co[idx].From=p1; co[idx].To=p2; co[idx].Color=Color3.new(0,0,0)
                               c[idx].Visible=true; c[idx].From=p1; c[idx].To=p2; c[idx].Color=mainColor
                           end

                           drawCorner(1, tl, tl+Vector2.new(len,0))
                           drawCorner(2, tl, tl+Vector2.new(0,len))
                           drawCorner(3, tr, tr-Vector2.new(len,0))
                           drawCorner(4, tr, tr+Vector2.new(0,len))
                           drawCorner(5, bl, bl+Vector2.new(len,0))
                           drawCorner(6, bl, bl-Vector2.new(0,len))
                           drawCorner(7, br, br-Vector2.new(len,0))
                           drawCorner(8, br, br-Vector2.new(0,len))
                      elseif espConfig.boxStyle == "Filled" then
                           cache.filledBox.Visible = true; cache.filledBox.Size = Vector2.new(width, height); cache.filledBox.Position = Vector2.new(vec.X - width/2, vec.Y - height/2); cache.filledBox.Color = mainColor; cache.filledBox.Transparency = espConfig.fillTransparency
                           cache.boxOutline.Visible = true; cache.boxOutline.Size = Vector2.new(width, height); cache.boxOutline.Position = Vector2.new(vec.X - width/2, vec.Y - height/2)
                           cache.box.Visible = true; cache.box.Size = Vector2.new(width, height); cache.box.Position = Vector2.new(vec.X - width/2, vec.Y - height/2); cache.box.Color = mainColor
                      else
                           cache.boxOutline.Visible = true; cache.boxOutline.Size = Vector2.new(width, height); cache.boxOutline.Position = Vector2.new(vec.X - width/2, vec.Y - height/2)
                           cache.box.Visible = true; cache.box.Size = Vector2.new(width, height); cache.box.Position = Vector2.new(vec.X - width/2, vec.Y - height/2); cache.box.Color = mainColor
                      end
                  end
                  
                  -- Nametags
                  if features.esp.nametags then
                      cache.name.Visible = true
                      cache.name.Text = p.Name
                      cache.name.Position = Vector2.new(vec.X, headPos.Y - 20)
                      cache.name.Color = mainColor
                      cache.name.Size = 16
                      cache.name.Outline = true
                  else
                      cache.name.Visible = false
                  end

                  -- Info (Dist/Class)
                  if features.esp.infoEnabled then
                      local distStr = "Unknown"
                      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                          distStr = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) .. "m"
                      end
                      local classStr = getTSBClass(p)
                      cache.dist.Visible = true
                      cache.dist.Text = distStr .. " | " .. classStr
                      cache.dist.Position = Vector2.new(vec.X, vec.Y + height/2 + 5)
                      cache.dist.Color = Color3.new(1,1,1)
                  else
                      cache.dist.Visible = false
                  end
                  
                  if espConfig.headDot then
                      cache.headDot.Visible = true; cache.headDot.Position = Vector2.new(headPos.X, headPos.Y); cache.headDot.Color = mainColor
                      cache.headDotOutline.Visible = true; cache.headDotOutline.Position = Vector2.new(headPos.X, headPos.Y)
                  else cache.headDot.Visible = false; cache.headDotOutline.Visible = false end

                  if espConfig.lookLines then
                      local lookDist = 5
                      local look3, lookOS = cam:WorldToViewportPoint(head.Position + (head.CFrame.LookVector * lookDist))
                      local lookVec = Vector2.new(look3.X, look3.Y)
                      if lookOS then
                          cache.lookLineOutline.Visible = true; cache.lookLineOutline.From = headPos; cache.lookLineOutline.To = lookVec
                          cache.lookLine.Visible = true; cache.lookLine.From = headPos; cache.lookLine.To = lookVec; cache.lookLine.Color = mainColor
                      else cache.lookLine.Visible = false; cache.lookLineOutline.Visible = false end
                  else cache.lookLine.Visible = false; cache.lookLineOutline.Visible = false end
                  
                  -- Health
                  if features.esp.healthEnabled then
                      local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                      local barHeight = height * healthPct
                      local healthColor = Color3.fromHSV(healthPct * 0.3, 1, 1) -- Interpolate Green -> Red
                      
                      if espConfig.healthStyle == "Bar" or espConfig.healthStyle == "Both" then
                          cache.healthOutline.Visible = true; cache.healthOutline.Size = Vector2.new(4, height); cache.healthOutline.Position = Vector2.new(vec.X - width/2 - 6, vec.Y - height/2)
                          cache.healthBar.Visible = true; cache.healthBar.Color = healthColor; cache.healthBar.Size = Vector2.new(2, barHeight); cache.healthBar.Position = Vector2.new(vec.X - width/2 - 5, (vec.Y - height/2) + (height - barHeight))
                      else cache.healthOutline.Visible=false; cache.healthBar.Visible=false end
                      
                      if espConfig.healthStyle == "Text" or espConfig.healthStyle == "Both" then
                          cache.hpText.Visible = true; cache.hpText.Text = math.floor(hum.Health); cache.hpText.Position = Vector2.new(vec.X - width/2 - 20, vec.Y - height/2)
                      else cache.hpText.Visible = false end
                  else cache.healthOutline.Visible=false; cache.healthBar.Visible=false; cache.hpText.Visible=false end

                  if espConfig.tsbClass then cache.classText.Visible = true; cache.classText.Text = getTSBClass(p); cache.classText.Position = Vector2.new(vec.X, headPos.Y - 32) else cache.classText.Visible = false end

                  if features.esp.tracersEnabled then
                      local origin3 = Vector3.zero
                      if espConfig.tracerOrigin == "Bottom" then origin3 = Vector3.new(cam.ViewportSize.X/2, cam.ViewportSize.Y, 0)
                      elseif espConfig.tracerOrigin == "Center" then origin3 = Vector3.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0)
                      else local m = UserInputService:GetMouseLocation(); origin3 = Vector3.new(m.X, m.Y, 0) end
                      
                      local origin = Vector2.new(origin3.X, origin3.Y)
                      cache.tracerOutline.Visible = true; cache.tracerOutline.From = origin; cache.tracerOutline.To = vec
                      cache.tracer.Visible = true; cache.tracer.From = origin; cache.tracer.To = vec; cache.tracer.Color = mainColor
                  else cache.tracer.Visible = false; cache.tracerOutline.Visible = false end

                  if features.esp.skeletonEnabled then
                      local function line(idx, p1, p2)
                          if not p1 or not p2 then return end
                          local l = cache.skeleton[idx]
                          local lo = cache.skeletonOutlines[idx]
                          if not l or not lo then return end
                          
                          local v3_1, os1 = cam:WorldToViewportPoint(p1.Position)
                          local v3_2, os2 = cam:WorldToViewportPoint(p2.Position)
                          local v1 = Vector2.new(v3_1.X, v3_1.Y)
                          local v2 = Vector2.new(v3_2.X, v3_2.Y)
                          
                          if os1 and os2 then 
                              lo.Visible = true; lo.From = v1; lo.To = v2
                              l.Visible = true; l.From = v1; l.To = v2; l.Color = mainColor
                          else l.Visible = false; lo.Visible = false end
                      end
                      if char:FindFirstChild("UpperTorso") then
                          line(1, char:FindFirstChild("Head"), char:FindFirstChild("UpperTorso")); line(2, char:FindFirstChild("UpperTorso"), char:FindFirstChild("LeftUpperArm")); line(3, char:FindFirstChild("UpperTorso"), char:FindFirstChild("RightUpperArm"))
                          line(4, char:FindFirstChild("LeftUpperArm"), char:FindFirstChild("LeftLowerArm")); line(5, char:FindFirstChild("RightUpperArm"), char:FindFirstChild("RightLowerArm"))
                          line(6, char:FindFirstChild("UpperTorso"), char:FindFirstChild("LowerTorso")); line(7, char:FindFirstChild("LowerTorso"), char:FindFirstChild("LeftUpperLeg"))
                          line(8, char:FindFirstChild("LowerTorso"), char:FindFirstChild("RightUpperLeg"))
                          line(9, char:FindFirstChild("LeftUpperLeg"), char:FindFirstChild("LeftLowerLeg")); line(10, char:FindFirstChild("RightUpperLeg"), char:FindFirstChild("RightLowerLeg"))
                       else -- R6 Skeleton
                           if char:FindFirstChild("Torso") then
                               line(1, char:FindFirstChild("Head"), char:FindFirstChild("Torso"))
                               line(2, char:FindFirstChild("Torso"), char:FindFirstChild("Left Arm"))
                               line(3, char:FindFirstChild("Torso"), char:FindFirstChild("Right Arm"))
                               line(4, char:FindFirstChild("Torso"), char:FindFirstChild("Left Leg"))
                               line(5, char:FindFirstChild("Torso"), char:FindFirstChild("Right Leg"))
                           else
                               for _,l in pairs(cache.skeleton) do l.Visible=false end
                               for _,l in pairs(cache.skeletonOutlines) do l.Visible=false end
                           end
                       end
                  else 
                      for _,l in pairs(cache.skeleton) do l.Visible=false end 
                      for _,l in pairs(cache.skeletonOutlines) do l.Visible=false end
                  end
             else
                  if cache and not cache.hidden then
                      cache.hidden = true
                      for k, d in pairs(cache) do 
                          if type(d) == "table" then for _, l in pairs(d) do l.Visible = false end elseif k ~= "hidden" then d.Visible = false end
                      end
                  end
             end
        else
             local cache = espCache[p]
             if cache and not cache.hidden then
                 cache.hidden = true
                 for k, d in pairs(cache) do 
                     if type(d) == "table" then for _, l in pairs(d) do l.Visible = false end elseif k ~= "hidden" then d.Visible = false end
                 end
             end
        end
    end
end)
Players.PlayerRemoving:Connect(removeEsp)

-- ESP UI
EspSection:Toggle({ name = "ESP Enabled", callback = function(bool) features.esp.enabled = bool; if not bool then for p,_ in pairs(espCache) do removeEsp(p) end end end })
EspSection:Toggle({ name = "Show TSB Class", callback = function(bool) espConfig.tsbClass = bool end })
EspSection:Toggle({ name = "Death Counter Highlight", callback = function(bool) espConfig.deathCounter = bool end })
EspSection:Toggle({ name = "Show Info (Dist/Class)", callback = function(bool) features.esp.infoEnabled = bool end })
EspSection:Toggle({ name = "Nametags", callback = function(bool) features.esp.nametags = bool end })
EspSection:Toggle({ name = "Rainbow ESP", callback = function(bool) features.esp.rainbow = bool end })
EspSection:Toggle({ name = "Visibility Check", callback = function(bool) espConfig.visibleCheck = bool end })
EspSection:Toggle({ name = "Team Check", callback = function(bool) espConfig.teamCheck = bool end })

EspSection:Toggle({ name = "Boxes", Name = "Boxes", callback = function(bool) features.esp.boxEnabled = bool end })
EspSection:Dropdown({ name = "Box Style", items = {"Full", "Filled", "Corner"}, default = "Corner", callback = function(val) espConfig.boxStyle = val end })
EspSection:Colorpicker({ name = "Box Color", default = Color3.new(1,0,0), callback = function(col) features.esp.boxColor = col end })
EspSection:Slider({ name = "Fill Transparency", min = 0, max = 100, default = 50, suffix = "%", callback = function(val) espConfig.fillTransparency = val/100 end })

EspSection:Toggle({ name = "Health", Name = "Health", callback = function(bool) features.esp.healthEnabled = bool end })
EspSection:Dropdown({ name = "Health Style", items = {"Bar", "Text", "Both"}, default = "Bar", callback = function(val) espConfig.healthStyle = val end })

EspSection:Toggle({ name = "Tracers", Name = "Tracers", callback = function(bool) features.esp.tracersEnabled = bool end })
EspSection:Dropdown({ name = "Tracer Origin", items = {"Bottom", "Center", "Mouse"}, default = "Bottom", callback = function(val) espConfig.tracerOrigin = val end })

EspSection:Toggle({ name = "Skeleton", Name = "Skeleton", callback = function(bool) features.esp.skeletonEnabled = bool end })
EspSection:Toggle({ name = "Head Dot", callback = function(bool) espConfig.headDot = bool end })
EspSection:Toggle({ name = "Look Lines", callback = function(bool) espConfig.lookLines = bool end })
EspSection:Toggle({ name = "Chams", Name = "Chams", callback = function(bool) features.esp.chamsEnabled = bool end })

-- Visual Mods
WorldSection:Toggle({ name = "Headless (Visual)", callback = function(bool) features.gimmicks.headless = bool end })
WorldSection:Toggle({ name = "Korblox Leg (Visual)", callback = function(bool) features.gimmicks.korblox = bool end })
WorldSection:Toggle({ name = "No Camera Shake", callback = function(bool) features.world.disableShake = bool end })






-- World UI
local cc = Lighting:FindFirstChild("TSB_CC") or Instance.new("ColorCorrectionEffect", Lighting); cc.Name = "TSB_CC"; cc.Enabled = false
local blur = Lighting:FindFirstChild("TSB_Blur") or Instance.new("BlurEffect", Lighting); blur.Name = "TSB_Blur"; blur.Size = 0; blur.Enabled = false

local function uiToggleWorld(bool) if bool then cc.Enabled=true else cc.Enabled=false; blur.Enabled=false end end -- Helper

local worldToggle = WorldSection:Toggle({ name = "World Modifications", Name = "World Modifications", text = "World Modifications", callback = function(bool) features.lighting.enabled = bool; uiToggleWorld(bool) end }) 
WorldSection:Colorpicker({ name = "Fog Color", Name = "Fog Color", text = "Fog Color", default = Color3.new(0.5,0.5,0.5), callback = function(col) Lighting.FogColor = col end })
WorldSection:Slider({ name = "Time", min=0, max=24, default=14, suffix = "h", callback = function(val) Lighting.TimeOfDay = tostring(val)..":00:00" end })
WorldSection:Slider({ name = "Brightness", min=0, max=10, default=2, suffix = " lux", callback = function(val) Lighting.Brightness = val end })
WorldSection:Slider({ name = "Saturation", min=0, max=2, default=1, suffix = "x", callback = function(val) cc.Saturation = val end })
WorldSection:Slider({ name = "Contrast", min=0, max=2, default=1, suffix = "x", callback = function(val) cc.Contrast = val end })
WorldSection:Slider({ name = "Blur Size", min=0, max=30, default = 0, suffix = "px", callback = function(val) blur.Size = val; blur.Enabled = (val > 0) end })

WorldSection:Toggle({ name = "FullBright", Name = "FullBright", text = "FullBright", callback = function(bool) features.lighting.fullBright = bool end })
WorldSection:Toggle({ name = "No Fog", Name = "No Fog", text = "No Fog", callback = function(bool) features.lighting.noFog = bool end })




-- Combined High Priority Visuals & Lighting
RunService.RenderStepped:Connect(function()
    if features.lighting.fullBright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
    end
    if features.lighting.noFog then
        Lighting.FogEnd = 999999
        Lighting.FogStart = 999999
    end
    
    if getgenv().resolutionActive then
        local cam = Workspace.CurrentCamera
        if cam then
            cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().resolutionScale, 0, 0, 0, 1)
        end
    end
end)



-- ====================
-- TAB: BLATANT
-- ====================
local BlatantCombat = BlatantTab:Section({ name = "Combat", side = "left" })
local BlatantExtra = BlatantTab:Section({ name = "Extra Features", side = "right" })

BlatantExtra:Toggle({ name = "Resolver (Anti-Fake & Prediction)", callback = function(bool) features.hvh.resolver = bool end })
BlatantExtra:Toggle({ name = "Anti-Exploit Detector", callback = function(bool) features.hvh.antiExploit = bool end })

BlatantCombat:Dropdown({ name = "Target Mode", Name = "Target Mode", text = "Target Mode", items = {"closest to player", "closest to mouse"}, default = "closest to player", callback = function(val) features.aimbot.mode = val end })

BlatantCombat:Toggle({
    name = "Garou Insta Kill", Name = "Garou Insta Kill", text = "Garou Insta Kill",
    callback = function(bool)
        if getgenv().loop then
            coroutine.close(getgenv().loop)
            getgenv().loop = nil
        end
        
        if bool then
            local animations = {
                ["rbxassetid://12273188754"]=1.31,
                ["rbxassetid://12296113986"]=1.2,
            }
            function ifind(t,a)
                for i,v in pairs(t) do
                    if i==a then return i end
                end
                return false
            end
            
            getgenv().loop = coroutine.create(function()
                local dothetech = false
                local lastcf
                while task.wait() do 
                    local character = LocalPlayer.Character
                    if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
                        local animate = character.Humanoid:FindFirstChild("Animator")
                        if animate then
                            for i,v in pairs(animate:GetPlayingAnimationTracks()) do
                                if v.Animation and ifind(animations, v.Animation.AnimationId) then
                                    -- DYNAMIC PING COMPENSATION
                                    local pTime = animations[v.Animation.AnimationId]
                                    local ping = LocalPlayer:GetNetworkPing()
                                    -- If ping is low (< 50ms), we wait slightly longer to ensure server hit
                                    local delay = (ping < 0.05) and 0.1 or 0
                                    
                                    task.wait(pTime + delay)
                                    dothetech=true
                                    lastcf = character.HumanoidRootPart.CFrame
                                    
                                    local stopConn
                                    stopConn = v.Stopped:Connect(function()
                                        dothetech = false
                                        if stopConn then stopConn:Disconnect() end
                                    end)
                                    
                                    local startTime = tick()
                                    repeat task.wait()
                                        Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                                        character.HumanoidRootPart.CFrame = CFrame.new(0,-498,0)
                                        character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                                        character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                                        if tick() - startTime > 1.5 then dothetech = false end -- Safety timeout
                                    until not dothetech
                                    
                                    if stopConn then stopConn:Disconnect() end
                                    task.wait(0.05)
                                    character.HumanoidRootPart.CFrame=lastcf
                                    Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                                    Workspace.CurrentCamera.CameraSubject = character.Humanoid
                                    task.wait(0.5) -- Faster cooldown
                                end
                            end
                        end
                    end
                end
            end)
            coroutine.resume(getgenv().loop)
        end
    end
})

BlatantExtra:Toggle({ name = "No Stun", Name = "No Stun", text = "No Stun", callback = function(bool) 
    if not _G.ScriptLoaded then return end
    features.noStun.enabled = bool 
end })
BlatantExtra:Toggle({ name = "Advanced Engine Stun Block", Name = "Advanced Engine Stun Block", text = "Advanced Engine Stun Block", callback = function(bool) 
    if not _G.ScriptLoaded then return end
    features.noStun.highUNC = bool 
end })
BlatantExtra:Toggle({ name = "Anti Fling", Name = "Anti Fling", text = "Anti Fling", callback = function(bool) features.antiFling.enabled = bool end })
BlatantExtra:Toggle({ name = "Anti Death", Name = "Anti Death", text = "Anti Death", callback = function(bool) features.antiDeath.enabled = bool end })
BlatantExtra:Toggle({ name = "No Animations", Name = "No Animations", text = "No Animations", callback = function(bool) features.stopAnims = bool end })
BlatantExtra:Toggle({ name = "Infinite Jump", Name = "Infinite Jump", text = "Infinite Jump", callback = function(bool) features.infJump = bool end })
BlatantExtra:Toggle({ name = "Spinbot", Name = "Spinbot", text = "Spinbot", callback = function(bool) features.gimmicks.spinbot = bool end })

local spinS = BlatantExtra:Slider({ name = "Spinbot Speed", Name = "Spinbot Speed", text = "Spinbot Speed", min = 1, max = 100, default = 50, suffix = " rpm", callback = function(val) features.gimmicks.spinSpeed = val end })
if spinS.items and spinS.items.name then spinS.items.name.set("Spinbot Speed") end

BlatantExtra:Toggle({ name = "Upside Down", Name = "Upside Down", text = "Upside Down", callback = function(bool)
    features.gimmicks.upsideDown = bool
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").HipHeight = bool and 2 or 0
    end
end })

-- Map TPs ONLY (No Players)
local tpTargetMap = "None"
local tpTargetPlayer = "None"
local tpLocations = {
    ["Safe Zone"] = CFrame.new(-10, 808, -378),
    ["Mid"] = CFrame.new(0, 50, 0),
    ["Void"] = CFrame.new(0, -490, 0),
    ["Left Mountain"] = Vector3.new(376.96, 699.10, 362.13),
    ["Right Mountain"] = Vector3.new(236.28, 699.10, 415.91),
    ["Looking Down"] = Vector3.new(4.35, 652.52, -336.13),
    ["Middle of the Map"] = Vector3.new(142.37, 440.76, 22.41),
    ["Gate 1"] = Vector3.new(291.19, 439.51, 375.03),
    ["Gate 2"] = Vector3.new(10.45, 439.51, -306.24),
    ["Death Counter Room"] = Vector3.new(-65.18, 29.25, 20347.43),
    ["Atomic Room"] = Vector3.new(1064.54, 131.29, 23007.78)
}
local sortedM = {}
for n, _ in pairs(tpLocations) do table.insert(sortedM, n) end
table.sort(sortedM)
mapNames = {"None"}
for _, n in ipairs(sortedM) do table.insert(mapNames, n) end

local mapTpDropdown = BlatantExtra:Dropdown({ name = "Map TP", Name = "Map TP", text = "Map TP", items = mapNames, default = "None", callback = function(val) tpTargetMap = val end })
local pTP = BlatantExtra:Dropdown({ name = "Player TP", Name = "Player TP", text = "Player TP", items = playerNames, default = "None", callback = function(val) tpTargetPlayer = val end })
table.insert(dropdownsToUpdate, pTP)

BlatantExtra:Button({ name = "Teleport Now", Name = "Teleport Now", text = "Teleport Now", callback = function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos = tpLocations[tpTargetMap]
    if tpTargetMap ~= "None" and targetPos then
        if typeof(targetPos) == "Vector3" then char.HumanoidRootPart.CFrame = CFrame.new(targetPos)
        else char.HumanoidRootPart.CFrame = targetPos end
    elseif tpTargetPlayer ~= "None" then
        local tPlayer = Players:FindFirstChild(tpTargetPlayer)
        if tPlayer and tPlayer.Character and tPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            char.HumanoidRootPart.CFrame = tPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) 
        end
    end
end})

local tpMoveTarget = "None"
local moveTpIds = {["12273188754"]=true, ["12296113986"]=true} 
BlatantExtra:Dropdown({ name = "TP on Garou Move", Name = "TP on Garou Move", text = "TP on Garou Move", items = mapNames, default = "None", callback = function(val) tpMoveTarget = val end })






-- Connections
local charConnections = {}

local function setupCharacter(char)
    -- Clear old connections
    for _, c in pairs(charConnections) do c:Disconnect() end
    table.clear(charConnections)

    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    local anim = hum:WaitForChild("Animator", 10)
    if not anim then return end

    -- Garou TP Hook
    local conn1 = anim.AnimationPlayed:Connect(function(t)
        if not t or not t.Animation then return end
        local id = t.Animation.AnimationId:match("%d+")
        if tpMoveTarget ~= "None" and moveTpIds[id] then
             local dest = tpLocations[tpMoveTarget]
             if dest then
                 if typeof(dest) == "Vector3" then char.HumanoidRootPart.CFrame = CFrame.new(dest)
                 else char.HumanoidRootPart.CFrame = dest end
             end
        end
    end)
    table.insert(charConnections, conn1)
    
    -- Anime TP Hook (Trashcan Aimbot)
    local conn2 = anim.AnimationPlayed:Connect(function(t)
        if features.aimbot.animeTp and t.Animation.AnimationId == "rbxassetid://13813955149" then
             local target = nil
             if features.aimbot.mode == "closest to player" then
                 local close, dist = nil, math.huge
                 for _, p in ipairs(Players:GetPlayers()) do
                     if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                         local d = (p.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                         if d < dist then dist = d; close = p end
                     end
                 end
                 target = close
             else -- Mouse
                 local close, dist = nil, math.huge
                 local mouse = UserInputService:GetMouseLocation()
                 for _, p in ipairs(Players:GetPlayers()) do
                     if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                         local v, os = Workspace.CurrentCamera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                         if os then
                             local d = (Vector2.new(v.X, v.Y) - mouse).Magnitude
                             if d < dist then dist = d; close = p end
                         end
                     end
                 end
                 target = close
             end
             
             if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                 local tHrp = target.Character.HumanoidRootPart
                 
                 -- GET PREDICTED POSITION (Resolver Integration)
                 local predictedOrigin = tHrp.Position
                 if features.hvh.resolver and features.hvh.resolvedPositions[target.Name] then
                     predictedOrigin = features.hvh.resolvedPositions[target.Name]
                 else
                     local ourPing = LocalPlayer:GetNetworkPing()
                     local theirPing = target:GetNetworkPing()
                     local totalLatency = (ourPing + theirPing) * 1.5
                     predictedOrigin = tHrp.Position + (tHrp.AssemblyLinearVelocity * totalLatency)
                 end
                 
                 local radius = 4.5 + (math.random(-5, 5) / 10)
                 local angle = math.rad(math.random(0,360))
                 local offset = Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
                 
                 local oldCF = char.HumanoidRootPart.CFrame
                 -- Teleport to Predicted Position with random look-at slightly off center
                 char.HumanoidRootPart.CFrame = CFrame.lookAt(predictedOrigin + offset, predictedOrigin + Vector3.new(math.random(-1,1),0,math.random(-1,1)))
                 
                 -- Look at loop (short)
                 local laLoop; laLoop = RunService.Heartbeat:Connect(function()
                      if char.Parent and tHrp.Parent then 
                          local curPredicted = tHrp.Position
                          if features.hvh.resolver and features.hvh.resolvedPositions[target.Name] then
                              curPredicted = features.hvh.resolvedPositions[target.Name]
                          end
                          char.HumanoidRootPart.CFrame = CFrame.lookAt(char.HumanoidRootPart.Position, curPredicted) 
                      else laLoop:Disconnect() end
                 end)
                 
                 t.Stopped:Wait()
                 laLoop:Disconnect()
                 task.wait(0.5)
                 char.HumanoidRootPart.CFrame = oldCF
             end
        end
    end)
    -- Death Counter Rescue & Counter-Strike Hook (Animation based)
    local conn3 = anim.AnimationPlayed:Connect(function(t)
        if t.Animation and t.Animation.AnimationId == "rbxassetid://11343250001" then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local oldPos = hrp.CFrame
                notify("Rescue System", "Counter detected! Counter-striking...", Color3.new(1,0,1))
                
                -- Immediate Camera Rescue
                task.wait(0.05)
                workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                workspace.CurrentCamera.CameraSubject = hum
                
                -- OFFENSIVE RETALIATION: Void Drop (Safe Depth)
                task.spawn(function()
                    -- Create Temp Platform above void
                    local p = Instance.new("Part", workspace)
                    p.Size = Vector3.new(30, 1, 30)
                    p.Position = Vector3.new(3000, -499, 3000) -- Safe height (-500 is void line)
                    p.Anchored = true
                    p.CanCollide = true
                    p.Transparency = 0.5
                    p.BrickColor = BrickColor.new("Really black")
                    
                    -- Teleport to Void Floor (Safety Offset)
                    hrp.CFrame = p.CFrame + Vector3.new(0, 4, 0)
                    
                    task.wait(2) -- Wait for attacker to fall/be trapped
                    
                    -- Teleport Home
                    hrp.CFrame = oldPos
                    p:Destroy()
                    
                    -- Second Camera Reset (Fixes camera break on death)
                    task.wait(5)
                    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                    workspace.CurrentCamera.CameraSubject = hum
                    
                    notify("Rescue System", "Retaliation complete. Returned to map.", Color3.new(0,1,0))
                end)
            end
        end
    end)
    table.insert(charConnections, conn3)
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
task.spawn(function()
    if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
end)

-- Anime TP (Keybind T with Animation)
Features.animeTpEnabled = false
BlatantExtra:Toggle({ name = "Anime TP (Keybind T)", Name = "Anime TP (Keybind T)", text = "Anime TP (Keybind T)", callback = function(bool) Features.animeTpEnabled = bool end })




UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if Features.animeTpEnabled and input.KeyCode == Enum.KeyCode.T then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            local mouse = LocalPlayer:GetMouse()
            if hrp and hum and mouse then
                local pos = mouse.Hit.Position + Vector3.new(0, 2.5, 0)
                hrp.CFrame = CFrame.new(pos)
                -- Play Animation
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://15957361339"
                local track = hum.Animator:LoadAnimation(anim)
                track:Play()
            end
        end
    end
end)

BlatantExtra:Button({ name = "Give Click TP Tool", Name = "Give Click TP Tool", text = "Give Click TP Tool", callback = function()
    local mouse = LocalPlayer:GetMouse()
    local tool = Instance.new("Tool"); tool.RequiresHandle = false; tool.Name = "Click TP"
    tool.Activated:Connect(function()
        local pos = mouse.Hit.Position + Vector3.new(0, 2.5, 0)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y, pos.Z) end
    end)
    if tool.items and tool.items.name then tool.items.name.set("Give Click TP Tool") end
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
local playerPosHistory = {}
local lastOrbitVelocity = {}
local lastOrbitTick = 0
local lastOrbitRandom = nil

-- Optimized Character Setup (Headless/Korblox)
local function applyVisualGimmicks(char)
    if not char then return end
    
    if features.gimmicks.headless then
        local head = char:WaitForChild("Head", 5)
        if head then
            head.Transparency = 1
            local face = head:FindFirstChild("face"); if face then face.Transparency = 1 end
            local m = head:FindFirstChild("HeadlessMesh")
            if not m then
                m = Instance.new("SpecialMesh")
                m.Name = "HeadlessMesh"; m.MeshType = Enum.MeshType.FileMesh
                m.MeshId = "rbxassetid://1095708"
                m.Scale = Vector3.new(0.001, 0.001, 0.001)
                m.Parent = head
            end
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name:lower():find("neck") or v.Name:lower():find("clutter")) then v.Transparency = 1 end
            if v:IsA("Accessory") and (v.Name:lower():find("head") or v.Name:lower():find("hair")) then
                local h = v:FindFirstChild("Handle"); if h then h.Transparency = 1 end
            end
        end
    end

    if features.gimmicks.korblox then
        local rig = (char:FindFirstChild("RightUpperLeg") and "R15") or "R6"
        local rightLeg = (rig == "R15" and char:FindFirstChild("RightUpperLeg")) or char:FindFirstChild("Right Leg")
        if rightLeg then
            local m = rightLeg:FindFirstChild("KorbloxMesh")
            if not m then
                m = Instance.new("SpecialMesh"); m.Name = "KorbloxMesh"; m.MeshType = Enum.MeshType.FileMesh
                m.MeshId = "rbxassetid://101851696"
                m.Scale = (rig == "R15" and Vector3.new(1.1, 1, 1.1)) or Vector3.new(1, 1, 1)
                m.Parent = rightLeg
            end
            rightLeg.Transparency = 0; rightLeg.Color = Color3.fromRGB(50, 50, 50)
            if rig == "R15" then
                local rl = char:FindFirstChild("RightLowerLeg"); if rl then rl.Transparency = 1 end
                local rf = char:FindFirstChild("RightFoot"); if rf then rf.Transparency = 1 end
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(applyVisualGimmicks)
if LocalPlayer.Character then applyVisualGimmicks(LocalPlayer.Character) end

-- SLOW LOOP (10 Hz) for Heavy Checks
task.spawn(function()
    while task.wait(0.1) do
        -- HVH: Anti-Exploit Features
        if features.hvh and features.hvh.antiExploit then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local velocity = hrp.AssemblyLinearVelocity.Magnitude
                        if velocity > 250 and not features.hvh.flaggedPlayers[p.Name] then
                            features.hvh.flaggedPlayers[p.Name] = true
                            notify("Exploit Detected", p.Name .. " is moving at high speed!", Color3.new(1, 0.5, 0))
                        end
                        if not _G.LastPosCache then _G.LastPosCache = {} end
                        if _G.LastPosCache[p.Name] then
                            local dist = (hrp.Position - _G.LastPosCache[p.Name]).Magnitude
                            if dist > 100 and velocity < 10 then 
                                 notify("Exploit Detected", p.Name .. " teleported " .. math.floor(dist) .. " studs!", Color3.new(1, 0, 0))
                            end
                        end
                        _G.LastPosCache[p.Name] = hrp.Position
                    end
                end
            end
        end
        
        -- HVH: Resolver
        if features.hvh and features.hvh.resolver and LocalPlayer.Character then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = p.Character.HumanoidRootPart
                    local totalLatency = LocalPlayer:GetNetworkPing() + p:GetNetworkPing()
                    if hrp.AssemblyLinearVelocity.Magnitude > 0.5 then
                        local predictedPos = hrp.Position + (hrp.AssemblyLinearVelocity * (totalLatency * 1.5))
                        if not features.hvh.resolvedPositions then features.hvh.resolvedPositions = {} end
                        if features.hvh.resolvedPositions[p.Name] then
                            features.hvh.resolvedPositions[p.Name] = features.hvh.resolvedPositions[p.Name]:Lerp(predictedPos, 0.5)
                        else
                            features.hvh.resolvedPositions[p.Name] = predictedPos
                        end
                    else
                        if not features.hvh.resolvedPositions then features.hvh.resolvedPositions = {} end
                        features.hvh.resolvedPositions[p.Name] = hrp.Position
                    end
                end
            end
        end
    end
end)

-- FAST LOOP (Stepped) for Physics/Movement
RunService.Stepped:Connect(function()
    if features.antiFling.enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if pRoot then pRoot.AssemblyLinearVelocity = Vector3.zero; pRoot.AssemblyAngularVelocity = Vector3.zero end
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end
    end

    if features.stopAnims and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    end

    if features.gimmicks.spinbot and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(features.gimmicks.spinSpeed/10), 0) end
    end

    if features.gimmicks.upsideDown and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then 
            local cf = hrp.CFrame
            hrp.CFrame = CFrame.fromMatrix(cf.Position, cf.RightVector, -cf.UpVector, -cf.LookVector) 
        end
    end

    if features.gimmicks.orbit and LocalPlayer.Character then
        local target = nil
        if features.gimmicks.orbitMode == "Selected" then target = features.gimmicks.orbitTarget
        elseif features.gimmicks.orbitMode == "Closest" then
            local close, dist = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if d < dist then dist = d; close = p end
                end
            end
            target = close
        end
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local tHrp = target.Character.HumanoidRootPart
            local rot = tick() * (features.gimmicks.orbitSpeed or 5)
            local radius = features.gimmicks.orbitRadius or 10
            local predictedPos = tHrp.Position + (tHrp.AssemblyLinearVelocity * (LocalPlayer:GetNetworkPing() + target:GetNetworkPing()))
            local offset = Vector3.new(math.cos(rot) * radius, 0, math.sin(rot) * radius)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(predictedPos + offset + Vector3.new(0, 3, 0), predictedPos)
        end
    end
end)



-- High Priority Priority Loop (Upside Down and Soft Aim)
RunService:BindToRenderStep("AntigravityGimmicks", Enum.RenderPriority.Camera.Value + 1, function()
    if features.gimmicks.upsideDown and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.pi)
        end
    end
    updateSoftAim()
end)

-- Optimized Performance Mods (Low Quality Mode)
local lowQualActive = false
local function updateLowQual()
    if lowQualActive then return end
    lowQualActive = true
    pcall(function()
        settings().Rendering.QualityLevel = 1
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        local descendants = Workspace:GetDescendants()
        for i, v in ipairs(descendants) do
            if i % 500 == 0 then task.wait() end -- Prevent hanging
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.CastShadow = false
            elseif v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.RenderFidelity = Enum.RenderFidelity.Performance
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end)
    lowQualActive = false
end






RunService.Heartbeat:Connect(function()
    -- Nothing heavy here anymore
end)


LocalPlayer.CharacterAdded:Connect(function() if flying then task.wait(0.5); startFly() end end)

-- ====================
-- TAB: MISC
-- ====================
local MiscLeft = MiscTab:Section({ name = "Movement", side = "left" })
local MiscRight = MiscTab:Section({ name = "HVH", side = "right" })


MiscLeft:Toggle({
    name = "Flight", Name = "Flight", text = "Flight",
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
local flyS = MiscLeft:Slider({ name = "Flight Speed", Name = "Flight Speed", text = "Flight Speed", min = 1, max = 10, default = 1, suffix = "x", callback = function(val) flySpeed = val end })
if flyS.items and flyS.items.name then flyS.items.name.set("Flight Speed") end

-- Speed Mod (Aggressive Property Signal)
local currentWs, currentJp, moveEnabled = 16, 50, false
MiscLeft:Toggle({ name = "Enable Speed/Jump", Name = "Enable Speed/Jump", text = "Enable Speed/Jump", callback = function(bool) moveEnabled = bool 
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum and bool then hum.WalkSpeed = currentWs; hum.JumpPower = currentJp end
end })
local wsS = MiscLeft:Slider({ name = "Walk Speed", Name = "Walk Speed", text = "Walk Speed", min = 16, max = 200, default = 16, suffix = " spd", callback = function(val) currentWs = val end })
local jpS = MiscLeft:Slider({ name = "Jump Power", Name = "Jump Power", text = "Jump Power", min = 50, max = 300, default = 50, suffix = " pwr", callback = function(val) currentJp = val end })

for _, s in pairs({wsS, jpS}) do if s.items and s.items.name then s.items.name.set(s.name or s.text) end end

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

-- HVH Section on RIGHT
MiscRight:Toggle({ name = "Anti Knockback (Velocity Bypass)", callback = function(bool)
    getgenv().antiKb = bool
    task.spawn(function()
        while getgenv().antiKb do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Zero out Y velocity if it's too high (knockup) and lock X/Z if not moving
                local vel = hrp.AssemblyLinearVelocity
                if vel.Magnitude > 50 then
                     hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
            task.wait(0.01)
        end
    end)
end })

MiscLeft:Toggle({ name = "TSB Chat Spam", callback = function(bool)
    getgenv().chatSpam = bool
    local msgs = {"GG", "L", "Skill Issue", "Nice try", "fpub on top", "femboys.pub", "get good"}
    task.spawn(function()
        while getgenv().chatSpam do
            local msg = msgs[math.random(1, #msgs)]
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
            task.wait(5)
        end
    end)
end })
local antiDCConn = nil
MiscRight:Toggle({ name = "Anti DC", callback = function(bool) 
    if antiDCConn then antiDCConn:Disconnect(); antiDCConn = nil end
    if bool then 
        local function check(v)
            if v.Name == "Death Cutscene" then 
                task.wait(0.1) -- Tiny delay so game sets up
                v:Destroy()
                notify("Anti DC", "Cutscene skipped automatically", Color3.new(1,1,1))
            end
        end
        local cut = Workspace:FindFirstChild("Cutscenes")
        if cut then
            antiDCConn = cut.ChildAdded:Connect(check)
            for _, v in pairs(cut:GetChildren()) do check(v) end
        end
    end 
end })
MiscRight:Toggle({ name = "Orbit", callback = function(bool) features.gimmicks.orbit = bool end })
MiscRight:Dropdown({ name = "Orbit Mode", items = {"Selected", "Closest", "Random"}, default = "Closest", callback = function(val) features.gimmicks.orbitMode = val end })
local orbT = MiscRight:Dropdown({ name = "Orbit Target", items = playerNames, default = "None", callback = function(val) features.gimmicks.orbitTarget = Players:FindFirstChild(val or "") end })
table.insert(dropdownsToUpdate, orbT)

local rS = MiscRight:Slider({ name = "Orbit Radius", min = 5, max = 50, default = 10, suffix = " studs", callback = function(val) features.gimmicks.orbitRadius = val end })
local oS = MiscRight:Slider({ name = "Orbit Speed", min = 1, max = 100, default = 5, suffix = "x", callback = function(val) features.gimmicks.orbitSpeed = val end })
local gS = MiscRight:Slider({ name = "World Gravity", min = 0, max = 500, default = 196.2, suffix = " g", callback = function(val) Workspace.Gravity = val end })
local fvS = MiscRight:Slider({ name = "FOV Expansion", min = 70, max = 120, default = 70, suffix = "°", callback = function(val) features.world.fov = val end })

for _, s in pairs({rS, oS, gS, fvS}) do if s.items and s.items.name then s.items.name.set(s.name or s.text) end end

local emtF = MiscRight:Dropdown({ name = "Emote Follow", items = playerNames, default = "None", callback = function(val)
    features.bootyClap.target = Players:FindFirstChild(val or "")
    features.bootyClap.following = (val ~= "None" and features.bootyClap.target)
    if features.bootyClap.following and not features.bootyClap.loop then
         local char = LocalPlayer.Character
         local hum = char and char:FindFirstChild("Humanoid")
         if hum then
             local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://120789866363939"
             local track = hum.Animator:LoadAnimation(anim)
             if track then track:Play() end
             features.bootyClap.loop = RunService.Heartbeat:Connect(function()
                 if not features.bootyClap.following or not features.bootyClap.target then 
                     if track then track:Stop() end 
                     if features.bootyClap.loop then features.bootyClap.loop:Disconnect(); features.bootyClap.loop = nil end 
                     return 
                 end
                 local tChar = features.bootyClap.target.Character
                 if tChar and tChar:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                     local offset = 3 + math.sin(tick() * 5) * 2
                     LocalPlayer.Character.HumanoidRootPart.CFrame = tChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, offset) 
                 end
             end)
         end
    end
end })
table.insert(dropdownsToUpdate, emtF)







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

-- ====================
-- TAB: SETTINGS
-- ====================
local MainSettings = ConfigTab:Section({ name = "Performance", side = "left" })
local ServerSettings = ConfigTab:Section({ name = "Server Tools", side = "right" })

-- Server fetch helper
local function fetchServers()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
    local success, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
    return success and res and res.data or {}
end

ServerSettings:Button({ name = "Rejoin Server", callback = rejoin })
ServerSettings:Button({ name = "Copy Job ID", callback = function() setclipboard(game.JobId); notify("Server", "Job ID copied to clipboard", Color3.new(1,1,1)) end })

ServerSettings:Button({ name = "Server Hop", callback = function() 
    notify("Server Hop", "Searching for servers...", Color3.fromRGB(200, 200, 200))
    local servers = fetchServers()
    local valid = {}
    for _, s in ipairs(servers) do 
        -- Better validation: check that server isn't full and has data
        if s.id and s.maxPlayers and s.playing and type(s.playing) == "number" and type(s.maxPlayers) == "number" then
            if s.playing < (s.maxPlayers - 1) and s.id ~= game.JobId then -- Leave 1 slot buffer
                table.insert(valid, s) 
            end
        end 
    end
    if #valid > 0 then 
        local chosen = valid[math.random(1, #valid)]
        notify("Server Hop", "Found server (" .. chosen.playing .. "/" .. chosen.maxPlayers .. " players)", Color3.fromRGB(100, 255, 100))
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, LocalPlayer) 
    else
        notify("Server Hop", "No available servers found!", Color3.fromRGB(255, 100, 100))
    end
end })
ServerSettings:Button({ name = "Lowest Players", callback = function() 
    notify("Server Hop", "Searching for least populated server...", Color3.fromRGB(200, 200, 200))
    local servers = fetchServers()
    local valid = {}
    for _, s in ipairs(servers) do 
        if s.id and s.maxPlayers and s.playing and type(s.playing) == "number" and type(s.maxPlayers) == "number" then
            if s.playing < (s.maxPlayers - 1) and s.id ~= game.JobId then
                table.insert(valid, s) 
            end
        end 
    end
    table.sort(valid, function(a, b) return a.playing < b.playing end)
    if valid[1] then 
        notify("Server Hop", "Found server (" .. valid[1].playing .. "/" .. valid[1].maxPlayers .. " players)", Color3.fromRGB(100, 255, 100))
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, valid[1].id, LocalPlayer) 
    else
        notify("Server Hop", "No available servers found!", Color3.fromRGB(255, 100, 100))
    end
end })


local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Cache for restoring original state
_G.FPSCache = _G.FPSCache or {
    parts = {},      -- [part] = origCastShadow
    decals = {},      -- [decal] = origTransparency
    effects = {},     -- [effect] = origEnabled
    materials = {},   -- [part] = origMaterial
    lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        Technology = Lighting.Technology,
    },
    conn = nil,
}

local function applyToInstance(v, lowQual)
    if v:IsA("BasePart") then
        if _G.FPSCache.parts[v] == nil then
            _G.FPSCache.parts[v] = v.CastShadow
        end
        v.CastShadow = false

        if lowQual then
            if _G.FPSCache.materials[v] == nil then
                _G.FPSCache.materials[v] = v.Material
            end
            v.Material = Enum.Material.SmoothPlastic
        end

    elseif v:IsA("Decal") or v:IsA("Texture") then
        if _G.FPSCache.decals[v] == nil then
            _G.FPSCache.decals[v] = v.Transparency
        end
        v.Transparency = 1

    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
        if _G.FPSCache.effects[v] == nil then
            _G.FPSCache.effects[v] = v.Enabled
        end
        v.Enabled = false
    end
end

MainSettings:Toggle({ name = "FPS Booster", callback = function(bool)
    features.performance.fpsBooster = bool

    if bool then
        -- Hit the big levers first — these matter way more than CastShadow
        if _G.FPSCache.lighting.GlobalShadows == nil then
            _G.FPSCache.lighting.GlobalShadows = Lighting.GlobalShadows
        end
        if _G.FPSCache.lighting.Technology == nil then
            _G.FPSCache.lighting.Technology = Lighting.Technology
        end

        Lighting.GlobalShadows = false
        pcall(function()
            Lighting.Technology = Enum.Technology.Compatibility -- biggest single FPS win on most maps
        end)

        -- Disable post-processing effects (Bloom, SunRays, DOF, ColorCorrection, Atmosphere)
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") or fx:IsA("Atmosphere") then
                if _G.FPSCache.effects[fx] == nil then
                    _G.FPSCache.effects[fx] = fx.Enabled
                end
                pcall(function() fx.Enabled = false end)
            end
        end

        -- Process existing instances in chunks
        task.spawn(function()
            local descendants = Workspace:GetDescendants()
            for i, v in ipairs(descendants) do
                applyToInstance(v, false)
                if i % 1500 == 0 then task.wait() end
            end
        end)

        -- Catch anything streamed/spawned in afterward
        if _G.FPSCache.conn then _G.FPSCache.conn:Disconnect() end
        _G.FPSCache.conn = Workspace.DescendantAdded:Connect(function(v)
            applyToInstance(v, features.performance.fpsUltraBooster)
        end)

    else
        -- Restore everything from cache
        Lighting.GlobalShadows = _G.FPSCache.lighting.GlobalShadows
        pcall(function() Lighting.Technology = _G.FPSCache.lighting.Technology end)

        if _G.FPSCache.conn then
            _G.FPSCache.conn:Disconnect()
            _G.FPSCache.conn = nil
        end

        for v, orig in pairs(_G.FPSCache.parts) do
            if v and v.Parent then v.CastShadow = orig end
        end
        for v, orig in pairs(_G.FPSCache.decals) do
            if v and v.Parent then v.Transparency = orig end
        end
        for v, orig in pairs(_G.FPSCache.effects) do
            if v and v.Parent then pcall(function() v.Enabled = orig end) end
        end
        if not features.performance.fpsUltraBooster then
            for v, orig in pairs(_G.FPSCache.materials) do
                if v and v.Parent then v.Material = orig end
            end
            _G.FPSCache.materials = {}
        end

        _G.FPSCache.parts = {}
        _G.FPSCache.decals = {}
        _G.FPSCache.effects = {}
    end
end })

MainSettings:Toggle({ name = "Ping Optimizer (Safe)", callback = function(bool)
    features.performance.pingBooster = bool
    if bool then
        local fflags = {
            ["FFlagOptimizeNetwork"] = "True",
            ["FFlagOptimizeNetworkTransport"] = "True",
            ["FFlagOptimizeNetworkRouting"] = "True",
            ["FFlagEnableAsyncInput"] = "True",
            ["FFlagParallelLuauRuntimeConcurrency"] = "True"
        }
        for f, v in pairs(fflags) do pcall(function() setfflag(f, v) end) end
        pcall(function() settings().Network.DirectReplicationLimit = 100 end) -- More conservative
        notify("Network", "Ping Optimization Applied (Balanced)", Color3.new(0.5, 1, 0.5))
    end
end })

MainSettings:Toggle({ name = "FPS Ultra Booster (LQ)", callback = function(bool)
    features.performance.fpsUltraBooster = bool

    if bool then
        task.spawn(function()
            local descendants = Workspace:GetDescendants()
            for i, v in ipairs(descendants) do
                if v:IsA("BasePart") then
                    if _G.FPSCache.materials[v] == nil then
                        _G.FPSCache.materials[v] = v.Material
                    end
                    v.Material = Enum.Material.SmoothPlastic
                end
                if i % 1500 == 0 then task.wait() end
            end
        end)
    else
        for v, orig in pairs(_G.FPSCache.materials) do
            if v and v.Parent then v.Material = orig end
        end
        _G.FPSCache.materials = {}
    end
end })
-- Resolution Stretcher
MainSettings:Dropdown({ name = "Resolution Preset", items = {"Native (1.0)", "4:3 Stretched (0.75)", "5:4 Stretched (0.8)", "Slight Stretch (0.9)", "Custom"}, default = "Native (1.0)", callback = function(val)
    if val == "Native (1.0)" then
        applyResolution(1.0)
    elseif val == "4:3 Stretched (0.75)" then
        applyResolution(0.75)
    elseif val == "5:4 Stretched (0.8)" then
        applyResolution(0.8)
    elseif val == "Slight Stretch (0.9)" then
        applyResolution(0.9)
    end
end })

local resSlider = MainSettings:Slider({ name = "Custom Stretch", min = 50, max = 150, default = 100, suffix = "%", callback = function(val)
    applyResolution(val / 100)
end })
if resSlider.items and resSlider.items.name then resSlider.items.name.set("Custom Stretch") end

MainSettings:Toggle({ name = "Input Delay Remover (LMLYX v9)", Name = "Input Delay Remover (LMLYX v9)", callback = function(bool)
    if bool then
        local fflags = {
            ["DFIntTouchSenderMaxBandwidthBps"] = "50000", ["DFIntPhysicsSenderMaxBandwidthBps"] = "200000000", ["DFIntClusterSenderMaxJoinBandwidthBps"] = "10000000",
            ["DFIntDataSenderRate"] = "10000", ["DFIntS2PhysicsSenderRate"] = "250", ["DFIntServerTickRate"] = "60", ["DFIntPlayerNetworkUpdateRate"] = "60",
            ["FFlagOptimizeNetwork"] = "True", ["FFlagOptimizeNetworkTransport"] = "True", ["FFlagOptimizeNetworkRouting"] = "True",
            ["DFIntRakNetNakResendDelayMs"] = "1", ["DFIntRakNetSelectTimeoutMs"] = "2", ["DFIntRakNetLoopMs"] = "1",
            ["DFIntMaxDataPacketPerSend"] = "2147483647", ["DFIntNetworkQualityResponderMaxWaitTime"] = "2",
            ["DFIntSimAdaptiveHumanoidPDControllerSubstepMultiplier"] = "50000", ["FFlagQuaternionPoseCorrection"] = "True",
            ["DFIntTimestepArbiterHumanoidTurningVelThreshold"] = "60000", ["FFlagAnimationStreamSourceUseRuntimeSyncPrims"] = "True",
            ["DFIntAngularVelociryLimit"] = "800000", ["DFFlagHumanoidSimWorld"] = "True", ["DFIntBandwidthManagerDataSenderMaxWorkCatchupMs"] = "5000",
            ["DFFlagTrackNetworkSenderStall"] = "True", ["DFFlagDataSenderEmptyTrackBeforeRun"] = "True", ["DFIntPhysicsNOUCountHundredth"] = "1000000",
            ["DFFlagFixPhysicsSenderBlockMultiplier"] = "True", ["FFlagAnimationStreamTrackUseRuntimeSyncPrims"] = "True",
            ["FFlagAvatarUseRuntimeSyncPrims4"] = "True", ["DFFlagRobloxTelemetryEnableSenderCallback"] = "False",
            ["DFFlagSimHumanoidFirstPerson240hz"] = "True", ["FFlagHumanoidStateUseRuntimeSyncPrims"] = "True",
            ["FFlagKeyframeSequenceUseRuntimeSyncPrims"] = "True", ["FFlagParallelLuauRuntimeConcurrency"] = "True",
            ["FFlagTaskSchedulerUseRuntimeSyncPrims"] = "True", ["FFlagEnableAsyncInput"] = "True",
            ["FFlagDebugDisplayFPS"] = "True", ["FFlagRenderShadowIntensity"] = "0", ["FFlagRenderTextureDelay"] = "0",
            ["FFlagRenderHighQualityColors"] = "False", ["FFlagRenderSmoothHumanoidMovement"] = "True",
            ["FFlagRenderForceLowDetailMeshes"] = "True", ["FFlagRenderLocalPlayerNameTag"] = "False"
        }
        for f, v in pairs(fflags) do pcall(function() setfflag(f, v) end) end
        settings().Rendering.MeshCacheSize = 0
        pcall(function() settings().Network.DirectReplicationLimit = 500 end)
    end
end })

-- FastFlags added to MainSettings
local capS = MainSettings:Slider({ name = "FPS Cap", min = 30, max = 2000, default = 240, suffix = " fps", callback = function(val) setfpscap(val) end })
if capS.items and capS.items.name then capS.items.name.set("FPS Cap") end

MainSettings:Button({ name = "Enable Performance FFlags", callback = function()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshCacheSize = 0
        if setfflag then
            setfflag("FFlagDebugDisplayFPS", "True")
            setfflag("FFlagRenderShadowIntensity", "0")
            setfflag("FFlagRenderTextureDelay", "0")
        end
    end)
    notify("Settings", "Optimized FFlags and Rendering applied!", Color3.fromRGB(100, 255, 100))
end })


_G.ScriptLoaded = true



local spamMsg = "femboy.sense owns you"
MainSettings:Textbox({ name = "Spam Message", placeholder = "Text here...", callback = function(val) spamMsg = val end })

local chatSpamLoopActive = false
MainSettings:Toggle({ name = "Enable Spammer", callback = function(bool)
    features.gimmicks.chatSpam = bool
    if bool and not chatSpamLoopActive then
        chatSpamLoopActive = true
        task.spawn(function()
            while features.gimmicks.chatSpam do
                pcall(function()
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(spamMsg, "All")
                end)
                task.wait(3 + (math.random(-5, 10) / 10))
            end
            chatSpamLoopActive = false
        end)
    end
end })



-- Init
task.delay(1, function()
    Window.toggle_menu(true)
    if Library.init_config then
        Library:init_config(Window)
    end
end)


-- Ping Monitor
local lastPingWarning = 0
task.spawn(function()
    while true do
        local stats = game:GetService("Stats")
        local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        if ping > 100 then
            if tick() - lastPingWarning > 60 then -- 1 minute cooldown to avoid spam
                lastPingWarning = tick()
                notify("Ping Warning", "your ping is a little high, teleporting players might not work due to game limitations", Color3.new(1,0,0))
            end
        end
        task.wait(10)
    end
end)

-- Anti Death Counter & DC Rescue Thread
task.spawn(function()
    while task.wait(0.5) do
        -- OFFENSIVE LOGIC: Kill others using DC (Legacy feature)
        if features.antiDeath.enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp and hum and hum.Health > 0 then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local backpack = p:FindFirstChild("Backpack")
                        local hasDC = (backpack and backpack:FindFirstChild("Death Counter")) or (p.Character and p.Character:FindFirstChild("Death Counter"))
                        
                        if hasDC then
                            local targetHRP = p.Character:FindFirstChild("HumanoidRootPart")
                            if targetHRP and (targetHRP.Position - hrp.Position).Magnitude < 20 then
                                local oldPos = hrp.CFrame
                                notify("Anti Death Counter", "Counter-Strike on " .. p.Name, Color3.new(1,0.5,0))
                                hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                                task.wait(0.1)
                                
                                if hum.Health > 0 then
                                    hrp.CFrame = CFrame.new(0, -900, 0) -- Deep void
                                end
                                
                                task.wait(0.5)
                                
                                if hum.Health > 0 then
                                    hrp.CFrame = oldPos
                                end
                                task.wait(1)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Init
task.delay(1, function()
    if Window then
        Window.toggle_menu(true)
        if Library.init_config then
            Library:init_config(Window)
        end
    end
end)

-- Ping Monitor
local lastPingWarning = 0
task.spawn(function()
    while true do
        local success, stats = pcall(function() return game:GetService("Stats") end)
        if success and stats then
            local pingItem = stats.Network:FindFirstChild("ServerStatsItem") and stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
            if pingItem then
                local ping = pingItem:GetValue()
                if ping > 150 then
                    if tick() - lastPingWarning > 60 then
                        lastPingWarning = tick()
                        notify("Ping Warning", "your ping is high ("..math.floor(ping).."ms), teleports might fail", Color3.new(1,0,0))
                    end
                end
            end
        end
        task.wait(10)
    end
end)
