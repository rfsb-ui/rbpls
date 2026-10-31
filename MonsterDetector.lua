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
	FlightSpeed = 13,
	DetectionRadius = 100,
	StopDistance = 3,
	BossRoomNumber = 19
}

pcall(function()
	if _G.DungeonSettings then
		CONFIG.FlightSpeed = _G.DungeonSettings.FlightSpeed or CONFIG.DungeonSettings.FlightSpeed
		CONFIG.DetectionRadius = _G.DungeonSettings.DetectionRadius or CONFIG.DetectionRadius
		CONFIG.StopDistance = _G.DungeonSettings.StopDistance or CONFIG.StopDistance
		CONFIG.BossRoomNumber = _G.DungeonSettings.BossRoomNumber or CONFIG.BossRoomNumber
	end
end)

local function saveSettings()
	_G.DungeonSettings = {
		FlightSpeed = CONFIG.FlightSpeed,
		DetectionRadius = CONFIG.DetectionRadius,
		StopDistance = CONFIG.StopDistance,
		BossRoomNumber = CONFIG.BossRoomNumber
	}
end
-- ============================================================================

-- Strict Animal property fetcher
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
local lastRestartAttempt = 0
local restartLoadingTimeout = 0

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

-- Function to check for "Dungeon Cleared" popup and auto-click "Run again" (Restricted to Boss Room)
local function checkAndRestartDungeon()
	if not isAutoRestartEnabled or (tick() - lastRestartAttempt < 6) then return end
	if currentWaypointIndex < CONFIG.BossRoomNumber and #waypoints > 0 then return end
	if tick() < restartLoadingTimeout then return end
	
	for _, gui in ipairs(playerGui:GetDescendants()) do
		if gui:IsA("TextButton") or gui:IsA("TextLabel") then
			local text = gui.Text:lower()
			if string.find(text, "dungeon cleared") or string.find(text, "victory") then
				for _, btn in ipairs(playerGui:GetDescendants()) do
					if btn:IsA("TextButton") then
						local btnText = btn.Text:lower()
						if string.find(btnText, "run") or string.find(btnText, "again") or string.find(btnText, "restart") then
							lastRestartAttempt = tick()
							restartLoadingTimeout = tick() + 4
							currentWaypointIndex = 1
							roomClearedConfirmed = true
							
							pcall(function()
								for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
									conn:Fire()
								end
							end)
							
							local absPos = btn.AbsolutePosition
							local absSize = btn.AbsoluteSize
							local clickX = absPos.X + absSize.X/2
							local clickY = absPos.Y + absSize.Y/2
							
							VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
							task.wait(0.05)
							VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
							print("Auto Dungeon Restarted via button: " .. btn.Name)
							return
						end
					end
				end
			end
		end
	end
end

-- Create the main ScreenGui safely with explicit ZIndex
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDungeonGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- Main Compact Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 530)
mainFrame.Position = UDim2.new(0, 30, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 1
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title Label / Drag Handler
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -65, 0, 32)
titleLabel.Position = UDim2.new(0, 8, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Dungeon v2.9.1"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 2
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
closeButton.ZIndex = 2
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
minimizeButton.ZIndex = 2
minimizeButton.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minimizeButton

-- Compact Status Dashboard
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -16, 0, 110)
statusFrame.Position = UDim2.new(0, 8, 0, 35)
statusFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
statusFrame.BorderSizePixel = 0
statusFrame.ZIndex = 2
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
targetLabel.ZIndex = 3
targetLabel.Parent = statusFrame

local currentWpLabel = Instance.new("TextLabel")
currentWpLabel.Size = UDim2.new(1, -8, 0, 18)
currentWpLabel.Position = UDim2.new(0, 4, 0, 24)
currentWpLabel.BackgroundTransparency = 1
currentWpLabel.Text = "Current WP: None"
currentWpLabel.TextColor3 = Color3.fromRGB(255, 150, 220)
currentWpLabel.TextSize = 11
currentWpLabel.Font = Enum.Font.SourceSansBold
currentWpLabel.TextXAlignment = Enum.TextXAlignment.Left
currentWpLabel.ZIndex = 3
currentWpLabel.Parent = statusFrame

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -8, 0, 18)
countLabel.Position = UDim2.new(0, 4, 0, 44)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Mobs Detected: 0"
countLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
countLabel.TextSize = 11
countLabel.Font = Enum.Font.SourceSansBold
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.ZIndex = 3
countLabel.Parent = statusFrame

local wpSavedLabel = Instance.new("TextLabel")
wpSavedLabel.Size = UDim2.new(1, -8, 0, 18)
wpSavedLabel.Position = UDim2.new(0, 4, 0, 64)
wpSavedLabel.BackgroundTransparency = 1
wpSavedLabel.Text = "Rooms Saved: 0"
wpSavedLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
wpSavedLabel.TextSize = 11
wpSavedLabel.Font = Enum.Font.SourceSansBold
wpSavedLabel.TextXAlignment = Enum.TextXAlignment.Left
wpSavedLabel.ZIndex = 3
wpSavedLabel.Parent = statusFrame

local wpImportedLabel = Instance.new("TextLabel")
wpImportedLabel.Size = UDim2.new(1, -8, 0, 18)
wpImportedLabel.Position = UDim2.new(0, 4, 0, 84)
wpImportedLabel.BackgroundTransparency = 1
wpImportedLabel.Text = "Imported WPs: 0"
wpImportedLabel.TextColor3 = Color3.fromRGB(220, 150, 255)
wpImportedLabel.TextSize = 11
wpImportedLabel.Font = Enum.Font.SourceSansBold
wpImportedLabel.TextXAlignment = Enum.TextXAlignment.Left
wpImportedLabel.ZIndex = 3
wpImportedLabel.Parent = statusFrame

-- Main Fly to All Mobs Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -16, 0, 28)
toggleButton.Position = UDim2.new(0, 8, 0, 152)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleButton.Text = "Fly to All Mobs: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 12
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.ZIndex = 2
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 5)
btnCorner.Parent = toggleButton

-- Dungeon Room Controls Row
local saveWpBtn = Instance.new("TextButton")
saveWpBtn.Size = UDim2.new(0, 52, 0, 26)
saveWpBtn.Position = UDim2.new(0, 8, 0, 188)
saveWpBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
saveWpBtn.Text = "Save"
saveWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveWpBtn.TextSize = 11
saveWpBtn.Font = Enum.Font.SourceSansBold
saveWpBtn.ZIndex = 2
saveWpBtn.Parent = mainFrame

local swpCorner = Instance.new("UICorner")
swpCorner.CornerRadius = UDim.new(0, 4)
swpCorner.Parent = saveWpBtn

local clearWpBtn = Instance.new("TextButton")
clearWpBtn.Size = UDim2.new(0, 52, 0, 26)
clearWpBtn.Position = UDim2.new(0, 64, 0, 188)
clearWpBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
clearWpBtn.Text = "Clear"
clearWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearWpBtn.TextSize = 11
clearWpBtn.Font = Enum.Font.SourceSansBold
clearWpBtn.ZIndex = 2
clearWpBtn.Parent = mainFrame

local cwpCorner = Instance.new("UICorner")
cwpCorner.CornerRadius = UDim.new(0, 4)
cwpCorner.Parent = clearWpBtn

local skipWpBtn = Instance.new("TextButton")
skipWpBtn.Size = UDim2.new(0, 52, 0, 26)
skipWpBtn.Position = UDim2.new(0, 120, 0, 188)
skipWpBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
skipWpBtn.Text = "Skip WP"
skipWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
skipWpBtn.TextSize = 11
skipWpBtn.Font = Enum.Font.SourceSansBold
skipWpBtn.ZIndex = 2
skipWpBtn.Parent = mainFrame

local skpCorner = Instance.new("UICorner")
skpCorner.CornerRadius = UDim.new(0, 4)
skpCorner.Parent = skipWpBtn

local loopWpBtn = Instance.new("TextButton")
loopWpBtn.Size = UDim2.new(0, 52, 0, 26)
loopWpBtn.Position = UDim2.new(0, 176, 0, 188)
loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
loopWpBtn.Text = "Run OFF"
loopWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopWpBtn.TextSize = 10
loopWpBtn.Font = Enum.Font.SourceSansBold
loopWpBtn.ZIndex = 2
loopWpBtn.Parent = mainFrame

local lwpCorner = Instance.new("UICorner")
lwpCorner.CornerRadius = UDim.new(0, 4)
lwpCorner.Parent = loopWpBtn

-- Auto Restart Toggle Button
local restartToggleBtn = Instance.new("TextButton")
restartToggleBtn.Size = UDim2.new(1, -16, 0, 26)
restartToggleBtn.Position = UDim2.new(0, 8, 0, 222)
restartToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
restartToggleBtn.Text = "Auto Restart: OFF"
restartToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
restartToggleBtn.TextSize = 11
restartToggleBtn.Font = Enum.Font.SourceSansBold
restartToggleBtn.ZIndex = 2
restartToggleBtn.Parent = mainFrame

local rstCorner = Instance.new("UICorner")
rstCorner.CornerRadius = UDim.new(0, 4)
rstCorner.Parent = restartToggleBtn

-- Waypoint Import Box
local importBox = Instance.new("TextBox")
importBox.Size = UDim2.new(1, -16, 0, 26)
importBox.Position = UDim2.new(0, 8, 0, 256)
importBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
importBox.PlaceholderText = "Paste Waypoints/Coordinates..."
importBox.Text = ""
importBox.TextColor3 = Color3.fromRGB(255, 255, 255)
importBox.TextSize = 11
importBox.Font = Enum.Font.SourceSans
importBox.ZIndex = 2
importBox.Parent = mainFrame

local impCorner = Instance.new("UICorner")
impCorner.CornerRadius = UDim.new(0, 4)
impCorner.Parent = importBox

-- Export Rooms Button
local exportWpBtn = Instance.new("TextButton")
exportWpBtn.Size = UDim2.new(1, -16, 0, 26)
exportWpBtn.Position = UDim2.new(0, 8, 0, 288)
exportWpBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 100)
exportWpBtn.Text = "Export Rooms"
exportWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exportWpBtn.TextSize = 11
exportWpBtn.Font = Enum.Font.SourceSansBold
exportWpBtn.ZIndex = 2
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
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 2
	lbl.Parent = mainFrame
	table.insert(configurableElements, lbl)
	
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, width, 0, 24)
	box.Position = UDim2.new(0, posX, 0, posY + 15)
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	box.Text = tostring(defaultVal)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 10
	box.Font = Enum.Font.SourceSans
	box.ZIndex = 2
	box.Parent = mainFrame
	table.insert(configurableElements, box)
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = box
	
	box.FocusLost:Connect(function()
		local val = tonumber(box.Text)
		if val then
			callback(val)
			saveSettings()
		else
			box.Text = tostring(defaultVal)
		end
	end)
	
	return box
end

createLabeledInput(8, 322, 52, "Speed", CONFIG.FlightSpeed, function(v) CONFIG.FlightSpeed = v end)
createLabeledInput(64, 322, 52, "Radius", CONFIG.DetectionRadius, function(v) CONFIG.DetectionRadius = v end)
createLabeledInput(120, 322, 52, "Stop", CONFIG.StopDistance, function(v) CONFIG.StopDistance = v end)
createLabeledInput(176, 322, 56, "Boss#", CONFIG.BossRoomNumber, function(v) CONFIG.BossRoomNumber = v end)

-- Scrollable Room List Viewer below UI
local roomListFrame = Instance.new("ScrollingFrame")
roomListFrame.Size = UDim2.new(1, -16, 0, 130)
roomListFrame.Position = UDim2.new(0, 8, 0, 364)
roomListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
roomListFrame.BorderSizePixel = 0
roomListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
roomListFrame.ScrollBarThickness = 5
roomListFrame.ZIndex = 2
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
		item.Text = string.format("Room %d%s: (%.1f, %.1f, %.1f)", i, (i == CONFIG.BossRoomNumber and " [BOSS]" or ""), pos.X, pos.Y, pos.Z)
		item.TextColor3 = Color3.fromRGB(220, 220, 220)
		item.TextSize = 10
		item.Font = Enum.Font.SourceSans
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.ZIndex = 3
		item.Parent = roomListFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = item
	end
	
	roomListFrame.CanvasSize = UDim2.new(0, 0, 0, #waypoints * 25)
end

-- State variables
local isMinimized = false

minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 240, 0, 150)
		toggleButton.Visible = false
		saveWpBtn.Visible = false
		clearWpBtn.Visible = false
		skipWpBtn.Visible = false
		loopWpBtn.Visible = false
		restartToggleBtn.Visible = false
		importBox.Visible = false
		exportWpBtn.Visible = false
		for _, el in ipairs(configurableElements) do
			el.Visible = false
		end
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 240, 0, 530)
		toggleButton.Visible = true
		saveWpBtn.Visible = true
		clearWpBtn.Visible = true
		skipWpBtn.Visible = true
		loopWpBtn.Visible = true
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
		wpSavedLabel.Text = "Rooms Saved: " .. #waypoints
		updateRoomListDisplay()
	end
end)

clearWpBtn.MouseButton1Click:Connect(function()
	waypoints = {}
	importedWaypointsCount = 0
	currentWaypointIndex = 1
	isLoopingWaypoints = false
	roomClearedConfirmed = true
	loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	loopWpBtn.Text = "Run OFF"
	wpSavedLabel.Text = "Rooms Saved: 0"
	wpImportedLabel.Text = "Imported WPs: 0"
	targetLabel.Text = "Rooms Cleared"
	currentWpLabel.Text = "Current WP: None"
	updateRoomListDisplay()
end)

skipWpBtn.MouseButton1Click:Connect(function()
	if #waypoints > 0 then
		currentWaypointIndex += 1
		if currentWaypointIndex > #waypoints then
			currentWaypointIndex = 1
		end
		roomClearedConfirmed = true
		targetLabel.Text = "Skipped to Room " .. currentWaypointIndex
	end
end)

loopWpBtn.MouseButton1Click:Connect(function()
	if #waypoints == 0 then
		targetLabel.Text = "No Rooms Saved!"
		return
	end
	isLoopingWaypoints = not isLoopingWaypoints
	if isLoopingWaypoints then
		isTrackingAll = false
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Fly to All Mobs: OFF"
		
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		loopWpBtn.Text = "Run ON"
		currentWaypointIndex = 1
		roomClearedConfirmed = true
	else
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		loopWpBtn.Text = "Run OFF"
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
		loopWpBtn.Text = "Run OFF"
		
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		toggleButton.Text = "Fly to All Mobs: ON"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Fly to All Mobs: OFF"
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
	
	importedWaypointsCount += countAdded
	wpSavedLabel.Text = "Rooms Saved: " .. #waypoints
	wpImportedLabel.Text = "Imported WPs: " .. importedWaypointsCount
	importBox.Text = ""
	targetLabel.Text = "Imported " .. countAdded .. " Rooms!"
	updateRoomListDisplay()
end)

exportWpBtn.MouseButton1Click:Connect(function()
	if #waypoints == 0 then
		targetLabel.Text = "No Rooms to Export!"
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
	targetLabel.Text = "Rooms Exported!"
end)

-- Main execution loop
RunService.Heartbeat:Connect(function(dt)
	checkAndRestartDungeon()
	
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	
	if not aggressorsFolder or not aggressorsFolder.Parent then
		local live = workspace:FindFirstChild("Animal_Live")
		if live then aggressorsFolder = live:FindFirstChild("Aggressors") end
	end
	
	local detectedCount = 0
	local nearestMonsterPart = nil
	local nearestMonsterName = "None"
	local shortestDist = math.huge
	
	-- 1. Scan for nearby monsters first (Top Priority)
	if myHrp and aggressorsFolder then
		for _, monster in ipairs(aggressorsFolder:GetChildren()) do
			if monster:IsA("Model") then
				local hrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
				local hum = monster:FindFirstChildOfClass("Humanoid")
				
				if hrp and hum and hum.Health > 0 then
					local dist = (myHrp.Position - hrp.Position).Magnitude
					if dist <= CONFIG.DetectionRadius then
						detectedCount += 1
						if dist < shortestDist then
							shortestDist = dist
							nearestMonsterPart = hrp
							nearestMonsterName = getAnimalName(monster) .. " (" .. math.floor(dist) .. "m)"
						end
					end
				end
			end
		end
	end
	
	countLabel.Text = "Mobs Detected: " .. detectedCount
	
	local targetPos = nil
	local targetName = "None"
	local currentWpName = "None"
	
	-- Update Current Waypoint Destination Display
	if isLoopingWaypoints and #waypoints > 0 then
		local currWp = waypoints[currentWaypointIndex]
		local isBoss = (currentWaypointIndex >= CONFIG.BossRoomNumber)
		currentWpName = string.format("Room %d%s (%.1f, %.1f, %.1f)", currentWaypointIndex, (isBoss and " [BOSS]" or ""), currWp.X, currWp.Y, currWp.Z)
	end
	currentWpLabel.Text = "Current WP: " .. currentWpName
	
	-- 2. Priority Queue: Monsters -> Waypoints
	local isBossRoom = (isLoopingWaypoints and #waypoints > 0 and currentWaypointIndex >= CONFIG.BossRoomNumber)
	
	if (isTrackingAll or isLoopingWaypoints) and nearestMonsterPart then
		if isBossRoom and waypoints[CONFIG.BossRoomNumber] then
			local bossCenterPos = waypoints[CONFIG.BossRoomNumber]
			local centerDist = (myHrp.Position - bossCenterPos).Magnitude
			
			if centerDist > 15 then
				targetPos = bossCenterPos + Vector3.new(0, 2, 0)
				targetName = "Returning to Boss Center"
			else
				targetPos = nearestMonsterPart.Position + Vector3.new(0, 2, 0)
				targetName = "Fighting Boss: " .. nearestMonsterName
			end
		else
			targetPos = nearestMonsterPart.Position + Vector3.new(0, 2, 0)
			targetName = "Killing Mob: " .. nearestMonsterName
		end
	elseif not targetPos and isTrackingAll and nearestMonsterPart then
		targetPos = nearestMonsterPart.Position + Vector3.new(0, 2, 0)
		targetName = nearestMonsterName
	end
	
	-- Dungeon Room Waypoints (Strict Gate Check: Room 1 to 2 is exception, others wait indefinitely for Room Cleared message)
	if not targetPos and isLoopingWaypoints and #waypoints > 0 and myHrp then
		local currentWp = waypoints[currentWaypointIndex]
		local wpDist = (myHrp.Position - currentWp).Magnitude
		
		if currentWaypointIndex == 1 then
			roomClearedConfirmed = true
		else
			roomClearedConfirmed = checkGateUnsealed()
		end
		
		if roomClearedConfirmed then
			targetPos = currentWp + Vector3.new(0, 2, 0)
			local isBoss = (currentWaypointIndex >= CONFIG.BossRoomNumber)
			targetName = (isBoss and "[BOSS] " or "") .. "Room " .. currentWaypointIndex .. "/" .. #waypoints .. " (" .. math.floor(wpDist) .. "m)"
			
			if wpDist <= (CONFIG.StopDistance + 2) then
				if currentWaypointIndex < CONFIG.BossRoomNumber then
					currentWaypointIndex += 1
				end
				roomClearedConfirmed = false
			end
		else
			-- While waiting for gate unseal, hold position at waypoint but KEEP mob detection running above
			targetPos = currentWp + Vector3.new(0, 2, 0)
			targetName = "Waiting for Room Cleared..."
		end
	end
	
	targetLabel.Text = "Target: " .. targetName
	
	-- 3. Smooth Flight Execution with anti-clipping
	if ((isTrackingAll or isLoopingWaypoints) and targetPos) and myHrp and humanoid then
		humanoid.PlatformStand = true
		local currentPos = myHrp.Position
		local direction = (targetPos - currentPos)
		local distance = direction.Magnitude
		
		if distance > CONFIG.StopDistance then
			local moveVector = direction.Unit * math.min(CONFIG.FlightSpeed * dt, distance)
			myHrp.CFrame = CFrame.new(currentPos + moveVector, targetPos)
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
