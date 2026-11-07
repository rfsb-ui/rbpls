-- Flight Execution (Active via Waypoint/Mob target OR Always Fly toggle)
	local shouldFly = ((isTrackingAll or isLoopingWaypoints) and targetPos) or isAlwaysFlyEnabled
	
	if shouldFly and myHrp and humanoid then
		humanoid.PlatformStand = true
		local currentPos = myHrp.Position
		
		if targetPos then
			local direction = (targetPos - currentPos)
			local distance = direction.Magnitude
			
			if distance > CONFIG.StopDistance then
				local moveVector = direction.Unit * math.min(CONFIG.FlightSpeed * dt, distance)
				-- Traveling toward target: face the destination normally
				myHrp.CFrame = CFrame.new(currentPos + moveVector, targetPos)
				myHrp.AssemblyLinearVelocity = Vector3.zero
			else
				-- Reached the target: hold position and pitch head/body to look straight down at the mob below
				local lookDownTarget = targetPos - Vector3.new(0, 5, 0)
				myHrp.CFrame = CFrame.new(currentPos, lookDownTarget)
				myHrp.AssemblyLinearVelocity = Vector3.zero
			end
		else
			-- Always Fly mode active without an explicit target: maintain current hover level and lock velocity
			myHrp.AssemblyLinearVelocity = Vector3.zero
		end
	else
		if humanoid and humanoid.PlatformStand then
			humanoid.PlatformStand = false
		end
	end
