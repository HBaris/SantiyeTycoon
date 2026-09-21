local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BASE_ROTATION_SPEED = 0.4 -- radyan / saniye (ağır kule vinç dönüşü)
local TURBO_MULTIPLIER = 2.5 -- Turbo modunda hızlı taşıma

-- Tüm şantiyelerdeki kule vinçlerin yatay kolunu (Jib) istemci tarafında pürüzsüzce döndür
RunService.RenderStepped:Connect(function(deltaTime)
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name:match("^Plot_") then
			local craneModel = child:FindFirstChild("TowerCrane") :: Model
			if craneModel then
				local jib = craneModel:FindFirstChild("CraneJib") :: BasePart
				local mast = craneModel:FindFirstChild("CraneMast") :: BasePart
				local beacon = craneModel:FindFirstChild("WarningBeacon") :: BasePart

				if jib and mast then
					local rateLabel = child:FindFirstChild("RateBillboard", true)
					local isTurbo = false
					if rateLabel and rateLabel:IsA("TextLabel") and rateLabel.Text:find("TURBO") then
						isTurbo = true
					end

					local speed = BASE_ROTATION_SPEED * (isTurbo and TURBO_MULTIPLIER or 1.0)
					local rotationAngle = speed * deltaTime

					-- Vinç kolunu direğin (Mast) dikey Y ekseni etrafında döndür
					local pivotPosition = Vector3.new(mast.Position.X, jib.Position.Y, mast.Position.Z)
					local currentOffset = jib.Position - pivotPosition
					local rotatedOffset = CFrame.Angles(0, rotationAngle, 0):VectorToWorldSpace(currentOffset)

					jib.CFrame = CFrame.new(pivotPosition + rotatedOffset) * (jib.CFrame - jib.Position) * CFrame.Angles(0, rotationAngle, 0)

					-- Turbo modunda tepe ikaz lambasını yanıp söndür
					if beacon then
						if isTurbo then
							beacon.Color = (math.sin(tick() * 12) > 0) and Color3.fromRGB(255, 230, 0) or Color3.fromRGB(255, 30, 30)
						else
							beacon.Color = (math.sin(tick() * 3) > 0) and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(80, 20, 20)
						end
					end
				end
			end
		end
	end
end)
