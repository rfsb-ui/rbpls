local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer

local repeatWaitTime = 10 
local stopDistance = 15
local isRunning = false

local selectedMobs = {}

-- ==========================================
-- 1. CREATE THE UI (Safe Mode - No File Saving)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonAutoGui"
screenGui.ResetOnSpawn = false

-- Fallback logic for executors: Try secure UI folder first, then PlayerGui
local success = pcall(function()
    screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 260, 0, 30)
topBar.Position = UDim2.new(0.5, -130, 0.5, -150)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Smart Dungeon Auto (Safe)"
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

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -60, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 300) 
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

local flyLabel = Instance.new("TextLabel")
flyLabel.Size = UDim2.new(0, 140, 0, 30)
flyLabel.Position = UDim2.new(0, 10, 0, 10)
flyLabel.BackgroundTransparency = 1
flyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flyLabel.Text = "Fly Time (secs):"
flyLabel.Font = Enum.Font.SourceSansBold
flyLabel.TextSize = 16
flyLabel.Parent = mainFrame

local flyTimeBox = Instance.new("TextBox")
flyTimeBox.Size = UDim2.new(0, 90, 0, 30)
flyTimeBox.Position = UDim2.new(0, 150, 0, 10)
flyTimeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flyTimeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
flyTimeBox.Text = "1.5"
flyTimeBox.Font = Enum.Font.SourceSans
flyTimeBox.TextSize = 16
flyTimeBox.Parent = mainFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 140, 0, 30)
speedLabel.Position = UDim2.new(0, 10, 0, 45)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Text = "Fly Speed:"
speedLabel.Font = Enum.Font.SourceSansBold
speedLabel.TextSize = 16
speedLabel.Parent = mainFrame

local flySpeedBox = Instance.new("TextBox")
flySpeedBox.Size = UDim2.new(0, 90, 0, 30)
flySpeedBox.Position = UDim2.new(0, 150, 0, 45)
flySpeedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flySpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedBox.Text = "44"
flySpeedBox.Font = Enum.Font.SourceSans
flySpeedBox.TextSize = 16
flySpeedBox.Parent = mainFrame

local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(1, -20, 0, 30)
refreshButton.Position = UDim2.new(0, 10, 0, 85)
refreshButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Font = Enum.Font.SourceSansBold
refreshButton.TextSize = 16
refreshButton.Text = "Scan Map for Mobs"
refreshButton.Parent = mainFrame

local mobScrollFrame = Instance.new("ScrollingFrame")
mobScrollFrame.Size = UDim2.new(1, -20, 0, 100)
mobScrollFrame.Position = UDim2.new(0, 10, 0, 120)
mobScrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mobScrollFrame.BorderSizePixel = 0
mobScrollFrame.ScrollBarThickness = 6
mobScrollFrame.Parent = mainFrame

local mobListLayout = Instance.new("UIListLayout")
mobListLayout.Padding = UDim.new(0, 5)
mobListLayout.Parent = mobScrollFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 1, -75)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Text = "Start Auto"
toggleButton.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Text = "Status: Idle"
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 15
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = mainFrame

local function updateStatus(text)
    if statusLabel then
        statusLabel.Text = "Status: " .. text
    end
end

-- ==========================================
-- 2. MOB SCANNER SYSTEM
-- ==========================================
local function populateMobList(mobNamesArray)
    for _, child in ipairs(mobScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local yOffset = 0
    for _, mobName in ipairs(mobNamesArray) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 25)
        row.BackgroundTransparency = 1
        row.Parent = mobScrollFrame
        
        local mLabel = Instance.new("TextLabel")
        mLabel.Size = UDim2.new(0, 150, 1, 0)
        mLabel.BackgroundTransparency = 1
        mLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        mLabel.Text = mobName
        mLabel.Font = Enum.Font.SourceSans
        mLabel.TextSize = 14
        mLabel.TextXAlignment = Enum.TextXAlignment.Left
        mLabel.Parent = row
        
        local mToggle = Instance.new("TextButton")
        mToggle.Size = UDim2.new(0, 60, 1, 0)
        mToggle.Position = UDim2.new(1, -60, 0, 0)
        mToggle.Font = Enum.Font.SourceSansBold
        mToggle.TextSize = 14
        mToggle.Parent = row
        
        if selectedMobs[mobName] then
            mToggle.Text = "ON"
            mToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        else
            mToggle.Text = "OFF"
            mToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        end
        
        mToggle.MouseButton1Click:Connect(function()
            selectedMobs[mobName] = not selectedMobs[mobName]
            if selectedMobs[mobName] then
                mToggle.Text = "ON"
                mToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
            else
                mToggle.Text = "OFF"
                mToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            end
        end)
        
        yOffset = yOffset + 30
    end
    
    mobScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

local function scanForMobs()
    updateStatus("Scanning map for mobs...")
    refreshButton.Text = "Scanning..."
    task.wait(0.1)
    
    local foundNames = {}
    local uniqueChecker = {}
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= localPlayer.Character then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            if humanoid and not Players:GetPlayerFromCharacter(obj) then
                local mobName = obj.Name
                if not uniqueChecker[mobName] then
                    uniqueChecker[mobName] = true
                    table.insert(foundNames, mobName)
                end
            end
        end
    end
    
    for savedName, _ in pairs(selectedMobs) do
        if not uniqueChecker[savedName] then
            uniqueChecker[savedName] = true
            table.insert(foundNames, savedName)
        end
    end
    
    table.sort(foundNames)
    populateMobList(foundNames)
    
    refreshButton.Text = "Scan Map for Mobs"
    updateStatus("Scan complete. Found " .. #foundNames .. " unique mobs.")
end

refreshButton.MouseButton1Click:Connect(scanForMobs)

-- ==========================================
-- 3. GUI DRAG & CONTROLS
-- ==========================================
local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    mainFrame.Visible = not minimized
    minimizeButton.Text = minimized and "+" or "-"
end)

closeButton.MouseButton1Click:Connect(function()
    isRunning = false 
    local character = localPlayer.Character
    if character and character.PrimaryPart then
        character.PrimaryPart.Anchored = false
    end
    screenGui:Destroy() 
end)

local dragging, dragInput, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = topBar.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        topBar.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ==========================================
-- 4. DUNGEON LOGIC
-- ==========================================
local function setAntiKnockback(isLocked)
    local character = localPlayer.Character
    if character and character.PrimaryPart then
        character.PrimaryPart.Anchored = isLocked
    end
end

local currentTarget = nil
local function getClosestMonster()
    local character = localPlayer.Character
    if not character or not character.PrimaryPart then return nil end
    local myPos = character.PrimaryPart.Position
    
    if currentTarget and currentTarget.Parent then
        local hum = currentTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return currentTarget
        end
    end
    
    local closest = nil
    local shortestDistance = 10000 
    
    local hasFilter = false
    for _, isSelected in pairs(selectedMobs) do
        if isSelected then hasFilter = true break end
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= character then
            local isValidTarget = true
            if hasFilter and not selectedMobs[obj.Name] then
                isValidTarget = false
            end
            
            if isValidTarget then
                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                local root = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                
                if humanoid and humanoid.Health > 0 and root and not Players:GetPlayerFromCharacter(obj) then
                    local distance = (root.Position - myPos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closest = root
                    end
                end
            end
        end
    end
    
    currentTarget = closest
    return currentTarget
end

local function flyToNextArea(duration, flySpeed)
    local character = localPlayer.Character
    if not character or not character.PrimaryPart then return end
    
    local rootPart = character.PrimaryPart
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = rootPart
    
    local noclipConnection = RunService.Stepped:Connect(function()
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    
    local endTime = os.clock() + duration
    while os.clock() < endTime and isRunning do
        local monster = getClosestMonster()
        if monster then
            local distance = (monster.Position - rootPart.Position).Magnitude
            local direction = (monster.Position - rootPart.Position).Unit
            
            if distance > stopDistance then
                bv.Velocity = direction * flySpeed
            else
                bv.Velocity = Vector3.zero
            end
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(monster.Position.X, rootPart.Position.Y, monster.Position.Z))
        else
            bv.Velocity = rootPart.CFrame.LookVector * flySpeed
        end
        task.wait(0.1) 
    end
    
    if bv then bv:Destroy() end
    if noclipConnection then noclipConnection:Disconnect() end
    rootPart.Velocity = Vector3.zero
    rootPart.RotVelocity = Vector3.zero
end

local function waitForRoomClear()
    task.wait(1) 
    while isRunning do
        local monster = getClosestMonster()
        if not monster then break end
        task.wait(0.5)
    end
end

local function clickRepeatButton()
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    for _, uiElement in ipairs(playerGui:GetDescendants()) do
        if (uiElement:IsA("TextButton") or uiElement:IsA("TextLabel")) and uiElement.Text == "Repeat Dungeon" then
            local targetButton = uiElement
            if uiElement:IsA("TextLabel") and uiElement.Parent:IsA("GuiButton") then
                targetButton = uiElement.Parent
            end
            
            local success = pcall(function()
                local centerX = targetButton.AbsolutePosition.X + (targetButton.AbsoluteSize.X / 2)
                local centerY = targetButton.AbsolutePosition.Y + (targetButton.AbsoluteSize.Y / 2)
                local guiInset = GuiService:GetGuiInset()
                VirtualInputManager:SendMouseButtonEvent(centerX + guiInset.X, centerY + guiInset.Y, 0, true, game, 0)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(centerX + guiInset.X, centerY + guiInset.Y, 0, false, game, 0)
            end)
            return success
        end
    end
    return false
end

local function runDungeonLoop()
    while isRunning do
        local currentFlyTime = tonumber(flyTimeBox.Text) or 1.5 
        local currentFlySpeed = tonumber(flySpeedBox.Text) or 44

        for stageNumber = 1, 50 do
            if not isRunning then break end
            
            updateStatus("Flying to next area...")
            setAntiKnockback(false)
            flyToNextArea(currentFlyTime, currentFlySpeed)
            
            if not isRunning then break end
            
            updateStatus("Clearing Room " .. stageNumber .. "...")
            setAntiKnockback(true)
            waitForRoomClear()
            
            if clickRepeatButton() then break end
        end
        
        if not isRunning then break end
        
        updateStatus("Restarting dungeon...")
        setAntiKnockback(false)
        task.wait(repeatWaitTime)
    end
    
    setAntiKnockback(false)
    if screenGui.Parent then
        updateStatus("Idle")
    end
end

toggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleButton.Text = "Stop Auto"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.spawn(runDungeonLoop)
    else
        toggleButton.Text = "Start Auto"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        updateStatus("Stopping...")
    end
end)
