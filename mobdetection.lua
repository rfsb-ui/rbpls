local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local isRunning = false
local autoApproach = false

-- ==========================================
-- CREATE TEST UI (V5.14 - Adjustable Fly Speed)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RadarApproachTestGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 260, 0, 30)
topBar.Position = UDim2.new(0.5, -130, 0.4, 0)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Radar & Approach [V5.14]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.BorderSizePixel = 0
closeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 315) -- Expanded to fit the new speed box
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

-- Target Prefix Input Box
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 130, 0, 30)
targetLabel.Position = UDim2.new(0, 10, 0, 10)
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetLabel.Text = "Target Prefix:"
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextSize = 15
targetLabel.Parent = mainFrame

local monsterBox = Instance.new("TextBox")
monsterBox.Size = UDim2.new(0, 100, 0, 30)
monsterBox.Position = UDim2.new(0, 150, 0, 10)
monsterBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
monsterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
monsterBox.Text = "A_"
monsterBox.Font = Enum.Font.SourceSans
monsterBox.TextSize = 14
monsterBox.Parent = mainFrame

-- Stud Radius Input Box
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0, 130, 0, 30)
radiusLabel.Position = UDim2.new(0, 10, 0, 50)
radiusLabel.BackgroundTransparency = 1
radiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusLabel.Text = "Stud Radius:"
radiusLabel.Font = Enum.Font.SourceSansBold
radiusLabel.TextSize = 15
radiusLabel.Parent = mainFrame

local radiusBox = Instance.new("TextBox")
radiusBox.Size = UDim2.new(0, 100, 0, 30)
radiusBox.Position = UDim2.new(0, 150, 0, 50)
radiusBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
radiusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusBox.Text = "500"
radiusBox.Font = Enum.Font.SourceSans
radiusBox.TextSize = 14
radiusBox.Parent = mainFrame

-- Stop Distance Input Box
local stopLabel = Instance.new("TextLabel")
stopLabel.Size = UDim2.new(0, 130, 0, 30)
stopLabel.Position = UDim2.new(0, 10, 0, 90)
stopLabel.BackgroundTransparency = 1
stopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
stopLabel.Text = "Stop Distance:"
stopLabel.Font = Enum.Font.SourceSansBold
stopLabel.TextSize = 15
stopLabel.Parent = mainFrame

local stopBox = Instance.new("TextBox")
stopBox.Size = UDim2.new(0, 100, 0, 30)
stopBox.Position = UDim2.new(0, 150, 0, 90)
stopBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
stopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBox.Text = "5"
stopBox.Font = Enum.Font.SourceSans
stopBox.TextSize = 14
stopBox.Parent = mainFrame

-- Fly Speed Input Box (New!)
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 130, 0, 30)
speedLabel.Position = UDim2.new(0, 10, 0, 130)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Text = "Fly Speed:"
speedLabel.Font = Enum.Font.SourceSansBold
speedLabel.TextSize = 15
speedLabel.Parent = mainFrame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 100, 0, 30)
speedBox.Position = UDim2.new(0, 150, 0, 130)
speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Text = "44" -- Default speed value
speedBox.Font = Enum.Font.SourceSans
speedBox.TextSize = 14
speedBox.Parent = mainFrame

-- Test Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 35)
toggleButton.Position = UDim2.new(0, 10, 0, 170)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Radar Test"
toggleButton.Parent = mainFrame

-- Auto Approach Toggle Button
local approachButton = Instance.new("TextButton")
approachButton.Size = UDim2.new(1, -20, 0, 35)
approachButton.Position = UDim2.new(0, 10, 0, 215)
approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
approachButton.TextColor3 = Color3.fromRGB(255, 255, 255)
approachButton.Font = Enum.Font.SourceSansBold
approachButton.TextSize = 15
approachButton.Text = "Auto Approach: OFF"
approachButton.Parent = mainFrame

-- Live Status Readout
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 45)
statusLabel.Position = UDim2.new(0, 10, 0, 260)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle\nDetected: None"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = mainFrame

-- ==========================================
-- UI CONTROLS
-- ==========================================
closeButton.MouseButton1Click:Connect(function()
    isRunning = false
    autoApproach = false
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if rootPart then
        rootPart.Anchored = false
    end
    screenGui:Destroy()
end)

toggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleButton.Text = "Stop Test"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        toggleButton.Text = "Start Radar Test"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        autoApproach = false
        approachButton.Text = "Auto Approach: OFF"
        approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        statusLabel.Text = "Status: Idle\nDetected: None"
    end
end)

approachButton.MouseButton1Click:Connect(function()
    if not isRunning then return end
    autoApproach = not autoApproach
    if autoApproach then
        approachButton.Text = "Auto Approach: ON"
        approachButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    else
        approachButton.Text = "Auto Approach: OFF"
        approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

-- ==========================================
-- REAL-TIME RADAR & APPROACH LOOP
-- ==========================================
RunService.RenderStepped:Connect(function(dt)
    if not isRunning then return end
    
    local character = localPlayer.Character
    local myRoot = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if not myRoot then
        statusLabel.Text = "Status: Character not found"
        return
    end
    
    local myPos = myRoot.Position
    local maxRadius = tonumber(radiusBox.Text) or 500
    local stopDistance = tonumber(stopBox.Text) or 5
    local flySpeed = tonumber(speedBox.Text) or 44
    local targetPrefix = monsterBox.Text:lower()
    
    local closestPart = nil
    local shortestDistance = math.huge
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= myRoot and not obj:IsDescendantOf(character) then
            local objName = obj.Name:lower()
            
            if targetPrefix == "" or string.find(objName, targetPrefix, 1, true) then
                local distance = (obj.Position - myPos).Magnitude
                if distance <= maxRadius and distance < shortestDistance then
                    shortestDistance = distance
                    closestPart = obj
                end
            end
        end
    end
    
    if closestPart then
        statusLabel.Text = string.format("Status: %s\nDetected: [%s] (Dist: %.1f)", autoApproach and "Approaching" or "Locked", closestPart.Name, shortestDistance)
        
        if autoApproach then
            local distance = (closestPart.Position - myRoot.Position).Magnitude
            local direction = (closestPart.Position - myRoot.Position).Unit
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            
            if distance > stopDistance then
                -- Speed-based delta step calculation
                local step = math.min(distance - stopDistance, flySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(closestPart.Position.X, myRoot.Position.Y, closestPart.Position.Z))
            end
        end
    else
        statusLabel.Text = "Status: Searching...\nDetected: None"
    end
end)
