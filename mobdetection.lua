local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local localPlayer = Players.LocalPlayer

local isRunning = false
local autoApproach = false
local autoLootEnabled = true
local mobDebugEnabled = false
local lockedTarget = nil
local mobApproachStartTime = 0
local configFileName = "RadarApproachTestConfig.json"

local recentTargetHistory = {}
local activeHighlights = {}

-- ==========================================
-- CREATE TEST UI (V5.54 - Updated FX Filter with Tide)
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
topBar.Size = UDim2.new(0, 520, 0, 55)
topBar.Position = UDim2.new(0.5, -260, 0.3, 0)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 180, 0, 20)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Radar & Approach [V5.54]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

-- Persistent Status Display in Top Bar (Visible when Minimized!)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -75, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle | Target: None"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = topBar

-- Close Button (X)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 55)
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
minimizeButton.Size = UDim2.new(0, 30, 0, 55)
minimizeButton.Position = UDim2.new(1, -65, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 310)
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
local monsterBox = createConfigRow("Target Name:", 15, "CTurtleFXc")
local radiusBox = createConfigRow("Stud Radius:", 45, "500")
local stopBox = createConfigRow("Stop Distance:", 75, "5")
local speedBox = createConfigRow("Fly Speed:", 105, "44")
local timeoutBox = createConfigRow("Mob Timeout (s):", 135, "1.0")
local heightBox = createConfigRow("Height Offset:", 165, "4")
local itemBox = createConfigRow("Item Prefix:", 195, "DropAura")
local minBlacklistDistBox = createConfigRow("Min Target Dist:", 225, "30")

-- Right Column Buttons Section
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

-- Auto Loot Toggle Button
local lootButton = Instance.new("TextButton")
lootButton.Size = UDim2.new(0, rightWidth, 0, 30)
lootButton.Position = UDim2.new(0, rightX, 0, 95)
lootButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
lootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lootButton.Font = Enum.Font.SourceSansBold
lootButton.TextSize = 15
lootButton.Text = "Auto Loot: ON"
lootButton.Parent = mainFrame

-- Mob Debug Toggle Button
local mobDebugButton = Instance.new("TextButton")
mobDebugButton.Size = UDim2.new(0, rightWidth, 0, 30)
mobDebugButton.Position = UDim2.new(0, rightX, 0, 135)
mobDebugButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
mobDebugButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mobDebugButton.Font = Enum.Font.SourceSansBold
mobDebugButton.TextSize = 15
mobDebugButton.Text = "Mob Debug: OFF"
mobDebugButton.Parent = mainFrame

-- Save Button
local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, rightWidth, 0, 35)
saveButton.Position = UDim2.new(0, rightX, 0, 175)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 15
saveButton.Text = "Save Settings"
saveButton.Parent = mainFrame

-- ==========================================
-- FILE SAVING & LOADING LOGIC
-- ==========================================
local function saveSettings()
    local data = {
        TargetName = monsterBox.Text,
        StudRadius = radiusBox.Text,
        StopDistance = stopBox.Text,
        FlySpeed = speedBox.Text,
        MobTimeout = timeoutBox.Text,
        HeightOffset = heightBox.Text,
        ItemPrefix = itemBox.Text,
        MinTargetDist = minBlacklistDistBox.Text
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
                if data.TargetName then monsterBox.Text = tostring(data.TargetName) end
                if data.StudRadius then radiusBox.Text = tostring(data.StudRadius) end
                if data.StopDistance then stopBox.Text = tostring(data.StopDistance) end
                if data.FlySpeed then flySpeedBox.Text = tostring(data.FlySpeed) end
                if data.MobTimeout then timeoutBox.Text = tostring(data.MobTimeout) end
                if data.HeightOffset then heightBox.Text = tostring(data.HeightOffset) end
                if data.ItemPrefix then itemBox.Text = tostring(data.ItemPrefix) end
                if data.MinTargetDist then minBlacklistDistBox.Text = tostring(data.MinTargetDist) end
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
    autoLootEnabled = true
    mobDebugEnabled = false
    lockedTarget = nil
    recentTargetHistory = {}
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
        lockedTarget = nil
        recentTargetHistory = {}
        clearHighlights()
        approachButton.Text = "Auto Approach: OFF"
        approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        statusLabel.Text = "Status: Idle | Target: None"
    end
end)

approachButton.MouseButton1Click:Connect(function()
    if not isRunning then return end
    autoApproach = not autoApproach
    if autoApproach then
        approachButton.Text = "Auto Approach: ON"
        approachButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        lockedTarget = nil
    else
        approachButton.Text = "Auto Approach: OFF"
        approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        lockedTarget = nil
    end
end)

lootButton.MouseButton1Click:Connect(function()
    autoLootEnabled = not autoLootEnabled
    if autoLootEnabled then
        lootButton.Text = "Auto Loot: ON"
        lootButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    else
        lootButton.Text = "Auto Loot: OFF"
        lootButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
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
-- REAL-TIME RADAR & APPROACH LOOP (V5.54)
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
    local targetNameInput = monsterBox.Text:lower()
    local itemPrefix = itemBox.Text:lower()
    local minBlacklistDist = tonumber(minBlacklistDistBox.Text) or 30
    
    local currentTime = os.clock()
    for i = #recentTargetHistory, 1, -1 do
        if currentTime - recentTargetHistory[i].time > 3.5 then
            table.remove(recentTargetHistory, i)
        end
    end
    
    if lockedTarget and (not lockedTarget.Parent or (lockedTarget.Position - myPos).Magnitude > maxRadius) then
        lockedTarget = nil
    end
    
    local closestItem = nil
    local shortestItemDist = math.huge
    
    local function getRecursiveDescendants(parentObj)
        local results = {}
        pcall(function()
            for _, child in ipairs(parentObj:GetChildren()) do
                table.insert(results, child)
                for _, subChild in ipairs(getRecursiveDescendants(child)) do
                    table.insert(results, subChild)
                end
            end
        end)
        return results
    end
    
    local allObjects = getRecursiveDescendants(workspace)
    table.insert(allObjects, workspace)
    
    for _, obj in ipairs(allObjects) do
        if obj:IsA("BasePart") and obj ~= myRoot and not obj:IsDescendantOf(character) then
            local objName = obj.Name:lower()
            local distance = (obj.Position - myPos).Magnitude
            
            if distance <= maxRadius then
                local model = obj.Parent
                local modelName = model and model.Name:lower() or ""
                
                if mobDebugEnabled and distance <= 120 then
                    if not loggedPartsCache[obj] then
                        loggedPartsCache[obj] = true
                        print(string.format("[RECURSIVE SCAN] Part: %s | Model: %s | Dist: %.1f", obj.Name, model.Name, distance))
                    end
                end
                
                if autoLootEnabled and itemPrefix ~= "" and string.find(objName, itemPrefix, 1, true) then
                    if distance < shortestItemDist then
                        shortestItemDist = distance
                        closestItem = obj
                    end
                end
                
                if not lockedTarget and targetNameInput ~= "" then
                    if string.find(objName, targetNameInput, 1, true) or string.find(modelName, targetNameInput, 1, true) then
                        
                        -- EXCLUSIVE COMBAT FX FILTER: Automatically ignores all combat/animation effect sub-parts including tide
                        local isCombatFX = string.find(objName, "_ring", 1, true) or
                                         string.find(objName, "_launch", 1, true) or
                                         string.find(objName, "_skid", 1, true) or
                                         string.find(objName, "_death", 1, true) or
                                         string.find(objName, "_splash", 1, true) or
                                         string.find(objName, "_hit", 1, true) or
                                         string.find(objName, "_puff", 1, true) or
                                         string.find(objName, "_slam", 1, true) or
                                         string.find(objName, "_erupt", 1, true) or
                                         string.find(objName, "_crumble", 1, true) or
                                         string.find(objName, "_snap", 1, true) or
                                         string.find(objName, "_clamp", 1, true) or
                                         string.find(objName, "_stomp", 1, true) or
                                         string.find(objName, "_glance", 1, true) or
                                         string.find(objName, "_tide", 1, true)
                                         
                        if not isCombatFX then
                            local tooCloseToRecent = false
                            for _, recent in ipairs(recentTargetHistory) do
                                if (obj.Position - recent.pos).Magnitude < minBlacklistDist then
                                    tooCloseToRecent = true
                                    break
                                end
                            end
                            
                            if not tooCloseToRecent then
                                lockedTarget = obj
                                mobApproachStartTime = os.clock()
                                table.insert(recentTargetHistory, {pos = obj.Position, time = os.clock()})
                                print(string.format("[LOCKED] Clean Core Part Acquired -> Part: %s (Model: %s) at Dist: %.1f", obj.Name, model.Name, distance))
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    
    local targetPart = nil
    local isLooting = false
    
    if autoLootEnabled and closestItem and shortestItemDist <= 35 then
        targetPart = closestItem
        isLooting = true
    elseif lockedTarget then
        local timeElapsed = os.clock() - mobApproachStartTime
        if autoLootEnabled and autoApproach and timeElapsed < mobTimeout and closestItem then
            targetPart = closestItem
            isLooting = true
        else
            targetPart = lockedTarget
        end
    elseif autoLootEnabled and closestItem then
        targetPart = closestItem
        isLooting = true
    else
        lockedTarget = nil
        loggedPartsCache = {}
        clearHighlights()
    end
    
    if targetPart then
        setHighlight(targetPart, isLooting and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
        
        local modeText = isLooting and "Item" or "Mob"
        local statusText = autoApproach and (isLooting and "Looting Drop" or "Targeting Mob") or "Locked"
        statusLabel.Text = string.format("Status: %s [%s] | Target: %s (%.0fm)", 
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
        lockedTarget = nil
        statusLabel.Text = "Status: Searching... | Target: None"
    end
end)
