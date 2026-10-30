local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local isRunning = false
local autoApproach = false
local lastMobTarget = nil
local mobApproachStartTime = 0

-- ==========================================
-- CREATE TEST UI (V5.17 - Configurable Mob Timeout)
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
topBar.Size = UDim2.new(0, 280, 0, 35)
topBar.Position = UDim2.new(0.5, -140, 0.3, 0)
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
titleLabel.Text = "Radar & Approach [V5.17]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -35, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.BorderSizePixel = 0
closeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 400) -- Expanded height to fit the new timeout row
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

-- Helper function to create clean rows
local function createRow(name, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 130, 0, 30)
    label.Position = UDim2.new(0, 15, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 100, 0, 30)
    box.Position = UDim2.new(0, 155, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.Parent = mainFrame
    
    return box
end

-- Generate rows dynamically
local monsterBox = createRow("Target Prefix:", 15, "A_")
local radiusBox = createRow("Stud Radius:", 55, "500")
local stopBox = createRow("Stop Distance:", 95, "5")
local speedBox = createRow("Fly Speed:", 135, "44")
local timeoutBox = createRow("Mob Timeout (s):", 175, "1.0") -- New configurable timeout row

-- Test Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -30, 0, 35)
toggleButton.Position = UDim2.new(0, 15, 0, 220)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Radar Test"
toggleButton.Parent = mainFrame

-- Auto Approach Toggle Button
local approachButton = Instance.new("TextButton")
approachButton.Size = UDim2.new(1, -30, 0, 35)
approachButton.Position = UDim2.new(0, 15, 0, 265)
approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
approachButton.TextColor3 = Color3.fromRGB(255, 255, 255)
approachButton.Font = Enum.Font.SourceSansBold
approachButton.TextSize = 15
approachButton.Text = "Auto Approach: OFF"
approachButton.Parent = mainFrame

-- Live Status Readout
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 65)
statusLabel.Position = UDim2.new(0, 15, 0, 310)
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
    lastMobTarget = nil
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
        lastMobTarget = nil
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
        lastMobTarget = nil
    else
        approachButton.Text = "Auto Approach: OFF"
        approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        lastMobTarget = nil
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
    local mobTimeout = tonumber(timeoutBox.Text) or 1.0
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
        -- Check if we just targeted a new mob or if timeout expired
        if closestPart ~= lastMobTarget then
            lastMobTarget = closestPart
            mobApproachStartTime = os.clock()
        end
        
        local timeElapsed = os.clock() - mobApproachStartTime
        
        if autoApproach and timeElapsed < mobTimeout then
            statusLabel.Text = string.format("Status: Waiting Timeout (%.1fs)\nDetected: [%s]", mobTimeout - timeElapsed, closestPart.Name)
            return
        end
        
        statusLabel.Text = string.format("Status: %s\nDetected: [%s] (Dist: %.1f)", autoApproach and "Approaching" or "Locked", closestPart.Name, shortestDistance)
        
        if autoApproach then
            local distance = (closestPart.Position - myRoot.Position).Magnitude
            local direction = (closestPart.Position - myRoot.Position).Unit
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            
            if distance > stopDistance then
                local step = math.min(distance - stopDistance, flySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(closestPart.Position.X, myRoot.Position.Y, closestPart.Position.Z))
            end
        end
    else
        lastMobTarget = nil
        statusLabel.Text = "Status: Searching...\nDetected: None"
    end
end)
