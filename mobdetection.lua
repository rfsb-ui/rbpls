local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PartScanDebugGui"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 240, 0, 30)
topBar.Position = UDim2.new(0.5, -120, 0.4, 0)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Draggable = true
topBar.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Part Scan Diagnostic"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 16
closeButton.BorderSizePixel = 0
closeButton.Parent = topBar

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 0, 60)
mainFrame.Position = UDim2.new(0, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = topBar

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(1, -20, 0, 40)
scanButton.Position = UDim2.new(0, 10, 0, 10)
scanButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Text = "Scan Nearby Parts (15 Studs)"
scanButton.Font = Enum.Font.SourceSansBold
scanButton.TextSize = 14
scanButton.Parent = mainFrame

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

scanButton.MouseButton1Click:Connect(function()
    local character = localPlayer.Character
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    
    if root then
        print("=== SCANNING NEARBY PARTS ===")
        local foundCount = 0
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                local dist = (part.Position - root.Position).Magnitude
                if dist < 15 then
                    foundCount = foundCount + 1
                    print("Part Name:", part.Name, "| Parent Name:", part.Parent.Name, "| Parent Class:", part.Parent.ClassName)
                end
            end
        end
        print("=== SCAN COMPLETE. Found parts within 15 studs:", foundCount, "===")
    else
        print("Error: Character root part not found.")
    end
end)
