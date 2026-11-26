local sp = game:GetService("StarterPlayer")
local clientFolder = sp.StarterPlayerScripts:FindFirstChild("Client")
local vc = clientFolder and clientFolder:FindFirstChild("VehicleController")
if not vc then return "No VehicleController in Client folder" end

local src = vc.Source
local idx = src:find("mover.LineDirection")
if idx then
    return src:sub(idx, idx + 100)
else
    return "LineDirection NOT FOUND in VehicleController!"
end
