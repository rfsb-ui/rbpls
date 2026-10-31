local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Direct path verification to workspace.Animal_Live.Aggressors
local animalLive = workspace:WaitForChild("Animal_Live", 30)
local aggressorsFolder = animalLive:WaitForChild("Aggressors", 30)

if not aggressorsFolder then
	warn("CRITICAL: workspace.Animal_Live.Aggressors could not be found!")
end

-- ================= CONFIGURABLE SETTINGS (WITH PERSISTENCE) =================
local CONFIG = {
	FlightSpeed = 12,
	DetectionRadius = 100,
	StopDistance = 3,
	GateTimeout = 15,
	BossRoomNumber = 19,
	LootRadius = 150,
	LootTimeout = 3
}

pcall(function()
	if _G.DungeonSettings then
		CONFIG.FlightSpeed = _G.DungeonSettings.FlightSpeed or CONFIG.FlightSpeed
		CONFIG.DetectionRadius = _G.DungeonSettings.DetectionRadius or CONFIG.DetectionRadius
		CONFIG.StopDistance = _G.DungeonSettings.StopDistance or CONFIG.StopDistance
		CONFIG.GateTimeout = _G.DungeonSettings.GateTimeout or CONFIG.GateTimeout
		CONFIG.BossRoomNumber = _G.DungeonSettings.BossRoomNumber or CONFIG.BossRoomNumber
		CONFIG.LootRadius = _G.DungeonSettings.LootRadius or CONFIG.LootRadius
		CONFIG.LootTimeout = _G.DungeonSettings.LootTimeout or CONFIG.LootTimeout
	end
end)

local function saveSettings()
	_G.DungeonSettings = {
		FlightSpeed = CONFIG.FlightSpeed,
		DetectionRadius = CONFIG.DetectionRadius,
		StopDistance = CONFIG.StopDistance,
		GateTimeout = CONFIG.GateTimeout,
		BossRoomNumber = CONFIG.BossRoomNumber,
		LootRadius = CONFIG.LootRadius,
		LootTimeout = CONFIG.LootTimeout
	}
end
-- ============================================================================

-- Strict Animal property fetcher
local function getAnimalName(monster)
	local animalProp = monster:GetAttribute("Animal")
	if not animalProp then
		local animalVal = monster:FindFirstChild("Animal")
		if animalVal and animalVal:IsA("StringValue") then
			animalProp = animalVal.Value
		end
	end
	return animalProp or monster.Name
end

-- Waypoint and Room tracking variables
local waypoints = {}
local importedWaypointsCount = 0
local currentWaypointIndex = 1
local isLoopingWaypoints = false
local isTrackingAll = false
local isAutoRestartEnabled = false
local isLootPickupEnabled = false
local roomClearedConfirmed = true
local gateTimer = 0
local lastRestartAttempt = 0
local restartLoadingTimeout = 0

-- Loot timing variables
local lootStartTime = 0
local isLootingActive = false

-- Function to check if the gate unseal message is active on screen
local function checkGateUnsealed()
	for _, gui in ipairs(playerGui:GetDescendants()) do
		if gui:IsA("TextLabel") or gui:IsA("TextButton") then
			local text = gui.Text:lower()
			if string.find(text, "room cleared") or string.find(text, "gate unseals") then
				return true
			end
		end
	end
	return false
end

-- Function to check for "Dungeon Cleared" popup and auto-click "Run again"
local function checkAndRestartDungeon()
	if not isAutoRestartEnabled or (tick() - lastRestartAttempt < 6) then return end
	if currentWaypointIndex < CONFIG.BossRoomNumber and #waypoints > 0 then return end
	if tick() < restartLoadingTimeout then return end
	
	for _, gui in ipairs(playerGui:GetDescendants()) do
		if gui:IsA("TextButton") or gui:IsA("TextLabel") then
			local text = gui.Text:lower()
			if string.find(text, "dungeon cleared") or string.find(text, "victory") then
				for _, btn in ipairs(playerGui:GetDescendants()) do
					if btn:IsA("TextButton") then
						local btnText = btn.Text:lower()
						if string.find(btnText, "run") or string.find(btnText, "again") or string.find(btnText, "restart") then
							lastRestartAttempt = tick()
							restartLoadingTimeout = tick() + 4
							currentWaypointIndex = 1
							roomClearedConfirmed = true
							isLootingActive = false
							
							pcall(function()
								for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
									conn:Fire()
								end
							end)
							
							local absPos = btn.AbsolutePosition
							local absSize = btn.AbsoluteSize
							local clickX = absPos.X + absSize.X/2
							local clickY = absPos.Y + absSize.Y/2
							
							VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
							task.wait(0.05)
							VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
							print("Auto Dungeon Restarted via button: " .. btn.Name)
							return
						end
					end
				end
			end
		end
	end
end

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDungeonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Compact Panel
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 595)
mainFrame.Position = UDim2.new(0, 30, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title Label / Drag Handler
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -65, 0, 32)
titleLabel.Position = UDim2.new(0, 8, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Dungeon v3.7"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.SourceSansBold
