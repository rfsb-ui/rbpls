local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

local isRunning = false
local currentRoomIndex = 1
local roomsCache = {}
local lastScanTime = 0

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
-- CREATE ROOM TARGETER UI (V1.5)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoomTargeterGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 440, 0, 55)
topBar.Position = UDim2.new(0.5, -220, 0.3, 0)
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
titleLabel.Text = "Room Targeter [V1.5]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -65, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle | Target: None | Rooms: 0"
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

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 310)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

local function createConfigRow(name, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 110, 0, 25)
    label.Position = UDim2.new(0, 15, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 85, 0, 25)
    box.Position = UDim2.new(0, 125, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultValue)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.Parent = mainFrame
    
    return box
end

local prefixBox = createConfigRow("Room Prefix:", 15, "room")
local radiusBox = createConfigRow("Scan Radius:", 45, "500")
local heightBox = createConfigRow("Height Offset:", 75, "5")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 200, 0, 30)
toggleButton.Position = UDim2.new(0, 225, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.Text = "Start Room Cycler"
toggleButton.Parent = mainFrame

local nextButton = Instance.new("TextButton")
nextButton.Size = UDim2.new(0, 200, 0, 30)
nextButton.Position = UDim2.new(0, 225, 0, 55)
nextButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nextButton.Font = Enum.Font.SourceSansBold
nextButton.TextSize = 14
nextButton.Text = "Next Room ➡️"
nextButton.Parent = mainFrame

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0, 200, 0, 30)
copyButton.Position = UDim2.new(0, 225, 0, 95)
copyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.Font = Enum.Font.SourceSansBold
copyButton.TextSize = 14
copyButton.Text = "Copy Room List"
copyButton.Parent = mainFrame

-- Scrollable Console Log Window
local logScrollingFrame = Instance.new("ScrollingFrame")
logScrollingFrame.Size = UDim2.new(1, -30, 0, 140)
logScrollingFrame.Position = UDim2.new(0, 15, 0, 145)
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
logLabel.Text = "Room Scanner ready..."
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 12
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Parent = logScrollingFrame

local logLines = {}
local function logMessage(msg)
    table.insert(logLines, msg)
    if #logLines > 100 then table.remove(logLines, 1) end
    logLabel.Text = table.concat(logLines, "\n")
    print(msg)
    logScrollingFrame.CanvasPosition = Vector2.new(0, logLabel.AbsoluteSize.Y)
end

closeButton.MouseButton1Click:Connect(function()
    isRunning = false
    screenGui:Destroy()
end)

local function scanRooms()
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if not rootPart then return end
    
    local myPos = rootPart.Position
    local maxRadius = tonumber(radiusBox.Text) or 500
    local prefix = prefixBox.Text:lower()
    
    local foundRooms = {}
    
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            local nameLower = obj.Name:lower()
            if string.find(nameLower, prefix, 1, true) then
                local targetPos = nil
                if obj:IsA("BasePart") then
                    targetPos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then
                    targetPos = obj.PrimaryPart.Position
                else
                    -- Fallback: find first basepart inside model/folder
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") then
                            targetPos = child.Position
                            break
                        end
                    end
                end
                
                if targetPos then
                    local dist = (targetPos - myPos).Magnitude
                    if dist <= maxRadius then
                        -- Check for duplicates to avoid adding every single part of the same room
                        local isDuplicate = false
                        for _, room in ipairs(foundRooms) do
                            if (room.Position - targetPos).Magnitude < 10 or room.Name == obj.Name then
                                isDuplicate = true
                                break
                            end
                        end
                        
                        if not isDuplicate then
                            table.insert(foundRooms, {
                                Name = obj.Name,
                                Position = targetPos,
                                Distance = dist
                            })
                        end
                    end
                end
            end
        end
    end)
    
    -- Sort by distance
    table.sort(foundRooms, function(a, b) return a.Distance < b.Distance end)
    roomsCache = foundRooms
    
    if currentRoomIndex > #roomsCache then
        currentRoomIndex = 1
    end
end

toggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleButton.Text = "Stop Room Cycler"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        scanRooms()
        logMessage(string.format("Started cycler. Found %d rooms matching '%s'.", #roomsCache, prefixBox.Text))
    else
        toggleButton.Text = "Start Room Cycler"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        statusLabel.Text = "Status: Idle | Target: None | Rooms:
