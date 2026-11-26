local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local folder = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
if not folder then return "No folder" end

local cp = folder:FindFirstChild("CommercialPromenade")
local pr = folder:FindFirstChild("PromenadeResidents")
local cr = folder:FindFirstChild("CityResidents")

return string.format("Promenade: %s | PromResidents: %s | CityResidents: %s",
    tostring(cp ~= nil), tostring(pr ~= nil), tostring(cr ~= nil))
