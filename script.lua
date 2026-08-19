local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local GlobalCData = require(ReplicatedStorage.Modules.GlobalCData)

-- Stamina Settings
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

-- Movement & Physics Enforcement
local isNoclipping = false
local customWalkSpeed = 16
local customJumpPower = 50
local overrideWalkSpeed = false
local overrideJumpPower = false

-- Dynamic Animation Settings
local dynamicAnimEnabled = false
local baseWalkSpeed = 16

local noclipConnection = nil
local movementConnection = nil
local animConnection = nil

local function getLocalCharacter()
    return LocalPlayer.Character or GlobalCData.Character
end

noclipConnection = RunService.Stepped:Connect(function()
    if isNoclipping then
        local char = getLocalCharacter()
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end
end)

movementConnection = RunService.RenderStepped:Connect(function()
    local char = getLocalCharacter()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if overrideWalkSpeed then
                hum.WalkSpeed = customWalkSpeed
            end
            if overrideJumpPower then
                hum.UseJumpPower = true
                hum.JumpPower = customJumpPower
            end
        end
    end
end)

animConnection = RunService.Stepped:Connect(function()
    if dynamicAnimEnabled then
        local char = getLocalCharacter()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                local currentVelocity = (hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
                local calculatedSpeed = currentVelocity / baseWalkSpeed
                if currentVelocity < 0.1 then
                    calculatedSpeed = 1.0
                end
                
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        track:AdjustSpeed(calculatedSpeed)
                    end
                end
            end
        end
    end
end)

-- UI Construction
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Unseen Liminality",
    LoadingTitle = "By M00KIE",
    LoadingSubtitle = "😹✌️",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- Stamina Controls Tab
local MainTab = Window:CreateTab("Stamina Controls", 4483362458)

MainTab:CreateSection("Stamina Rates (Per Second)")

local DrainSlider = MainTab:CreateSlider({
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

local GainSlider = MainTab:CreateSlider({
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
        DrainSlider:Set(0)
        Rayfield:Notify({ Title = "Stamina", Content = "Infinite Sprint Enabled!", Duration = 2 })
    end,
})

MainTab:CreateButton({
    Name = "Reset Defaults (4 Loss / 10 Gain)",
    Callback = function()
        DrainSlider:Set(4)
        GainSlider:Set(10)
        Rayfield:Notify({ Title = "Stamina", Content = "Reset to standard values.", Duration = 2 })
    end,
})

-- Visuals Tab
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

local activeHighlights = {}
local eventConnections = {}

local function clearHighlights()
    for _, hl in ipairs(activeHighlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
    end
    activeHighlights = {}
end

local npcHighlightsEnabled = false
local playerHighlightsEnabled = false

local npcFillColor = Color3.fromRGB(255, 50, 50)
local npcOutlineColor = Color3.fromRGB(255, 255, 255)

local playerFillColor = Color3.fromRGB(0, 200, 255)
local playerOutlineColor = Color3.fromRGB(255, 255, 255)

local function highlightModel(model, isPlayer)
    if not model or model == getLocalCharacter() then return end
    
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if not isPlayer and npcHighlightsEnabled then
        local highlight = Instance.new("Highlight")
        highlight.Name = "NPCHighlight"
        highlight.Adornee = model
        highlight.FillColor = npcFillColor
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = npcOutlineColor
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
        table.insert(activeHighlights, highlight)
    elseif isPlayer and playerHighlightsEnabled then
        local highlight = Instance.new("Highlight")
        highlight.Name = "PlayerHighlight"
        highlight.Adornee = model
        highlight.FillColor = playerFillColor
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = playerOutlineColor
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
        table.insert(activeHighlights, highlight)
    end
end

local function applyHighlights()
    clearHighlights()
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
            highlightModel(obj, isPlayer)
        end
    end
end

-- Auto Listeners for Respawn / New Players
local function setupAutoHighlighting()
    for _, conn in ipairs(eventConnections) do
        conn:Disconnect()
    end
    eventConnections = {}

    local function onCharacterAdded(char, plr)
        task.wait(0.5)
        if playerHighlightsEnabled then
            highlightModel(char, true)
        end
    end

    local function onPlayerAdded(plr)
        local conn = plr.CharacterAdded:Connect(function(char)
            onCharacterAdded(char, plr)
        end)
        table.insert(eventConnections, conn)
        if plr.Character then
            onCharacterAdded(plr.Character, plr)
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            onPlayerAdded(plr)
        end
    end

    local pAddConn = Players.PlayerAdded:Connect(onPlayerAdded)
    table.insert(eventConnections, pAddConn)
end

setupAutoHighlighting()

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

-- Player & Utility Tab
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

local WalkSpeedSlider = UtilityTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    Suffix = " spd",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        customWalkSpeed = Value
        overrideWalkSpeed = (Value ~= 16)
        
        local char = getLocalCharacter()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = Value
            end
        end
    end,
})

local JumpPowerSlider = UtilityTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    Increment = 5,
    Suffix = " pwr",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        customJumpPower = Value
        overrideJumpPower = (Value ~= 50)
        
        local char = getLocalCharacter()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = Value
            end
        end
    end,
})

UtilityTab:CreateButton({
    Name = "Reset Movement Defaults",
    Callback = function()
        WalkSpeedSlider:Set(16)
        JumpPowerSlider:Set(50)
        overrideWalkSpeed = false
        overrideJumpPower = false
        Rayfield:Notify({ Title = "Movement", Content = "Speed & Jump reset to default.", Duration = 2 })
    end,
})

UtilityTab:CreateSection("Animation Controls")

UtilityTab:CreateToggle({
    Name = "Dynamic Animation Scaling",
    CurrentValue = false,
    Flag = "DynamicAnimToggle",
    Callback = function(Value)
        dynamicAnimEnabled = Value
        if not Value then
            local char = getLocalCharacter()
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local animator = hum:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            track:AdjustSpeed(1.0)
                        end
                    end
                end
            end
        end
        Rayfield:Notify({ Title = "Animations", Content = Value and "Dynamic Scaling Enabled" or "Reset to Normal", Duration = 2 })
    end,
})

UtilityTab:CreateSection("Teleportation")

local targetPlayerTP = nil
local playerTPMap = {}
local playerTPNames = {}
local playerTPDropdown = nil

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
    if playerTPDropdown then
        playerTPDropdown:Refresh(playerTPNames)
    end
end

updatePlayerTPList()

playerTPDropdown = UtilityTab:CreateDropdown({
    Name = "Select Player to Teleport",
    Options = playerTPNames,
    CurrentOption = playerTPNames[1] or "No Players Found",
    Flag = "PlayerTPDropdown",
    Callback = function(Option)
        if type(Option) == "table" then Option = Option[1] end
        targetPlayerTP = playerTPMap[Option]
    end,
})

-- Dynamic Player List Update Listeners
local tpPlayerAddedConn = Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    updatePlayerTPList()
end)
table.insert(eventConnections, tpPlayerAddedConn)

local tpPlayerRemovingConn = Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    updatePlayerTPList()
end)
table.insert(eventConnections, tpPlayerRemovingConn)

UtilityTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        updatePlayerTPList()
    end,
})

UtilityTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if targetPlayerTP and targetPlayerTP.Character then
            local targetHRP = targetPlayerTP.Character:FindFirstChild("HumanoidRootPart")
            local myChar = getLocalCharacter()
            if myChar and targetHRP then
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    local targetPos = targetHRP.Position + Vector3.new(0, 2, 3)
                    task.spawn(function()
                        LocalPlayer:RequestStreamAroundAsync(targetPos)
                        myHRP.CFrame = CFrame.new(targetPos)
                        Rayfield:Notify({ Title = "Teleported", Content = "Arrived at " .. targetPlayerTP.Name, Duration = 2 })
                    end)
                end
            end
        end
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("GUI Management")

SettingsTab:CreateButton({
    Name = "Unload GUI",
    Callback = function()
        if staminaThread then task.cancel(staminaThread) end
        if noclipConnection then noclipConnection:Disconnect() end
        if movementConnection then movementConnection:Disconnect() end
        if animConnection then animConnection:Disconnect() end
        
        for _, conn in ipairs(eventConnections) do
            conn:Disconnect()
        end
        eventConnections = {}
        
        clearHighlights()
        
        local char = getLocalCharacter()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        track:AdjustSpeed(1.0)
                    end
                end
            end
        end
        
        Rayfield:Destroy()
    end,
})
