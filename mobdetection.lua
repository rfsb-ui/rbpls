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
-- CREATE TEST UI (V5.25 - Debug Scanner)
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
titleLabel.Text = "Radar & Approach [V5.25]"
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
mainFrame.Size = UDim2.new(1, 0, 0, 510)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

-- 1. Target Prefix Row
local label1 = Instance.new("TextLabel")
label1.Size = UDim2.new(0, 140, 0, 30)
label1.Position = UDim2.new(0, 15, 0, 15)
label1.BackgroundTransparency = 1
label1.TextColor3 = Color3.fromRGB(255, 255, 255)
label1.Text = "Target Prefix:"
label1.Font = Enum.Font.SourceSansBold
label1.TextSize = 15
label1.TextXAlignment = Enum.TextXAlignment.Left
label1.Parent = mainFrame

local monsterBox = Instance.new("TextBox")
monsterBox.Size = UDim2.new(0, 110, 0, 30)
monsterBox.Position = UDim2.new(0, 165, 0, 15)
monsterBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
monsterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
monsterBox.Text = "A_"
monsterBox.Font = Enum.Font.SourceSans
monsterBox.TextSize = 14
monsterBox.Parent = mainFrame

-- 2. Stud Radius Row
local label2 = Instance.new("TextLabel")
label2.Size = UDim2.new(0, 140, 0, 30)
label2.Position = UDim2.new(0, 15, 0, 55)
label2.BackgroundTransparency = 1
label2.TextColor3 = Color3.fromRGB(255, 255, 255)
label2.Text = "Stud Radius:"
label2.Font = Enum.Font.SourceSansBold
label2.TextSize = 15
label2.TextXAlignment = Enum.TextXAlignment.Left
label2.Parent = mainFrame

local radiusBox = Instance.new("TextBox")
radiusBox.Size = UDim2.new(0, 110, 0, 30)
radiusBox.Position = UDim2.new(0, 165, 0, 55)
radiusBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
radiusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusBox.Text = "500"
radiusBox.Font = Enum.Font.SourceSans
radiusBox.TextSize = 14
radiusBox.Parent = mainFrame

-- 3. Stop Distance Row
local label3 = Instance.new("TextLabel")
label3.Size = UDim2.new(0, 140, 0, 30)
label3.Position = UDim2.new(0, 15, 0, 95)
label3.BackgroundTransparency = 1
label3.TextColor3 = Color3.fromRGB(255, 255, 255)
label3.Text = "Stop Distance:"
label3.Font = Enum.Font.SourceSansBold
label3.TextSize = 15
label3.TextXAlignment = Enum.TextXAlignment.Left
label3.Parent = mainFrame

local stopBox = Instance.new("TextBox")
stopBox.Size = UDim2.new(0, 110, 0, 30)
stopBox.Position = UDim2.new(0, 165, 0, 95)
stopBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
stopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBox.Text = "5"
stopBox.Font = Enum.Font.SourceSans
stopBox.TextSize = 14
stopBox.Parent = mainFrame

-- 4. Fly Speed Row
local label4 = Instance.new("TextLabel")
label4.Size = UDim2.new(0, 140, 0, 30)
label4.Position = UDim2.new(0, 15, 0, 135)
label4.BackgroundTransparency = 1
label4.TextColor3 = Color3.fromRGB(255, 255, 255)
label4.Text = "Fly Speed:"
label4.Font = Enum.Font.SourceSansBold
label4.TextSize = 15
label4.TextXAlignment = Enum.TextXAlignment.Left
label4.Parent = mainFrame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 110, 0, 30)
speedBox.Position = UDim2.new(0, 165, 0, 135)
speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Text = "44"
speedBox.Font = Enum.Font.SourceSans
speedBox.TextSize = 14
speedBox.Parent = mainFrame

-- 5. Mob Timeout Row
local label5 = Instance.new("TextLabel")
label5.Size = UDim2.new(0, 140, 0, 30)
label5.Position = UDim2.new(0, 15, 0, 175)
label5.BackgroundTransparency = 1
label5.TextColor3 = Color3.fromRGB(255, 255, 255)
label5.Text = "Mob Timeout (s):"
label5.Font = Enum.Font.SourceSansBold
label5.TextSize = 15
label5.TextXAlignment = Enum.TextXAlignment.Left
label5.Parent = mainFrame

local timeoutBox = Instance.new("TextBox")
timeoutBox.Size = UDim2.new(0, 110, 0, 30)
timeoutBox.Position = UDim2.new(0, 165, 0, 175)
timeoutBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
timeoutBox.TextColor3 = Color3.fromRGB(255, 255, 255)
timeoutBox.Text = "1.0"
timeoutBox.Font = Enum.Font.SourceSans
timeoutBox.TextSize = 14
timeoutBox.Parent = mainFrame

-- 6. Height Offset Row
local label6 = Instance.new("TextLabel")
label6.Size = UDim2.new(0, 140, 0, 30)
label6.Position = UDim2.new(0, 15, 0, 215)
label6.BackgroundTransparency = 1
label6.TextColor3 = Color3.fromRGB(255, 255, 255)
label6.Text = "Height Offset:"
label6.Font = Enum.Font.SourceSansBold
label6.TextSize = 15
label6.TextXAlignment = Enum.TextXAlignment.Left
label6.Parent = mainFrame

local heightBox = Instance.new("TextBox")
heightBox.Size = UDim2.new(0, 110, 0, 30)
heightBox.Position = UDim2.new(0, 165, 0, 215)
heightBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
heightBox.TextColor3 = Color3.fromRGB(255, 255, 255)
heightBox.Text = "4"
heightBox.Font = Enum.Font.SourceSans
heightBox.TextSize = 14
heightBox.Parent = mainFrame

-- 7. Item Prefix Row
local label7 = Instance.new("TextLabel")
label7.Size = UDim2.new(0, 140, 0, 30)
label7.Position = UDim2.new(0, 15, 0, 255)
label7.BackgroundTransparency = 1
label7.TextColor3 = Color3.fromRGB(255, 255, 255)
label7.Text = "Item Prefix:"
label7.Font = Enum.Font.SourceSansBold
label7.TextSize = 15
label7.TextXAlignment = Enum.TextXAlignment.Left
label7.Parent = mainFrame

local itemBox = Instance.new("TextBox")
itemBox.Size = UDim2.new(0, 110, 0, 30)
itemBox.Position = UDim2.new(0, 165, 0, 255)
itemBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
itemBox.TextColor3 = Color3.fromRGB(255, 255, 255)
itemBox.Text = "Drop_"
itemBox.Font = Enum.Font.SourceSans
itemBox.TextSize = 14
itemBox.Parent = mainFrame

-- Test Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -30, 0, 35)
toggleButton.Position = UDim2.new(0, 15, 0, 300)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Radar Test"
toggleButton.Parent = mainFrame

-- Auto Approach Toggle Button
local approachButton = Instance.new("TextButton")
approachButton.Size = UDim2.new(1, -30, 0, 35)
approachButton.Position = UDim2.new(0, 15, 0, 345)
approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
approachButton.TextColor3 = Color3.fromRGB(255, 255, 255)
approachButton.Font = Enum.Font.SourceSansBold
approachButton.TextSize = 15
approachButton.Text = "Auto Approach: OFF"
approachButton.Parent = mainFrame

-- Save Button
local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(1, -30, 0, 35)
saveButton.Position = UDim2.new(0, 15, 0, 390)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 15
saveButton.Text = "Save Settings"
saveButton.Parent = mainFrame

-- Live Status Readout
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 65)
statusLabel.Position = UDim2.new(0, 15, 0, 435)
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
                -- DEBUG: Print every single part name to console once per second so you can see what parts exist
                if math.random(1, 60) == 1 then
                    print("[SCANNER DEBUG] Found Part:", obj.Name, "Distance:", math.floor(distance))
                end

                if targetPrefix ~= "" and string.find(objName, targetPrefix, 1, true) then
                    if distance < shortestMonsterDist then
                        shortestMonsterDist = distance
                        closestMonster = obj
                    end
                end
                
                if itemPrefix ~= "" and string.find(objName, itemPrefix, 1, true) then
                    print(string.format("[ITEM FOUND!] Match: %s | Distance: %.1f", obj.Name, distance))
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
    
    if closestMonster then
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
    end
    
    if targetPart then
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
