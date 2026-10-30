local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

local isRunning = false
local autoApproach = false
local lastMobTarget = nil
local mobApproachStartTime = 0
local configFileName = "RadarApproachTestConfig.json"

-- ==========================================
-- CREATE TEST UI (V5.20 - Height Offset Above Mobs)
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
topBar.Size = UDim2.new(0, 300, 0, 35)
topBar.Position = UDim2.new(0.5, -150, 0.3, 0)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -75, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Radar & Approach [V5.20]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

-- Close Button (X)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 35)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.BorderSizePixel = 0
closeButton.Parent = topBar

-- Minimize Button (-)
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 35)
minimizeButton.Position = UDim2.new(1, -65, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 470) -- Expanded height to fit the new height offset row
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

-- Helper function to create clean rows
local function createRow(name, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 140, 0, 30)
    label.Position = UDim2.new(0, 15, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 110, 0, 30)
    box.Position = UDim2.new(0, 165, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.Parent = mainFrame
    
    return box
end

-- Generate input rows dynamically
local monsterBox = createRow("Target Prefix:", 15, "A_")
local radiusBox = createRow("Stud Radius:", 55, "500")
local stopBox = createRow("Stop Distance:", 95, "5")
local speedBox = createRow("Fly Speed:", 135, "44")
local timeoutBox = createRow("Mob Timeout (s):", 175, "1.0")
local heightBox = createRow("Height Offset:", 215, "4") -- New height offset row (defaults to 4 studs above)

-- Test Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -30, 0, 35)
toggleButton.Position = UDim2.new(0, 15, 0, 260)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Radar Test"
toggleButton.Parent = mainFrame

-- Auto Approach Toggle Button
local approachButton = Instance.new("TextButton")
approachButton.Size = UDim2.new(1, -30, 0, 35)
approachButton.Position = UDim2.new(0, 15, 0, 305)
approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
approachButton.TextColor3 = Color3.fromRGB(255, 255, 255)
approachButton.Font = Enum.Font.SourceSansBold
approachButton.TextSize = 15
approachButton.Text = "Auto Approach: OFF"
approachButton.Parent = mainFrame

-- Save Button
local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(1, -30, 0, 35)
saveButton.Position = UDim2.new(0, 15, 0, 350)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 15
saveButton.Text = "Save Settings"
saveButton.Parent = mainFrame

-- Live Status Readout
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 60)
statusLabel.Position = UDim2.new(0, 15, 0, 395)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle\nDetected: None"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = mainFrame

-- ==========================================
-- FILE SAVING & LOADING LOGIC
-- ==========================================
local function saveSettings()
    local data = {
        TargetPrefix = monsterBox.Text,
        StudRadius = radiusBox.Text,
        StopDistance = stopBox.Text,
        FlySpeed = speedBox.Text,
        MobTimeout = timeoutBox.Text,
        HeightOffset = heightBox.Text
    }
    
    pcall(function()
        if writefile then
            local jsonData = HttpService:JSONEncode(data)
            writefile(configFileName, jsonData)
        end
    end)
    
    saveButton.Text = "Saved!"
    task.wait(1)
    saveButton.Text = "Save Settings"
end

local function loadSettings()
    pcall(function()
        if isfile and isfile(configFileName) then
            local jsonData = readfile(configFileName)
            local success, data = pcall(function()
                return HttpService:JSONDecode(jsonData)
            end)
            
            if success and data then
                if data.TargetPrefix then monsterBox.Text = tostring(data.TargetPrefix) end
                if data.StudRadius then radiusBox.Text = tostring(data.StudRadius) end
                if data.StopDistance then stopBox.Text = tostring(data.StopDistance) end
                if data.FlySpeed then speedBox.Text = tostring(data.FlySpeed) end
                if data.MobTimeout then timeoutBox.Text = tostring(data.MobTimeout) end
                if data.HeightOffset then heightBox.Text = tostring(data.HeightOffset) end
            end
        end
    end)
end

loadSettings()
saveButton.MouseButton1Click:Connect(saveSettings)

-- ==========================================
-- UI CONTROLS
-- ==========================================
local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    mainFrame.Visible = not minimized
    minimizeButton.Text = minimized and "+" or "-"
end)

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
    local heightOffset = tonumber(heightBox.Text) or 4
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
            -- Apply height offset to target position so we hover above uphill/sloped mobs
            local targetPos = closestPart.Position + Vector3.new(0, heightOffset, 0)
            local distance = (targetPos - myRoot.Position).Magnitude
            local direction = (targetPos - myRoot.Position).Unit
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            
            if distance > stopDistance then
                local step = math.min(distance - stopDistance, flySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
            end
        end
    else
        lastMobTarget = nil
        statusLabel.Text = "Status: Searching...\nDetected: None"
    end
end)
