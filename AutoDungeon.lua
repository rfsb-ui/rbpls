local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local forwardKey = Enum.KeyCode.W

local repeatWaitTime = 10 
local isRunning = false
local roomTextBoxes = {} 
local configFileName = "AutoDungeonConfig.json"

local defaultTimes = {5, 8, 4, 6, 10, 3, 7, 5, 4, 9, 6, 4, 8, 5, 7, 3, 12, 15}

-- ==========================================
-- 1. CREATE THE UI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonAutoGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 260, 0, 30)
topBar.Position = UDim2.new(0.5, -130, 0.5, -180)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Auto Dungeon Config"
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
mainFrame.Size = UDim2.new(1, 0, 0, 330)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

local walkLabel = Instance.new("TextLabel")
walkLabel.Size = UDim2.new(0, 140, 0, 30)
walkLabel.Position = UDim2.new(0, 10, 0, 10)
walkLabel.BackgroundTransparency = 1
walkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
walkLabel.Text = "Walk Time (secs):"
walkLabel.Font = Enum.Font.SourceSansBold
walkLabel.TextSize = 16
walkLabel.Parent = mainFrame

local walkTimeBox = Instance.new("TextBox")
walkTimeBox.Size = UDim2.new(0, 60, 0, 30)
walkTimeBox.Position = UDim2.new(0, 160, 0, 10)
walkTimeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
walkTimeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
walkTimeBox.Text = "2" 
walkTimeBox.Font = Enum.Font.SourceSans
walkTimeBox.TextSize = 16
walkTimeBox.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 0, 180)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 18 * 35)
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

for i = 1, 18 do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = scrollFrame
    
    local stageLabel = Instance.new("TextLabel")
    stageLabel.Size = UDim2.new(0, 120, 1, 0)
    stageLabel.BackgroundTransparency = 1
    stageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    stageLabel.Text = "Stage " .. i .. " Wait:"
    stageLabel.Font = Enum.Font.SourceSans
    stageLabel.TextSize = 16
    stageLabel.Parent = row
    
    local stageBox = Instance.new("TextBox")
    stageBox.Size = UDim2.new(0, 60, 1, 0)
    stageBox.Position = UDim2.new(0, 130, 0, 0)
    stageBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    stageBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    stageBox.Text = tostring(defaultTimes[i] or 5)
    stageBox.Font = Enum.Font.SourceSans
    stageBox.TextSize = 16
    stageBox.Parent = row
    
    roomTextBoxes[i] = stageBox
end

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 150, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 1, -75)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Text = "Start Auto"
toggleButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 80, 0, 40)
saveButton.Position = UDim2.new(0, 170, 1, -75)
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
        WalkTime = tonumber(walkTimeBox.Text) or 2,
        StageTimes = {}
    }
    
    for i = 1, 18 do
        data.StageTimes[i] = tonumber(roomTextBoxes[i].Text) or defaultTimes[i]
    end
    
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
            if data.WalkTime then
                walkTimeBox.Text = tostring(data.WalkTime)
            end
            if data.StageTimes then
                for i = 1, 18 do
                    if data.StageTimes[i] and roomTextBoxes[i] then
                        roomTextBoxes[i].Text = tostring(data.StageTimes[i])
                    end
                end
            end
        end
    end
end

loadSettings()
saveButton.MouseButton1Click:Connect(saveSettings)

-- ==========================================
-- 3. GUI FUNCTIONALITY (DRAG, MINIMIZE, CLOSE)
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
    VirtualInputManager:SendKeyEvent(false, forwardKey, false, game)
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
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.Anchored = isLocked
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
        local currentWalkTime = tonumber(walkTimeBox.Text) or 2 

        for stageNumber = 1, 18 do
            if not isRunning then break end
            
            local currentWaitTime = tonumber(roomTextBoxes[stageNumber].Text) or 5
            
            updateStatus("Walking to Stage " .. stageNumber .. "...")
            setAntiKnockback(false)
            VirtualInputManager:SendKeyEvent(true, forwardKey, false, game)
            task.wait(currentWalkTime)
            VirtualInputManager:SendKeyEvent(false, forwardKey, false, game)
            
            if not isRunning then break end
            
            updateStatus("Clearing Stage " .. stageNumber .. "...")
            setAntiKnockback(true)
            task.wait(currentWaitTime)
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
    VirtualInputManager:SendKeyEvent(false, forwardKey, false, game)
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
