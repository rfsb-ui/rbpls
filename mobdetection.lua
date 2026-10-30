local localPlayer = game.Players.LocalPlayer
local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

if root then
    print("=== SCANNING NEARBY PARTS ===")
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            local dist = (part.Position - root.Position).Magnitude
            if dist < 15 then -- Within 15 studs of you
                print("Part Name:", part.Name, "| Parent:", part.Parent.Name, "| Class:", part.Parent.ClassName)
            end
        end
    end
    print("=== SCAN COMPLETE ===")
end
