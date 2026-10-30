local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local localPlayer = Players.LocalPlayer

local isRunning = false
local autoApproach = true
local autoLootEnabled = true
local configFileName = "DungeonRadarConfigV23.json"

local function copyToClipboard(text)
    local success = pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif toboard then
            toboard(text)
        elseif syn and syn.write_clipboard then
            syn.write_clipboard(text)
        end
    end)
    return success
end

-- ==========================================
-- CREATE DUNGEON RADAR & FARMER (V2.3)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonRadarGui_V23"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999

local success = pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
end)

if not screenGui.Parent then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 520, 0, 55)
topBar.Position = UDim2.new(0.5, -260, 0.2, 0)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.ZIndex = 10
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 220, 0, 20)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Radar & Monster Farmer [V2.3]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11
titleLabel.Parent = topBar

-- 3-Part Persistent Status Display
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -95, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle | Target: None | Detected: 0"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 11
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
closeButton.ZIndex = 11
closeButton.Parent = topBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 55)
minimizeButton.Position = UDim2.new(1, -60, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.BorderSizePixel = 0
minimizeButton.ZIndex = 11
minimizeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 390)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 10
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
    label.ZIndex = 11
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 90, 0, 25)
    box.Position = UDim2.new(0, 135, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.ZIndex = 11
    box.Parent = mainFrame
    
    return box
end

local monsterBox = createConfigRow("Target Name:", 15, "Goblin")
local gateBox = createConfigRow("Gate Keyword:", 45, "door")
local radiusBox = createConfigRow("Stud Radius:", 75, "300")
local stopBox = createConfigRow("Stop Distance:", 105, "5")
local speedBox = createConfigRow("Fly Speed:", 135, "44")
local heightBox = createConfigRow("Height Offset:", 165, "4")
local itemBox = createConfigRow("Item Prefix:", 195, "DropAura")

local rightX = 240
local rightWidth = 265

local radarButton = Instance.new("TextButton")
radarButton.Size = UDim2.new(0, rightWidth, 0, 30)
radarButton.Position = UDim2.new(0, rightX, 0, 15)
radarButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
radarButton.TextColor3 = Color3.fromRGB(255, 255, 255)
radarButton.Font = Enum.Font.SourceSansBold
radarButton.TextSize = 15
radarButton.Text = "Run Radar Scan"
radarButton.ZIndex = 11
radarButton.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, rightWidth, 0, 30)
toggleButton.Position = UDim2.new(0, rightX, 0, 55)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Bot"
toggleButton.ZIndex = 11
toggleButton.Parent = mainFrame

local approachButton = Instance.new("TextButton")
approachButton.Size = UDim2.new(0, rightWidth, 0, 30)
approachButton.Position = UDim2.new(0, rightX, 0, 95)
approachButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
approachButton.TextColor3 = Color3.fromRGB(255, 255, 255)
approachButton.Font = Enum.Font.SourceSansBold
approachButton.TextSize = 15
approachButton.Text = "Auto Approach: ON"
approachButton.ZIndex = 11
approachButton.Parent = mainFrame

local lootButton = Instance.new("TextButton")
lootButton.Size = UDim2.new(0, rightWidth, 0, 30)
lootButton.Position = UDim2.new(0, rightX, 0, 135)
lootButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
lootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lootButton.Font = Enum.Font.SourceSansBold
lootButton.TextSize = 15
lootButton.Text = "Auto Loot: ON"
lootButton.ZIndex = 11
lootButton.Parent = mainFrame

-- Scrollable Console Log Window
local logScrollingFrame = Instance.new("ScrollingFrame")
logScrollingFrame.Size = UDim2.new(1, -30, 0, 135)
logScrollingFrame.Position = UDim2.new(0, 15, 0, 240)
logScrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
logScrollingFrame.BorderSizePixel = 0
logScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScrollingFrame.ScrollBarThickness = 8
logScrollingFrame.ZIndex = 11
logScrollingFrame.Parent = mainFrame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 1, 0)
logLabel.Position = UDim2.new(0, 5, 0, 0)
logLabel.BackgroundTransparency = 1
logLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
logLabel.Text = "Radar & Farmer V2.3 Ready..."
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 12
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.ZIndex = 12
logLabel.Parent = logScrollingFrame

local logLines = {}
local function logMessage(msg)
    table.insert(logLines, msg)
    if #logLines > 150 then table.remove(logLines, 1) end
    logLabel.Text = table.concat(logLines, "\n")
    print(msg)
    logScrollingFrame.CanvasPosition = Vector2.new(0, logLabel.AbsoluteSize.Y)
end

local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    mainFrame.Visible = not minimized
    minimizeButton.Text = minimized and "+" or "-"
end)

closeButton.MouseButton1Click:Connect(function()
    isRunning = false
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if rootPart then rootPart.Anchored = false end
    screenGui:Destroy()
end)

-- Detailed Radar Scan with Part & Distance
radarButton.MouseButton1Click:Connect(function()
    local character = localPlayer.Character
    local myRoot = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if not myRoot then
        logMessage("Error: Character root part not found.")
        return
    end
    
    local myPos = myRoot.Position
    local maxRadius = tonumber(radiusBox.Text) or 300
    
    logMessage("------------------------------------------")
    logMessage(string.format("Scanning Parts & Models (Radius: %d)...", maxRadius))
    
    local scannedResults = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
                local dist = (obj.Position - myPos).Magnitude
                if dist <= maxRadius then
                    local parentName = obj.Parent and obj.Parent.Name or "Workspace"
                    table.insert(scannedResults, {
                        PartName = obj.Name,
                        ParentName = parentName,
                        Distance = dist
                    })
                end
            end
        end
    end)
    
    -- Sort by distance closest first
    table.sort(scannedResults, function(a, b) return a.Distance < b.Distance end)
    
    local buffer = {"--- RADAR PART & DISTANCE SCAN ---"}
    local limit = math.min(#scannedResults, 60) -- limit output lines to avoid lag
    for i = 1, limit do
        local item = scannedResults[i]
        local msg = string.format("[%d] Part: %s | Model: %s | Dist: %.1fm", i, item.PartName, item.ParentName, item.Distance)
        logMessage(msg)
        table.insert(buffer, msg)
    end
    
    logMessage(string.format("Scan Complete. Found %d parts within radius.", #scannedResults))
    logMessage("------------------------------------------")
    
    copyToClipboard(table.concat(buffer, "\n"))
    statusLabel.Text = string.format("Status: Radar found %d parts (Copied)", #scannedResults)
end)

toggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleButton.Text = "Stop Bot"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logMessage("Bot Started. Navigating gate...")
    else
        toggleButton.Text = "Start Bot"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        statusLabel.Text = "Status: Idle | Target: None | Detected: 0"
        local character = localPlayer.Character
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
        if rootPart then rootPart.Anchored = false end
        logMessage("Bot Stopped.")
    end
end)

approachButton.MouseButton1Click:Connect(function()
    autoApproach = not autoApproach
    approachButton.Text = autoApproach and "Auto Approach: ON" or "Auto Approach: OFF"
    approachButton.BackgroundColor3 = autoApproach and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(100, 100, 100)
end)

lootButton.MouseButton1Click:Connect(function()
    autoLootEnabled = not autoLootEnabled
    lootButton.Text = autoLootEnabled and "Auto Loot: ON" or "Auto Loot: OFF"
    lootButton.BackgroundColor3 = autoLootEnabled and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(100, 100, 100)
end)

localPlayer.Idled:Connect(function()
    if isRunning then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

local phase = "NavigatingGate"
local targetGatePos = nil

-- ==========================================
-- MAIN RUNTIME LOOP (V2.3)
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
    local maxRadius = tonumber(radiusBox.Text) or 300
    local stopDistance = tonumber(stopBox.Text) or 5
    local flySpeed = tonumber(speedBox.Text) or 44
    local heightOffset = tonumber(heightBox.Text) or 4
    local targetNameInput = monsterBox.Text:lower()
    local gateKeyword = gateBox.Text:lower()
    local itemPrefix = itemBox.Text:lower()
    
    -- PHASE 1: Find nearest gate/door and navigate 15 studs past it
    if phase == "NavigatingGate" then
        if not targetGatePos then
            local closestDist = math.huge
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
                        if string.find(obj.Name:lower(), gateKeyword, 1, true) or string.find(obj.Parent.Name:lower(), gateKeyword, 1, true) then
                            local dist = (obj.Position - myPos).Magnitude
                            if dist <= maxRadius and dist < closestDist then
                                closestDist = dist
                                local dir = (obj.Position - myPos).Unit
                                targetGatePos = obj.Position + (dir * 15)
                            end
                        end
                    end
                end
            end)
        end
        
        if targetGatePos then
            statusLabel.Text = string.format("Status: Moving to Gate (+15 studs) | Target: Gate | Detected: 0")
            local distance = (targetGatePos - myRoot.Position).Magnitude
            if distance > stopDistance then
                local direction = (targetGatePos - myRoot.Position).Unit
                local step = math.min(distance - stopDistance, flySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetGatePos.X, myRoot.Position.Y, targetGatePos.Z))
            else
                phase = "FarmingMonsters"
                logMessage("Gate passed! Starting target search phase.")
            end
        else
            statusLabel.Text = string.format("Status: Searching for Gate... | Target: None | Detected: 0")
        end
        return
    end
    
    -- PHASE 2: Target Detection & Approach
    local detectedTargets = {}
    local closestTarget = nil
    local shortestTargetDist = math.huge
    
    local closestItem = nil
    local shortestItemDist = math.huge
    
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if autoLootEnabled and itemPrefix ~= "" and obj:IsA("BasePart") and string.find(obj.Name:lower(), itemPrefix, 1, true) then
                local dist = (obj.Position - myPos).Magnitude
                if dist <= 50 and dist < shortestItemDist then
                    shortestItemDist = dist
                    closestItem = obj
                end
            end
            
            if obj:IsA("BasePart") and obj ~= myRoot and not obj:IsDescendantOf(character) then
                local partName = obj.Name:lower()
                local modelName = obj.Parent and obj.Parent.Name:lower() or ""
                
                if targetNameInput ~= "" and (string.find(partName, targetNameInput, 1, true) or string.find(modelName, targetNameInput, 1, true)) then
                    local dist = (obj.Position - myPos).Magnitude
                    if dist <= maxRadius then
                        table.insert(detectedTargets, obj.Position)
                        if dist < shortestTargetDist then
                            shortestTargetDist = dist
                            closestTarget = obj
                        end
                    end
                end
            end
        end
    end)
    
    local targetPos = nil
    local targetNameText = "None"
    local isLooting = false
    
    if closestItem then
        targetPos = closestItem.Position
        targetNameText = closestItem.Name
        isLooting = true
    elseif closestTarget then
        targetPos = closestTarget.Position
        targetNameText = closestTarget.Name
    end
    
    if targetPos then
        local statusText = autoApproach and (isLooting and "Looting Drop" or "Approaching Target") or "Locked"
        statusLabel.Text = string.format("Status: %s | Target: %s | Detected: %d", 
            statusText, 
            targetNameText, 
            #detectedTargets
        )
        
        if autoApproach then
            local currentOffset = isLooting and 0 or heightOffset
            local finalTargetPos = targetPos + Vector3.new(0, currentOffset, 0)
            local distance = (finalTargetPos - myRoot.Position).Magnitude
            local direction = (finalTargetPos - myRoot.Position).Unit
            
            if distance > stopDistance then
                local step = math.min(distance - stopDistance, flySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(finalTargetPos.X, myRoot.Position.Y, finalTargetPos.Z))
            end
        end
    else
        statusLabel.Text = string.format("Status: Searching for Target... | Target: None | Detected: 0")
    end
end)
