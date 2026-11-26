local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local ps = lp:FindFirstChild("PlayerScripts")
local clientFolder = ps and ps:FindFirstChild("Client")
local vc = clientFolder and clientFolder:FindFirstChild("VehicleController")
if not vc then return "No VehicleController in PlayerScripts.Client" end

local src = vc.Source
local idx = src:find("mover.LineDirection")
if idx then
    return "FOUND: " .. src:sub(idx, idx + 80)
else
    return "NOT FOUND in PlayerScripts.Client.VehicleController!"
end
