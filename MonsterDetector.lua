local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Direct path verification to workspace.Animal_Live.Aggressors
local animalLive = workspace:WaitForChild("Animal_Live", 30)
local aggressorsFolder = animalLive:WaitForChild("Aggressors", 30)

if not aggressorsFolder then
	warn("CRITICAL: workspace.Animal_Live.Aggressors could not be found!")
end

-- ================= CONFIGURABLE SETTINGS (WITH PERSISTENCE) =================
local CONFIG = {
	FlightSpeed = 12,
	DetectionRadius = 100,
	StopDistance = 3,
	GateTimeout = 15,
	BossRoomNumber = 19
}

pcall(function()
	if _G.DungeonSettings then
		CONFIG.FlightSpeed = _G.DungeonSettings.FlightSpeed or CONFIG.FlightSpeed
		CONFIG.DetectionRadius = _G.DungeonSettings.DetectionRadius or CONFIG.DetectionRadius
		CONFIG.StopDistance = _G.DungeonSettings.StopDistance or CONFIG.StopDistance
		CONFIG.GateTimeout = _G.DungeonSettings.GateTimeout or CONFIG.GateTimeout
		CONFIG.BossRoomNumber = _G.DungeonSettings.BossRoomNumber or CONFIG.BossRoomNumber
	end
end)

local function saveSettings()
	_G.DungeonSettings = {
		FlightSpeed = CONFIG.FlightSpeed,
		DetectionRadius = CONFIG.DetectionRadius,
		StopDistance = CONFIG.StopDistance,
		GateTimeout = CONFIG.GateTimeout,
		BossRoomNumber = CONFIG.BossRoomNumber
	}
end
-- ============================================================================

-- Strict Animal property fetcher for clean display names
local function getAnimalName(monster)
	local animalProp = monster:GetAttribute("Animal")
	if not animalProp then
		local animalVal = monster:FindFirstChild("Animal")
		if animalVal and animalVal:IsA("StringValue") then
			animalProp = animalVal.Value
		end
	end
	return animalProp or monster.Name
end

-- Waypoint and Room tracking variables
local waypoints = {}
local importedWaypointsCount = 0
local currentWaypointIndex = 1
local isLoopingWaypoints = false
local isTrackingAll = false
local isAutoRestartEnabled = false
local roomClearedConfirmed = true
local gateTimer = 0
local lastRestartAttempt = 0

-- Function to check if the gate unseal message is active on screen
local function checkGateUnsealed()
	for _, gui in ipairs(playerGui:GetDescendants()) do
		if gui:IsA("TextLabel") or gui:IsA("TextButton") then
			local text = gui.Text:lower()
			if string.find(text, "room cleared") or string.find(text, "gate unseals") then
				return true
			end
		end
	end
	return false
end

-- Function to check for "Dungeon Cleared" popup and auto-click "Run again"
local function checkAndRestartDungeon()
	if not isAutoRestartEnabled or (tick() - lastRestartAttempt < 3) then return end
	if currentWaypointIndex < CONFIG.BossRoomNumber and #waypoints > 0 then return end
	
	for _, gui in ipairs(playerGui:GetDescendants()) do
		if gui:IsA("TextButton") or gui:IsA("TextLabel") then
			local text = gui.Text:lower()
			if string.find(text, "dungeon cleared") then
				for _, btn in ipairs(playerGui:GetDescendants()) do
					if btn:IsA("TextButton") and string.find(btn.Text:lower(), "run again") then
						lastRestartAttempt = tick()
						currentWaypointIndex = 1
						roomClearedConfirmed = true
						
						local absPos = btn.AbsolutePosition
						local absSize = btn.AbsoluteSize
						VirtualInputManager:SendMouseButtonEvent(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2, 0, true, game, 1)
						task.wait(0.05)
						VirtualInputManager:SendMouseButtonEvent(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2, 0, false, game, 1)
						print("Auto Dungeon Restarted via 'Run again' button!")
						return
					end
				end
			end
		end
	end
end

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDungeonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Compact Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 540)
mainFrame.Position = UDim2.new(0, 30, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title Label / Drag Handler
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -65, 0, 32)
titleLabel.Position = UDim2.new(0, 8, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Dungeon v2.8.10"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

-- Draggable Window Logic
local dragging, dragInput, dragStart, startPos
titleLabel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleLabel.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Close (X) Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 26, 0, 26)
closeButton.Position = UDim2.new(1, -30, 0, 3)
closeButton.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 12
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Minimize (-) Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 26, 0, 26)
minimizeButton.Position = UDim2.new(1, -60, 0, 3)
minimizeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 14
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minimizeButton

-- Compact Status Dashboard
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -16, 0, 90)
statusFrame.Position = UDim2.new(0, 8, 0, 35)
statusFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = statusFrame

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -8, 0, 18)
targetLabel.Position = UDim2.new(0, 4, 0, 4)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target: None"
targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
targetLabel.TextSize = 11
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = statusFrame

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -8, 0, 18)
countLabel.Position = UDim2.new(0, 4, 0, 24)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Mobs Detected: 0"
countLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
countLabel.TextSize = 11
countLabel.Font = Enum.Font.SourceSansBold
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = statusFrame

local wpSavedLabel = Instance.new("TextLabel")
wpSavedLabel.Size = UDim2.new(1, -8, 0, 18)
wpSavedLabel.Position = UDim2.new(0, 4, 0, 44)
wpSavedLabel.BackgroundTransparency = 1
wpSavedLabel.Text = "Rooms Saved: 0"
wpSavedLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
wpSavedLabel.TextSize = 11
wpSavedLabel.Font = Enum.Font.SourceSansBold
wpSavedLabel.TextXAlignment = Enum.TextXAlignment.Left
wpSavedLabel.Parent = statusFrame

local wpImportedLabel = Instance.new("TextLabel")
wpImportedLabel.Size = UDim2.new(1, -8, 0, 18)
wpImportedLabel.Position = UDim2.new(0, 4, 0, 64)
wpImportedLabel.BackgroundTransparency = 1
wpImportedLabel.Text = "Imported WPs: 0"
wpImportedLabel.TextColor3 = Color3.fromRGB(220, 150, 255)
wpImportedLabel.TextSize = 11
wpImportedLabel.Font = Enum.Font.SourceSansBold
wpImportedLabel.TextXAlignment = Enum.TextXAlignment.Left
wpImportedLabel.Parent = statusFrame

-- Main Fly to All Mobs Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -16, 0, 28)
toggleButton.Position = UDim2.new(0, 8, 0, 132)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleButton.Text = "Fly to All Mobs: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 12
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 5)
btnCorner.Parent = toggleButton

-- Dungeon Room Controls Row
local saveWpBtn = Instance.new("TextButton")
saveWpBtn.Size = UDim2.new(0, 52, 0, 26)
saveWpBtn.Position = UDim2.new(0, 8, 0, 168)
saveWpBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
saveWpBtn.Text = "Save"
saveWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveWpBtn.TextSize = 11
saveWpBtn.Font = Enum.Font.SourceSansBold
saveWpBtn.Parent = mainFrame

local swpCorner = Instance.new("UICorner")
swpCorner.CornerRadius = UDim.new(0, 4)
swpCorner.Parent = saveWpBtn

local clearWpBtn = Instance.new("TextButton")
clearWpBtn.Size = UDim2.new(0, 52, 0, 26)
clearWpBtn.Position = UDim2.new(0, 64, 0, 168)
clearWpBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
clearWpBtn.Text = "Clear"
clearWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearWpBtn.TextSize = 11
clearWpBtn.Font = Enum.Font.SourceSansBold
clearWpBtn.Parent = mainFrame

local cwpCorner = Instance.new("UICorner")
cwpCorner.CornerRadius = UDim.new(0, 4)
cwpCorner.Parent = clearWpBtn

local skipWpBtn = Instance.new("TextButton")
skipWpBtn.Size = UDim2.new(0, 52, 0, 26)
skipWpBtn.Position = UDim2.new(0, 120, 0, 168)
skipWpBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
skipWpBtn.Text = "Skip WP"
skipWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
skipWpBtn.TextSize = 11
skipWpBtn.Font = Enum.Font.SourceSansBold
skipWpBtn.Parent = mainFrame

local skpCorner = Instance.new("
