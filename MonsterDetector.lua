local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Direct path verification to workspace.Animal_Live.Aggressors
local animalLive = workspace:WaitForChild("Animal_Live", 30)
local aggressorsFolder = animalLive:WaitForChild("Aggressors", 30)

if not aggressorsFolder then
	warn("CRITICAL: workspace.Animal_Live.Aggressors could not be found!")
end

-- ================= FILE-BASED CONFIG & TARGET SYSTEM =================
local CONFIG_FOLDER = "AutoDungeonConfigs"
local CONFIG_FILE = CONFIG_FOLDER .. "/dungeon_config.json"

local CONFIG = {
	FlightSpeed = 50,
	DetectionRadius = 500,
	StopDistance = 4,
	GateTimeout = 15,
	BossRoomNumber = 19,
	NoclipOffset = 8,
	MobArrivalDelay = 1,
	PotThreshold = 40,
	BossDelay = 10,
	TargetPosX = 0,
	TargetPosY = 0,
	UseDefaultPos = true,
	AtkPosX = 0,
	AtkPosY = 0,
	AtkUseDefaultPos = true
}

local waypoints = {}
local runsCounter = 0

local function saveToDevice()
	pcall(function()
		if not isfolder(CONFIG_FOLDER) then
			makefolder(CONFIG_FOLDER)
		end
		
		local dataToSave = {
			Settings = CONFIG,
			Waypoints = {}
		}
		
		for _, pos in ipairs(waypoints) do
			table.insert(dataToSave.Waypoints, {X = pos.X, Y = pos.Y, Z = pos.Z})
		end
		
		writefile(CONFIG_FILE, HttpService:JSONEncode(dataToSave))
	end)
end

local function loadFromDevice()
	pcall(function()
		if isfile(CONFIG_FILE) then
			local content = readfile(CONFIG_FILE)
			local decoded = HttpService:JSONDecode(content)
			
			if decoded and decoded.Settings then
				for k, v in pairs(decoded.Settings) do
					if CONFIG[k] ~= nil then
						CONFIG[k] = v
					end
				end
			end
			
			if decoded and decoded.Waypoints then
				waypoints = {}
				for _, wp in ipairs(decoded.Waypoints) do
					table.insert(waypoints, Vector3.new(wp.X, wp.Y, wp.Z))
				end
			end
		end
	end)
end

loadFromDevice()
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
local currentWaypointIndex = 1
local isLoopingWaypoints = false
local isTrackingAll = false
local isAutoRestartEnabled = false
local isNoClipEnabled = false
local isAatEnabled = false
local isAutoPotEnabled = false
local roomClearedConfirmed = true
local gateTimer = 0
local lastPotionTime = 0
local lastAtkClickTime = 0

local bossWasPresent = false
local bossDefeatedTimer = 0
local postRestartCooldown = 0
local preClickCountdownTimer = 0
local mobArrivalTimer = 0
local lastTargetMonsterId = nil

-- Throttle variables for heavy UI scanning
local lastGuiThrottle = 0
local cachedGateUnsealed = false

-- Function to completely reset state back to Room 1
local function resetToRoomOne()
	currentWaypointIndex = 1
	roomClearedConfirmed = true
	bossWasPresent = false
	bossDefeatedTimer = 0
	preClickCountdownTimer = 0
	postRestartCooldown = tick()
	runsCounter += 1
	print("Dungeon state fully reset to Room 1. Total Runs:", runsCounter)
end

-- Throttled function to check if the gate unseal message is active on screen
local function checkGateUnsealedThrottled()
	if tick() - lastGuiThrottle < 0.5 then
		return cachedGateUnsealed
	end
	
	lastGuiThrottle = tick()
	cachedGateUnsealed = false
	
	for _, gui in ipairs(playerGui:GetDescendants()) do
		if gui:IsA("TextLabel") or gui:IsA("TextButton") then
			local text = gui.Text:lower()
			if string.find(text, "room cleared") or string.find(text, "gate unseals") then
				cachedGateUnsealed = true
				break
			end
		end
	end
	
	return cachedGateUnsealed
end

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDungeonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ================= COMPACT DRAGGABLE CLICK TARGET BOX ("Run again") =================
local clickTargetFrame = Instance.new("Frame")
clickTargetFrame.Size = UDim2.new(0, 48, 0, 15)

if CONFIG.UseDefaultPos then
	clickTargetFrame.Position = UDim2.new(0.5, -24, 0.5, -7)
else
	clickTargetFrame.Position = UDim2.new(0, CONFIG.TargetPosX, 0, CONFIG.TargetPosY)
end

clickTargetFrame.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
clickTargetFrame.BackgroundTransparency = 0.4
clickTargetFrame.BorderSizePixel = 1
clickTargetFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
clickTargetFrame.Active = true
clickTargetFrame.Parent = screenGui

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 4)
targetCorner.Parent = clickTargetFrame

local targetText = Instance.new("TextLabel")
targetText.Size = UDim2.new(1, 0, 1, 0)
targetText.BackgroundTransparency = 1
targetText.Text = "Run again"
targetText.TextColor3 = Color3.fromRGB(255, 255, 255)
targetText.TextSize = 8
targetText.Font = Enum.Font.SourceSansBold
targetText.Parent = clickTargetFrame

-- Drag logic for Run again target box
local targetDragging, targetDragInput, targetDragStart, targetStartPos
clickTargetFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		targetDragging = true
		targetDragStart = input.Position
		targetStartPos = clickTargetFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				targetDragging = false
				CONFIG.TargetPosX = clickTargetFrame.AbsolutePosition.X
				CONFIG.TargetPosY = clickTargetFrame.AbsolutePosition.Y
				CONFIG.UseDefaultPos = false
				saveToDevice()
			end
		end)
	end
end)

clickTargetFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		targetDragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == targetDragInput and targetDragging then
		local delta = input.Position - targetDragStart
		clickTargetFrame.Position = UDim2.new(targetStartPos.X.Scale, targetStartPos.X.Offset + delta.X, targetStartPos.Y.Scale, targetStartPos.Y.Offset + delta.Y)
	end
end)


-- ================= COMPACT DRAGGABLE ATK TARGET BOX ("ATK") =================
local atkTargetFrame = Instance.new("Frame")
atkTargetFrame.Size = UDim2.new(0, 48, 0, 15)

if CONFIG.AtkUseDefaultPos then
	atkTargetFrame.Position = UDim2.new(0.5, -24, 0.5, 15)
else
	atkTargetFrame.Position = UDim2.new(0, CONFIG.AtkPosX, 0, CONFIG.AtkPosY)
end

atkTargetFrame.BackgroundColor3 = Color3.fromRGB(50, 150, 220)
atkTargetFrame.BackgroundTransparency = 0.4
atkTargetFrame.BorderSizePixel = 1
atkTargetFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
atkTargetFrame.Active = true
atkTargetFrame.Parent = screenGui

local atkCorner = Instance.new("UICorner")
atkCorner.CornerRadius = UDim.new(0, 4)
atkCorner.Parent = atkTargetFrame

local atkText = Instance.new("TextLabel")
atkText.Size = UDim2.new(1, 0, 1, 0)
atkText.BackgroundTransparency = 1
atkText.Text = "ATK"
atkText.TextColor3 = Color3.fromRGB(255, 255, 255)
atkText.TextSize = 8
atkText.Font = Enum.Font.SourceSansBold
atkText.Parent = atkTargetFrame

-- Drag logic for ATK target box with auto-save persistence
local atkDragging, atkDragInput, atkDragStart, atkStartPos
atkTargetFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		atkDragging = true
		atkDragStart = input.Position
		atkStartPos = atkTargetFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				atkDragging = false
				CONFIG.AtkPosX = atkTargetFrame.AbsolutePosition.X
				CONFIG.AtkPosY = atkTargetFrame.AbsolutePosition.Y
				CONFIG.AtkUseDefaultPos = false
				saveToDevice()
			end
		end)
	end
end)

atkTargetFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		atkDragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == atkDragInput and atkDragging then
		local delta = input.Position - atkDragStart
		atkTargetFrame.Position = UDim2.new(atkStartPos.X.Scale, atkStartPos.X.Offset + delta.X, atkStartPos.Y.Scale, atkStartPos.Y.Offset + delta.Y)
	end
end)
-- ============================================================================

-- Precision Multi-Clicker (Fires 3 clicks in quick succession)
local function triggerRunAgainButton()
	local absPos = clickTargetFrame.AbsolutePosition
	local absSize = clickTargetFrame.AbsoluteSize
	local centerX = absPos.X + absSize.X / 2
	local centerY = absPos.Y + absSize.Y / 2
	
	task.spawn(function()
		for i = 1, 3 do
			VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
			task.wait(0.03)
			VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
			task.wait(0.03)
		end
		print("Fired 3 rapid clicks on 'Run again' via Target Box at coordinates:", centerX, centerY)
	end)
	
	resetToRoomOne()
end

-- Main Compact Panel (Boots up Maximized)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 510)
mainFrame.Position = UDim2.new(0, 30, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.3
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
titleLabel.Text = "RF Auto-all v2.8.56"
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
closeButton.BackgroundTransparency = 0.3
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
minimizeButton.BackgroundTransparency = 0.3
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
statusFrame.Size = UDim2.new(1, -16, 0, 58)
statusFrame.Position = UDim2.new(0, 8, 0, 35)
statusFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
statusFrame.BackgroundTransparency = 0.3
statusFrame.BorderSizePixel = 0
statusFrame.Visible = true
statusFrame.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = statusFrame

-- Column 1 Labels (Left side)
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.33, -2, 0, 14)
targetLabel.Position = UDim2.new(0, 3, 0, 3)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target: None"
targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
targetLabel.TextSize = 9
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = statusFrame

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(0.33, -2, 0, 14)
countLabel.Position = UDim2.new(0, 3, 0, 18)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Mobs: 0"
countLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
countLabel.TextSize = 9
countLabel.Font = Enum.Font.SourceSansBold
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = statusFrame

-- Column 2 Labels (Middle)
local runsLabel = Instance.new("TextLabel")
runsLabel.Size = UDim2.new(0.33, -2, 0, 14)
runsLabel.Position = UDim2.new(0.33, 1, 0, 3)
runsLabel.BackgroundTransparency = 1
runsLabel.Text = "Runs: 0"
runsLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
runsLabel.TextSize = 9
runsLabel.Font = Enum.Font.SourceSansBold
runsLabel.TextXAlignment = Enum.TextXAlignment.Left
runsLabel.Parent = statusFrame

local wpSavedLabel = Instance.new("TextLabel")
wpSavedLabel.Size = UDim2.new(0.33, -2, 0, 14)
wpSavedLabel.Position = UDim2.new(0.33, 1, 0, 18)
wpSavedLabel.BackgroundTransparency = 1
wpSavedLabel.Text = "Rooms: 0"
wpSavedLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
wpSavedLabel.TextSize = 9
wpSavedLabel.Font = Enum.Font.SourceSansBold
wpSavedLabel.TextXAlignment = Enum.TextXAlignment.Left
wpSavedLabel.Parent = statusFrame

-- Column 3 Top: FTM (Fly to All Mobs) Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.33, -4, 0, 13)
toggleButton.Position = UDim2.new(0.66, 1, 0, 2)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleButton.BackgroundTransparency = 0.3
toggleButton.Text = "FTM ▶ [OFF]"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 7
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = statusFrame

local tBtnCorner = Instance.new("UICorner")
tBtnCorner.CornerRadius = UDim.new(0, 3)
tBtnCorner.Parent = toggleButton

-- Column 3 Middle: RWP (Run Waypoint) Toggle Button
local loopWpBtn = Instance.new("TextButton")
loopWpBtn.Size = UDim2.new(0.33, -4, 0, 13)
loopWpBtn.Position = UDim2.new(0.66, 1, 0, 16)
loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
loopWpBtn.BackgroundTransparency = 0.3
loopWpBtn.Text = "RWP ▶ [OFF]"
loopWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopWpBtn.TextSize = 7
loopWpBtn.Font = Enum.Font.SourceSansBold
loopWpBtn.Parent = statusFrame

local lwpCorner = Instance.new("UICorner")
lwpCorner.CornerRadius = UDim.new(0, 3)
lwpCorner.Parent = loopWpBtn

-- Column 3 Bottom: AAT (ATK Target Box Clicker) Toggle Button
local aatToggleBtn = Instance.new("TextButton")
aatToggleBtn.Size = UDim2.new(0.33, -4, 0, 13)
aatToggleBtn.Position = UDim2.new(0.66, 1, 0, 30)
aatToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
aatToggleBtn.BackgroundTransparency = 0.3
aatToggleBtn.Text = "AAT ▶ [OFF]"
aatToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aatToggleBtn.TextSize = 7
aatToggleBtn.Font = Enum.Font.SourceSansBold
aatToggleBtn.Parent = statusFrame

local aatCorner = Instance.new("UICorner")
aatCorner.CornerRadius = UDim.new(0, 3)
aatCorner.Parent = aatToggleBtn

-- Status Bottom Sub-label
local statusSubLabel = Instance.new("TextLabel")
statusSubLabel.Size = UDim2.new(1, -6, 0, 12)
statusSubLabel.Position = UDim2.new(0, 3, 0, 44)
statusSubLabel.BackgroundTransparency = 1
statusSubLabel.Text = "Status: Ready"
statusSubLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusSubLabel.TextSize = 8
statusSubLabel.Font = Enum.Font.SourceSans
statusSubLabel.TextXAlignment = Enum.TextXAlignment.Left
statusSubLabel.Parent = statusFrame

-- No-Clip Toggle Button
local noclipToggleBtn = Instance.new("TextButton")
noclipToggleBtn.Size = UDim2.new(1, -16, 0, 26)
noclipToggleBtn.Position = UDim2.new(0, 8, 0, 98)
noclipToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
noclipToggleBtn.BackgroundTransparency = 0.3
noclipToggleBtn.Text = "No-Clip: OFF"
noclipToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipToggleBtn.TextSize = 11
noclipToggleBtn.Font = Enum.Font.SourceSansBold
noclipToggleBtn.Visible = true
noclipToggleBtn.Parent = mainFrame

local nclCorner = Instance.new("UICorner")
nclCorner.CornerRadius = UDim.new(0, 4)
nclCorner.Parent = noclipToggleBtn

-- Dungeon Room Controls Row
local saveWpBtn = Instance.new("TextButton")
saveWpBtn.Size = UDim2.new(0, 54, 0, 26)
saveWpBtn.Position = UDim2.new(0, 8, 0, 130)
saveWpBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
saveWpBtn.BackgroundTransparency = 0.3
saveWpBtn.Text = "Save"
saveWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveWpBtn.TextSize = 10
saveWpBtn.Font = Enum.Font.SourceSansBold
saveWpBtn.Visible = true
saveWpBtn.Parent = mainFrame

local swpCorner = Instance.new("UICorner")
swpCorner.CornerRadius = UDim.new(0, 4)
swpCorner.Parent = saveWpBtn

local clearWpBtn = Instance.new("TextButton")
clearWpBtn.Size = UDim2.new(0, 54, 0, 26)
clearWpBtn.Position = UDim2.new(0, 66, 0, 130)
clearWpBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
clearWpBtn.BackgroundTransparency = 0.3
clearWpBtn.Text = "Clear"
clearWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearWpBtn.TextSize = 10
clearWpBtn.Font = Enum.Font.SourceSansBold
clearWpBtn.Visible = true
clearWpBtn.Parent = mainFrame

local cwpCorner = Instance.new("UICorner")
cwpCorner.CornerRadius = UDim.new(0, 4)
cwpCorner.Parent = clearWpBtn

local skipWpBtn = Instance.new("TextButton")
skipWpBtn.Size = UDim2.new(0, 50, 0, 26)
skipWpBtn.Position = UDim2.new(0, 124, 0, 130)
skipWpBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
skipWpBtn.BackgroundTransparency = 0.3
skipWpBtn.Text = "Skip WP"
skipWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
skipWpBtn.TextSize = 9
skipWpBtn.Font = Enum.Font.SourceSansBold
skipWpBtn.Visible = true
skipWpBtn.Parent = mainFrame

local skpCorner = Instance.new("UICorner")
skpCorner.CornerRadius = UDim.new(0, 4)
skpCorner.Parent = skipWpBtn

-- Auto Pot Toggle Button
local autoPotBtn = Instance.new("TextButton")
autoPotBtn.Size = UDim2.new(0, 48, 0, 26)
autoPotBtn.Position = UDim2.new(0, 178, 0, 130)
autoPotBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
autoPotBtn.BackgroundTransparency = 0.3
autoPotBtn.Text = "Auto Pot"
autoPotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoPotBtn.TextSize = 9
autoPotBtn.Font = Enum.Font.SourceSansBold
autoPotBtn.Visible = true
autoPotBtn.Parent = mainFrame

local aptCorner = Instance.new("UICorner")
aptCorner.CornerRadius = UDim.new(0, 4)
aptCorner.Parent = autoPotBtn

-- Auto Restart Toggle Button
local restartToggleBtn = Instance.new("TextButton")
restartToggleBtn.Size = UDim2.new(1, -16, 0, 26)
restartToggleBtn.Position = UDim2.new(0, 8, 0, 164)
restartToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
restartToggleBtn.BackgroundTransparency = 0.3
restartToggleBtn.Text = "Auto Restart: OFF"
restartToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
restartToggleBtn.TextSize = 11
restartToggleBtn.Font = Enum.Font.SourceSansBold
restartToggleBtn.Visible = true
restartToggleBtn.Parent = mainFrame

local rstCorner = Instance.new("UICorner")
rstCorner.CornerRadius = UDim.new(0, 4)
rstCorner.Parent = restartToggleBtn

-- Waypoint Import Box
local importBox = Instance.new("TextBox")
importBox.Size = UDim2.new(1, -16, 0, 26)
importBox.Position = UDim2.new(0, 8, 0, 198)
importBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
importBox.BackgroundTransparency = 0.3
importBox.PlaceholderText = "Paste Waypoints/Coordinates..."
importBox.Text = ""
importBox.TextColor3 = Color3.fromRGB(255, 255, 255)
importBox.TextSize = 11
importBox.Font = Enum.Font.SourceSans
importBox.Visible = true
importBox.Parent = mainFrame

local impCorner = Instance.new("UICorner")
impCorner.CornerRadius = UDim.new(0, 4)
impCorner.Parent = importBox

-- Export Rooms Button
local exportWpBtn = Instance.new("TextButton")
exportWpBtn.Size = UDim2.new(1, -16, 0, 26)
exportWpBtn.Position = UDim2.new(0, 8, 0, 230)
exportWpBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 100)
exportWpBtn.BackgroundTransparency = 0.3
exportWpBtn.Text = "Export Rooms"
exportWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exportWpBtn.TextSize = 11
exportWpBtn.Font = Enum.Font.SourceSansBold
exportWpBtn.Visible = true
exportWpBtn.Parent = mainFrame

local expCorner = Instance.new("UICorner")
expCorner.CornerRadius = UDim.new(0, 4)
expCorner.Parent = exportWpBtn

-- Configurable Inputs
local configurableElements = {}

local function createLabeledInput(posX, posY, width, labelText, defaultVal, callback)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, width, 0, 15)
	lbl.Position = UDim2.new(0, posX, 0, posY)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
	lbl.TextSize = 8
	lbl.Font = Enum.Font.SourceSansBold
	lbl.Visible = true
	lbl.Parent = mainFrame
	table.insert(configurableElements, lbl)
	
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, width, 0, 24)
	box.Position = UDim2.new(0, posX, 0, posY + 15)
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	box.BackgroundTransparency = 0.3
	box.Text = tostring(defaultVal)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 9
	box.Font = Enum.Font.SourceSans
	box.Visible = true
	box.Parent = mainFrame
	table.insert(configurableElements, box)
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = box
	
	box.FocusLost:Connect(function()
		local val = tonumber(box.Text)
		if val then
			callback(val)
			saveToDevice()
		else
			box.Text = tostring(defaultVal)
		end
	end)
	
	return box
end

createLabeledInput(6, 264, 25, "Speed", CONFIG.FlightSpeed, function(v) CONFIG.FlightSpeed = v end)
createLabeledInput(33, 264, 25, "Radius", CONFIG.DetectionRadius, function(v) CONFIG.DetectionRadius = v end)
createLabeledInput(60, 264, 25, "Stop", CONFIG.StopDistance, function(v) CONFIG.StopDistance = v end)
createLabeledInput(87, 264, 25, "GateSec", CONFIG.GateTimeout, function(v) CONFIG.GateTimeout = v end)
createLabeledInput(114, 264, 25, "Boss#", CONFIG.BossRoomNumber, function(v) CONFIG.BossRoomNumber = v end)
createLabeledInput(141, 264, 27, "Offset", CONFIG.NoclipOffset, function(v) CONFIG.NoclipOffset = v end)
createLabeledInput(170, 264, 30, "PotHP%", CONFIG.PotThreshold, function(v) CONFIG.PotThreshold = v end)
createLabeledInput(202, 264, 32, "BossSec", CONFIG.BossDelay, function(v) CONFIG.BossDelay = v end)

-- Scrollable Room List Viewer below UI (70% Opacity)
local roomListFrame = Instance.new("ScrollingFrame")
roomListFrame.Size = UDim2.new(1, -16, 0, 195)
roomListFrame.Position = UDim2.new(0, 8, 0, 306)
roomListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
roomListFrame.BackgroundTransparency = 0.3
roomListFrame.BorderSizePixel = 0
roomListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
roomListFrame.ScrollBarThickness = 5
roomListFrame.Visible = true
roomListFrame.Parent = mainFrame
table.insert(configurableElements, roomListFrame)

local roomListLayout = Instance.new("UIListLayout")
roomListLayout.Parent = roomListFrame
roomListLayout.SortOrder = Enum.SortOrder.LayoutOrder
roomListLayout.Padding = UDim.new(0, 3)

local function updateRoomListDisplay()
	for _, child in ipairs(roomListFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	
	for i, pos in ipairs(waypoints) do
		local item = Instance.new("TextLabel")
		item.Size = UDim2.new(1, -6, 0, 22)
		item.BackgroundColor3 = (i == CONFIG.BossRoomNumber) and Color3.fromRGB(100, 50, 50) or Color3.fromRGB(50, 50, 50)
		item.BackgroundTransparency = 0.3
		item.Text = string.format("Room %d%s: (%.1f, %.1f, %.1f)", i, (i == CONFIG.BossRoomNumber and " [BOSS]" or ""), pos.X, pos.Y, pos.Z)
		item.TextColor3 = Color3.fromRGB(220, 220, 220)
		item.TextSize = 10
		item.Font = Enum.Font.SourceSans
		item.Parent = roomListFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = item
	end
	
	roomListFrame.CanvasSize = UDim2.new(0, 0, 0, #waypoints * 25)
end

updateRoomListDisplay()

-- State variables (Starts maximized)
local isMinimized = false

minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 240, 0, 95)
		statusFrame.Visible = true
		noclipToggleBtn.Visible = false
		saveWpBtn.Visible = false
		clearWpBtn.Visible = false
		skipWpBtn.Visible = false
		autoPotBtn.Visible = false
		restartToggleBtn.Visible = false
		importBox.Visible = false
		exportWpBtn.Visible = false
		for _, el in ipairs(configurableElements) do
			el.Visible = false
		end
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 240, 0, 510)
		statusFrame.Visible = true
		noclipToggleBtn.Visible = true
		saveWpBtn.Visible = true
		clearWpBtn.Visible = true
		skipWpBtn.Visible = true
		autoPotBtn.Visible = true
		restartToggleBtn.Visible = true
		importBox.Visible = true
		exportWpBtn.Visible = true
		for _, el in ipairs(configurableElements) do
			el.Visible = true
		end
		minimizeButton.Text = "-"
	end
end)

saveWpBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	if myHrp then
		table.insert(waypoints, myHrp.Position)
		updateRoomListDisplay()
		saveToDevice()
	end
end)

clearWpBtn.MouseButton1Click:Connect(function()
	waypoints = {}
	resetToRoomOne()
	isLoopingWaypoints = false
	loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	loopWpBtn.Text = "RWP ▶ [OFF]"
	updateRoomListDisplay()
	targetLabel.Text = "Target: None"
	statusSubLabel.Text = "Status: Cleared"
	saveToDevice()
end)

skipWpBtn.MouseButton1Click:Connect(function()
	if #waypoints > 0 then
		currentWaypointIndex += 1
		if currentWaypointIndex > #waypoints then
			currentWaypointIndex = 1
		end
		roomClearedConfirmed = true
		gateTimer = tick()
		targetLabel.Text = "Target: Room " .. currentWaypointIndex
	end
end)

loopWpBtn.MouseButton1Click:Connect(function()
	if #waypoints == 0 then
		targetLabel.Text = "Target: None"
		statusSubLabel.Text = "Status: No Rooms!"
		return
	end
	isLoopingWaypoints = not isLoopingWaypoints
	if isLoopingWaypoints then
		isTrackingAll = false
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "FTM ▶ [OFF]"
		
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		loopWpBtn.Text = "RWP ⏸ [ON]"
		resetToRoomOne()
		gateTimer = tick()
	else
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		loopWpBtn.Text = "RWP ▶ [OFF]"
	end
end)

restartToggleBtn.MouseButton1Click:Connect(function()
	isAutoRestartEnabled = not isAutoRestartEnabled
	if isAutoRestartEnabled then
		restartToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		restartToggleBtn.Text = "Auto Restart: ON"
	else
		restartToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		restartToggleBtn.Text = "Auto Restart: OFF"
	end
end)

toggleButton.MouseButton1Click:Connect(function()
	isTrackingAll = not isTrackingAll
	if isTrackingAll then
		isLoopingWaypoints = false
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		loopWpBtn.Text = "RWP ▶ [OFF]"
		
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		toggleButton.Text = "FTM ⏸ [ON]"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "FTM ▶ [OFF]"
	end
end)

aatToggleBtn.MouseButton1Click:Connect(function()
	isAatEnabled = not isAatEnabled
	if isAatEnabled then
		aatToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		aatToggleBtn.Text = "AAT ⏸ [ON]"
	else
		aatToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		aatToggleBtn.Text = "AAT ▶ [OFF]"
	end
end)

autoPotBtn.MouseButton1Click:Connect(function()
	isAutoPotEnabled = not isAutoPotEnabled
	if isAutoPotEnabled then
		autoPotBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		autoPotBtn.Text = "Pot ON"
	else
		autoPotBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		autoPotBtn.Text = "Auto Pot"
	end
end)

noclipToggleBtn.MouseButton1Click:Connect(function()
	isNoClipEnabled = not isNoClipEnabled
	if isNoClipEnabled then
		noclipToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		noclipToggleBtn.Text = "No-Clip: ON"
	else
		noclipToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		noclipToggleBtn.Text = "No-Clip: OFF"
	end
end)

importBox.FocusLost:Connect(function()
	local text = importBox.Text
	if text == "" then return end
	
	local countAdded = 0
	for x, y, z in string.gmatch(text, "([%-?%d%.]+)%s*,%s*([%-?%d%.]+)%s*,%s*([%-?%d%.]+)") do
		local numX, numY, numZ = tonumber(x), tonumber(y), tonumber(z)
		if numX and numY and numZ then
			table.insert(waypoints, Vector3.new(numX, numY, numZ))
			countAdded += 1
		end
	end
	
	importBox.Text = ""
	statusSubLabel.Text = "Status: Imported " .. countAdded
	updateRoomListDisplay()
	saveToDevice()
end)

exportWpBtn.MouseButton1Click:Connect(function()
	if #waypoints == 0 then
		statusSubLabel.Text = "Status: No Rooms!"
		return
	end
	
	local exportStr = ""
	for _, pos in ipairs(waypoints) do
		exportStr = exportStr .. string.format("%.2f, %.2f, %.2f\n", pos.X, pos.Y, pos.Z)
	end
	
	pcall(function()
		setclipboard(exportStr)
	end)
	print("--- EXPORTED DUNGEON ROOMS ---")
	print(exportStr)
	statusSubLabel.Text = "Status: Exported"
end)

-- Main execution loop
RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	
	-- No-Clip execution loop
	if isNoClipEnabled and char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
	
	-- AAT Target Box Click Simulation Loop (Paused during boss delay, pre-click countdown, and post-restart cooldown)
	local isPreClickActive = (preClickCountdownTimer > 0)
	if isAatEnabled and bossDefeatedTimer == 0 and not isPreClickActive and (tick() - postRestartCooldown >= 10) then
		if tick() - lastAtkClickTime >= 0.15 then
			lastAtkClickTime = tick()
			local absPos = atkTargetFrame.AbsolutePosition
			local absSize = atkTargetFrame.AbsoluteSize
			local centerX = absPos.X + absSize.X / 2
			local centerY = absPos.Y + absSize.Y / 2
			
			VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
			task.wait(0.02)
			VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
		end
	end
	
	-- Auto Potion / HP Monitor Logic
	if isAutoPotEnabled and humanoid and humanoid.Health > 0 then
		local hpPercent = (humanoid.Health / humanoid.MaxHealth) * 100
		if hpPercent <= CONFIG.PotThreshold then
			if tick() - lastPotionTime >= 3 then
				lastPotionTime = tick()
				print("HP dropped below " .. CONFIG.PotThreshold .. "%. Using potion (Key 2 -> Key 1)...")
				
				task.spawn(function()
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
					task.wait(0.05)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
					
					task.wait(1.0)
					
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
					task.wait(0.05)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
				end)
			end
		end
	end
	
	-- Update live Run counter on UI dashboard
	runsLabel.Text = "Runs: " .. runsCounter
	
	-- If pre-click 5-second status countdown is active before clicking Run again
	if preClickCountdownTimer > 0 then
		local elapsedPreClick = tick() - preClickCountdownTimer
		local preClickRemaining = math.max(0, math.ceil(5 - elapsedPreClick))
		
		targetLabel.Text = "Target: Restarting"
		countLabel.Text = "Mobs: 0"
		statusSubLabel.Text = "Status: Clicking Run again (" .. preClickRemaining .. "s)"
		
		if elapsedPreClick >= 5 then
			triggerRunAgainButton()
		end
		return
	end
	
	-- If post-restart cooldown is active, pause navigation and show status
	if tick() - postRestartCooldown < 10 then
		targetLabel.Text = "Target: Restarting"
		countLabel.Text = "Mobs: 0"
		statusSubLabel.Text = "Status: Cooldown"
		return
	end
	
	if not aggressorsFolder or not aggressorsFolder.Parent then
		local live = workspace:FindFirstChild("Animal_Live")
		if live then aggressorsFolder = live:FindFirstChild("Aggressors") end
	end
	
	local detectedCount = 0
	local nearestMonsterPart = nil
	local nearestMonsterModel = nil
	local nearestMonsterName = "None"
	local shortestDist = math.huge
	local hasBossPresent = false
	
	local isBossRoomScan = (isLoopingWaypoints and #waypoints > 0 and currentWaypointIndex >= CONFIG.BossRoomNumber)
	local bossWp = isBossRoomScan and waypoints[CONFIG.BossRoomNumber] or nil
	local shortestBossDist = math.huge
	
	if aggressorsFolder and myHrp then
		for _, monster in ipairs(aggressorsFolder:GetChildren()) do
			if monster:IsA("Model") then
				local hrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart or monster:FindFirstChildWhichIsA("BasePart")
				if hrp then
					local dist = (myHrp.Position - hrp.Position).Magnitude
					if dist <= CONFIG.DetectionRadius then
						detectedCount += 1
						hasBossPresent = true
						
						if bossWp then
							local wpDist = (hrp.Position - bossWp).Magnitude
							if wpDist < shortestBossDist then
								shortestBossDist = wpDist
								shortestDist = dist
								nearestMonsterPart = hrp
								nearestMonsterModel = monster
								local animalName = getAnimalName(monster)
								nearestMonsterName = animalName .. " (Boss)"
							end
						else
							if dist < shortestDist then
								shortestDist = dist
								nearestMonsterPart = hrp
								nearestMonsterModel = monster
								local animalName = getAnimalName(monster)
								nearestMonsterName = animalName .. " (" .. math.floor(dist) .. "m)"
							end
						end
					end
				end
			end
		end
	end
	
	-- Boss Room Defeat Auto-Restart Trigger with BossDelay, then Pre-Click 5s Countdown
	local statusMsg = "Active"
	if isAutoRestartEnabled and #waypoints > 0 and currentWaypointIndex >= CONFIG.BossRoomNumber then
		if bossWasPresent and not hasBossPresent and bossDefeatedTimer == 0 then
			bossDefeatedTimer = tick()
			print("Boss defeated! Starting " .. CONFIG.BossDelay .. "-second boss delay countdown...")
		elseif hasBossPresent then
			bossWasPresent = true
		end
		
		if bossDefeatedTimer > 0 then
			local elapsed = tick() - bossDefeatedTimer
			local remaining = math.max(0, math.ceil(CONFIG.BossDelay - elapsed))
			
			if remaining > 0 then
				statusMsg = "Boss Down (" .. remaining .. "s)"
			else
				bossDefeatedTimer = 0
				preClickCountdownTimer = tick() -- Start the pre-click 5s status countdown
			end
		end
	end
	
	countLabel.Text = "Mobs: " .. detectedCount
	
	local targetPos = nil
	local targetName = "None"
	
	-- Check if we are currently delayed at a mob arrival spot
	if mobArrivalTimer > 0 and bossDefeatedTimer == 0 and preClickCountdownTimer == 0 then
		if tick() - mobArrivalTimer < CONFIG.MobArrivalDelay then
			statusMsg = "Waiting Drop"
			targetName = "Looting..."
			targetPos = nil
		else
			mobArrivalTimer = 0
		end
	end
	
	-- Priority Logic & Waypoint Room Navigation
	local isBossRoom = (isLoopingWaypoints and #waypoints > 0 and currentWaypointIndex >= CONFIG.BossRoomNumber)
	local heightOffset = Vector3.new(0, CONFIG.NoclipOffset, 0)
	
	if bossDefeatedTimer == 0 and preClickCountdownTimer == 0 then
		if mobArrivalTimer == 0 and ((isTrackingAll or isLoopingWaypoints) and nearestMonsterPart) then
			if lastTargetMonsterId ~= nearestMonsterModel and shortestDist <= (CONFIG.StopDistance + 2) then
				lastTargetMonsterId = nearestMonsterModel
				mobArrivalTimer = tick()
			end
			
			if isBossRoom and waypoints[CONFIG.BossRoomNumber] then
				local bossCenterPos = waypoints[CONFIG.BossRoomNumber]
				local centerDist = (myHrp.Position - bossCenterPos).Magnitude
				
				if centerDist > 15 then
					targetPos = bossCenterPos + heightOffset
					targetName = "Boss Center"
					statusMsg = "Centering"
				else
					targetPos = nearestMonsterPart.Position + heightOffset
					targetName = "Boss Mob"
					statusMsg = "Fighting"
				end
			else
				targetPos = nearestMonsterPart.Position + heightOffset
				targetName = "Mob Target"
				statusMsg = "Attacking"
			end
			gateTimer = tick()
		elseif mobArrivalTimer == 0 and (isLoopingWaypoints and #waypoints > 0 and myHrp) then
			local currentWp = waypoints[currentWaypointIndex]
			local wpDist = (myHrp.Position - currentWp).Magnitude
			
			if currentWaypointIndex == 1 or currentWaypointIndex >= CONFIG.BossRoomNumber then
				roomClearedConfirmed = true
			else
				if checkGateUnsealedThrottled() or (tick() - gateTimer >= CONFIG.GateTimeout) then
					roomClearedConfirmed = true
				else
					roomClearedConfirmed = false
				end
			end
			
			if roomClearedConfirmed then
				targetPos = currentWp + heightOffset
				local isBoss = (currentWaypointIndex >= CONFIG.BossRoomNumber)
				targetName = (isBoss and "Boss " or "") .. "Room " .. currentWaypointIndex .. "/" .. #waypoints
				statusMsg = "Moving (" .. math.floor(wpDist) .. "m)"
				
				if wpDist <= (CONFIG.StopDistance + 2) then
					if currentWaypointIndex < CONFIG.BossRoomNumber then
						currentWaypointIndex += 1
					end
					roomClearedConfirmed = false
					gateTimer = tick()
				end
			else
				targetName = "Room " .. currentWaypointIndex
				statusMsg = "Waiting Gate"
			end
		elseif mobArrivalTimer == 0 and (isTrackingAll and nearestMonsterPart) then
			targetPos = nearestMonsterPart.Position + heightOffset
			targetName = "All Mobs"
			statusMsg = "Tracking"
		else
			if isLoopingWaypoints and #waypoints == 0 and mobArrivalTimer == 0 then
				targetName = "None"
				statusMsg = "No Rooms!"
			elseif mobArrivalTimer == 0 then
				statusMsg = "Idle"
			end
		end
	end
	
	targetLabel.Text = "Target: " .. targetName
	statusSubLabel.Text = "Status: " .. statusMsg
	
	-- Smooth Flight Execution with Level Posture Correction (Locking Pitch/Roll)
	if ((isTrackingAll or isLoopingWaypoints) and targetPos) and myHrp and humanoid then
		humanoid.PlatformStand = true
		local currentPos = myHrp.Position
		local direction = (targetPos - currentPos)
		local distance = direction.Magnitude
		
		if distance > CONFIG.StopDistance then
			local moveVector = direction.Unit * math.min(CONFIG.FlightSpeed * dt, distance)
			local flatTarget = Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)
			if (flatTarget - currentPos).Magnitude > 1 then
				myHrp.CFrame = CFrame.new(currentPos + moveVector, flatTarget + Vector3.new(0, (targetPos.Y - currentPos.Y), 0))
			else
				myHrp.CFrame = CFrame.new(currentPos + moveVector, targetPos)
			end
			myHrp.AssemblyLinearVelocity = Vector3.zero
		else
			myHrp.CFrame = CFrame.new(currentPos, targetPos)
			myHrp.AssemblyLinearVelocity = Vector3.zero
		end
	else
		if humanoid and humanoid.PlatformStand then
			humanoid.PlatformStand = false
		end
	end
end)
