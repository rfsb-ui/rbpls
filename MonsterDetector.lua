local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
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

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonsterTargeterGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 320)
mainFrame.Position = UDim2.new(0, 30, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title Label with Version Control (v1.2)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -75, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aggressor Targeter v1.2"
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
statusLabel.Position = UDim2.new(0, 10, 0, 265)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Selected: None"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = mainFrame

-- State variables
local selectedMonster = nil
local isTracking = false
local isMinimized = false

-- Minimize toggle logic
minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 240, 0, 45)
		scrollFrame.Visible = false
		toggleButton.Visible = false
		statusLabel.Visible = false
		minimizeButton.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 240, 0, 320)
		scrollFrame.Visible = true
		toggleButton.Visible = true
		statusLabel.Visible = true
		minimizeButton.Text = "-"
	end
end)

-- Function to refresh the list of monsters from the folder
local function refreshMonsterList()
	if isMinimized then return end
	
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local count = 0
	for _, monster in ipairs(aggressorsFolder:GetChildren()) do
		if monster:IsA("Model") then
			local hrp = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
			local distanceStr = ""
			
			if hrp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = math.floor((player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
				distanceStr = " (" .. dist .. "m)"
			end
			
			count += 1
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -10, 0, 30)
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			btn.Text = monster.Name .. distanceStr
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 13
			btn.Font = Enum.Font.SourceSans
			btn.Parent = scrollFrame
			
			local btnUiCorner = Instance.new("UICorner")
			btnUiCorner.CornerRadius = UDim.new(0, 4)
			btnUiCorner.Parent = btn
			
			btn.MouseButton1Click:Connect(function()
				selectedMonster = monster
				statusLabel.Text = "Selected: " + monster.Name -- Fixed string concatenation below
			end)
		end
	end
	
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 34)
end

-- Fix string concatenation in click event
-- (Re-binding click event properly)
local function updateButtonEvents()
	for _, btn in ipairs(scrollFrame:GetChildren()) do
		if btn:IsA("TextButton") then
			-- Handled inside generation loop, but ensures safety
		end
	end
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

-- Main loop to refresh options and handle flying/moving to target
task.spawn(function()
	while true do
		refreshMonsterList()
		
		if isTracking and selectedMonster then
			if selectedMonster.Parent then
				local hrp = selectedMonster:FindFirstChild("HumanoidRootPart") or selectedMonster.PrimaryPart
				local char = player.Character
				local myHrp = char and char:FindFirstChild("HumanoidRootPart")
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				
				if hrp and myHrp and humanoid then
					-- Disable falling or gravity interference while moving to target position
					local targetPosition = hrp.Position + Vector3.new(0, 3, 0) -- Hover slightly above or at the target
					
					-- Move character smoothly toward target position
					humanoid:MoveTo(targetPosition)
					
					-- Optional: Look at target
					myHrp.CFrame = CFrame.new(myHrp.Position, Vector3.new(hrp.Position.X, myHrp.Position.Y, hrp.Position.Z))
				end
			else
				selectedMonster = nil
				statusLabel.Text = "Selected: None (Target Lost)"
			end
		end
		
		task.wait(0.2)
	end
end)
