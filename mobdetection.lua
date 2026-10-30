local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local localPlayer = Players.LocalPlayer

local isRunning = false
local autoApproach = false
local autoLootEnabled = true
local mobDebugEnabled = false
local lastMobTarget = nil
local mobApproachStartTime = 0
local configFileName = "RadarApproachTestConfig.json"

-- Spatial Target History (Prevents re-targeting the same mob location)
local recentTargetHistory = {}

-- ESP Visual Tracking Elements
local activeHighlights = {}

-- ==========================================
-- CREATE TEST UI (V5.40 - Auto Loot Toggle)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RadarApproachTestGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 520, 0, 35)
topBar.Position = UDim2.new(0.5, -260, 0.3, 0)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -75, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Radar & Approach [V5.40]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

-- Close Button (X)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 35)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.BorderSizePixel = 0
closeButton.Parent = topBar

-- Minimize Button (-)
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 35)
minimizeButton.Position = UDim2.new(1, -65, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 380) -- Expanded slightly for the new button
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

-- Helper function to create clean configuration rows on the Left Section
local function createConfigRow(name, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 0, 25)
    label.Position = UDim2.new(0, 15, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 90, 0, 25)
    box.Position = UDim2.new(0, 135, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.Parent = mainFrame
    
    return box
end

-- Left Column Inputs
local monsterBox = createConfigRow("Target Name:", 15, "Divecrab")
local radiusBox = createConfigRow("Stud Radius:", 45, "500")
local stopBox = createConfigRow("Stop Distance:", 75, "5")
local speedBox = createConfigRow("Fly Speed:", 105, "44")
local timeoutBox = createConfigRow("Mob Timeout (s):", 135, "1.0")
local heightBox = createConfigRow("Height Offset:", 165, "4")
local itemBox = createConfigRow("Item Prefix:", 195, "DropAura")

-- Right Column Buttons & Status Section
local rightX = 250
local rightWidth = 255

-- Test Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, rightWidth, 0, 30)
toggleButton.Position = UDim2.new(0, rightX, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Radar Test"
toggleButton.Parent = mainFrame

-- Auto Approach Toggle Button
local approachButton = Instance.new("TextButton")
approachButton.Size = UDim2.new(0, rightWidth, 0, 30)
approachButton.Position = UDim2.new(0, rightX, 0, 55)
approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
approachButton.TextColor3 = Color3.fromRGB(255, 255, 255)
approachButton.Font = Enum.Font.SourceSansBold
approachButton.TextSize = 15
approachButton.Text = "Auto Approach: OFF"
approachButton.Parent = mainFrame

-- Auto Loot Toggle Button (New!)
local lootButton = Instance.new("TextButton")
lootButton.Size = UDim2.new(0, rightWidth, 0, 30)
lootButton.Position = UDim2.new(0, rightX, 0, 95)
lootButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
lootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lootButton.Font = Enum.Font.SourceSansBold
lootButton.TextSize = 15
lootButton.Text = "Auto Loot: ON"
lootButton.Parent = mainFrame

-- Mob Debug Toggle Button
local mobDebugButton = Instance.new("TextButton")
mobDebugButton.Size = UDim2.new(0, rightWidth, 0, 30)
mobDebugButton.Position = UDim2.new(0, rightX, 0, 135)
mobDebugButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
mobDebugButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mobDebugButton.Font = Enum.Font.SourceSansBold
mobDebugButton.TextSize = 15
mobDebugButton.Text = "Mob Debug: OFF"
mobDebugButton.Parent = mainFrame

-- Save Button
local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, rightWidth, 0, 30)
saveButton.Position = UDim2.new(0, rightX, 0, 175)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 15
saveButton.Text = "Save Settings"
saveButton.Parent = mainFrame

-- Live Status Readout
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, rightWidth, 0, 85)
statusLabel.Position = UDim2.new(0, rightX, 0, 215)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle\nDetected: None"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = mainFrame

-- ==========================================
-- FILE SAVING & LOADING LOGIC
-- ==========================================
local function saveSettings()
    local data = {
        TargetPrefix = monsterBox.Text,
        StudRadius = radiusBox.Text,
        StopDistance = stopBox.Text,
        FlySpeed = speedBox.Text,
        MobTimeout = timeoutBox.Text,
        HeightOffset = heightBox.Text,
        ItemPrefix = itemBox.Text
    }
    
    pcall(function()
        if writefile then
            local jsonData = HttpService:JSONEncode(data)
            writefile(configFileName, jsonData)
        end
    end)
    
    saveButton.Text = "Saved!"
    task.wait(1)
    saveButton.Text = "Save Settings"
end

local function loadSettings()
    pcall(function()
        if isfile and isfile(configFileName) then
            local jsonData = readfile(configFileName)
            local success, data = pcall(function()
                return HttpService:JSONDecode(jsonData)
            end)
            
            if success and data then
                if data.TargetPrefix then monsterBox.Text = tostring(data.TargetPrefix) end
                if data.StudRadius then radiusBox.Text = tostring(data.StudRadius) end
                if data.StopDistance then stopBox.Text = tostring(data.StopDistance) end
                if data.FlySpeed then speedBox.Text = tostring(data.FlySpeed) end
                if data.MobTimeout then timeoutBox.Text = tostring(data.MobTimeout) end
                if data.HeightOffset then heightBox.Text = tostring(data.HeightOffset) end
                if data.ItemPrefix then itemBox.Text = tostring(data.ItemPrefix) end
            end
        end
    end)
end

loadSettings()
saveButton.MouseButton1Click:Connect(saveSettings)

-- ==========================================
-- ESP HIGHLIGHT CLEANUP UTILITY
-- ==========================================
local function clearHighlights()
    for _, item in pairs(activeHighlights) do
        if item and item.Parent then
            item:Destroy()
        end
    end
    activeHighlights = {}
end

local function setHighlight(targetObj, color)
    clearHighlights()
    if targetObj and targetObj.Parent then
        local model = targetObj.Parent
        if not model:IsA("Model") then
            model = targetObj
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.4
        highlight.Parent = screenGui
        table.insert(activeHighlights, highlight)
    end
end

-- ==========================================
-- UI CONTROLS
-- ==========================================
local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    mainFrame.Visible = not minimized
    minimizeButton.Text = minimized and "+" or "-"
end)

closeButton.MouseButton1Click:Connect(function()
    isRunning = false
    autoApproach = false
    autoLootEnabled = true
    mobDebugEnabled = false
    lastMobTarget = nil
    recentTargetHistory = {}
    clearHighlights()
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if rootPart then
        rootPart.Anchored = false
    end
    screenGui:Destroy()
end)

toggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleButton.Text = "Stop Test"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        toggleButton.Text = "Start Radar Test"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        autoApproach = false
        lastMobTarget = nil
        recentTargetHistory = {}
        clearHighlights()
        approachButton.Text = "Auto Approach: OFF"
        approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        statusLabel.Text = "Status: Idle\nDetected: None"
    end
end)

approachButton.MouseButton1Click:Connect(function()
    if not isRunning then return end
    autoApproach = not autoApproach
    if autoApproach then
        approachButton.Text = "Auto Approach: ON"
        approachButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        lastMobTarget
