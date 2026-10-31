local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
	FlightSpeed = 50,
	DetectionRadius = 500,
	StopDistance = 4
}

pcall(function()
	if _G.DungeonSettings then
		CONFIG.FlightSpeed = _G.DungeonSettings.FlightSpeed or CONFIG.FlightSpeed
		CONFIG.DetectionRadius = _G.DungeonSettings.DetectionRadius or CONFIG.DetectionRadius
		CONFIG.StopDistance = _G.DungeonSettings.StopDistance or CONFIG.StopDistance
	end
end)

local function saveSettings()
	_G.DungeonSettings = {
		FlightSpeed = CONFIG.FlightSpeed,
		DetectionRadius = CONFIG.DetectionRadius,
		StopDistance = CONFIG.StopDistance
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

-- Waypoint variables (Each waypoint represents a Dungeon Room)
local waypoints = {}
local currentWaypointIndex = 1
local isLoopingWaypoints = false
local isTrackingAll = false

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDungeonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Compact Panel (Height expanded to fit labels and import box)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 390)
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
titleLabel.Text = "Auto Dungeon v2.2"
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

-- Compact Status Dashboard (Includes Live Rooms/Waypoints Count)
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -16, 0, 72)
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

-- Main Fly to All Mobs Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -16, 0, 28)
toggleButton.Position = UDim2.new(0, 8, 0, 114)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleButton.Text = "Fly to All Mobs: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 12
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 5)
btnCorner.Parent = toggleButton

-- Dungeon Room Controls Row (Save Room, Clear Rooms, Loop Rooms)
local saveWpBtn = Instance.new("TextButton")
saveWpBtn.Size = UDim2.new(0, 72, 0, 26)
saveWpBtn.Position = UDim2.new(0, 8, 0, 150)
saveWpBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
saveWpBtn.Text = "Save Room"
saveWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveWpBtn.TextSize = 11
saveWpBtn.Font = Enum.Font.SourceSansBold
saveWpBtn.Parent = mainFrame

local swpCorner = Instance.new("UICorner")
swpCorner.CornerRadius = UDim.new(0, 4)
swpCorner.Parent = saveWpBtn

local clearWpBtn = Instance.new("TextButton")
clearWpBtn.Size = UDim2.new(0, 72, 0, 26)
clearWpBtn.Position = UDim2.new(0, 84, 0, 150)
clearWpBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
clearWpBtn.Text = "Clear Rooms"
clearWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearWpBtn.TextSize = 10
clearWpBtn.Font = Enum.Font.SourceSansBold
clearWpBtn.Parent = mainFrame

local cwpCorner = Instance.new("UICorner")
cwpCorner.CornerRadius = UDim.new(0, 4)
cwpCorner.Parent = clearWpBtn

local loopWpBtn = Instance.new("TextButton")
loopWpBtn.Size = UDim2.new(0, 72, 0, 26)
loopWpBtn.Position = UDim2.new(0, 160, 0, 150)
loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
loopWpBtn.Text = "Dungeon: OFF"
loopWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopWpBtn.TextSize = 10
loopWpBtn.Font = Enum.Font.SourceSansBold
loopWpBtn.Parent = mainFrame

local lwpCorner = Instance.new("UICorner")
lwpCorner.CornerRadius = UDim.new(0, 4)
lwpCorner.Parent = loopWpBtn

-- Waypoint Import Box
local importBox = Instance.new("TextBox")
importBox.Size = UDim2.new(1, -16, 0, 26)
importBox.Position = UDim2.new(0, 8, 0, 184)
importBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
importBox.PlaceholderText = "Paste Waypoints/Coordinates to Import..."
importBox.Text = ""
importBox.TextColor3 = Color3.fromRGB(255, 255, 255)
importBox.TextSize = 11
importBox.Font = Enum.Font.SourceSans
importBox.Parent = mainFrame

local impCorner = Instance.new("UICorner")
impCorner.CornerRadius = UDim.new(0, 4)
impCorner.Parent = importBox

-- Configurable Inputs with Clear Labels
local function createLabeledInput(posX, posY, width, labelText, defaultVal, callback)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, width, 0, 15)
	lbl.Position = UDim2.new(0, posX, 0, posY)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
	lbl.TextSize = 10
	lbl.Font = Enum.Font.SourceSansBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = mainFrame
	
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, width, 0, 24)
	box.Position = UDim2.new(0, posX, 0, posY + 16)
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	box.Text = tostring(defaultVal)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 11
	box.Font = Enum.Font.SourceSans
	box.Parent = mainFrame
	
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

createLabeledInput(8, 216, 72, "Speed", CONFIG.FlightSpeed, function(v) CONFIG.FlightSpeed = v end)
createLabeledInput(84, 216, 72, "Radius", CONFIG.DetectionRadius, function(v) CONFIG.DetectionRadius = v end)
createLabeledInput(160, 216, 72, "Stop Dist", CONFIG.StopDistance, function(v) CONFIG.StopDistance = v end)

-- State variables
local isMinimized = false

minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 240, 0, 36)
		statusFrame.Visible = false
		toggleButton.Visible = false
		saveWpBtn.Visible = false
		clearWpBtn.Visible = false
		loopWpBtn.Visible = false
		importBox.Visible = false
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 240, 0, 390)
		statusFrame.Visible = true
		toggleButton.Visible = true
		saveWpBtn.Visible = true
		clearWpBtn.Visible = true
		loopWpBtn.Visible = true
		importBox.Visible = true
		minimizeButton.Text = "-"
	end
end)

-- Waypoint button handlers
saveWpBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	if myHrp then
		table.insert(waypoints, myHrp.Position)
		wpSavedLabel.Text = "Rooms Saved: " .. #waypoints
	end
end)

clearWpBtn.MouseButton1Click:Connect(function()
	waypoints = {}
	currentWaypointIndex = 1
	isLoopingWaypoints = false
	loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	loopWpBtn.Text = "Dungeon: OFF"
	wpSavedLabel.Text = "Rooms Saved: 0"
	targetLabel.Text = "Rooms Cleared"
end)

loopWpBtn.MouseButton1Click:Connect(function()
	if #waypoints == 0 then
		targetLabel.Text = "No Dungeon Rooms Saved!"
		return
	end
	isLoopingWaypoints = not isLoopingWaypoints
	if isLoopingWaypoints then
		isTrackingAll = false
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Fly to All Mobs: OFF"
		
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		loopWpBtn.Text = "Dungeon: ON"
		currentWaypointIndex = 1
	else
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		loopWpBtn.Text = "Dungeon: OFF"
	end
end)

toggleButton.MouseButton1Click:Connect(function()
	isTrackingAll = not isTrackingAll
	if isTrackingAll then
		isLoopingWaypoints = false
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		loopWpBtn.Text = "Dungeon: OFF"
		
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		toggleButton.Text = "Fly to All Mobs: ON"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Fly to All Mobs: OFF"
	end
end)

-- Waypoint Import handler (Parses pasted Vector3 coordinates or JSON-like arrays)
importBox.FocusLost:Connect(function()
	local text = importBox.Text
	if text == "" then return end
	
	-- Simple pattern matching for Vector3 coordinates e.g., Vector3.new(x, y, z) or x, y, z
	for x, y, z in string.gmatch(text, "([%-?%d%.]+)%s*,%s*([%-?%d%.]+)%s*,%s*([%-?%d%.]+)") do
		local numX, numY, numZ = tonumber(x), tonumber(y), tonumber(z)
		if numX and numY and numZ then
			table.insert(waypoints, Vector3.new(numX, numY, numZ))
		end
	end
	
	wpSavedLabel.Text = "Rooms Saved: " .. #waypoints
	importBox.Text = ""
	targetLabel.Text = "Imported Rooms Successfully!"
end)

-- Main loop
RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	
	if not aggressorsFolder or not aggressorsFolder.Parent then
		local live = workspace:FindFirstChild("Animal_Live")
		if live then aggressorsFolder = live:FindFirstChild("Aggressors") end
	end
	
	local detectedCount = 0
	local targetPos = nil
	local targetName = "None"
	local shortestDist = math.huge
	
	if myHrp and aggressorsFolder then
		for _, monster in ipairs(aggressorsFolder:GetChildren()) do
			if monster:IsA("Model") then
				local hrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
				if hrp then
					local dist = (myHrp.Position - hrp.Position).Magnitude
					if dist <= CONFIG.DetectionRadius then
						detectedCount += 1
						local animalName = getAnimalName(monster)
						
						if isTrackingAll then
							if dist < shortestDist then
								shortestDist = dist
								targetPos = hrp.Position + Vector3.new(0, 2, 0)
								targetName = animalName .. " (" .. math.floor(dist) .. "m)"
							end
						end
					end
				end
			end
		end
	end
	
	-- Handle Dungeon Room Waypoint Looping logic
	if isLoopingWaypoints and #waypoints > 0 and myHrp then
		local currentWp = waypoints[currentWaypointIndex]
		targetPos = currentWp + Vector3.new(0, 2, 0)
		local wpDist = (myHrp.Position - currentWp).Magnitude
		targetName = "Room " .. currentWaypointIndex .. "/" .. #waypoints .. " (" .. math.floor(wpDist) .. "m)"
		
		if wpDist <= (CONFIG.StopDistance + 2) then
			currentWaypointIndex += 1
			if currentWaypointIndex > #waypoints then
				currentWaypointIndex = 1 -- Loop back to room 1
			end
		end
	end
	
	countLabel.Text = "Mobs Detected: " + detectedCount -- (Fixed string display below)
	countLabel.Text = "Mobs Detected: " .. detectedCount
	if (isTrackingAll or isLoopingWaypoints) and targetName ~= "None" then
		targetLabel.Text = "Target: " .. targetName
	else
		targetLabel.Text = "Target: None"
	end
	
	-- Flight execution
	if (isTrackingAll or isLoopingWaypoints) and targetPos and myHrp and humanoid then
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
