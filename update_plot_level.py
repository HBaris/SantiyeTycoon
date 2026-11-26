import sys
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
sid = client.get_studio_id()

code = """
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
if not player then return "No player yet" end

local DataService = require(game:GetService("ServerScriptService").Server.Services.DataService)
local IslandManager = require(game:GetService("ServerScriptService").Server.Services.IslandManager)

local profile = DataService.GetProfile(player)
if not profile then return "No profile" end

-- Ensure Plot 1 is at least Level 4 so Promenade & Residents spawn
if not profile.Plots or not profile.Plots[1] then
    profile.Plots = { [1] = { BuildingLevel = 5, ProjectType = "Villa", DeliveredMaterials = 0 } }
else
    profile.Plots[1].BuildingLevel = 5
end

-- Refresh plot visuals
local plot = IslandManager.GetPlot(player, 1)
if plot then
    IslandManager.UpdatePlotVisuals(player, 1, 5)
    return "Plot 1 updated to Level 5 with Commercial Promenade!"
end
return "Plot not found"
"""

res = client.call_tool("execute_luau", {
    "studio_id": sid,
    "datamodel_type": "Server",
    "code": code
})
print("Result:", res.get("content", [{}])[0].get("text", ""))
client.close()
