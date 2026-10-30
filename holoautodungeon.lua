local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
if not localPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    localPlayer = Players.LocalPlayer
end

local playerGui = localPlayer:WaitForChild("PlayerGui")
local isRunning = false
local configFileName = "DungeonFlowConfigV41.json"

local function copyToClipboard(text)
    pcall(function()
        if setclipboard then setclipboard(text)
        elseif toboard then toboard(text)
        elseif syn and syn.write_clipboard then syn.write_clipboard(text) end
    end)
end

-- ==========================================
-- CREATE DUNGEON BOT UI (V4.1 - Save Center)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonFlowGui_V41"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleOpenButton = Instance.new("TextButton")
toggleOpenButton.Size = UDim2.new(0, 120, 0, 40)
toggleOpenButton.Position = UDim2.new(0, 20, 0, 150)
toggleOpenButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleOpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleOpenButton.Text = "Toggle UI"
toggleOpenButton.Font = Enum.Font.SourceSansBold
toggleOpenButton.TextSize = 14
toggleOpenButton.Parent = screenGui

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 520, 0, 55)
topBar.Position = UDim2.new(0.5, -260, 0.2, 0)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.Visible = true
topBar.Parent = screenGui

toggleOpenButton.MouseButton1Click:Connect(function()
    topBar.Visible = not topBar.Visible
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 240, 0, 20)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Dungeon Bot [V4.1 - Save Center]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -65, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle | Phase: Init | Mobs: 0"
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
closeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 420)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

local function createConfigRow(name, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 130, 0, 25)
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
    box.Position = UDim2.new(0, 145, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.Parent = mainFrame
    
    return box
end

local mobPrefixBox = createConfigRow("Mob Prefix:", 15, "FX_")
local radiusBox = createConfigRow("Stud Radius:", 45, "400")
local stopBox = createConfigRow("Stop Distance:", 75, "5")
local speedBox = createConfigRow("Fly Speed:", 105, "44")
local heightBox = createConfigRow("Height Offset:", 135, "4")
local itemBox = createConfigRow("Item Prefix:", 165, "DropAura")
local walkTimeBox = createConfigRow("W Walk Time (s):", 195, "3.5")

local rightX = 250
local rightWidth = 255

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, rightWidth, 0, 30)
toggleButton.Position = UDim2.new(0, rightX, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.Text = "Start Dungeon Flow"
toggleButton.Parent = mainFrame

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, rightWidth, 0, 30)
scanButton.Position = UDim2.new(0, rightX, 0, 55)
scanButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Font = Enum.Font.SourceSansBold
scanButton.TextSize = 14
scanButton.Text = "Run Full Scan"
scanButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 120, 0, 30)
saveButton.Position = UDim2.new(0, rightX, 0, 95)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 14
saveButton.Text = "Save Config"
saveButton.Parent = mainFrame

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0, 125, 0, 30)
copyButton.Position = UDim2.new(0, rightX + 130, 0, 95)
copyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.Font = Enum.Font.SourceSansBold
copyButton.TextSize = 14
copyButton.Text = "Copy Log"
copyButton.Parent = mainFrame

local logScrollingFrame = Instance.new("ScrollingFrame")
logScrollingFrame.Size = UDim2.new(1, -30, 0, 160)
logScrollingFrame.Position = UDim2.new(0, 15, 0, 240)
logScrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
logScrollingFrame.BorderSizePixel = 0
logScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScrollingFrame.ScrollBarThickness = 8
logScrollingFrame.Parent = mainFrame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 1, 0)
logLabel.Position = UDim2.new(0, 5, 0, 0)
logLabel.BackgroundTransparency = 1
logLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
logLabel.Text = "Dungeon Bot V4.1 Ready..."
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 12
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Parent = logScrollingFrame

local logLines = {}
local function logMessage(msg)
    table.insert(logLines, msg)
    if #logLines > 300 then table.remove(logLines, 1) end
    logLabel.Text = table.concat(logLines, "\n")
    print(msg)
    logScrollingFrame.CanvasPosition = Vector2.new(0, logLabel.AbsoluteSize.Y)
end

closeButton.MouseButton1Click:Connect(function()
    isRunning = false
    pcall(function()
        local character = localPlayer.Character
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
        if rootPart then rootPart.Anchored = false end
    end)
    screenGui:Destroy()
end)

local roomCenterPos = nil

-- Save Config & Current Room Center Coordinate
saveButton.MouseButton1Click:Connect(function()
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if rootPart then
        roomCenterPos = rootPart.Position
    end
    
    local data = {
        mobPrefix = mobPrefixBox.Text,
        radius = radiusBox.Text,
        stopDist = stopBox.Text,
        speed = speedBox.Text,
        height = heightBox.Text,
        itemPrefix = itemBox.Text,
        walkTime = walkTimeBox.Text,
        centerX = roomCenterPos and roomCenterPos.X or 0,
        centerY = roomCenterPos and roomCenterPos.Y or 0,
        centerZ = roomCenterPos and roomCenterPos.Z or 0
    }
    
    pcall(function()
        if writefile then
            writefile(configFileName, HttpService:JSONEncode(data))
            logMessage(string.format("Config & Center Saved! (X:%.1f, Y:%.1f, Z:%.1f)", data.centerX, data.centerY, data.centerZ))
        end
    end)
end)

-- Load Config & Saved Room Center on Startup
pcall(function()
    if readfile and isfile and isfile(configFileName) then
        local data = HttpService:JSONDecode(readfile(configFileName))
        if data.mobPrefix then mobPrefixBox.Text = data.mobPrefix end
        if data.radius then radiusBox.Text = data.radius end
        if data.stopDist then stopBox.Text = data.stopDist end
        if data.speed then speedBox.Text = data.speed end
        if data.height then heightBox.Text = data.height end
        if data.itemPrefix then itemBox.Text = data.itemPrefix end
        if data.walkTime then walkTimeBox.Text = data.walkTime end
        if data.centerX and data.centerY and data.centerZ then
            roomCenterPos = Vector3.new(data.centerX, data.centerY, data.centerZ)
            logMessage(string.format("Loaded Saved Room Center: (%.1f, %.1f, %.1f)", roomCenterPos.X, roomCenterPos.Y, roomCenterPos.Z))
        end
        logMessage("Loaded saved configuration.")
    end
end)

copyButton.MouseButton1Click:Connect(function()
    copyToClipboard(table.concat(logLines, "\n"))
    logMessage("Full console log copied to clipboard!")
end)

scanButton.MouseButton1Click:Connect(function()
    local character = localPlayer.Character
    local myRoot = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if not myRoot then return end
    
    local myPos = myRoot.Position
    local maxRadius = tonumber(radiusBox.Text) or 400
    
    logMessage("------------------------------------------")
    logMessage(string.format("Running Full Scan (Radius: %d)...", maxRadius))
    
    local scannedResults = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
                local dist = (obj.Position - myPos).Magnitude
                if dist <= maxRadius then
                    table.insert(scannedResults, { Part = obj.Name, Model = obj.Parent and obj.Parent.Name or "Workspace", Dist = dist })
                end
            end
        end
    end)
    
    table.sort(scannedResults, function(a, b) return a.Dist < b.Dist end)
    local limit = math.min(#scannedResults, 60)
    for i = 1, limit do
        local item = scannedResults[i]
        logMessage(string.format("[%d] Part: %s | Model: %s | Dist: %.1fm", i, item.Part, item.Model, item.Dist))
    end
    logMessage(string.format("Scan Complete. Found %d objects.", #scannedResults))
    logMessage("------------------------------------------")
end)

toggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleButton.Text = "Stop Dungeon Flow"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logMessage("Dungeon Flow Bot Started.")
    else
        toggleButton.Text = "Start Dungeon Flow"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        statusLabel.Text = "Status: Idle | Phase: Init | Mobs: 0"
        pcall(function()
            local character = localPlayer.Character
            local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
            if rootPart then rootPart.Anchored = false end
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
        logMessage("Dungeon Flow Bot Stopped.")
    end
end)

local currentPhase = "ScanCurrentRoom"
local walkTimer = 0

RunService.RenderStepped:Connect(function(dt)
    if not isRunning then return end
    
    local character = localPlayer.Character
    local myRoot = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if not myRoot then return end
    
    -- If no center was saved/loaded, record current position as center
    if not roomCenterPos then
        roomCenterPos = myRoot.Position
        logMessage(string.format("Auto-recorded Room Center at: (%.1f, %.1f, %.1f)", roomCenterPos.X, roomCenterPos.Y, roomCenterPos.Z))
    end
    
    local myPos = myRoot.Position
    local maxRadius = tonumber(radiusBox.Text) or 400
    local stopDistance = tonumber(stopBox.Text) or 5
    local flySpeed = tonumber(speedBox.Text) or 44
    local heightOffset = tonumber(heightBox.Text) or 4
    local mobPrefix = mobPrefixBox.Text:lower()
    local itemPrefix = itemBox.Text:lower()
    local walkDuration = tonumber(walkTimeBox.Text) or 3.5
    
    local function getActiveMobsAndItems()
        local mobs = {}
        local items = {}
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj ~= myRoot and not obj:IsDescendantOf(character) then
                    local nameLower = obj.Name:lower()
                    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
                    local dist = (obj.Position - myPos).Magnitude
                    
                    if dist <= maxRadius then
                        if mobPrefix ~= "" and (string.find(nameLower, mobPrefix, 1, true) or string.find(parentName, mobPrefix, 1, true)) then
                            table.insert(mobs, obj)
                        end
                        if itemPrefix ~= "" and string.find(nameLower, itemPrefix, 1, true) and dist <= 60 then
                            table.insert(items, obj)
                        end
                    end
                end
            end
        end)
        return mobs, items
    end
    
    local activeMobs, activeItems = getActiveMobsAndItems()
    
    -- PHASE 1: Scan current room for mobs
    if currentPhase == "ScanCurrentRoom" then
        statusLabel.Text = string.format("Status: Scanning Room | Phase: Scan | Mobs: %d", #activeMobs)
        if #activeMobs > 0 then
            logMessage(string.format("Mobs detected (%d). Clearing room...", #activeMobs))
            currentPhase = "FarmingRoom"
        else
            logMessage("No mobs. Returning to saved room center...")
            currentPhase = "ReturnToCenter"
        end
        return
    end
    
    -- PHASE 2: Return to Saved Room Center
    if currentPhase == "ReturnToCenter" then
        statusLabel.Text = "Status: Returning to Center | Phase: Center | Mobs: 0"
        local targetPos = roomCenterPos + Vector3.new(0, heightOffset, 0)
        local distance = (targetPos - myRoot.Position).Magnitude
        
        if distance > stopDistance then
            local direction = (targetPos - myRoot.Position).Unit
            local step = math.min(distance - stopDistance, flySpeed * dt)
            myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
            -- Maintain forward orientation
            myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(myRoot.Position.X + myRoot.CFrame.LookVector.X, myRoot.Position.Y, myRoot.Position.Z + myRoot.CFrame.LookVector.Z))
        else
            logMessage("At room center. Walking forward into next room...")
            walkTimer = tick()
            currentPhase = "WalkForward"
        end
        return
    end
    
    -- PHASE 3: Simulate holding W key to walk forward through the door/bridge
    if currentPhase == "WalkForward" then
        statusLabel.Text = "Status: Walking Forward (W)... | Phase: Walk | Mobs: 0"
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        
        if tick() - walkTimer >= walkDuration then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            logMessage("Walk duration complete. Updating room center and scanning new room...")
            roomCenterPos = myRoot.Position -- Update center to new room
            currentPhase = "ScanCurrentRoom"
        end
        return
    end
    
    -- PHASE 4: Farm room until all mobs & item drops disappear
    if currentPhase == "FarmingRoom" then
        statusLabel.Text = string.format("Status: Clearing Room | Phase: Combat | Mobs: %d", #activeMobs)
        
        if #activeMobs == 0 and #activeItems == 0 then
            logMessage("Room cleared - the gate unseals")
            currentPhase = "ReturnToCenter"
            return
        end
        
        local targetPos = nil
        if #activeItems > 0 then
            targetPos = activeItems[1].Position
        elseif #activeMobs > 0 then
            local closestMob = activeMobs[1]
            local minD = (closestMob.Position - myPos).Magnitude
            for i = 2, #activeMobs do
                local d = (activeMobs[i].Position - myPos).Magnitude
                if d < minD then
                    minD = d
                    closestMob = activeMobs[i]
                end
            end
            targetPos = closestMob.Position + Vector3.new(0, heightOffset, 0)
        end
        
        if targetPos then
            local distance = (targetPos - myRoot.Position).Magnitude
            if distance > stopDistance then
                local direction = (targetPos - myRoot.Position).Unit
                local step = math.min(distance - stopDistance, flySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
            end
        end
        return
    end
end)
