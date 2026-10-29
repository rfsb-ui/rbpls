local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer

local repeatWaitTime = 10 
local stopDistance = 15
local isRunning = false
local configFileName = "AutoDungeonSmartConfig.json"

-- ==========================================
-- 1. CREATE THE UI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonAutoGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 260, 0, 30)
topBar.Position = UDim2.new(0.5, -130, 0.5, -100)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Smart Dungeon Auto"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.BorderSizePixel = 0
closeButton.Parent = topBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -60, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 180)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

local flyLabel = Instance.new("TextLabel")
flyLabel.Size = UDim2.new(0, 140, 0, 30)
flyLabel.Position = UDim2.new(0, 10, 0, 10)
flyLabel.BackgroundTransparency = 1
flyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flyLabel.Text = "Fly Time (secs):"
flyLabel.Font = Enum.Font.SourceSansBold
flyLabel.TextSize = 16
flyLabel.Parent = mainFrame

local flyTimeBox = Instance.new("TextBox")
flyTimeBox.Size = UDim2.new(0, 90, 0, 30)
flyTimeBox.Position = UDim2.new(0, 150, 0, 10)
flyTimeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flyTimeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
flyTimeBox.Text = "1.5"
flyTimeBox.Font = Enum.Font.SourceSans
flyTimeBox.TextSize = 16
flyTimeBox.Parent = mainFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 140, 0, 30)
speedLabel.Position = UDim2.new(0, 10, 0, 45)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Text = "Fly Speed:"
speedLabel.Font = Enum.Font.SourceSansBold
speedLabel.TextSize = 16
speedLabel.Parent = mainFrame

local flySpeedBox = Instance.new("TextBox")
flySpeedBox.Size = UDim2.new(0, 90, 0, 30)
flySpeedBox.Position = UDim2.new(0, 150, 0, 45)
flySpeedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flySpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedBox.Text = "44"
flySpeedBox.Font = Enum.Font.SourceSans
flySpeedBox.TextSize = 16
flySpeedBox.Parent = mainFrame

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 140, 0, 30)
targetLabel.Position = UDim2.new(0, 10, 0, 80)
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetLabel.Text = "Target Mobs:"
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextSize = 16
targetLabel.Parent = mainFrame

local monsterBox = Instance.new("TextBox")
monsterBox.Size = UDim2.new(0, 90, 0, 30)
monsterBox.Position = UDim2.new(0, 150, 0, 80)
monsterBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
monsterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
monsterBox.Text = ""
monsterBox.PlaceholderText = "Goblin, Orc"
monsterBox.Font = Enum.Font.SourceSans
monsterBox.TextSize = 14
monsterBox.ClipsDescendants = true
monsterBox.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 160, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 120)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Text = "Start Auto"
toggleButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 70, 0, 40)
saveButton.Position = UDim2.new(0, 180, 0, 120)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 16
saveButton.Text = "Save"
saveButton.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 1, -20)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Text = "Status: Idle"
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 15
status
