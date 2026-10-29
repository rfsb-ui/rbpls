local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer

local repeatWaitTime = 10 
local stopDistance = 15
local isRunning = false
local configFileName = "AutoDungeonSmartConfig.json"

-- ==========================================
-- 1. CREATE THE UI (Compact Version)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonAutoGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 260, 0, 30)
topBar.Position = UDim2.new(0.5, -130, 0.5, -90)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Smart Dungeon Auto"
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

-- Much smaller main frame since the scroll list is gone
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 150)
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
flyTimeBox.Size = UDim2.new(0, 60, 0, 30)
flyTimeBox.Position = UDim2.new(0, 160, 0, 10)
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
flySpeedBox.Size = UDim2.new(0, 60, 0, 30)
flySpeedBox.Position = UDim2.new(0, 160, 0, 45)
flySpeedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flySpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedBox.Text = "44"
flySpeedBox.Font = Enum.Font.SourceSans
flySpeedBox.TextSize = 16
flySpeedBox.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 150, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 85)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Text = "Start Auto"
toggleButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 80, 0, 40)
saveButton.Position = UDim2.new(0, 170, 0, 85)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 16
saveButton.Text = "Save"
saveButton.Parent = mainFrame

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
-- 2. FILE SAVING & LOADING
-- ==========================================
local function saveSettings()
    local data = {
        FlyTime = tonumber(flyTimeBox.Text) or 1.5,
        FlySpeed = tonumber(flySpeedBox.Text) or 44
    }
    
    if writefile then
        local jsonData = HttpService:JSONEncode(data)
        writefile(configFileName, jsonData)
        saveButton.Text = "Saved!"
        task.wait(1)
        saveButton.Text = "Save"
    end
end

local function loadSettings()
    if isfile and isfile(configFileName) then
        local jsonData = readfile(configFileName)
        local success, data = pcall(function()
            return HttpService:JSONDecode(jsonData)
        end)
        
        if success and data then
            if data.FlyTime then flyTimeBox.Text = tostring(data.FlyTime) end
            if data.FlySpeed then flySpeedBox.Text = tostring(data.FlySpeed) end
        end
    end
end

loadSettings()
saveButton.MouseButton1Click:Connect(saveSettings)

-- ==========================================
-- 3. GUI FUNCTIONALITY
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
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.Anchored = false
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
-- 4. DUNGEON LOGIC & SMART DETECTION
-- ==========================================
local function setAntiKnockback(isLocked)
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.Anchored = isLocked
    end
end

local function getClosestMonster()
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local hrpPos = character.HumanoidRootPart.Position
    
    local closest = nil
    local shortestDistance = 2000 
    
    local containers = {workspace}
    local commonFolders = {"Enemies", "Mobs", "NPCs", "Monsters", "Live"}
    for _, name in ipairs(commonFolders) do
        local folder = workspace:FindFirstChild(name)
        if folder then
            table.insert(containers, folder)
        end
    end
    
    for _, container in ipairs(containers) do
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Model") and obj ~= character then
                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart")
                
                if humanoid and humanoid.Health > 0 and root and not Players:GetPlayerFromCharacter(obj) then
                    local distance = (root.Position - hrpPos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closest = root
                    end
                end
            end
        end
    end
    
    return closest
end

local function flyToNextArea(duration, flySpeed)
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = hrp
    
    local noclipConnection = RunService.Stepped:Connect(function()
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    
    local endTime = os.clock() + duration
    while os.clock() < endTime and isRunning do
        local monster = getClosestMonster()
        
        if monster then
            local distance = (monster.Position - hrp.Position).Magnitude
            local direction = (monster.Position - hrp.Position).Unit
            
            if distance > stopDistance then
                bv.Velocity = direction * flySpeed
            else
                bv.Velocity = Vector3.zero
            end
            
            hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(monster.Position.X, hrp.Position.Y, monster.Position.Z))
        else
            bv.Velocity = hrp.CFrame.LookVector * flySpeed
        end
        
        task.wait(0.1) 
    end
    
    if bv then bv:Destroy() end
    if noclipConnection then noclipConnection:Disconnect() end
    
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
end

local function waitForRoomClear()
    -- Wait 1 second to allow monsters to render/spawn just in case you arrived early
    task.wait(1)
    
    -- Continuously check the radar while the script is running
    while isRunning do
        local monster = getClosestMonster()
        if not monster then
            -- No monsters found, the room is completely clear
            break
        end
        -- Wait half a second before checking the radar again to save performance
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

            local centerX = targetButton.AbsolutePosition.X + (targetButton.AbsoluteSize.X / 2)
            local centerY = targetButton.AbsolutePosition.Y + (targetButton.AbsoluteSize.Y / 2)
            
            local guiInset = GuiService:GetGuiInset()
            VirtualInputManager:SendMouseButtonEvent(centerX + guiInset.X, centerY + guiInset.Y, 0, true, game, 0)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(centerX + guiInset.X, centerY + guiInset.Y, 0, false, game, 0)
            return true
        end
    end
    return false
end

local function runDungeonLoop()
    while isRunning do
        local currentFlyTime = tonumber(flyTimeBox.Text) or 1.5 
        local currentFlySpeed = tonumber(flySpeedBox.Text) or 44

        for stageNumber = 1, 18 do
            if not isRunning then break end
            
            updateStatus("Flying to Stage " .. stageNumber .. " at " .. currentFlySpeed .. " SPD...")
            setAntiKnockback(false)
            
            flyToNextArea(currentFlyTime, currentFlySpeed)
            
            if not isRunning then break end
            
            updateStatus("Clearing Stage " .. stageNumber .. "...")
            setAntiKnockback(true)
            
            -- Call the smart detection function instead of a hardcoded timer
            waitForRoomClear()
        end
        
        if not isRunning then break end
        
        updateStatus("Searching for Repeat button...")
        setAntiKnockback(false)
        
        local buttonClicked = false
        for i = 1, 10 do
            if not isRunning then break end
            if clickRepeatButton() then
                buttonClicked = true
                break
            end
            task.wait(1)
        end
        
        if buttonClicked and isRunning then
            updateStatus("Restarting dungeon...")
            task.wait(repeatWaitTime)
        else
            updateStatus("Failed to find Repeat button.")
            break 
        end
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
