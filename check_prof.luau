local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end
local ls = p:FindFirstChild("leaderstats")
local DataService = require(game:GetService("ServerScriptService").Server.Services.DataService)
local prof = DataService.GetProfile(p)
return string.format("Player: %s | leaderstats: %s | profile: %s", p.Name, tostring(ls ~= nil), tostring(prof ~= nil))
