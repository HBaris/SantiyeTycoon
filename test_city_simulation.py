import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()
print("Connected to Studio ID:", studio_id)

test_code = """
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players:GetPlayers()[1]
if not player then return "NO_PLAYER_FOUND" end

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)

local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local CityManager = require(Server.Services.CityManager)
local IslandManager = require(Server.Services.IslandManager)
local DataService = require(Server.Services.DataService)

local results = {}
table.insert(results, "=== 1. CURRENCY & LEADERSTATS VERIFICATION ===")
local leaderstats = player:FindFirstChild("leaderstats")
local cashVal = leaderstats and leaderstats:FindFirstChild(GameConfig.CURRENCY_NAME)
table.insert(results, "Leaderstats Currency Name: " .. (cashVal and cashVal.Name or "NOT_FOUND"))
table.insert(results, "NumberFormat Sample: " .. NumberFormat.FormatCash(150000))
table.insert(results, "Config Currency Symbol: " .. tostring(GameConfig.CURRENCY_SYMBOL))

table.insert(results, "\\n=== 2. INITIAL CITY STATS ===")
local initialStats = CityManager.GetCityStats(player)
table.insert(results, string.format("Initial Population: %d", initialStats.Population))
table.insert(results, string.format("Initial Happiness: %d%%", initialStats.Happiness))
table.insert(results, string.format("Initial Multiplier: %.2fx", initialStats.HappinessMultiplier))

table.insert(results, "\\n=== 3. ZONING (BÖLGELEME) TEST ===")
-- Give player enough cash for testing
DataService.AddCash(player, 100000)

-- Test Commercial Zone
local zSuccess, zMsg = CityManager.SetPlotZone(player, 1, "Commercial")
table.insert(results, string.format("Set Zone Commercial: success=%s, msg=%s", tostring(zSuccess), tostring(zMsg)))
local commStats = CityManager.GetCityStats(player)
local commMult = CityManager.GetCommercialMultiplier(player, 1)
table.insert(results, string.format("Commercial Zones Count: %d, Rent Multiplier: %.2fx", commStats.Zones.Commercial, commMult))

-- Test Industrial Zone
CityManager.SetPlotZone(player, 1, "Industrial")
local indStats = CityManager.GetCityStats(player)
local cargoB, turboB = CityManager.GetIndustrialBonus(player, 1)
table.insert(results, string.format("Industrial Zones Count: %d, Cargo Bonus: %.1fx, Turbo Bonus: %.1fx", indStats.Zones.Industrial, cargoB, turboB))

-- Test Residential Zone
CityManager.SetPlotZone(player, 1, "Residential")
local resStats = CityManager.GetCityStats(player)
table.insert(results, string.format("Residential Population: %d (Plot 1 Lv1)", resStats.Population))

-- Check 3D Zone Indicator Model
local plot = IslandManager.GetPlot(player, 1)
local zInd = plot and plot.Folder and plot.Folder:FindFirstChild("ZoneIndicator")
table.insert(results, string.format("3D Zone Indicator Model exists: %s", tostring(zInd ~= nil)))

table.insert(results, "\\n=== 4. SERVICE BUILDINGS (HİZMET BİNALARI) TEST ===")
-- Build FireStation
local s1, m1 = CityManager.BuildService(player, "FireStation", 1)
local statsAfterFire = CityManager.GetCityStats(player)
table.insert(results, string.format("FireStation Built: %s, Happiness: %d%% (+%d%%)", tostring(s1), statsAfterFire.Happiness, statsAfterFire.Happiness - initialStats.Happiness))

-- Build Clinic
local s2, m2 = CityManager.BuildService(player, "Clinic", 1)
local statsAfterClinic = CityManager.GetCityStats(player)
table.insert(results, string.format("Clinic Built: %s, Happiness: %d%%", tostring(s2), statsAfterClinic.Happiness))

-- Build Park
local s3, m3 = CityManager.BuildService(player, "Park", 1)
local statsAfterPark = CityManager.GetCityStats(player)
table.insert(results, string.format("Park Built: %s, Final Happiness: %d%%, Final Multiplier: %.2fx", tostring(s3), statsAfterPark.Happiness, statsAfterPark.HappinessMultiplier))

-- Check Service Visuals on Plot
local servFolder = plot and plot.Folder and plot.Folder:FindFirstChild("Services")
table.insert(results, string.format("Services Folder on Plot: %s", tostring(servFolder ~= nil)))
if servFolder then
    for _, sType in ipairs({"FireStation", "Clinic", "Park"}) do
        local m = servFolder:FindFirstChild("Service_" .. sType)
        table.insert(results, string.format("  Service_%s: exists=%s, parts=%d", sType, tostring(m ~= nil), m and #m:GetDescendants() or 0))
    end
end

table.insert(results, "\\n=== 5. PROMENADE READY PROPS TEST ===")
IslandManager.UpdateBuildingVisuals(player, 1, 5) -- Level 5 triggers full promenade
local prom = plot and plot.Folder and plot.Folder:FindFirstChild("CommercialPromenade")
if prom then
    local lamp = prom:FindFirstChild("PromenadeLamp")
    local bench = prom:FindFirstChild("PromenadeBench")
    local planter = prom:FindFirstChild("PromenadePlanter")
    table.insert(results, string.format("Promenade Ready Lamp: exists=%s, descendants=%d", tostring(lamp ~= nil), lamp and #lamp:GetDescendants() or 0))
    table.insert(results, string.format("Promenade Ready Bench: exists=%s, descendants=%d", tostring(bench ~= nil), bench and #bench:GetDescendants() or 0))
    table.insert(results, string.format("Promenade Ready Planter: exists=%s, descendants=%d", tostring(planter ~= nil), planter and #planter:GetDescendants() or 0))
end

return table.concat(results, "\\n")
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Server",
    "code": test_code
})

txt = res.get("content", [{}])[0].get("text", "")
print(txt.encode('ascii', 'replace').decode('ascii'))
client.close()
