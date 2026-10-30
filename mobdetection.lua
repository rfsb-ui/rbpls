local Players = game:GetService("Players")
local RunService = service and service.RunService or game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Create a quick floating button to trigger a deep print of nearby models
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RadarDeepDebug"
screenGui.ResetOnSpawn = false

local success = pcall(function()
    screenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not success then
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.4, 0)
btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Text = "Deep Inspect Nearby Models"
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 16
btn.Active = true
btn.Draggable = true
btn.Parent = screenGui

btn.MouseButton1Click:Connect(function()
    print("=== DEEP INSPECTING NEARBY MODELS ===")
    local character = localPlayer.Character
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    if not root then
        print("Character root not found!")
        return
    end
    
    local myPos = root.Position
    local inspected = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= character then
            -- Find the closest part inside this model to check distance
            local samplePart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if samplePart then
                local dist = (samplePart.Position - myPos).Magnitude
                if dist < 50 then -- Only inspect models within 50 studs of you
                    inspected = inspected + 1
                    print("-----------------------------------------")
                    print("Model Name:", obj.Name, "| Distance:", string.format("%.1f", dist))
                    print("Children inside model:")
                    for _, child in ipairs(obj:GetChildren()) do
                        print("   -> Child:", child.Name, "[Class:", child.ClassName, "].")
                    end
                end
            end
        end
    end
    print("=== INSPECTION COMPLETE. Inspected models:", inspected, "===")
end)
