local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local GlobalCData = require(ReplicatedStorage.Modules.GlobalCData)

local CustomRates = {
    DrainRate = 0.4,
    RegenRate = 1.0,
}

local realStamina = GlobalCData.Stamina or 100
local lastStamina = realStamina

local staminaThread = task.spawn(function()
    while task.wait() do
        local current = GlobalCData.Stamina
        if current ~= lastStamina then
            local diff = current - lastStamina
            
            if diff < 0 then
                local lossRatio = diff / -0.4
                realStamina = math.clamp(realStamina - (CustomRates.DrainRate * lossRatio), 0, GlobalCData.MaxStamina or 100)
            elseif diff > 0 then
                local gainRatio = diff / 1.0
                realStamina = math.clamp(realStamina + (CustomRates.RegenRate * gainRatio), 0, GlobalCData.MaxStamina or 100)
            end
            
            GlobalCData.Stamina = realStamina
            lastStamina = realStamina
        end
    end
end)

local isNoclipping = false
local noclipConnection = nil

noclipConnection = RunService.Stepped:Connect(function()
    if isNoclipping then
        local char = GlobalCData.Character or LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Unseen Liminality",
    LoadingTitle = "By M00KIE",
    LoadingSubtitle = "😹✌️",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab("Stamina Controls", 4483362458)

MainTab:CreateSection("Stamina Rates (Per Second)")

MainTab:CreateSlider({
    Name = "Stamina Loss Rate",
    Range = {0, 50},
    Increment = 0.5,
    Suffix = " /sec",
    CurrentValue = CustomRates.DrainRate * 10,
    Flag = "StaminaLoss",
    Callback = function(Value)
        CustomRates.DrainRate = Value / 10
    end,
})

MainTab:CreateSlider({
    Name = "Stamina Gain Rate",
    Range = {0, 50},
    Increment = 0.5,
    Suffix = " /sec",
    CurrentValue = CustomRates.RegenRate * 10,
    Flag = "StaminaGain",
    Callback = function(Value)
        CustomRates.RegenRate = Value / 10
    end,
})

MainTab:CreateSection("Quick Actions")

MainTab:CreateButton({
    Name = "Infinite Sprint (0 Loss)",
    Callback = function()
        CustomRates.DrainRate = 0
        Rayfield:Notify({ Title = "Stamina", Content = "Infinite Sprint Enabled!", Duration = 2 })
    end,
})

MainTab:CreateButton({
    Name = "Reset Defaults (4 Loss / 10 Gain)",
    Callback = function()
        CustomRates.DrainRate = 0.4
        CustomRates.RegenRate = 1.0
        Rayfield:Notify({ Title = "Stamina", Content = "Reset to standard values.", Duration = 2 })
    end,
})

MainTab:CreateSection("Settings")

local activeHighlights = {}

local function clearHighlights()
    for _, hl in ipairs(activeHighlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
    end
    activeHighlights = {}
end

local spectateTrackerThread = nil

MainTab:CreateButton({
    Name = "Unload GUI",
    Callback = function()
        if staminaThread then task.cancel(staminaThread) end
        if spectateTrackerThread then task.cancel(spectateTrackerThread) end
        if noclipConnection then noclipConnection:Disconnect() end
        clearHighlights()
        
        local camera = workspace.CurrentCamera
        local char = GlobalCData.Character or LocalPlayer.Character
        if camera and char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then camera.CameraSubject = hum end
        end
        
        Rayfield:Destroy()
    end,
})

local VisualsTab = Window:CreateTab("Visuals", 4483362458)

local npcHighlightsEnabled = false
local playerHighlightsEnabled = false

local npcFillColor = Color3.fromRGB(255, 50, 50)
local npcOutlineColor = Color3.fromRGB(255, 255, 255)

local playerFillColor = Color3.fromRGB(0, 200, 255)
local playerOutlineColor = Color3.fromRGB(255, 255, 255)

local function applyHighlights()
    clearHighlights()
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
            
            if hum then
                if not isPlayer and npcHighlightsEnabled then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "NPCHighlight"
                    highlight.Adornee = obj
                    highlight.FillColor = npcFillColor
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = npcOutlineColor
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = obj
                    
                    table.insert(activeHighlights, highlight)
                elseif isPlayer and playerHighlightsEnabled then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "PlayerHighlight"
                    highlight.Adornee = obj
                    highlight.FillColor = playerFillColor
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = playerOutlineColor
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = obj
                    
                    table.insert(activeHighlights, highlight)
                end
            end
        end
    end
end

VisualsTab:CreateSection("Toggles")

VisualsTab:CreateToggle({
    Name = "Highlight NPCs",
    CurrentValue = false,
    Flag = "NPCHighlightToggle",
    Callback = function(Value)
        npcHighlightsEnabled = Value
        applyHighlights()
    end,
})

VisualsTab:CreateToggle({
    Name = "Highlight Players",
    CurrentValue = false,
    Flag = "PlayerHighlightToggle",
    Callback = function(Value)
        playerHighlightsEnabled = Value
        applyHighlights()
    end,
})

VisualsTab:CreateSection("NPC Colors")

VisualsTab:CreateColorPicker({
    Name = "NPC Fill Color",
    Color = npcFillColor,
    Flag = "NPCFillColorPicker",
    Callback = function(Value)
        npcFillColor = Value
        applyHighlights()
    end,
})

VisualsTab:CreateColorPicker({
    Name = "NPC Outline Color",
    Color = npcOutlineColor,
    Flag = "NPCOutlineColorPicker",
    Callback = function(Value)
        npcOutlineColor = Value
        applyHighlights()
    end,
})

VisualsTab:CreateSection("Player Colors")

VisualsTab:CreateColorPicker({
    Name = "Player Fill Color",
    Color = playerFillColor,
    Flag = "PlayerFillColorPicker",
    Callback = function(Value)
        playerFillColor = Value
        applyHighlights()
    end,
})

VisualsTab:CreateColorPicker({
    Name = "Player Outline Color",
    Color = playerOutlineColor,
    Flag = "PlayerOutlineColorPicker",
    Callback = function(Value)
        playerOutlineColor = Value
        applyHighlights()
    end,
})

VisualsTab:CreateSection("Controls")

VisualsTab:CreateButton({
    Name = "Refresh Highlights",
    Callback = function()
        applyHighlights()
        Rayfield:Notify({ Title = "Visuals", Content = "Refreshed highlights.", Duration = 2 })
    end,
})

local UtilityTab = Window:CreateTab("Player & Utility", 4483362458)

UtilityTab:CreateSection("Movement Controls")

UtilityTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value)
        isNoclipping = Value
        Rayfield:Notify({ Title = "Noclip", Content = isNoclipping and "Enabled" or "Disabled", Duration = 2 })
    end,
})

UtilityTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    Suffix = " spd",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        local char = GlobalCData.Character or LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = Value
            end
        end
    end,
})

UtilityTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    Increment = 5,
    Suffix = " pwr",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        local char = GlobalCData.Character or LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = Value
            end
        end
    end,
})

UtilityTab:CreateSection("Teleportation")

local targetPlayerTP = nil
local playerTPMap = {}
local playerTPNames = {}

local function updatePlayerTPList()
    playerTPMap = {}
    playerTPNames = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local name = plr.DisplayName .. " (@" .. plr.Name .. ")"
            table.insert(playerTPNames, name)
            playerTPMap[name] = plr
        end
    end
    if #playerTPNames == 0 then
        table.insert(playerTPNames, "No Players Found")
    end
end

updatePlayerTPList()

local playerTPDropdown = UtilityTab:CreateDropdown({
    Name = "Select Player to Teleport",
    Options = playerTPNames,
    CurrentOption = playerTPNames[1] or "No Players Found",
    Flag = "PlayerTPDropdown",
    Callback = function(Option)
        if type(Option) == "table" then Option = Option[1] end
        targetPlayerTP = playerTPMap[Option]
    end,
})

UtilityTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        updatePlayerTPList()
        playerTPDropdown:Refresh(playerTPNames)
    end,
})

UtilityTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if targetPlayerTP and targetPlayerTP.Character then
            local targetHRP = targetPlayerTP.Character:FindFirstChild("HumanoidRootPart")
            local myChar = GlobalCData.Character or LocalPlayer.Character
            if myChar and targetHRP then
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 2, 3)
                    Rayfield:Notify({ Title = "Teleported", Content = "Arrived at " .. targetPlayerTP.Name, Duration = 2 })
                end
            end
        end
    end,
})

UtilityTab:CreateSection("Spectate HUD & Controls")

local spectateTargets = {}
local currentIndex = 1
local isSpectating = false

local function scanSpectateTargets()
    spectateTargets = {}
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                table.insert(spectateTargets, {
                    Name = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    Humanoid = hum,
                    RootPart = hrp,
                    Model = plr.Character,
                    Type = "Player"
                })
            end
        end
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
            
            if hum and hrp and not isPlayer then
                table.insert(spectateTargets, {
                    Name = "[NPC] " .. obj.Name,
                    Humanoid = hum,
                    RootPart = hrp,
                    Model = obj,
                    Type = "NPC"
                })
            end
        end
    end
end

scanSpectateTargets()

local targetLabel = UtilityTab:CreateLabel("◀   Self (Local Player)   ▶", 4483362458)
local statsLabel = UtilityTab:CreateLabel("Speed: 0.0 | Health: --/-- | Distance: 0 studs", 4483362458)

local function updateSpectateView()
    if not isSpectating or #spectateTargets == 0 then
        targetLabel:Set("◀   Self (Local Player)   ▶", 4483362458)
        statsLabel:Set("Speed: 0.0 | Health: --/-- | Distance: 0 studs", 4483362458)
        local char = GlobalCData.Character or LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then workspace.CurrentCamera.CameraSubject = hum end
        end
        return
    end
    
    if currentIndex < 1 then currentIndex = #spectateTargets end
    if currentIndex > #spectateTargets then currentIndex = 1 end
    
    local data = spectateTargets[currentIndex]
    if data and data.Humanoid then
        workspace.CurrentCamera.CameraSubject = data.Humanoid
        targetLabel:Set("◀   " .. data.Name .. "   ▶", 4483362458)
    end
end

UtilityTab:CreateButton({
    Name = "◀  Previous Target",
    Callback = function()
        scanSpectateTargets()
        if #spectateTargets > 0 then
            isSpectating = true
            currentIndex = currentIndex - 1
            updateSpectateView()
        end
    end,
})

UtilityTab:CreateButton({
    Name = "Next Target  ▶",
    Callback = function()
        scanSpectateTargets()
        if #spectateTargets > 0 then
            isSpectating = true
            currentIndex = currentIndex + 1
            updateSpectateView()
        end
    end,
})

UtilityTab:CreateButton({
    Name = "Stop Spectating (View Self)",
    Callback = function()
        isSpectating = false
        updateSpectateView()
        Rayfield:Notify({ Title = "Spectate", Content = "Returned to self.", Duration = 2 })
    end,
})

spectateTrackerThread = task.spawn(function()
    while task.wait(0.1) do
        if isSpectating and #spectateTargets > 0 and spectateTargets[currentIndex] then
            local target = spectateTargets[currentIndex]
            if target.Humanoid and target.RootPart then
                local currentVel = target.RootPart.AssemblyLinearVelocity
                local flatVel = Vector3.new(currentVel.X, 0, currentVel.Z)
                local currentSpeed = math.round(flatVel.Magnitude * 10) / 10
                
                local hp = math.round(target.Humanoid.Health)
                local maxHp = math.round(target.Humanoid.MaxHealth)
                
                local distStr = "N/A"
                local myChar = GlobalCData.Character or LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local dist = (myChar.HumanoidRootPart.Position - target.RootPart.Position).Magnitude
                    distStr = tostring(math.round(dist)) .. " studs"
                end
                
                statsLabel:Set("Speed: " .. tostring(currentSpeed) .. " st/s | HP: " .. tostring(hp) .. "/" .. tostring(maxHp) .. " | Dist: " .. distStr, 4483362458)
            end
        end
    end
end)
