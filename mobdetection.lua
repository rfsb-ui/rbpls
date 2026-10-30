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
-- 1. CREATE THE UI (V5.7)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonAutoGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 260, 0, 30)
topBar.Position = UDim2.new(0.5, -130, 0.5, -100)
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

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 180)
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

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 140, 0, 30)
targetLabel.Position = UDim2.new(0, 10, 0, 80)
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetLabel.Text = "Target Mobs:"
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextSize = 16
targetLabel.Parent = mainFrame

local monsterBox = Instance.new("TextBox")
monsterBox.Size = UDim2.new(0, 90, 0, 30)
monsterBox.Position = UDim2.new(0, 150, 0, 80)
monsterBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
monsterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
monsterBox.Text = "A_28"
monsterBox.PlaceholderText = "A_28"
monsterBox.Font = Enum.Font.SourceSans
monsterBox.TextSize = 14
monsterBox.ClipsDescendants = true
monsterBox.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 160, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 120)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Text = "Start Auto"
toggleButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 70, 0, 40)
saveButton.Position = UDim2.new(0, 180, 0, 120)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 16
saveButton.Text = "Save"
saveButton.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -60, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 1, -20)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Text = "Status: Idle"
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 15
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 40, 0, 20)
versionLabel.Position = UDim2.new(1, -45, 1, -20)
versionLabel.BackgroundTransparency = 1
versionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
versionLabel.Text = "V5.7"
versionLabel.Font = Enum.Font.SourceSansBold
versionLabel.TextSize = 14
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = mainFrame

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
        FlySpeed = tonumber(flySpeedBox.Text) or 44,
        TargetMobs = monsterBox.Text
    }
    
    pcall(function()
        if writefile then
            local jsonData = HttpService:JSONEncode(data)
            writefile(configFileName, jsonData)
        end
    end)
    
    saveButton.Text = "Saved!"
    task.wait(1)
    saveButton.Text = "Save"
end

local function loadSettings()
    pcall(function()
        if isfile and isfile(configFileName) then
            local jsonData = readfile(configFileName)
            local success, data = pcall(function()
                return HttpService:JSONDecode(jsonData)
            end)
            
            if success and data then
                if data.FlyTime then flyTimeBox.Text = tostring(data.FlyTime) end
                if data.FlySpeed then flySpeedBox.Text = tostring(data.FlySpeed) end
                if data.TargetMobs then monsterBox.Text = tostring(data.TargetMobs) end
            end
        end
    end)
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
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if rootPart then
        rootPart.Anchored = false
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
-- 4. DUNGEON LOGIC & PART-BASED RADAR
-- ==========================================
local function setAntiKnockback(isLocked)
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if rootPart then
        rootPart.Anchored = isLocked
    end
end

local function getParsedMonsterNames()
    local text = monsterBox.Text
    if text == "" then return {"a_28"} end
    
    local names = {}
    for name in string.gmatch(text, "([^,]+)") do
        local cleanName = name:match("^%s*(.-)%s*$"):lower()
        if cleanName ~= "" then
            table.insert(names, cleanName)
        end
    end
    return names
end

local currentTarget = nil

local function getClosestMonster()
    local character = localPlayer.Character
    local myRoot = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if not myRoot then return nil end
    local myPos = myRoot.Position
    
    if currentTarget and currentTarget.Parent then
        return currentTarget
    end
    
    local closest = nil
    local shortestDistance = 100000 
    
    local validNames = getParsedMonsterNames()
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= myRoot and not obj:IsDescendantOf(character) then
            local objName = obj.Name:lower()
            local matches = false
            
            for _, vName in ipairs(validNames) do
                if string.find(objName, vName, 1, true) then
                    matches = true
                    break
                end
            end
            
            if matches then
                local distance = (obj.Position - myPos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closest = obj
                end
            end
        end
    end
    
    currentTarget = closest
    return currentTarget
end

local function flyToNextArea(duration, flySpeed)
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if not rootPart then return end
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = rootPart
    
    local noclipConnection = RunService.Stepped:Connect(function()
        local c = localPlayer.Character
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
    
    local endTime = os.clock() + duration
    while os.clock() < endTime and isRunning do
        local monster = getClosestMonster()
        if monster then
            local distance = (monster.Position - rootPart.Position).Magnitude
            local direction = (monster.Position - rootPart.Position).Unit
            
            if distance > stopDistance then
                bv.Velocity = direction * fly
