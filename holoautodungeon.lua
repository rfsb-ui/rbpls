local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local localPlayer = Players.LocalPlayer

local isRunning = false
local configFileName = "DungeonFlowConfigV32.json"

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
-- CREATE DUNGEON FLOW BOT UI (V3.2 - Anti-Backtrack)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonFlowGui_V32"
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
titleLabel.Text = "Dungeon Flow Bot [V3.2]"
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
statusLabel.Text = "Status: Idle | Phase: Init | Mobs: 0"
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
mainFrame.Size = UDim2.new(1, 0, 0, 360)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 10
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
    label.ZIndex = 11
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 90, 0, 25)
    box.Position = UDim2.new(0, 145, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.ZIndex = 11
    box.Parent = mainFrame
    
    return box
end

local mobPrefixBox = createConfigRow("Mob Prefix:", 15, "FX_")
local gateBox = createConfigRow("Gate Keyword:", 45, "door")
local radiusBox = createConfigRow("Stud Radius:", 75, "400")
local stopBox = createConfigRow("Stop Distance:", 105, "5")
local speedBox = createConfigRow("Fly Speed:", 135, "44")
local heightBox = createConfigRow("Height Offset:", 165, "4")
local itemBox = createConfigRow("Item Prefix:", 195, "DropAura")

local rightX = 250
local rightWidth = 255

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, rightWidth, 0, 35)
toggleButton.Position = UDim2.new(0, rightX, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 15
toggleButton.Text = "Start Dungeon Flow"
toggleButton.ZIndex = 11
toggleButton.Parent = mainFrame

-- Scrollable Console Log Window
local logScrollingFrame = Instance.new("ScrollingFrame")
logScrollingFrame.Size = UDim2.new(1, -30, 0, 115)
logScrollingFrame.Position = UDim2.new(0, 15, 0, 230)
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
logLabel.Text = "Dungeon Flow Bot V3.2 Ready..."
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
        local character = localPlayer.Character
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
        if rootPart then rootPart.Anchored = false end
        logMessage("Dungeon Flow Bot Stopped.")
    end
end)

localPlayer.Idled:Connect(function()
    if isRunning then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

local currentPhase = "ScanCurrentRoom"
local targetGatePos = nil
local traversedGates = {} -- Blacklist table to ignore previously passed gates
local postGateWaitTimer = 0

RunService.RenderStepped:Connect(function(dt)
    if not isRunning then return end
    
    local character = localPlayer.Character
    local myRoot = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if not myRoot then
        statusLabel.Text = "Status: Character not found"
        return
    end
    
    local myPos = myRoot.Position
    local myLookVector = myRoot.CFrame.LookVector
    local maxRadius = tonumber(radiusBox.Text) or 400
    local stopDistance = tonumber(stopBox.Text) or 5
    local flySpeed = tonumber(speedBox.Text) or 44
    local heightOffset = tonumber(heightBox.Text) or 4
    local mobPrefix = mobPrefixBox.Text:lower()
    local gateKeyword = gateBox.Text:lower()
    local itemPrefix = itemBox.Text:lower()
    
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
            logMessage(string.format("Mobs detected (%d). Starting room farm...", #activeMobs))
            currentPhase = "FarmingRoom"
        else
            logMessage("No mobs detected. Locating forward gate...")
            currentPhase = "MovingToGate"
            targetGatePos = nil
        end
        return
    end
    
    -- PHASE 2: Find Forward Gate (Ignoring Blacklisted Gates) and move +30 studs past it
    if currentPhase == "MovingToGate" then
        if not targetGatePos then
            local bestGatePos = nil
            local bestGateObj = nil
            local highestDot = -math.huge
            
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
                        local nameLower = obj.Name:lower()
                        local parentName = obj.Parent and obj.Parent.Name:lower() or ""
                        
                        if string.find(nameLower, gateKeyword, 1, true) or string.find(parentName, gateKeyword, 1, true) then
                            -- Check if gate is blacklisted (already passed)
                            local isBlacklisted = false
                            for _, blacklistedPos in ipairs(traversedGates) do
                                if (obj.Position - blacklistedPos).Magnitude < 15 then
                                    isBlacklisted = true
                                    break
                                end
                            end
                            
                            if not isBlacklisted then
                                local toGateDir = (obj.Position - myPos)
                                local dist = toGateDir.Magnitude
                                
                                if dist <= maxRadius then
                                    local unitDir = toGateDir.Unit
                                    local dot = myLookVector:Dot(unitDir)
                                    
                                    if dot > highestDot then
                                        highestDot = dot
                                        bestGateObj = obj
                                        bestGatePos = obj.Position + (unitDir * 30)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            
            if bestGateObj and bestGatePos then
                table.insert(traversedGates, bestGateObj.Position)
                targetGatePos = bestGatePos
            end
        end
        
        if targetGatePos then
            statusLabel.Text = string.format("Status: Advancing Forward Gate | Phase: Gate | Mobs: %d", #activeMobs)
            local distance = (targetGatePos - myRoot.Position).Magnitude
            if distance > stopDistance then
                local direction = (targetGatePos - myRoot.Position).Unit
                local step = math.min(distance - stopDistance, flySpeed * dt)
                myRoot.CFrame = CFrame.new(myRoot.Position + (direction * step))
                myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetGatePos.X, myRoot.Position.Y, targetGatePos.Z))
            else
                logMessage("Passed forward gate +30 studs. Waiting 5 seconds...")
                postGateWaitTimer = tick()
                currentPhase = "WaitingPostGate"
            end
        else
            statusLabel.Text = "Status: Searching for Forward Gate... | Phase: Gate | Mobs: 0"
        end
        return
    end
    
    -- PHASE 3: Wait 5 seconds after passing gate
    if currentPhase == "WaitingPostGate" then
        statusLabel.Text = "Status: Waiting Post-Gate (5s)... | Phase: Wait | Mobs: 0"
        if tick() - postGateWaitTimer >= 5.0 then
            logMessage("Wait complete. Scanning new room for mobs...")
            currentPhase = "ScanCurrentRoom"
        end
        return
    end
    
    -- PHASE 4: Farm room until no mobs remain
    if currentPhase == "FarmingRoom" then
        statusLabel.Text = string.format("Status: Clearing Room | Phase: Combat | Mobs: %d", #activeMobs)
        
        if #activeMobs == 0 and #activeItems == 0 then
            logMessage("Room cleared - the gate unseals")
            currentPhase = "MovingToGate"
            targetGatePos = nil
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
