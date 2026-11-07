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
				-- Traveling toward target: face forward normally along flight path
				myHrp.CFrame = CFrame.new(currentPos + moveVector, targetPos)
				myHrp.AssemblyLinearVelocity = Vector3.zero
			else
				-- Reached target: hold position and tilt to look straight down at the mob below
				local lookDownTarget = targetPos - Vector3.new(0, 5, 0)
				myHrp.CFrame = CFrame.new(currentPos, lookDownTarget)
				myHrp.AssemblyLinearVelocity = Vector3.zero
			end
		else
			-- Always Fly mode active without an explicit target: lock current position and freeze velocity to prevent any gravity sag
			myHrp.CFrame = CFrame.new(currentPos)
			myHrp.AssemblyLinearVelocity = Vector3.zero
			myHrp.AssemblyAngularVelocity = Vector3.zero
		end
	else
		if humanoid and humanoid.PlatformStand then
			humanoid.PlatformStand = false
		end
	end
