local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

local isRunning = false
local configFileName = "DungeonFlowConfigV35.json"

local function copyToClipboard(text)
    local success = pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif toboard then
            toboard(text)
        elseif syn and syn.write_clipboard then
            syn.write_clipboard(text)
        end
    end)
    return success
end

-- ==========================================
-- CREATE DUNGEON FLOW BOT UI (V3.5 - Furthest Forward Target)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonFlowGui_V35"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999

local success = pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
end)

if not screenGui.Parent then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 520, 0, 55)
topBar.Position = UDim2.new(0.5, -260, 0.2, 0)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.ZIndex = 10
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 240, 0, 20)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Dungeon Flow Bot [V3.5 - Furthest]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11
titleLabel.Parent = topBar

-- 3-Part Persistent Status Display
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -95, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle | Phase: Init | Mobs: 0"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 11
statusLabel.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 55)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 11
closeButton.Parent = topBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 55)
minimizeButton.Position = UDim2.new(1, -60, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.BorderSizePixel = 0
minimizeButton.ZIndex = 11
minimizeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 420)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 10
mainFrame.Parent = topBar

local function createConfigRow(name, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 130, 0, 25)
    label.Position = UDim2.new(0, 15, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 11
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 90, 0, 25)
    box.Position = UDim2.new(0, 145, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.ZIndex = 11
    box.Parent = mainFrame
    
    return box
end

local mobPrefixBox = createConfigRow("Mob Prefix:", 15, "FX_")
local gateBox = createConfigRow("Gate/Bridge Keyword:", 45, "door")
local radiusBox = createConfigRow("Stud Radius:", 75, "400")
local stopBox = createConfigRow("Stop Distance:", 105, "5")
local speedBox = createConfigRow("Fly Speed:", 135, "44")
local heightBox = createConfigRow("Height Offset:", 165, "4")
local itemBox = createConfigRow("Item Prefix:", 195, "DropAura")

local rightX = 250
local rightWidth = 255

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, rightWidth, 0, 30)
toggleButton.Position = UDim2.new(0, rightX, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.Text = "Start Dungeon Flow"
toggleButton.ZIndex = 11
toggleButton.Parent = mainFrame

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, rightWidth, 0, 30)
scanButton.Position = UDim2.new(0, rightX, 0, 55)
scanButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Font = Enum.Font.SourceSansBold
scanButton.TextSize = 14
scanButton.Text = "Run Full Scan"
scanButton.ZIndex = 11
scanButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 120, 0, 30)
saveButton.Position = UDim2.new(0, rightX, 0, 95)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 14
saveButton.Text = "Save Config"
saveButton.ZIndex = 11
saveButton.Parent = mainFrame

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0, 125, 0, 30)
copyButton.Position = UDim2.new(0, rightX + 130, 0, 95)
copyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.Font = Enum.Font.SourceSansBold
copyButton.TextSize = 14
copyButton.Text = "Copy Log"
copyButton.ZIndex = 11
copyButton.Parent = mainFrame

-- Scrollable Console Log Window
local logScrollingFrame = Instance.new("ScrollingFrame")
logScrollingFrame.Size = UDim2.new(1, -30, 0, 160)
logScrollingFrame.Position = UDim2.new(0, 15, 0, 240)
logScrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
logScrollingFrame.BorderSizePixel = 0
logScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScrollingFrame.ScrollBarThickness = 8
logScrollingFrame.Z
