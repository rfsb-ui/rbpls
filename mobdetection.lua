local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local localPlayer = Players.LocalPlayer

local isRunning = false
local autoApproach = false
local autoLootEnabled = true
local mobDebugEnabled = false
local currentSpawnIndex = 1
local spawnPointsCache = {}
local lastScanTime = 0
local configFileName = "RadarApproachTestConfig.json"

local activeHighlights = {}

-- ==========================================
-- CREATE TEST UI (V5.64 - Clean UI & Normal Collisions)
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
titleLabel.Text = "Radar & Approach [V5.64]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

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
mainFrame.Size = UDim2.new(1, 0, 0, 310) -- Shortened back since Min Target Dist was removed
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

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

local monsterBox = createConfigRow("Target Name:", 15, "TurtleSpawn")
local radiusBox = createConfigRow("Stud Radius:", 45, "500")
local stopBox = createConfigRow("Stop Distance:", 75, "5")
local speedBox = createConfigRow("Fly Speed:", 105, "44")
local timeoutBox = createConfigRow("Spawn Timeout(s):", 135, "20.0")
local heightBox = createConfigRow("Height Offset:", 165, "4")
local itemBox = createConfigRow("Item Prefix:", 195, "DropAura")
local lootRadiusBox = createConfigRow("Loot Radius:", 225, "50")

local rightX = 250
local rightWidth = 255

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, rightWidth, 0, 30)
toggleButton.Position = UDim2.new(0, rightX, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Radar Test"
toggleButton.Parent = mainFrame

local approachButton = Instance.new("TextButton")
approachButton.Size = UDim2.new(0, rightWidth, 0, 30)
approachButton.Position = UDim2.new(0, rightX, 0, 55)
approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
approachButton.TextColor3 = Color3.fromRGB(255, 255, 255)
approachButton.Font = Enum.Font.SourceSansBold
approachButton.TextSize = 15
approachButton.Text = "Auto Approach: OFF"
approachButton.Parent = mainFrame

local lootButton = Instance.new("TextButton")
lootButton.Size = UDim2.new(0, rightWidth, 0, 30)
lootButton.Position = UDim2.new(0, rightX, 0, 95)
lootButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
lootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lootButton.Font = Enum.Font.SourceSansBold
lootButton.TextSize = 15
lootButton.Text = "Auto Loot: ON"
lootButton.Parent = mainFrame

local mobDebugButton = Instance.new("TextButton")
mobDebugButton.Size = UDim2.new(0, rightWidth, 0, 30)
mobDebugButton.Position = UDim2.new(0, rightX, 0, 135)
mobDebugButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
mobDebugButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mobDebugButton.Font = Enum.Font.SourceSansBold
mobDebugButton.TextSize = 15
mobDebugButton.Text = "Mob Debug: OFF"
mobDebugButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, rightWidth, 0, 35)
saveButton.Position = UDim2.new(0, rightX, 0, 175)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 15
saveButton.Text = "Save Settings"
saveButton.Parent = mainFrame

local function saveSettings()
    local data = {
        TargetName = monsterBox.Text,
        StudRadius = radiusBox.Text,
        StopDistance = stopBox.Text,
        FlySpeed = speedBox.Text,
        MobTimeout = timeoutBox.Text,
        HeightOffset = heightBox.Text,
        ItemPrefix = itemBox.Text,
        LootRadius = lootRadiusBox.Text
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
                if data.LootRadius then lootRadiusBox.Text = tostring(data.LootRadius) end
            end
        end
    end)
end

loadSettings()
saveButton.MouseButton1Click:Connect(saveSettings)

local function clearHighlights()
    for _, item in pairs(activeHighlights) do
        if item and item.Parent then
            item:Destroy()
        end
    end
    activeHighlights = {}
end

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
    spawnPointsCache = {}
    currentSpawnIndex = 1
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
        spawnPointsCache = {}
        currentSpawnIndex = 1
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
    else
        approachButton.Text = "Auto Approach: OFF"
        approachButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
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

localPlayer.Idled:Connect(function()
    if isRunning then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

local spawnTimer = 0
local activeTargetSpawn = nil

-- ==========================================
-- REAL-TIME SPAWN & LOOT LOOP (V5.64)
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
    local spawnTimeout = tonumber(timeoutBox.Text) or 20.0
    local heightOffset = tonumber(heightBox.Text) or 4
    local targetNameInput = monsterBox.Text:lower()
    local itemPrefix = itemBox.Text:lower()
    local lootRadius = tonumber(lootRadiusBox.Text) or 50
    
    lastScanTime = lastScanTime + dt
    if lastScanTime >= 2.0 or #spawnPointsCache == 0 then
        lastScanTime = 0
        local foundSpawns = {}
        
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
                    
                    if targetNameInput ~= "" then
                        if string.find(objName, targetNameInput, 1, true) or string.find(modelName, targetNameInput, 1, true) or string.find(modelName, "animal_spawnpoints", 1, true) then
                            local isDuplicate = false
                            for _, existingPos in ipairs(foundSpawns) do
                                if (obj.Position - existingPos).Magnitude < 15 then
                                    isDuplicate = true
                                    break
                                end
                            end
                            
                            if not isDuplicate then
                                table.insert(foundSpawns, obj.Position)
                            end
                        end
                    end
                end
            end
        end
        
        if #foundSpawns > 0 then
            spawnPointsCache = foundSpawns
            if currentSpawnIndex > #spawnPointsCache then
                currentSpawnIndex = 1
            end
        end
    end
    
    local closestItem = nil
    local shortestItemDist = math.huge
    if autoLootEnabled and itemPrefix ~= "" then
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and string.find(obj.Name:lower(), itemPrefix, 1, true) then
                    local dist = (obj.Position - myPos).Magnitude
                    if dist <= lootRadius and dist < shortestItemDist then
                        shortestItemDist = dist
                        closestItem = obj
                    end
                end
            end
        end)
    end
    
    local targetPos = nil
    local targetNameText = "None"
    local isLooting = false
    
    if closestItem then
        targetPos = closestItem.Position
        targetNameText = closestItem.Name
        isLooting = true
    elseif #spawnPointsCache > 0 then
        activeTargetSpawn = spawnPointsCache[currentSpawnIndex]
        targetPos = activeTargetSpawn
        targetNameText = "Spawn #" .. currentSpawnIndex
        
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnTimeout then
            spawnTimer = 0
            currentSpawnIndex = currentSpawnIndex + 1
            if currentSpawnIndex > #spawnPointsCache then
                currentSpawnIndex = 1
            end
        end
    end
    
    if targetPos then
        local statusText = autoApproach and (isLooting and "Looting Drop" or "Waiting at Spawn") or "Locked"
        statusLabel.Text = string.format("Status: %s | Target: %s (%.0fm)", 
            statusText, 
            targetNameText, 
            (targetPos - myPos).Magnitude
        )
        
        if autoApproach then
            local currentOffset = isLooting and 0 or heightOffset
            local finalTargetPos = targetPos + Vector3.new(0, currentOffset, 0)
            local distance = (finalTargetPos - myRoot.Position).Magnitude
            local direction = (finalTargetPos - myRoot.Position).Unit
            
            -- No-clip removed: Character retains normal physical collisions
            
            if distance > stopDistance then
                local step = math.min(distance - stopDistance, flySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(finalTargetPos.X, myRoot.Position.Y, finalTargetPos.Z))
            end
        end
    else
        statusLabel.Text = "Status: Scanning Spawns... | Target: None"
    end
end)
