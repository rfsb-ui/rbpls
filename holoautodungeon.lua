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
local configFileName = "DungeonWaypointConfigV21.json"

local function copyToClipboard(text)
    pcall(function()
        if setclipboard then setclipboard(text)
        elseif toboard then toboard(text)
        elseif syn and syn.write_clipboard then syn.write_clipboard(text) end
    end)
end

-- ==========================================
-- CREATE WAYPOINT ROUTER UI (V2.1)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonWaypointGui_V21"
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
titleLabel.Size = UDim2.new(0, 280, 0, 20)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Waypoint Router [V2.1 - 6s Backward Step]"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -65, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.Text = "Status: Idle | Waypoints: 0 | Target: None"
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
mainFrame.Size = UDim2.new(1, 0, 0, 430)
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

local speedBox = createConfigRow("Travel Speed:", 15, "16")
local stopBox = createConfigRow("Stop Distance:", 45, "3")
local waitBox = createConfigRow("Wait at Room (s):", 75, "2.0")

local rightX = 250
local rightWidth = 255

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, rightWidth, 0, 30)
toggleButton.Position = UDim2.new(0, rightX, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.Text = "Start Route Bot"
toggleButton.Parent = mainFrame

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, rightWidth, 0, 30)
saveButton.Position = UDim2.new(0, rightX, 0, 55)
saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 14
saveButton.Text = "Save Waypoint (Room)"
saveButton.Parent = mainFrame

local clearButton = Instance.new("TextButton")
clearButton.Size = UDim2.new(0, 120, 0, 30)
clearButton.Position = UDim2.new(0, rightX, 0, 95)
clearButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
clearButton.Font = Enum.Font.SourceSansBold
clearButton.TextSize = 14
clearButton.Text = "Clear Waypoints"
clearButton.Parent = mainFrame

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0, 125, 0, 30)
copyButton.Position = UDim2.new(0, rightX + 130, 0, 95)
copyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.Font = Enum.Font.SourceSansBold
copyButton.TextSize = 14
copyButton.Text = "Copy Log"
copyButton.Parent = mainFrame

local importBox = Instance.new("TextBox")
importBox.Size = UDim2.new(0, 175, 0, 30)
importBox.Position = UDim2.new(0, 15, 0, 110)
importBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
importBox.TextColor3 = Color3.fromRGB(255, 255, 255)
importBox.PlaceholderText = "Paste JSON Waypoints..."
importBox.Text = ""
importBox.Font = Enum.Font.SourceSans
importBox.TextSize = 12
importBox.Parent = mainFrame

local importButton = Instance.new("TextButton")
importButton.Size = UDim2.new(0, 70, 0, 30)
importButton.Position = UDim2.new(0, 195, 0, 110)
importButton.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
importButton.TextColor3 = Color3.fromRGB(255, 255, 255)
importButton.Font = Enum.Font.SourceSansBold
importButton.TextSize = 14
importButton.Text = "Import"
importButton.Parent = mainFrame

local logScrollingFrame = Instance.new("ScrollingFrame")
logScrollingFrame.Size = UDim2.new(1, -30, 0, 240)
logScrollingFrame.Position = UDim2.new(0, 15, 0, 150)
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
logLabel.Text = "Waypoint Router V2.1 Ready...\nWalk to each room and click 'Save Waypoint', or paste JSON and click 'Import'."
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

local waypoints = {}

saveButton.MouseButton1Click:Connect(function()
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if rootPart then
        local pos = rootPart.Position
        table.insert(waypoints, {X = pos.X, Y = pos.Y, Z = pos.Z})
        logMessage(string.format("[Room #%d Saved] X: %.1f, Y: %.1f, Z: %.1f", #waypoints, pos.X, pos.Y, pos.Z))
        statusLabel.Text = string.format("Status: Idle | Waypoints: %d | Target: None", #waypoints)
        
        pcall(function()
            if writefile then
                writefile(configFileName, HttpService:JSONEncode(waypoints))
            end
        end)
    else
        logMessage("Error: Character root part not found.")
    end
end)

importButton.MouseButton1Click:Connect(function()
    local rawText = importBox.Text
    local success, result = pcall(function()
        return HttpService:JSONDecode(rawText)
    end)
    
    if success and type(result) == "table" and #result > 0 then
        waypoints = result
        logMessage(string.format("Successfully imported %d waypoints!", #waypoints))
        statusLabel.Text = string.format("Status: Idle | Waypoints: %d | Target: None", #waypoints)
        pcall(function()
            if writefile then writefile(configFileName, HttpService:JSONEncode(waypoints)) end
        end)
    else
        logMessage("Error: Invalid JSON waypoint format. Ensure it's a valid coordinate table.")
    end
end)

clearButton.MouseButton1Click:Connect(function()
    waypoints = {}
    logLines = {}
    logLabel.Text = "All waypoints and logs cleared."
    statusLabel.Text = "Status: Idle | Waypoints: 0 | Target: None"
    pcall(function()
        if writefile then writefile(configFileName, "[]") end
    end)
end)

pcall(function()
    if readfile and isfile and isfile(configFileName) then
        local data = HttpService:JSONDecode(readfile(configFileName))
        if type(data) == "table" then
            waypoints = data
            logMessage(string.format("Loaded %d saved waypoints from file.", #waypoints))
            statusLabel.Text = string.format("Status: Idle | Waypoints: %d | Target: None", #waypoints)
        end
    end
end)

copyButton.MouseButton1Click:Connect(function()
    copyToClipboard(table.concat(logLines, "\n"))
    logMessage("Full log copied to clipboard!")
end)

toggleButton.MouseButton1Click:Connect(function()
    if #waypoints == 0 then
        logMessage("Error: No waypoints recorded or imported!")
        return
    end
    
    isRunning = not isRunning
    if isRunning then
        toggleButton.Text = "Stop Route Bot"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logMessage("Waypoint Router Started!")
    else
        toggleButton.Text = "Start Route Bot"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        statusLabel.Text = string.format("Status: Idle | Waypoints: %d | Target: None", #waypoints)
        pcall(function()
            local character = localPlayer.Character
            local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
            if rootPart then rootPart.Anchored = false end
        end)
        logMessage("Waypoint Router Stopped.")
    end
end)

local currentWaypointIndex = 1
local roomWaitTimer = 0
local waitingInRoom = false
local backwardStepTimer = tick()
local isSteppingBack = false
local backwardStepDuration = 0

RunService.RenderStepped:Connect(function(dt)
    if not isRunning then return end
    
    local character = localPlayer.Character
    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if not rootPart then return end
    
    local travelSpeed = tonumber(speedBox.Text) or 16
    local stopDistance = tonumber(stopBox.Text) or 3
    local roomWaitDuration = tonumber(waitBox.Text) or 2.0
    
    if currentWaypointIndex > #waypoints then
        logMessage("Route complete! Reached final waypoint.")
        isRunning = false
        toggleButton.Text = "Start Route Bot"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        currentWaypointIndex = 1
        return
    end
    
    local targetData = waypoints[currentWaypointIndex]
    local targetPos = Vector3.new(targetData.X, targetData.Y, targetData.Z)
    
    if waitingInRoom then
        statusLabel.Text = string.format("Status: Waiting in Room #%d", currentWaypointIndex)
        if tick() - roomWaitTimer >= roomWaitDuration then
            waitingInRoom = false
            currentWaypointIndex = currentWaypointIndex + 1
            backwardStepTimer = tick() -- Reset timer for next room leg
            logMessage(string.format("Advancing to Waypoint #%d...", currentWaypointIndex))
        end
        return
    end
    
    local distance = (targetPos - rootPart.Position).Magnitude
    
    if distance > stopDistance then
        -- Check if it's time to take a 2-stud backward step every 6 seconds
        if not isSteppingBack and (tick() - backwardStepTimer >= 6.0) then
            isSteppingBack = true
            backwardStepDuration = tick()
            logMessage("Taking anti-stuck 2 stud backward step...")
        end
        
        local direction = (targetPos - rootPart.Position).Unit
        local step = math.min(distance, travelSpeed * dt)
        
        if isSteppingBack then
            statusLabel.Text = string.format("Status: Stepping Back | Target: Waypoint #%d", currentWaypointIndex)
            -- Move backward (-direction) for roughly 0.25 seconds or until 2 studs covered
            rootPart.CFrame = rootPart.CFrame - (direction * (travelSpeed * dt))
            
            if tick() - backwardStepDuration >= 0.25 then
                isSteppingBack = false
                backwardStepTimer = tick() -- Reset 6s timer
            end
        else
            statusLabel.Text = string.format("Status: Moving Forward | Target: Waypoint #%d", currentWaypointIndex)
            rootPart.CFrame = CFrame.new(rootPart.Position + (direction * step))
        end
        
        rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z))
    else
        logMessage(string.format("Reached Waypoint #%d! Pausing...", currentWaypointIndex))
        roomWaitTimer = tick()
        waitingInRoom = isRunning
    end
end)
