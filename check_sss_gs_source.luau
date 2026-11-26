local sss = game:GetService("ServerScriptService")
local gs = sss.Server.Services.GarageService
local src = gs.Source
local lineIdx = src:find("mover.LineDirection")
if lineIdx then
    return src:sub(lineIdx, lineIdx + 100)
else
    return "LineDirection NOT FOUND in ServerScriptService GarageService!"
end
