local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local DataService = require(game:GetService("ServerScriptService").Server.Services.DataService)
local IslandManager = require(game:GetService("ServerScriptService").Server.Services.IslandManager)
local Network = require(game:GetService("ReplicatedStorage").Shared.Network)

local prof = _G.ContractorProfiles and _G.ContractorProfiles[p.UserId] or DataService.GetProfile(p)
if not prof then return "No profile found yet" end
prof.Plots[1].BuildingLevel = 5

-- Rebuild visuals for Level 5
IslandManager.UpdateBuildingVisuals(p, 1, 5)

-- Sync to client
Network.SyncBuildingEvent:FireClient(p, 5, 1, prof.Plots[1].ProjectType or "SingleBuilding")

return "Upgraded plot to Level 5 and synced to client!"
