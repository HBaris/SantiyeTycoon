local RS = game:GetService("ReplicatedStorage")
local scoot = RS.Assets.Vehicles:FindFirstChild("Scooter")
if not scoot then return "No Scooter in RS.Assets.Vehicles" end

local parts = {}
for _, d in ipairs(scoot:GetDescendants()) do
    if d:IsA("BasePart") or d:IsA("Seat") or d:IsA("VehicleSeat") then
        table.insert(parts, string.format("%s (%s)", d.Name, d.ClassName))
    end
end
return table.concat(parts, "\n")
