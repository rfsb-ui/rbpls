local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Safely wait for the nested folder structure
local animalLive = workspace:WaitForChild("Animal_Live", 10)
if not animalLive then
	warn("Animal_Live folder not found in workspace!")
	return
end

local aggressorsFolder = animalLive:WaitForChild("Aggressors", 10)
if not aggressorsFolder then
	warn("Aggressors folder not found inside Animal_Live!")
	return
end

-- ================= CONFIGURABLE SETTINGS (WITH PERSISTENCE) =================
local CONFIG = {
	FlightSpeed = 50,
	DetectionRadius = 100,
	StopDistance = 4
}

-- Load saved settings if available
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

-- Helper function to fetch the Animal name property or fallback to model name
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

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonsterTargeterGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Panel (Expanded height to fit new stop distance input)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 460)
mainFrame.Position = UDim2.new(0, 30, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title Label with Version Control (v1.5)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -75, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aggressor Targeter v1.5"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

-- Close (X) Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Minimize (-) Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -70, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 16
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeButton

-- Scrolling Frame for Monster List
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 0, 140)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = scrollFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 4)

-- Main Flight Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 35)
toggleButton.Position = UDim2.new(0, 10, 0, 195)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleButton.Text = "Fly to Target: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

-- Continuous Auto-Target Checkbox Toggle
local autoToggle = Instance.new("TextButton")
autoToggle.Size = UDim2.new(1, -20, 0, 30)
autoToggle.Position = UDim2.new(0, 10, 0, 235)
autoToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
autoToggle.Text = "Auto-Track Nearest: OFF"
autoToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
autoToggle.TextSize = 13
autoToggle.Font = Enum.Font.SourceSansBold
autoToggle.Parent = mainFrame

local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 6)
autoCorner.Parent = autoToggle

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 270)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Selected: None"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = mainFrame

-- Live Input Container: Speed
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 110, 0, 25)
speedLabel.Position = UDim2.new(0, 10, 0, 305)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Flight Speed:"
speedLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.SourceSansBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0, 110, 0, 25)
speedInput.Position = UDim2.new(0, 130, 0, 305)
speedInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedInput.Text = tostring(CONFIG.FlightSpeed)
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.TextSize = 12
speedInput.Font = Enum.Font.SourceSans
speedInput.Parent = mainFrame

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 4)
speedCorner.Parent = speedInput

speedInput.FocusLost:Connect(function()
	local val = tonumber(speedInput.Text)
	if val then
		CONFIG.FlightSpeed = val
		saveSettings()
	else
		speedInput.Text = tostring(CONFIG.FlightSpeed)
	end
end)

-- Live Input Container: Radius
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0, 110, 0, 25)
radiusLabel.Position = UDim2.new(0, 10, 0, 340)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Detection Radius:"
radiusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
radiusLabel.TextSize = 12
radiusLabel.Font = Enum.Font.SourceSansBold
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = mainFrame

local radiusInput = Instance.new("TextBox")
radiusInput.Size = UDim2.new(0, 110, 0, 25)
radiusInput.Position = UDim2.new(0, 130, 0, 340)
radiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
radiusInput.Text = tostring(CONFIG.DetectionRadius)
radiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusInput.TextSize = 12
radiusInput.Font = Enum.Font.SourceSans
radiusInput.Parent = mainFrame

local radiusCorner = Instance.new("UICorner")
radiusCorner.CornerRadius = UDim.new(0, 4)
radiusCorner.Parent = radiusInput

radiusInput.FocusLost:Connect(function()
	local val = tonumber(radiusInput.Text)
	if val then
		CONFIG.DetectionRadius = val
		saveSettings()
	else
		radiusInput.Text = tostring(CONFIG.DetectionRadius)
	end
end)

-- Live Input Container: Stop Distance
local stopDistLabel = Instance.new("TextLabel")
stopDistLabel.Size = UDim2.new(0, 110, 0, 25)
stopDistLabel.Position = UDim2.new(0, 10, 0, 375)
stopDistLabel.BackgroundTransparency = 1
stopDistLabel.Text = "Stop Distance:"
stopDistLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
stopDistLabel.TextSize = 12
stopDistLabel.Font = Enum.Font.SourceSansBold
stopDistLabel.TextXAlignment = Enum.TextXAlignment.Left
stopDistLabel.Parent = mainFrame

local stopDistInput = Instance.new("TextBox")
stopDistInput.Size = UDim2.new(0, 110, 0, 25)
stopDistInput.Position = UDim2.new(0, 130, 0, 375)
stopDistInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
stopDistInput.Text = tostring(CONFIG.StopDistance)
stopDistInput.TextColor3 = Color3.fromRGB(255, 255, 255)
stopDistInput.TextSize = 12
stopDistInput.Font = Enum.Font.SourceSans
stopDistInput.Parent = mainFrame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 4)
stopCorner.Parent = stopDistInput

stopDistInput.FocusLost:Connect(function()
	local val = tonumber(stopDistInput.Text)
	if val then
		CONFIG.StopDistance = val
		saveSettings()
	else
		stopDistInput.Text = tostring(CONFIG.StopDistance)
	end
end)

-- State variables
local selectedMonster = nil
local isTracking = false
local isAutoTracking = false
local isMinimized = false

-- Minimize toggle logic
minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 260, 0, 45)
		scrollFrame.Visible = false
		toggleButton.Visible = false
		autoToggle.Visible = false
		statusLabel.Visible = false
		speedLabel.Visible = false
		speedInput.Visible = false
		radiusLabel.Visible = false
		radiusInput.Visible = false
		stopDistLabel.Visible = false
		stopDistInput.Visible = false
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 260, 0, 460)
		scrollFrame.Visible = true
		toggleButton.Visible = true
		autoToggle.Visible = true
		statusLabel.Visible = true
		speedLabel.Visible = true
		speedInput.Visible = true
		radiusLabel.Visible = true
		radiusInput.Visible = true
		stopDistLabel.Visible = true
		stopDistInput.Visible = true
		minimizeButton.Text = "-"
	end
end)

-- Auto-Track toggle handler
autoToggle.MouseButton1Click:Connect(function()
	isAutoTracking = not isAutoTracking
	if isAutoTracking then
		autoToggle.BackgroundColor3 = Color3.fromRGB(50, 140, 180)
		autoToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
		autoToggle.Text = "Auto-Track Nearest: ON"
	else
		autoToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		autoToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
		autoToggle.Text = "Auto-Track Nearest: OFF"
	end
end)

-- Function to refresh list and handle auto-targeting
local function refreshMonsterList()
	if isMinimized then return end
	
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local count = 0
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	
	local nearestMonster = nil
	local shortestDist = math.huge
	
	for _, monster in ipairs(aggressorsFolder:GetChildren()) do
		if monster:IsA("Model") then
			local hrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
			
			if hrp and myHrp then
				local dist = math.floor((myHrp.Position - hrp.Position).Magnitude)
				
				if dist <= CONFIG.DetectionRadius then
					count += 1
					local animalName = getAnimalName(monster)
					
					if dist < shortestDist then
						shortestDist = dist
						nearestMonster = monster
					end
					
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, -10, 0, 30)
					btn.BackgroundColor3 = (selectedMonster == monster) and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(60, 60, 60)
					btn.Text = animalName .. " (" .. dist .. "m)"
					btn.TextColor3 = Color3.fromRGB(255, 255, 255)
					btn.TextSize = 13
					btn.Font = Enum.Font.SourceSans
					btn.Parent = scrollFrame
					
					local btnUiCorner = Instance.new("UICorner")
					btnUiCorner.CornerRadius = UDim.new(0, 4)
					btnUiCorner.Parent = btn
					
					btn.MouseButton1Click:Connect(function()
						selectedMonster = monster
						isAutoTracking = false -- Disable auto-track when manually clicking a target
						autoToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
						autoToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
						autoToggle.Text = "Auto-Track Nearest: OFF"
						statusLabel.Text = "Selected: " .. animalName
					end)
				end
			end
		end
	end
	
	if isAutoTracking and nearestMonster then
		selectedMonster = nearestMonster
		statusLabel.Text = "Auto-Target: " .. getAnimalName(nearestMonster)
	end
	
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 34)
end

-- Toggle button click handler
toggleButton.MouseButton1Click:Connect(function()
	isTracking = not isTracking
	if isTracking then
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		toggleButton.Text = "Fly to Target: ON"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Fly to Target: OFF"
	end
end)

-- Flight physics loop
RunService.Heartbeat:Connect(function(dt)
	local timeIndex = tick()
	if math.floor(timeIndex * 2) % 2 == 0 then
		refreshMonsterList()
	end
	
	if isTracking and selectedMonster then
		if selectedMonster.Parent then
			local hrp = selectedMonster:FindFirstChild("HumanoidRootPart") or selectedMonster.PrimaryPart
			local char = player.Character
			local myHrp = char and char:FindFirstChild("HumanoidRootPart")
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			
			if hrp and myHrp and humanoid then
				humanoid.PlatformStand = true
				
				local targetPos = hrp.Position + Vector3.new(0, 2, 0)
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
			end
		else
			selectedMonster = nil
			statusLabel.Text = "Selected: None (Target Lost)"
		end
	else
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.PlatformStand then
			humanoid.PlatformStand = false
		end
	end
end)
