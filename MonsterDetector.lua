local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Safely wait for the nested folder structure to prevent infinite yielding or nil errors
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

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aggressor Targeter"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

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
toggleButton.Text = "Targeting: OFF"
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

-- Function to refresh the list of monsters from the folder
local function refreshMonsterList()
	-- Clear old buttons safely
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local count = 0
	for _, monster in ipairs(aggressorsFolder:GetChildren()) do
		-- Check if it's a model and has a primary root or position reference
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
			
			-- Selection click event
			btn.MouseButton1Click:Connect(function()
				selectedMonster = monster
				statusLabel.Text = "Selected: " .. monster.Name
			end)
		end
	end
	
	-- Explicitly update CanvasSize so scrolling works and items are fully visible
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 34)
end

-- Toggle button click handler
toggleButton.MouseButton1Click:Connect(function()
	isTracking = not isTracking
	if isTracking then
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		toggleButton.Text = "Targeting: ON"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		toggleButton.Text = "Targeting: OFF"
	end
end)

-- Main loop to refresh options and handle constant targeting
task.spawn(function()
	while true do
		refreshMonsterList()
		
		if isTracking and selectedMonster then
			-- Verify target still exists in workspace
			if selectedMonster.Parent then
				local hrp = selectedMonster:FindFirstChild("HumanoidRootPart") or selectedMonster.PrimaryPart
				local char = player.Character
				local myHrp = char and char:FindFirstChild("HumanoidRootPart")
				
				if hrp and myHrp then
					-- Keeps the player character facing/locked onto the targeted monster
					myHrp.CFrame = CFrame.new(myHrp.Position, Vector3.new(hrp.Position.X, myHrp.Position.Y, hrp.Position.Z))
				end
			else
				selectedMonster = nil
				statusLabel.Text = "Selected: None (Target Lost)"
			end
		end
		
		task.wait(1)
	end
end)
