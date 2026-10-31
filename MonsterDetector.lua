local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================= CONFIGURABLE SETTINGS =================
local CONFIG = {
	FlightSpeed = 50,
	DetectionRadius = 1000, -- Large radius to find doors/gates across the map
	StopDistance = 2
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
-- ========================================================

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PrefixTargeterGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Ultra-Compact Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 245)
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
titleLabel.Text = "Prefix Targeter v2.0"
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

-- Status Dashboard Frame
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -16, 0, 52)
statusFrame.Position = UDim2.new(0, 8, 0, 35)
statusFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = statusFrame

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -8, 0, 20)
targetLabel.Position = UDim2.new(0, 4, 0, 4)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target Match: None"
targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
targetLabel.TextSize = 11
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = statusFrame

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -8, 0, 20)
countLabel.Position = UDim2.new(0, 4, 0, 26)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Matches Found: 0"
countLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
countLabel.TextSize = 11
countLabel.Font = Enum.Font.SourceSansBold
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = statusFrame

-- Manual Prefix Box & Fly Toggle Row
local prefixBox = Instance.new("TextBox")
prefixBox.Size = UDim2.new(0, 130, 0, 28)
prefixBox.Position = UDim2.new(0, 8, 0, 95)
prefixBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
prefixBox.PlaceholderText = "Type door/gate prefix..."
prefixBox.Text = ""
prefixBox.TextColor3 = Color3.fromRGB(255, 255, 255)
prefixBox.TextSize = 11
prefixBox.Font = Enum.Font.SourceSans
prefixBox.Parent = mainFrame

local prefixCorner = Instance.new("UICorner")
prefixCorner.CornerRadius = UDim.new(0, 4)
prefixCorner.Parent = prefixBox

local prefixToggleBtn = Instance.new("TextButton")
prefixToggleBtn.Size = UDim2.new(0, 86, 0, 28)
prefixToggleBtn.Position = UDim2.new(0, 142, 0, 95)
prefixToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
prefixToggleBtn.Text = "Fly to Prefix: OFF"
prefixToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prefixToggleBtn.TextSize = 10
prefixToggleBtn.Font = Enum.Font.SourceSansBold
prefixToggleBtn.Parent = mainFrame

local pBtnCorner = Instance.new("UICorner")
pBtnCorner.CornerRadius = UDim.new(0, 4)
pBtnCorner.Parent = prefixToggleBtn

-- Config Row (Speed, Radius, Stop Dist)
local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0, 72, 0, 24)
speedInput.Position = UDim2.new(0, 8, 0, 133)
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
radiusInput.Position = UDim2.new(0, 84, 0, 133)
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
stopInput.Position = UDim2.new(0, 160, 0, 133)
stopInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
stopInput.Text = tostring(CONFIG.StopDistance)
stopInput.PlaceholderText = "Stop"
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

-- Quick Teleport / Instant Pass Button
local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(1, -16, 0, 28)
teleportBtn.Position = UDim2.new(0, 8, 0, 168)
teleportBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 180)
teleportBtn.Text = "Instant TP Through Match"
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.TextSize = 11
teleportBtn.Font = Enum.Font.SourceSansBold
teleportBtn.Parent = mainFrame

local tpCorner = Instance.new("UICorner")
tpCorner.CornerRadius = UDim.new(0, 5)
tpCorner.Parent = teleportBtn

-- State variables
local isTrackingPrefix = false
local isMinimized = false

minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 240, 0, 36)
		statusFrame.Visible = false
		prefixBox.Visible = false
		prefixToggleBtn.Visible = false
		speedInput.Visible = false
		radiusInput.Visible = false
		stopInput.Visible = false
		teleportBtn.Visible = false
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 240, 0, 210)
		statusFrame.Visible = true
		prefixBox.Visible = true
		prefixToggleBtn.Visible = true
		speedInput.Visible = true
		radiusInput.Visible = true
		stopInput.Visible = true
		teleportBtn.Visible = true
		minimizeButton.Text = "-"
	end
end)

prefixToggleBtn.MouseButton1Click:Connect(function()
	if prefixBox.Text == "" then return end
	isTrackingPrefix = not isTrackingPrefix
	if isTrackingPrefix then
		prefixToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		prefixToggleBtn.Text = "Fly to Prefix: ON"
	else
		prefixToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		prefixToggleBtn.Text = "Fly to Prefix: OFF"
	end
end)

-- Function to find best matching part in workspace by prefix
local function findMatchingTarget()
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	if not myHrp or prefixBox.Text == "" then return nil, "None", 0 end
	
	local prefix = prefixBox.Text:lower()
	local bestPart = nil
	local bestName = "None"
	local shortestDist = math.huge
	local matchCount = 0
	
	-- Scan all descendants in workspace to catch parts, models, doors, or gates anywhere
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Model") then
			local objName = obj.Name:lower()
			if string.sub(objName, 1, string.len(prefix)) == prefix or string.find(objName, prefix) then
				local partPos = nil
				if obj:IsA("BasePart") then
					partPos = obj.Position
				elseif obj.PrimaryPart then
					partPos = obj.PrimaryPart.Position
				else
					local p = obj:FindFirstChildWhichIsA("BasePart")
					if p then partPos = p.Position end
				end
				
				if partPos then
					local dist = (myHrp.Position - partPos).Magnitude
					if dist <= CONFIG.DetectionRadius then
						matchCount += 1
						if dist < shortestDist then
							shortestDist = dist
							if obj:IsA("BasePart") then
								bestPart = obj
							else
								bestPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
							end
							bestName = obj.Name .. " (" .. math.floor(dist) .. "m)"
						end
					end
				end
			end
		end
	end
	
	return bestPart, bestName, matchCount
end

-- Instant Teleport Button action (useful for passing straight through locked gates/doors instantly)
teleportBtn.MouseButton1Click:Connect(function()
	local targetPart, _, _ = findMatchingTarget()
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	if targetPart and myHrp then
		myHrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
	end
end)

-- Main loop scanning workspace for prefix matches
RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local myHrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	
	local targetPart, targetName, matchCount = findMatchingTarget()
	
	countLabel.Text = "Matches Found: " .. matchCount
	if isTrackingPrefix and targetPart then
		targetLabel.Text = "Match: " .. targetName
	else
		targetLabel.Text = "Target Match: None"
	end
	
	-- Flight execution towards prefix match
	if isTrackingPrefix and targetPart and myHrp and humanoid then
		humanoid.PlatformStand = true
		local targetPos = targetPart.Position + Vector3.new(0, 2, 0)
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
