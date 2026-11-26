local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local DS = require(game:GetService("ServerScriptService").Server.Services.DataService)
local prof = DS.GetProfile(p)
local gProf = _G.ContractorProfiles and _G.ContractorProfiles[p.UserId]
return string.format("DS prof: %s, _G prof: %s", tostring(prof ~= nil), tostring(gProf ~= nil))
