local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local vehs = {}
for _, v in ipairs(workspace:GetChildren()) do
    if v.Name:find("Vehicle") or v.Name:find("Scooter") or v.Name:find("Pickup") then
        local cf, sz = v:GetBoundingBox()
        table.insert(vehs, string.format("Veh '%s' at (%.1f, %.1f, %.1f)", v.Name, cf.Position.X, cf.Position.Y, cf.Position.Z))
    end
end

local garage = workspace:FindFirstChild("GarageFacility") or workspace:FindFirstChild("CentralGarageDepot")
local gInfo = garage and string.format("Garage '%s' found at pos=(%.1f, %.1f, %.1f)", garage.Name, garage:GetPivot().Position.X, garage:GetPivot().Position.Y, garage:GetPivot().Position.Z) or "No garage in workspace"

return table.concat(vehs, "\n") .. "\n" .. gInfo
