from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()
print("Studio ID:", studio_id)

test_code = """
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]

local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local IslandManager = require(Server.Services.IslandManager)

local isDummy = false
if not player then
    isDummy = true
    player = Instance.new("Player")
    player.Name = "TestMuteahhit"
end

local plot = IslandManager.GetPlot(player, 1)
if not plot then
    plot = IslandManager.CreatePlot(player, 1, 1, 1)
end

local results = {}
table.insert(results, "Player: " .. player.Name .. (isDummy and " (Mock)" or " (Live)"))

-- 1. Test Level 4 (Residence + Promenade with Bakery & Market)
IslandManager.UpdateBuildingVisuals(player, 1, 4)

local bModel4 = plot.Folder:FindFirstChild("BuildingModel")
local prom4 = plot.Folder:FindFirstChild("CommercialPromenade")
local res4 = plot.Folder:FindFirstChild("PromenadeResidents")

table.insert(results, "\\n--- LEVEL 4 PROMENADE & TOWER TEST ---")
table.insert(results, "BuildingModel exists: " .. tostring(bModel4 ~= nil))
if bModel4 then
    table.insert(results, "  Has GrandEntranceCanopy: " .. tostring(bModel4:FindFirstChild("GrandEntranceCanopy") ~= nil))
    table.insert(results, "  Has CanopyFascia (Sign): " .. tostring(bModel4:FindFirstChild("CanopyFascia") ~= nil))
    table.insert(results, "  Has CanopySpot (Warm Light): " .. tostring(bModel4:FindFirstChild("CanopySpot") ~= nil))
    table.insert(results, "  Has LobbyDoorFrame: " .. tostring(bModel4:FindFirstChild("LobbyDoorFrame") ~= nil))
    table.insert(results, "  Has LobbyGlassFront: " .. tostring(bModel4:FindFirstChild("LobbyGlassFront") ~= nil))
    table.insert(results, "  Has ReceptionDesk: " .. tostring(bModel4:FindFirstChild("ReceptionDesk") ~= nil))
    table.insert(results, "  Storefront clutter removed: " .. tostring(bModel4:FindFirstChild("Shop_Bakery") == nil))
end

table.insert(results, "CommercialPromenade exists: " .. tostring(prom4 ~= nil))
if prom4 then
    table.insert(results, "  Has PromenadePavement: " .. tostring(prom4:FindFirstChild("PromenadePavement") ~= nil))
    table.insert(results, "  Has PromenadeEntranceGate: " .. tostring(prom4:FindFirstChild("PromenadeEntranceGate") ~= nil))
    table.insert(results, "  Has Shop_Bakery: " .. tostring(prom4:FindFirstChild("Shop_Bakery") ~= nil))
    table.insert(results, "  Has Shop_Market: " .. tostring(prom4:FindFirstChild("Shop_Market") ~= nil))
    table.insert(results, "  Has FountainPool: " .. tostring(prom4:FindFirstChild("FountainPool") ~= nil))
    table.insert(results, "  Has PromenadeLamp: " .. tostring(prom4:FindFirstChild("PromenadeLamp") ~= nil))
    table.insert(results, "  Has PromenadeBench: " .. tostring(prom4:FindFirstChild("PromenadeBench") ~= nil))
    table.insert(results, "  Has PromenadePlanter: " .. tostring(prom4:FindFirstChild("PromenadePlanter") ~= nil))
end

table.insert(results, "PromenadeResidents exists: " .. tostring(res4 ~= nil))
if res4 then
    table.insert(results, "  PromenadeResidents count: " .. #res4:GetChildren())
    for _, r in ipairs(res4:GetChildren()) do
        table.insert(results, "    - " .. r.Name)
    end
end

-- 2. Test Level 5 (Skyscraper + Full Promenade with Barber, PetShop, Restaurant Cafe Terrace)
IslandManager.UpdateBuildingVisuals(player, 1, 5)

local bModel5 = plot.Folder:FindFirstChild("BuildingModel")
local prom5 = plot.Folder:FindFirstChild("CommercialPromenade")
local res5 = plot.Folder:FindFirstChild("PromenadeResidents")

table.insert(results, "\\n--- LEVEL 5 PROMENADE & PRESTIGE SKYSCRAPER TEST ---")
table.insert(results, "BuildingModel exists: " .. tostring(bModel5 ~= nil))
if bModel5 then
    table.insert(results, "  Has GrandAtriumCanopy: " .. tostring(bModel5:FindFirstChild("GrandAtriumCanopy") ~= nil))
    table.insert(results, "  Has CanopyGoldEdge (3D Sign): " .. tostring(bModel5:FindFirstChild("CanopyGoldEdge") ~= nil))
    table.insert(results, "  Has RevolvingDrum (Revolving Door): " .. tostring(bModel5:FindFirstChild("RevolvingDrum") ~= nil))
    table.insert(results, "  Has AtriumCurtainGlass: " .. tostring(bModel5:FindFirstChild("AtriumCurtainGlass") ~= nil))
    table.insert(results, "  Has ExecReceptionDesk: " .. tostring(bModel5:FindFirstChild("ExecReceptionDesk") ~= nil))
    table.insert(results, "  Has AtriumChandelier: " .. tostring(bModel5:FindFirstChild("AtriumChandelier") ~= nil))
    table.insert(results, "  Storefront clutter removed: " .. tostring(bModel5:FindFirstChild("Shop_Barber") == nil))
end

table.insert(results, "CommercialPromenade exists: " .. tostring(prom5 ~= nil))
if prom5 then
    table.insert(results, "  Has Shop_Bakery: " .. tostring(prom5:FindFirstChild("Shop_Bakery") ~= nil))
    table.insert(results, "  Has Shop_Market: " .. tostring(prom5:FindFirstChild("Shop_Market") ~= nil))
    table.insert(results, "  Has Shop_Barber: " .. tostring(prom5:FindFirstChild("Shop_Barber") ~= nil))
    table.insert(results, "  Has Shop_PetShop: " .. tostring(prom5:FindFirstChild("Shop_PetShop") ~= nil))
    table.insert(results, "  Has Shop_Restaurant: " .. tostring(prom5:FindFirstChild("Shop_Restaurant") ~= nil))
    local rest = prom5:FindFirstChild("Shop_Restaurant")
    if rest then
        table.insert(results, "    Restaurant has CafeDeck: " .. tostring(rest:FindFirstChild("CafeDeck") ~= nil))
        table.insert(results, "    Restaurant has CafeTable_1: " .. tostring(rest:FindFirstChild("CafeTable_1") ~= nil))
        table.insert(results, "    Restaurant has CafeTable_4: " .. tostring(rest:FindFirstChild("CafeTable_4") ~= nil))
        table.insert(results, "    Restaurant has UmbrellaCanopy: " .. tostring(rest:FindFirstChild("UmbrellaCanopy") ~= nil))
    end

    local gate = prom5:FindFirstChild("PromenadeEntranceGate")
    if gate then
        local beam = gate:FindFirstChild("ArchBeam")
        if beam then
            local sg = beam:FindFirstChildOfClass("SurfaceGui")
            if sg and sg:FindFirstChild("Frame") then
                for _, lbl in ipairs(sg.Frame:GetChildren()) do
                    if lbl:IsA("TextLabel") then
                        table.insert(results, "    Gate Sign Text: " .. lbl.Text)
                    end
                end
            end
        end
    end
end

table.insert(results, "PromenadeResidents exists: " .. tostring(res5 ~= nil))
if res5 then
    table.insert(results, "  PromenadeResidents count: " .. #res5:GetChildren())
    for _, c in ipairs(res5:GetChildren()) do
        table.insert(results, "    - " .. c.Name)
    end
end

-- Rent check
local rent4 = IslandManager.GetCommercialRent(4)
local rent5 = IslandManager.GetCommercialRent(5)
table.insert(results, "\\n--- RENT VERIFICATION ---")
table.insert(results, "Level 4 Rent: " .. tostring(rent4) .. " $/s (Expected 75)")
table.insert(results, "Level 5 Rent: " .. tostring(rent5) .. " $/s (Expected 235)")

return table.concat(results, "\\n")
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Server",
    "code": test_code
})

text = res.get("content", [{}])[0].get("text", "")
print("=== PROMENADE TEST RESULT ===")
print(text.encode("ascii", "replace").decode("ascii"))
