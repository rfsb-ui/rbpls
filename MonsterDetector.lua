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

-- Helper function to fetch the Animal type name
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

-- Main Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 420)
mainFrame.Position = UDim2.new(0, 30, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title Label with Version Control (v1.6)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -75, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aggressor Targeter v1.6"
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

-- Dropdown Main Button (Shows selected monster type)
local dropdownButton = Instance.new("TextButton")
dropdownButton.Size = UDim2.new(1, -20, 0, 35)
dropdownButton.Position = UDim2.new(0, 10, 0, 45)
dropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropdownButton.Text = "Select Monster Type ▼"
dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownButton.TextSize = 13
dropdownButton.Font = Enum.Font.SourceSansBold
dropdownButton.Parent = mainFrame

local dropCorner = Instance.new("UICorner")
dropCorner.CornerRadius = UDim.new(0, 6)
dropCorner.Parent = dropdownButton

-- Dropdown Scrolling Frame (Hidden by default)
local dropdownScroll = Instance.new("ScrollingFrame")
dropdownScroll.Size = UDim2.new(1, -20, 0, 120)
dropdownScroll.Position = UDim2.new(0, 10, 0, 82)
dropdownScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropdownScroll.BorderSizePixel = 0
dropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownScroll.ScrollBarThickness = 6
dropdownScroll.Visible = false
dropdownScroll.ZIndex = 5
dropdownScroll.Parent = mainFrame

local dropListLayout = Instance.new("UIListLayout")
dropListLayout.Parent = dropdownScroll
dropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropListLayout.Padding = UDim.new(0, 4)

-- Main Flight Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 35)
toggleButton.Position = UDim2.new(0, 10, 0, 175)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleButton.Text = "Fly to Target: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 215)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Target Type: None"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = mainFrame

-- Live Input Container: Speed
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 110, 0, 25)
speedLabel.Position = UDim2.new(0, 10, 0, 255)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Flight Speed:"
speedLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.SourceSansBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0, 110, 0, 25)
speedInput.Position = UDim2.new(0, 130, 0, 255)
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
	if val then CONFIG.FlightSpeed = val; saveSettings() else speedInput.Text = tostring(CONFIG.FlightSpeed) end
end)

-- Live Input Container: Radius
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0, 110, 0, 25)
radiusLabel.Position = UDim2.new(0, 10, 0, 290)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Detection Radius:"
radiusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
radiusLabel.TextSize = 12
radiusLabel.Font = Enum.Font.SourceSansBold
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = mainFrame

local radiusInput = Instance.new("TextBox")
radiusInput.Size = UDim2.new(0, 110, 0, 25)
radiusInput.Position = UDim2.new(0, 130, 0, 290)
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
	if val then CONFIG.DetectionRadius = val; saveSettings() else radiusInput.Text = tostring(CONFIG.DetectionRadius) end
end)

-- Live Input Container: Stop Distance
local stopDistLabel = Instance.new("TextLabel")
stopDistLabel.Size = UDim2.new(0, 110, 0, 25)
stopDistLabel.Position = UDim2.new(0, 10, 0, 325)
stopDistLabel.BackgroundTransparency = 1
stopDistLabel.Text = "Stop Distance:"
stopDistLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
stopDistLabel.TextSize = 12
stopDistLabel.Font = Enum.Font.SourceSansBold
stopDistLabel.TextXAlignment = Enum.TextXAlignment.Left
stopDistLabel.Parent = mainFrame

local stopDistInput = Instance.new("TextBox")
stopDistInput.Size = UDim2.new(0, 110, 0, 25)
stopDistInput.Position = UDim2.new(0, 130, 0, 325)
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
	if val then CONFIG.StopDistance = val; saveSettings() else stopDistInput.Text = tostring(CONFIG.StopDistance) end
end)

-- State variables
local selectedMonsterType = nil
local isTracking = false
local isMinimized = false

-- Dropdown toggle open/close
dropdownButton.MouseButton1Click:Connect(function()
	dropdownScroll.Visible = not dropdownScroll.Visible
end)

-- Minimize toggle logic
minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	dropdownScroll.Visible = false
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 260, 0, 45)
		dropdownButton.Visible = false
		toggleButton.Visible = false
		statusLabel.Visible = false
		speedLabel.Visible = false
		speedInput.Visible = false
		radiusLabel.Visible = false
		radiusInput.Visible = false
		stopDistLabel.Visible = false
		stopDistInput.Visible = false
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 260, 0, 420)
		dropdownButton.Visible = true
		toggleButton.Visible = true
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

-- Function to refresh dropdown list with 1 record per unique monster type
local function refreshDropdownList()
	if isMinimized then return end
	
	for _, child in ipairs(dropdownScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local uniqueTypes = {}
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	
	for _, monster in ipairs(aggressorsFolder:GetChildren()) do
		if monster:IsA("Model") then
			local hrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
			if hrp and myHrp then
				local dist = (myHrp.Position - hrp.Position).Magnitude
				if dist <= CONFIG.DetectionRadius then
					local animalName = getAnimalName(monster)
					if not uniqueTypes[animalName] then
						uniqueTypes[animalName] = true
					end
				end
			end
		end
	end
	
	local count = 0
	for animalName, _ in pairs(uniqueTypes) do
		count += 1
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 28)
		btn.BackgroundColor3 = (selectedMonsterType == animalName) and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(60, 60, 60)
		btn.Text = animalName
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 13
		btn.Font = Enum.Font.SourceSans
		btn.ZIndex = 6
		btn.Parent = dropdownScroll
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = btn
		
		btn.MouseButton1Click:Connect(function()
			selectedMonsterType = animalName
			dropdownButton.Text = "Type: " .. animalName .. " ▼"
			statusLabel.Text = "Target Type: " .. animalName
			dropdownScroll.Visible = false
		end)
	end
	
	dropdownScroll.CanvasSize = UDim2.new(0, 0, 0, count * 32)
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

-- Main tracking and list update loop
RunService.Heartbeat:Connect(function(dt)
	local timeIndex = tick()
	if math.floor(timeIndex * 2) % 2 == 0 then
		refreshDropdownList()
	end
	
	if isTracking and selectedMonsterType then
		local char = player.Character
		local myHrp = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		
		if myHrp and humanoid then
			-- Find the nearest active monster matching the selected type
			local nearestTarget = nil
			local shortestDist = math.huge
			
			for _, monster in ipairs(aggressorsFolder:GetChildren()) do
				if monster:IsA("Model") then
					local hrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
					if hrp then
						local animalName = getAnimalName(monster)
						if animalName == selectedMonsterType then
							local dist = (myHrp.Position - hrp.Position).Magnitude
							if dist < shortestDist then
								shortestDist = dist
								nearestTarget = hrp
							end
						end
					end
				end
			end
			
			if nearestTarget then
				humanoid.PlatformStand = true
				local targetPos = nearestTarget.Position + Vector3.new(0, 2, 0)
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
		end
	else
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.PlatformStand then
			humanoid.PlatformStand = false
		end
	end
end)
