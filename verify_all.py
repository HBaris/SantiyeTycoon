import time
import base64
from roblox_mcp_client import RobloxStudioMCPClient

time.sleep(3)
client = RobloxStudioMCPClient()
sid = client.get_studio_id()

# 1. Server: Give Cash, Upgrade to Level 5, Spawn Scooter
setup_code = """
local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local DataService = require(game:GetService("ServerScriptService").Server.Services.DataService)
local ConstructionService = require(game:GetService("ServerScriptService").Server.Services.ConstructionService)
local GarageService = require(game:GetService("ServerScriptService").Server.Services.GarageService)
local IslandManager = require(game:GetService("ServerScriptService").Server.Services.IslandManager)
local Network = require(game:GetService("ReplicatedStorage").Shared.Network)

local profile = DataService.GetProfile(p)
if not profile then
    profile = DataService.LoadPlayer(p)
end

profile.Cash = 500000
local ls = p:FindFirstChild("leaderstats")
if ls and ls:FindFirstChild("💰 Kasa (İP)") then
    ls["💰 Kasa (İP)"].Value = 500000
end

-- Upgrade to Level 5
for targetLvl = 2, 5 do
    ConstructionService.HandleUpgradeBuilding(p, 1)
end

-- Spawn Scooter
GarageService.SpawnVehicle(p, "Scooter")

return string.format("Level: %d, Cash: %d, Scooter spawned!", profile.Plots[1].BuildingLevel, profile.Cash)
"""

res = client.call_tool("execute_luau", {
    "studio_id": sid,
    "datamodel_type": "Server",
    "code": setup_code
})
print("Server setup result:", res.get("content", [{}])[0].get("text", ""))

time.sleep(1.5)

# 2. Capture View 1: Commercial Promenade with Non-glare Ground, Fountain, and Residents
cam_prom_code = """
local Players = game:GetService("Players")
local p = Players.LocalPlayer
local char = p.Character
if char then
    local targetCF = CFrame.lookAt(Vector3.new(-22, 10, 44), Vector3.new(-22, 9, 15))
    char:PivotTo(targetCF)
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.lookAt(Vector3.new(-22, 13, 44), Vector3.new(-22, 8, 12))
    return "Camera facing Promenade"
end
return "No char"
"""
client.call_tool("execute_luau", {"studio_id": sid, "datamodel_type": "Client", "code": cam_prom_code})
time.sleep(0.5)

res = client.call_tool("screen_capture", {"studio_id": sid, "capture_id": "promenade_verified_final"})
with open("promenade_verified_final.png", "wb") as f:
    f.write(base64.b64decode(res["content"][0]["data"]))
print("Saved promenade_verified_final.png")

# 3. Capture View 2: Scooter and Depot Entrance Ramp
cam_depot_code = """
local Players = game:GetService("Players")
local p = Players.LocalPlayer
local char = p.Character
local scooter = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
if char and scooter then
    local root = scooter.PrimaryPart or scooter:FindFirstChild("Seat")
    if root then
        local cam = workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = CFrame.lookAt(root.Position + Vector3.new(10, 6, 12), root.Position)
        return "Camera facing Scooter at Depot"
    end
end
return "Scooter or char missing"
"""
res2 = client.call_tool("execute_luau", {"studio_id": sid, "datamodel_type": "Client", "code": cam_depot_code})
print("Depot cam result:", res2.get("content", [{}])[0].get("text", ""))
time.sleep(0.5)

res = client.call_tool("screen_capture", {"studio_id": sid, "capture_id": "scooter_depot_final"})
with open("scooter_depot_final.png", "wb") as f:
    f.write(base64.b64decode(res["content"][0]["data"]))
print("Saved scooter_depot_final.png")

# 4. Capture View 3: Plot Entrance Ramp (Connecting highway up to plot)
cam_ramp_code = """
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = CFrame.lookAt(Vector3.new(16, 11, 56), Vector3.new(0, 6.0, 38))
return "Camera facing Entrance Ramp"
"""
client.call_tool("execute_luau", {"studio_id": sid, "datamodel_type": "Client", "code": cam_ramp_code})
time.sleep(0.5)

res = client.call_tool("screen_capture", {"studio_id": sid, "capture_id": "entrance_ramp_final"})
with open("entrance_ramp_final.png", "wb") as f:
    f.write(base64.b64decode(res["content"][0]["data"]))
print("Saved entrance_ramp_final.png")

client.close()
