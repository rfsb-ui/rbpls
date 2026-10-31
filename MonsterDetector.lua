local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Reference your specific folder
local aggressorsFolder = workspace:WaitForChild("Animal_Live"):WaitForChild("Aggressors")

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

-- Scrolling Frame for Monster List (Dropdown options)
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 0, 160)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = scrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

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
	-- Clear old buttons
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local count = 0
	for _, monster in ipairs(aggressorsFolder:GetChildren()) do
		if monster:IsA("Model") then
			count += 1
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -10, 0, 30)
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			btn.Text = monster.Name .. " (" .. monster.CFrame.Position.Magnitude .. "m)"
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
		
		if isTracking and selectedMonster and selectedMonster.Parent then
			local hrp = selectedMonster:FindFirstChild("HumanoidRootPart")
			local char = player.Character
			local myHrp = char and char:FindFirstChild("HumanoidRootPart")
			
			if hrp and myHrp then
				-- Example action: Point camera or character toward the targeted monster
				myHrp.CFrame = CFrame.new(myHrp.Position, Vector3.new(hrp.Position.X, myHrp.Position.Y, hrp.Position.Z))
			end
		elseif isTracking and selectedMonster and not selectedMonster.Parent then
			-- Reset if target is destroyed or removed
			selectedMonster = nil
			statusLabel.Text = "Selected: None (Target Lost)"
		end
		
		task.wait(1)
	end
end)
