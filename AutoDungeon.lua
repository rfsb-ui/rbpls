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

-- This table will store which mobs you have toggled ON
local selectedMobs = {}

-- ==========================================
-- 1. CREATE THE UI (With Mob Scanner)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonAutoGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

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
mainFrame.Size = UDim2.new(1, 0, 0, 300) -- Expanded to fit the scanner
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

-- Scanner Button
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(1, -20, 0, 30)
refreshButton.Position = UDim2.new(0, 10, 0, 85)
refreshButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Font = Enum.Font.SourceSansBold
refreshButton.TextSize = 16
refreshButton.Text = "Scan Map for Mobs"
refreshButton.Parent = mainFrame

-- Mob List Container
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
toggleButton.Size = UDim2.new(0, 160, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 1, -75)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Text = "Start Auto"
toggleButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 70, 0, 40)
saveButton.Position = UDim2.new(0, 180, 1, -75)
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
-- 2. MOB SCANNER SYSTEM
-- ==========================================
local function populateMobList(mobNamesArray)
    -- Clear out old UI buttons
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
        
        -- Check our saved data to see if it should be ON or OFF
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
                -- Make sure we don't add the same name to the list 50 times
                if not uniqueChecker[mobName] then
                    uniqueChecker[mobName] = true
                    table.insert(foundNames, mobName)
                end
            end
        end
    end
    
    -- Also include any mobs we previously saved, in case they haven't spawned yet
    for savedName, _ in pairs(selectedMobs) do
        if not uniqueChecker[savedName] then
            uniqueChecker[savedName] = true
            table.insert(foundNames, savedName)
        end
    end
    
    table.sort(foundNames) -- Alphabetize the list
    populateMobList(foundNames)
    
    refreshButton.Text = "Scan Map for Mobs"
    updateStatus("Scan complete. Found " .. #foundNames .. " unique mobs.")
end

refreshButton.MouseButton1Click:Connect(scanForMobs)

-- ==========================================
-- 3. FILE SAVING & LOADING
-- ==========================================
local function saveSettings()
    local data = {
        FlyTime = tonumber(flyTimeBox.Text) or 1.5,
        FlySpeed = tonumber(flySpeedBox.Text) or 44,
        SelectedMobs = selectedMobs
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
            if data.SelectedMobs then 
                selectedMobs = data.SelectedMobs 
                
                -- Rebuild the UI list with our loaded memory
                local savedNames = {}
                for name, _ in pairs(selectedMobs) do
                    table.insert(savedNames, name)
                end
                table.sort(savedNames)
                populateMobList(savedNames)
            end
        end
    end
end

loadSettings()
saveButton.MouseButton1Click:Connect(saveSettings)

-- ==========================================
-- 4. GUI FUNCTIONALITY 
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
