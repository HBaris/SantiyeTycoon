local wedge = Instance.new("WedgePart")
wedge.Size = Vector3.new(16, 2, 10)
wedge.CFrame = CFrame.new(0, 5, 43) * CFrame.Angles(0, math.pi, 0)
wedge.Anchored = true
wedge.Parent = workspace

local pFront = wedge.CFrame * Vector3.new(0, -1, -5) -- top or bottom?
local pBack = wedge.CFrame * Vector3.new(0, 1, 5)
local res = string.format("Front: %s | Back: %s", tostring(pFront), tostring(pBack))
wedge:Destroy()
return res
