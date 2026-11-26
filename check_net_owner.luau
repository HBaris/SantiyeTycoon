local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
if not veh then return "No vehicle" end

local root = veh.PrimaryPart
local owner = root:GetNetworkOwner()
return "Network Owner of Scooter: " .. (owner and owner.Name or "Server (nil)")
