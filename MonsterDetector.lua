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
	if _G.TargeterSettings then
		CONFIG.FlightSpeed = _G.TargeterSettings.FlightSpeed or CONFIG.FlightSpeed
		CONFIG.DetectionRadius = _G.TargeterSettings.DetectionRadius or CONFIG.DetectionRadius
		CONFIG.StopDistance = _G.TargeterSettings.StopDistance or CONFIG.StopDistance
	end
end)

local function saveSettings()
	_G.TargeterSettings = {
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

-- Waypoint variables
local waypoints = {}
local currentWaypointIndex = 1
local isLoopingWaypoints = false

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonsterTargeterGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Compact Panel (Slightly taller to fit waypoint controls)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 340)
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
titleLabel.Text = "Aggressor Targeter v2.1"
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
statusFrame.Size = UDim2.new(1, -16, 0, 55)
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
countLabel.Position = UDim2.new(0, 4, 0, 22)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Mobs Detected: 0"
countLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
countLabel.TextSize = 11
countLabel.Font = Enum.Font.SourceSansBold
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = statusFrame

-- Main Fly to All Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -16, 0, 28)
toggleButton.Position = UDim2.new(0, 8, 0, 96)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleButton.Text = "Fly to All Mobs: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 12
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 5)
btnCorner.Parent = toggleButton

-- Manual Prefix Function Box Container
local prefixBox = Instance.new("TextBox")
prefixBox.Size = UDim2.new(0, 130, 0, 26)
prefixBox.Position = UDim2.new(0, 8, 0, 132)
prefixBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
prefixBox.PlaceholderText = "Enter Name Prefix"
prefixBox.Text = ""
prefixBox.TextColor3 = Color3.fromRGB(255, 255, 255)
prefixBox.TextSize = 11
prefixBox.Font = Enum.Font.SourceSans
prefixBox.Parent = mainFrame

local prefixCorner = Instance.new("UICorner")
prefixCorner.CornerRadius = UDim.new(0, 4)
prefixCorner.Parent = prefixBox

local prefixToggleBtn = Instance.new("TextButton")
prefixToggleBtn.Size = UDim2.new(0, 86, 0, 26)
prefixToggleBtn.Position = UDim2.new(0, 142, 0, 132)
prefixToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
prefixToggleBtn.Text = "Fly Prefix: OFF"
prefixToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prefixToggleBtn.TextSize = 11
prefixToggleBtn.Font = Enum.Font.SourceSansBold
prefixToggleBtn.Parent = mainFrame

local pBtnCorner = Instance.new("UICorner")
pBtnCorner.CornerRadius = UDim.new(0, 4)
pBtnCorner.Parent = prefixToggleBtn

-- Waypoint Controls Row
local saveWpBtn = Instance.new("TextButton")
saveWpBtn.Size = UDim2.new(0, 72, 0, 26)
saveWpBtn.Position = UDim2.new(0, 8, 0, 168)
saveWpBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
saveWpBtn.Text = "Save WP"
saveWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveWpBtn.TextSize = 11
saveWpBtn.Font = Enum.Font.SourceSansBold
saveWpBtn.Parent = mainFrame

local swpCorner = Instance.new("UICorner")
swpCorner.CornerRadius = UDim.new(0, 4)
swpCorner.Parent = saveWpBtn

local clearWpBtn = Instance.new("TextButton")
clearWpBtn.Size = UDim2.new(0, 72, 0, 26)
clearWpBtn.Position = UDim2.new(0, 84, 0, 168)
clearWpBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
clearWpBtn.Text = "Clear WPs"
clearWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearWpBtn.TextSize = 11
clearWpBtn.Font = Enum.Font.SourceSansBold
clearWpBtn.Parent = mainFrame

local cwpCorner = Instance.new("UICorner")
cwpCorner.CornerRadius = UDim.new(0, 4)
cwpCorner.Parent = clearWpBtn

local loopWpBtn = Instance.new("TextButton")
loopWpBtn.Size = UDim2.new(0, 72, 0, 26)
loopWpBtn.Position = UDim2.new(0, 160, 0, 168)
loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
loopWpBtn.Text = "Loop: OFF"
loopWpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopWpBtn.TextSize = 10
loopWpBtn.Font = Enum.Font.SourceSansBold
loopWpBtn.Parent = mainFrame

local lwpCorner = Instance.new("UICorner")
lwpCorner.CornerRadius = UDim.new(0, 4)
lwpCorner.Parent = loopWpBtn

-- Compact Config Inputs (Speed, Radius, Stop Dist)
local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0, 72, 0, 24)
speedInput.Position = UDim2.new(0, 8, 0, 204)
speedInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
speedInput.Text = tostring(CONFIG.FlightSpeed)
speedInput.PlaceholderText = "Speed"
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.TextSize = 11
speedInput.Font = Enum.Font.SourceSans
speedInput.Parent = mainFrame

local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 4)
sCorner.Parent = speedInput

speedInput.FocusLost:Connect(function()
	local val = tonumber(speedInput.Text)
	if val then CONFIG.FlightSpeed = val; saveSettings() else speedInput.Text = tostring(CONFIG.FlightSpeed) end
end)

local radiusInput = Instance.new("TextBox")
radiusInput.Size = UDim2.new(0, 72, 0, 24)
radiusInput.Position = UDim2.new(0, 84, 0, 204)
radiusInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
radiusInput.Text = tostring(CONFIG.DetectionRadius)
radiusInput.PlaceholderText = "Radius"
radiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusInput.TextSize = 11
radiusInput.Font = Enum.Font.SourceSans
radiusInput.Parent = mainFrame

local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(0, 4)
rCorner.Parent = radiusInput

radiusInput.FocusLost:Connect(function()
	local val = tonumber(radiusInput.Text)
	if val then CONFIG.DetectionRadius = val; saveSettings() else radiusInput.Text = tostring(CONFIG.DetectionRadius) end
end)

local stopInput = Instance.new("TextBox")
stopInput.Size = UDim2.new(0, 72, 0, 24)
stopInput.Position = UDim2.new(0, 160, 0, 204)
stopInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
stopInput.Text = tostring(CONFIG.StopDistance)
stopInput.PlaceholderText = "Stop Dist"
stopInput.TextColor3 = Color3.fromRGB(255, 255, 255)
stopInput.TextSize = 11
stopInput.Font = Enum.Font.SourceSans
stopInput.Parent = mainFrame

local stCorner = Instance.new("UICorner")
stCorner.CornerRadius = UDim.new(0, 4)
stCorner.Parent = stopInput

stopInput.FocusLost:Connect(function()
	local val = tonumber(stopInput.Text)
	if val then CONFIG.StopDistance = val; saveSettings() else stopInput.Text = tostring(CONFIG.StopDistance) end
end)

-- State variables
local isTrackingAll = false
local isTrackingPrefix = false
local isMinimized = false

minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 240, 0, 36)
		statusFrame.Visible = false
		toggleButton.Visible = false
		prefixBox.Visible = false
		prefixToggleBtn.Visible = false
		saveWpBtn.Visible = false
		clearWpBtn.Visible = false
		loopWpBtn.Visible = false
		speedInput.Visible = false
		radiusInput.Visible = false
		stopInput.Visible = false
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 240, 0, 340)
		statusFrame.Visible = true
		toggleButton.Visible = true
		prefixBox.Visible = true
		prefixToggleBtn.Visible = true
		saveWpBtn.Visible = true
		clearWpBtn.Visible = true
		loopWpBtn.Visible = true
		speedInput.Visible = true
		radiusInput.Visible = true
		stopInput.Visible = true
		minimizeButton.Text = "-"
	end
end)

-- Waypoint button handlers
saveWpBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	if myHrp then
		table.insert(waypoints, myHrp.Position)
		targetLabel.Text = "WP Saved! Total: " .. #waypoints
	end
end)

clearWpBtn.MouseButton1Click:Connect(function()
	waypoints = {}
	currentWaypointIndex = 1
	isLoopingWaypoints = false
	loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	loopWpBtn.Text = "Loop: OFF"
	targetLabel.Text = "Waypoints Cleared"
end)

loopWpBtn.MouseButton1Click:Connect(function()
	if #waypoints == 0 then
		targetLabel.Text = "No Waypoints Saved!"
		return
	end
	isLoopingWaypoints = not isLoopingWaypoints
	if isLoopingWaypoints then
		isTrackingAll = false
		isTrackingPrefix = false
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Fly to All Mobs: OFF"
		prefixToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		prefixToggleBtn.Text = "Fly Prefix: OFF"
		
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		loopWpBtn.Text = "Loop: ON"
		currentWaypointIndex = 1
	else
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		loopWpBtn.Text = "Loop: OFF"
	end
end)

toggleButton.MouseButton1Click:Connect(function()
	isTrackingAll = not isTrackingAll
	if isTrackingAll then
		isTrackingPrefix = false
		isLoopingWaypoints = false
		prefixToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		prefixToggleBtn.Text = "Fly Prefix: OFF"
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		loopWpBtn.Text = "Loop: OFF"
		
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		toggleButton.Text = "Fly to All Mobs: ON"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Fly to All Mobs: OFF"
	end
end)

prefixToggleBtn.MouseButton1Click:Connect(function()
	if prefixBox.Text == "" then return end
	isTrackingPrefix = not isTrackingPrefix
	if isTrackingPrefix then
		isTrackingAll = false
		isLoopingWaypoints = false
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Fly to All Mobs: OFF"
		loopWpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		loopWpBtn.Text = "Loop: OFF"
		
		prefixToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		prefixToggleBtn.Text = "Fly Prefix: ON"
	else
		prefixToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		prefixToggleBtn.Text = "Fly Prefix: OFF"
	end
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
						elseif isTrackingPrefix and prefixBox.Text ~= "" then
							local prefix = prefixBox.Text:lower()
							if string.sub(animalName:lower(), 1, string.len(prefix)) == prefix or string.find(animalName:lower(), prefix) then
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
	end
	
	-- Handle Waypoint Looping logic
	if isLoopingWaypoints and #waypoints > 0 and myHrp then
		local currentWp = waypoints[currentWaypointIndex]
		targetPos = currentWp + Vector3.new(0, 2, 0)
		local wpDist = (myHrp.Position - currentWp).Magnitude
		targetName = "WP " .. currentWaypointIndex .. "/" .. #waypoints .. " (" .. math.floor(wpDist) .. "m)"
		
		if wpDist <= (CONFIG.StopDistance + 2) then
			currentWaypointIndex += 1
			if currentWaypointIndex > #waypoints then
				currentWaypointIndex = 1 -- Loop back to start
			end
		end
	end
	
	countLabel.Text = "Mobs Detected: " .. detectedCount
	if (isTrackingAll or isTrackingPrefix or isLoopingWaypoints) and targetName ~= "None" then
		targetLabel.Text = "Target: " .. targetName
	else
		targetLabel.Text = "Target: None"
	end
	
	-- Flight execution
	if (isTrackingAll or isTrackingPrefix or isLoopingWaypoints) and targetPos and myHrp and humanoid then
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
