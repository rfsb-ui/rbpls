local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local localPlayer = Players.LocalPlayer

local isRunning = false
local autoApproach = false
local mobDebugEnabled = false
local lastMobTarget = nil
local mobApproachStartTime = 0
local configFileName = "RadarApproachTestConfig.json"

-- ESP Visual Tracking Elements
local activeHighlights = {}

-- ==========================================
-- CREATE TEST UI (V5.31 - Deadzone Jitter Fix)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RadarApproachTestGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 520, 0, 35)
topBar.Position = UDim2.new(0.5, -260, 0.3, 0)
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
titleLabel.Text = "Radar & Approach [V5.31]"
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
mainFrame.Size = UDim2.new(1, 0, 0, 350)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

-- Helper function to create clean configuration rows on the Left Section
local function createConfigRow(name, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 0, 25)
    label.Position = UDim2.new(0, 15, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 90, 0, 25)
    box.Position = UDim2.new(0, 135, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.Parent = mainFrame
    
    return box
end

-- Left Column Inputs
local monsterBox = createConfigRow("Target Prefix:", 15, "A_")
local radiusBox = createConfigRow("Stud Radius:", 45, "500")
local stopBox = createConfigRow("Stop Distance:", 75, "5")
local speedBox = createConfigRow("Fly Speed:", 105, "44")
local timeoutBox = createConfigRow("Mob Timeout (s):", 135, "1.0")
local heightBox = createConfigRow("Height Offset:", 165, "4")
local itemBox = createConfigRow("Item Prefix:", 195, "DropAura")

-- Right Column Buttons & Status Section
local rightX = 250
local rightWidth = 255

-- Test Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, rightWidth, 0, 30)
toggleButton.Position = UDim2.new(0, rightX, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Radar Test"
toggleButton.Parent = mainFrame

-- Auto Approach Toggle Button
local approachButton = Instance.new("TextButton")
approachButton.Size = UDim2.new(0, rightWidth, 0, 30)
approachButton.Position = UDim2.new(0, rightX, 0, 55)
approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
approachButton.TextColor3 = Color3.fromRGB(255, 255, 255)
approachButton.Font = Enum.Font.SourceSansBold
approachButton.TextSize = 15
approachButton.Text = "Auto Approach: OFF"
approachButton.Parent = mainFrame

-- Mob Debug Toggle Button
local mobDebugButton = Instance.new("TextButton")
mobDebugButton.Size = UDim2.new(0, rightWidth, 0, 30)
mobDebugButton.Position = UDim2.new(0, rightX, 0, 95)
mobDebugButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
mobDebugButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mobDebugButton.Font = Enum.Font.SourceSansBold
mobDebugButton.TextSize = 15
mobDebugButton.Text = "Mob Debug: OFF"
mobDebugButton.Parent = mainFrame

-- Save Button
local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, rightWidth, 0, 30)
saveButton.Position = UDim2.new(0, rightX, 0, 135)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 15
saveButton.Text = "Save Settings"
saveButton.Parent = mainFrame

-- Live Status Readout
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, rightWidth, 0, 85)
statusLabel.Position = UDim2.new(0, rightX, 0, 175)
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
        HeightOffset = heightBox.Text,
        ItemPrefix = itemBox.Text
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
                if data.ItemPrefix then itemBox.Text = tostring(data.ItemPrefix) end
            end
        end
    end)
end

loadSettings()
saveButton.MouseButton1Click:Connect(saveSettings)

-- ==========================================
-- ESP HIGHLIGHT CLEANUP UTILITY
-- ==========================================
local function clearHighlights()
    for _, item in pairs(activeHighlights) do
        if item and item.Parent then
            item:Destroy()
        end
    end
    activeHighlights = {}
end

local function setHighlight(targetObj, color)
    clearHighlights()
    if targetObj and targetObj.Parent then
        local model = targetObj.Parent
        if not model:IsA("Model") then
            model = targetObj
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.4
        highlight.Parent = screenGui
        table.insert(activeHighlights, highlight)
    end
end

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
    mobDebugEnabled = false
    lastMobTarget = nil
    clearHighlights()
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
        clearHighlights()
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

mobDebugButton.MouseButton1Click:Connect(function()
    mobDebugEnabled = not mobDebugEnabled
    if mobDebugEnabled then
        mobDebugButton.Text = "Mob Debug: ON"
        mobDebugButton.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
    else
        mobDebugButton.Text = "Mob Debug: OFF"
        mobDebugButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

-- Anti-AFK Connection
localPlayer.Idled:Connect(function()
    if isRunning then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

local loggedPartsCache = {}

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
    local baseFlySpeed = tonumber(speedBox.Text) or 44
    local mobTimeout = tonumber(timeoutBox.Text) or 1.0
    local heightOffset = tonumber(heightBox.Text) or 4
    local targetPrefix = monsterBox.Text:lower()
    local itemPrefix = itemBox.Text:lower()
    
    local closestMonster = nil
    local shortestMonsterDist = math.huge
    
    local closestItem = nil
    local shortestItemDist = math.huge
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= myRoot and not obj:IsDescendantOf(character) then
            local objName = obj.Name:lower()
            local distance = (obj.Position - myPos).Magnitude
            
            if distance <= maxRadius then
                if mobDebugEnabled and distance <= 100 then
                    if not loggedPartsCache[obj] then
                        loggedPartsCache[obj] = true
                        print(string.format("[MOB DEBUG SCAN] Name: %s | Parent: %s | Dist: %.1f", obj.Name, tostring(obj.Parent), distance))
                    end
                end
                
                if targetPrefix ~= "" and string.find(objName, targetPrefix, 1, true) then
                    if distance < shortestMonsterDist then
                        shortestMonsterDist = distance
                        closestMonster = obj
                    end
                end
                
                if itemPrefix ~= "" and string.find(objName, itemPrefix, 1, true) then
                    if distance < shortestItemDist then
                        shortestItemDist = distance
                        closestItem = obj
                    end
                end
            end
        end
    end
    
    local targetPart = nil
    local isLooting = false
    
    if closestItem and shortestItemDist <= 35 then
        targetPart = closestItem
        isLooting = true
    elseif closestMonster then
        if closestMonster ~= lastMobTarget then
            lastMobTarget = closestMonster
            mobApproachStartTime = os.clock()
        end
        
        local timeElapsed = os.clock() - mobApproachStartTime
        
        if autoApproach and timeElapsed < mobTimeout and closestItem then
            targetPart = closestItem
            isLooting = true
        else
            targetPart = closestMonster
        end
    elseif closestItem then
        targetPart = closestItem
        isLooting = true
    else
        lastMobTarget = nil
        loggedPartsCache = {}
        clearHighlights()
    end
    
    if targetPart then
        setHighlight(targetPart, isLooting and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
        
        local modeText = isLooting and "Item" or "Mob"
        local statusText = autoApproach and (isLooting and "Looting Drop" or "Approaching Mob") or "Locked"
        statusLabel.Text = string.format("Status: %s [%s]\nDetected: [%s] (Dist: %.1f)", 
            statusText, 
            modeText, 
            targetPart.Name, 
            (targetPart.Position - myPos).Magnitude
        )
        
        if autoApproach then
            local currentOffset = heightOffset
            if isLooting then
                currentOffset = 0
            end
            
            local targetPos = targetPart.Position + Vector3.new(0, currentOffset, 0)
            local distance = (targetPos - myRoot.Position).Magnitude
            local direction = (targetPos - myRoot.Position).Unit
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            
            if distance > stopDistance then
                local speedMultiplier = math.clamp(distance / 25, 0.25, 1.0)
                local currentFlySpeed = baseFlySpeed * speedMultiplier
                
                local step = math.min(distance - stopDistance, currentFlySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
            else
                -- Deadzone filter: Freeze physics velocity completely to prevent micro-jumping upon arrival
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end
    else
        lastMobTarget = nil
        statusLabel.Text = "Status: Searching...\nDetected: None"
    end
end)
