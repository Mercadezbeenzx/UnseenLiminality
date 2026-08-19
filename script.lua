local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

MainTab:CreateButton({
    Name = "Unload GUI",
    Callback = function()
        if staminaThread then
            task.cancel(staminaThread)
        end
        clearHighlights()
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
