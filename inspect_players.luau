local Players = game:GetService("Players")
local DataService = require(game:GetService("ServerScriptService").Server.Services.DataService)
local res = {}
for _, p in ipairs(Players:GetPlayers()) do
    local prof = DataService.GetProfile(p)
    table.insert(res, string.format("Player: %s, hasProfile: %s", p.Name, tostring(prof ~= nil)))
end
return table.concat(res, "\n")
