local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

local isScanning = false
local scanInterval = 0
local configFileName = "DungeonMapperConfig.json"

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
-- CREATE DUNGEON MAPPER UI (V1.4 - Separated Copy & Scrollable Console)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonMapperGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 440, 0, 50)
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
titleLabel.Text = "Dungeon Mapper [V1.4]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -65, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Ready to Measure"
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 50)
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

local searchBox = createConfigRow("Search Keyword:", 15, "room")
local radiusBox = createConfigRow("Scan Radius:", 45, "300")

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, 200, 0, 25)
scanButton.Position = UDim2.new(0, 225, 0, 15)
scanButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Font = Enum.Font.SourceSansBold
scanButton.TextSize = 14
scanButton.Text = "Scan Surroundings"
scanButton.Parent = mainFrame

local continuousButton = Instance.new("TextButton")
continuousButton.Size = UDim2.new(0, 200, 0, 25)
continuousButton.Position = UDim2.new(0, 225, 0, 45)
continuousButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
continuousButton.TextColor3 = Color3.fromRGB(255, 255, 255)
continuousButton.Font = Enum.Font.SourceSansBold
continuousButton.TextSize = 14
continuousButton.Text = "Continuous: OFF"
continuousButton.Parent = mainFrame

-- Dedicated Copy Button
local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0, 200, 0, 25)
copyButton.Position = UDim2.new(0, 225, 0, 75)
copyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.Font = Enum.Font.SourceSansBold
copyButton.TextSize = 14
copyButton.Text = "Copy Full Log"
copyButton.Parent = mainFrame

-- Fully Scrollable In-UI Console Log Window
local logScrollingFrame = Instance.new("ScrollingFrame")
logScrollingFrame.Size = UDim2.new(1, -30, 0, 180)
logScrollingFrame.Position = UDim2.new(0, 15, 0, 110)
logScrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
logScrollingFrame.BorderSizePixel = 0
logScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScrollingFrame.ScrollBarThickness = 8
logScrollingFrame.ScrollingEnabled = true
logScrollingFrame.Parent = mainFrame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -10, 1, 0)
logLabel.Position = UDim2.new(0, 5, 0, 0)
logLabel.BackgroundTransparency = 1
logLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
logLabel.Text = "Console Logs will appear here..."
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 12
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Parent = logScrollingFrame

local logLines = {}
local function logMessage(msg)
    table.insert(logLines, msg)
    if #logLines > 100 then
        table.remove(logLines, 1)
    end
    logLabel.Text = table.concat(logLines, "\n")
    print(msg)
    
    -- Auto-scroll down to bottom when new logs arrive
    logScrollingFrame.CanvasPosition = Vector2.new(0, logLabel.AbsoluteSize.Y)
end

closeButton.MouseButton1Click:Connect(function()
    isScanning = false
    screenGui:Destroy()
end)

local function performScan()
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if not rootPart then
        statusLabel.Text = "Status: Character not found"
        return
    end
    
    local myPos = rootPart.Position
    local maxRadius = tonumber(radiusBox.Text) or 300
    local keyword = searchBox.Text:lower()
    
    logMessage("------------------------------------------")
    logMessage(string.format("Measuring for '%s' (Radius: %d)", keyword, maxRadius))
    
    local count = 0
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
                local objName = obj.Name:lower()
                local model = obj.Parent
                local modelName = model and model.Name:lower() or ""
                
                if string.find(objName, keyword, 1, true) or string.find(modelName, keyword, 1, true) then
                    local dist = (obj.Position - myPos).Magnitude
                    if dist <= maxRadius then
                        count = count + 1
                        local size = obj.Size
                        logMessage(string.format("[%d] %s (Model: %s) | Size: (%.1f, %.1f, %.1f) | Dist: %.1fm", 
                            count, obj.Name, model.Name, size.X, size.Y, size.Z, dist))
                    end
                end
            end
        end
    end)
    
    statusLabel.Text = string.format("Status: Found %d matching objects", count)
    logMessage(string.format("Scan Complete. Found: %d", count))
end

scanButton.MouseButton1Click:Connect(performScan)

-- Copy Button Handler
copyButton.MouseButton1Click:Connect(function()
    local fullText = table.concat(logLines, "\n")
    if copyToClipboard(fullText) then
        statusLabel.Text = "Status: Log copied to clipboard!"
        copyButton.Text = "Copied!"
        task.wait(1)
        copyButton.Text = "Copy Full Log"
    else
        statusLabel.Text = "Status: Clipboard failed"
    end
end)

continuousButton.MouseButton1Click:Connect(function()
    isScanning = not isScanning
    if isScanning then
        continuousButton.Text = "Continuous: ON"
        continuousButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    else
        continuousButton.Text = "Continuous: OFF"
        continuousButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not isScanning then return end
    
    scanInterval = scanInterval + dt
    if scanInterval >= 3.0 then
        scanInterval = 0
        performScan()
    end
end)
