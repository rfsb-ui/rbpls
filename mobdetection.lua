local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- ==========================================
-- CREATE DETACHED DIAGNOSTIC UI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RadarDiagnosticGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 300, 0, 30)
topBar.Position = UDim2.new(0.5, -150, 0.2, 0)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Radar Diagnostic [V5.2]"
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

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 160)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

-- Status readout labels inside the detached window
local function createInfoLabel(name, posY)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Size = UDim2.new(1, -20, 0, 25)
    lbl.Position = UDim2.new(0, 10, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Text = name .. ": Scanning..."
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = mainFrame
    return lbl
end

local totalModelsLbl = createInfoLabel("Total Models", 10)
local closestMobLbl = createInfoLabel("Closest Target", 40)
local healthLbl = createInfoLabel("Target Health", 70)
local distanceLbl = createInfoLabel("Distance", 100)

local targetStatusLbl = createInfoLabel("Radar Status", 130)
targetStatusLbl.TextColor3 = Color3.fromRGB(100, 200, 255)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ==========================================
-- REAL-TIME DIAGNOSTIC SCANNER LOOP
-- ==========================================
RunService.RenderStepped:Connect(function()
    if not screenGui.Parent then return end
    
    local character = localPlayer.Character
    local myRoot = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if not myRoot then
        totalModelsLbl.Text = "Total Models: Character not found"
        return
    end
    
    local myPos = myRoot.Position
    local modelCount = 0
    local closestObj = nil
    local shortestDist = math.huge
    local closestRoot = nil
    local closestHum = nil
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= character and not Players:GetPlayerFromCharacter(obj) then
            modelCount = modelCount + 1
            
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local root = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso") or obj:FindFirstChildWhichIsA("BasePart")
            
            if humanoid and root then
                local dist = (root.Position - myPos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestObj = obj
                    closestRoot = root
                    closestHum = humanoid
                end
            end
        end
    end
    
    totalModelsLbl.Text = "Total Models Scanned: " .. tostring(modelCount)
    
    if closestObj then
        closestMobLbl.Text = "Closest Target: " .. closestObj.Name
        healthLbl.Text = "Target Health: " .. math.floor(closestHum.Health) .. " / " .. math.floor(closestHum.MaxHealth)
        distanceLbl.Text = "Distance: " .. string.format("%.1f", shortestDist) .. " studs"
        targetStatusLbl.Text = "Radar Status: TARGET LOCKED"
        targetStatusLbl.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        closestMobLbl.Text = "Closest Target: None Found"
        healthLbl.Text = "Target Health: N/A"
        distanceLbl.Text = "Distance: N/A"
        targetStatusLbl.Text = "Radar Status: SEARCHING..."
        targetStatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)
