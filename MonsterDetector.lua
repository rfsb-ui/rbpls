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

-- ================= CONFIGURABLE SETTINGS =================
local CONFIG = {
	FlightSpeed = 50,         -- Speed at which the player flies toward the target (higher = faster)
	DetectionRadius = 100,    -- Maximum stud distance to scan and list monsters
	StopDistance = 4          -- How close to get before stopping on the target
}
-- ========================================================

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonsterTargeterGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 360)
mainFrame.Position = UDim2.new(0, 30, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title Label with Version Control (v1.3)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -75, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aggressor Targeter v1.3"
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
scrollFrame.Size = UDim2.new(1, -20, 0, 160)
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

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 215)
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
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 260)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Selected: None"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = mainFrame

-- Settings indicator
local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1, -20, 0, 30)
settingsLabel.Position = UDim2.new(0, 10, 0, 290)
settingsLabel.BackgroundTransparency = 1
settingsLabel.Text = "Radius: " .. CONFIG.DetectionRadius .. "m | Speed: " .. CONFIG.FlightSpeed
settingsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
settingsLabel.TextSize = 11
settingsLabel.Font = Enum.Font.SourceSans
settingsLabel.Parent = mainFrame

-- State variables
local selectedMonster = nil
local isTracking = false
local isMinimized = false

-- Minimize toggle logic
minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 260, 0, 45)
		scrollFrame.Visible = false
		toggleButton.Visible = false
		statusLabel.Visible = false
		settingsLabel.Visible = false
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 260, 0, 360)
		scrollFrame.Visible = true
		toggleButton.Visible = true
		statusLabel.Visible = true
		settingsLabel.Visible = true
		minimizeButton.Text = "-"
	end
end)

-- Function to refresh the list of monsters within the configurable radius
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
	
	for _, monster in ipairs(aggressorsFolder:GetChildren()) do
		if monster:IsA("Model") then
			local hrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
			
			if hrp and myHrp then
				local dist = math.floor((myHrp.Position - hrp.Position).Magnitude)
				
				-- Only display if within configured detection radius
				if dist <= CONFIG.DetectionRadius then
					count += 1
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, -10, 0, 30)
					btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					btn.Text = monster.Name .. " (" .. dist .. "m)"
					btn.TextColor3 = Color3.fromRGB(255, 255, 255)
					btn.TextSize = 13
					btn.Font = Enum.Font.SourceSans
					btn.Parent = scrollFrame
					
					local btnUiCorner = Instance.new("UICorner")
					btnUiCorner.CornerRadius = UDim.new(0, 4)
					btnUiCorner.Parent = btn
					
					btn.MouseButton1Click:Connect(function()
						selectedMonster = monster
						statusLabel.Text = "Selected: " .. monster.Name
					end)
				end
			end
		end
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

-- Flight and list refresh loop running smoothly on Heartbeat / RenderStepped
RunService.Heartbeat:Connect(function(dt)
	-- Periodically refresh list items
	local timeIndex = tick()
	if math.floor(timeIndex * 2) % 2 == 0 then
		refreshMonsterList()
	end
	
	-- Handle flight physics when active
	if isTracking and selectedMonster then
		if selectedMonster.Parent then
			local hrp = selectedMonster:FindFirstChild("HumanoidRootPart") or selectedMonster.PrimaryPart
			local char = player.Character
			local myHrp = char and char:FindFirstChild("HumanoidRootPart")
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			
			if hrp and myHrp and humanoid then
				-- Disable platform standing / physics interruption
				humanoid.PlatformStand = true
				
				local targetPos = hrp.Position + Vector3.new(0, 2, 0)
				local currentPos = myHrp.Position
				local direction = (targetPos - currentPos)
				local distance = direction.Magnitude
				
				if distance > CONFIG.StopDistance then
					-- Move smoothly toward the target using speed configuration
					local moveVector = direction.Unit * math.min(CONFIG.FlightSpeed * dt, distance)
					myHrp.CFrame = CFrame.new(currentPos + moveVector, targetPos)
					myHrp.AssemblyLinearVelocity = Vector3.zero
				else
					-- Hold position right next to target and face it
					myHrp.CFrame = CFrame.new(currentPos, targetPos)
					myHrp.AssemblyLinearVelocity = Vector3.zero
				end
			end
		else
			selectedMonster = nil
			statusLabel.Text = "Selected: None (Target Lost)"
		end
	else
		-- Re-enable normal character physics when toggled off
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.PlatformStand then
			humanoid.PlatformStand = false
		end
	end
end)
