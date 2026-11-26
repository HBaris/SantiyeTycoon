local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart
if not seat then return "No seat" end
local veh = seat.Parent

local lines = {}
for _, p in ipairs(veh:GetDescendants()) do
    if p:IsA("BasePart") then
        local cf = p.CFrame
        local sz = p.Size
        local bottomY = cf.Position.Y - sz.Y / 2
        table.insert(lines, string.format("Part '%s': pos=(%.2f, %.2f, %.2f), size=(%.2f, %.2f, %.2f), bottomY=%.2f, Anchored=%s, CanCollide=%s, Mass=%.1f",
            p.Name, cf.Position.X, cf.Position.Y, cf.Position.Z, sz.X, sz.Y, sz.Z, bottomY, tostring(p.Anchored), tostring(p.CanCollide), p.Mass))
    end
end

-- Ground check: cast a ray downward from seat
local rayOrigin = seat.Position
local rayDir = Vector3.new(0, -10, 0)
local params = RaycastParams.new()
params.FilterDescendantsInstances = { veh, char }
params.FilterType = Enum.RaycastFilterType.Exclude

local result = workspace:Raycast(rayOrigin, rayDir, params)
if result then
    table.insert(lines, string.format("Ground detected: '%s' at hitPos=(%.2f, %.2f, %.2f), Dist=%.2f",
        result.Instance.Name, result.Position.X, result.Position.Y, result.Position.Z, result.Distance))
else
    table.insert(lines, "NO GROUND DETECTED")
end

return table.concat(lines, "\n")
