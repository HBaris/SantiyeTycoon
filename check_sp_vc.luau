local sp = game:GetService("StarterPlayer")
local vc = sp.StarterPlayerScripts:FindFirstChild("VehicleController")
if not vc then return "No VehicleController in StarterPlayerScripts" end

local src = vc.Source
local idx = src:find("mover.LineDirection")
if idx then
    return src:sub(idx, idx + 100)
else
    return "LineDirection NOT FOUND in StarterPlayerScripts VehicleController!"
end
