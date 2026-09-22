import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    test_code = """
    local Players = game:GetService("Players")
    local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
    local IslandManager = require(Server.Services.IslandManager)

    local player = Players:GetPlayers()[1]
    if not player then return "NO_PLAYER_FOUND" end

    local plot = IslandManager.GetPlot(player, 1)
    if not plot then
        plot = IslandManager.CreatePlot(player, 1, 1, 1)
    end

    local results = {}

    -- ========================================================================
    -- TEST 1: STAGE 1 (Ahşap Kulübe) - Active Construction Site & Stage 1 Landscape
    -- ========================================================================
    IslandManager.UpdateBuildingVisuals(player, 1, 1)
    table.insert(results, "=== STAGE 1 (LEVEL 1: AHŞAP KULÜBE) ===")

    local crane1 = plot.Folder:FindFirstChild("TowerCrane")
    local office1 = plot.Folder:FindFirstChild("SiteOffice")
    local plaque1 = plot.Folder:FindFirstChild("CorporatePlaque")
    local workers1 = plot.Folder:FindFirstChild("SiteWorkers")
    local landscape1 = plot.Folder:FindFirstChild("ParcelLandscape")
    local cargo1 = plot.Folder:FindFirstChild("CargoUnloadPad")

    local usta1 = workers1 and workers1:FindFirstChild("Worker_Usta Ahmet")
    local burak1 = workers1 and workers1:FindFirstChild("Worker_Mühendis Burak")
    local can1 = workers1 and workers1:FindFirstChild("Worker_Sevkiyatçı Can")

    table.insert(results, string.format("Crane present: %s (Expected: true)", tostring(crane1 ~= nil)))
    table.insert(results, string.format("SiteOffice present: %s (Expected: true)", tostring(office1 ~= nil)))
    table.insert(results, string.format("CorporatePlaque present: %s (Expected: false)", tostring(plaque1 ~= nil)))
    table.insert(results, string.format("Workers present: Ahmet=%s, Burak=%s, Can=%s (Expected: true, true, true)", tostring(usta1 ~= nil), tostring(burak1 ~= nil), tostring(can1 ~= nil)))
    table.insert(results, string.format("CargoPad active: Transparency=%d, Collide=%s (Expected: 0, true)", cargo1 and cargo1.Transparency or -1, tostring(cargo1 and cargo1.CanCollide)))

    local pineCount1 = 0
    if landscape1 then
        for _, child in ipairs(landscape1:GetChildren()) do
            if child.Name == "LandscapePine" then pineCount1 += 1 end
        end
    end
    table.insert(results, string.format("Stage 1 Pines in Landscape: %d (Expected: >= 2)", pineCount1))

    -- ========================================================================
    -- TEST 2: STAGE 2 & 3 - Dynamic Tree/Landscape Transition
    -- ========================================================================
    IslandManager.UpdateBuildingVisuals(player, 1, 2)
    local landscape2 = plot.Folder:FindFirstChild("ParcelLandscape")
    local gardenCount2 = 0
    if landscape2 then
        for _, child in ipairs(landscape2:GetChildren()) do
            if child.Name == "LandscapeGardenTree" then gardenCount2 += 1 end
        end
    end
    table.insert(results, string.format("\\n=== STAGE 2: Suburban Garden Trees=%d (Expected: >= 2)", gardenCount2))

    IslandManager.UpdateBuildingVisuals(player, 1, 3)
    local landscape3 = plot.Folder:FindFirstChild("ParcelLandscape")
    local cypressCount3 = 0
    if landscape3 then
        for _, child in ipairs(landscape3:GetChildren()) do
            if child.Name == "LandscapeCypress" then cypressCount3 += 1 end
        end
    end
    table.insert(results, string.format("=== STAGE 3: Modern Villa Cypress Trees=%d (Expected: >= 3)", cypressCount3))

    -- ========================================================================
    -- TEST 3: STAGE 5 (%100 PROJE TAMAMLANDI) - Full Construction Removal!
    -- ========================================================================
    IslandManager.UpdateBuildingVisuals(player, 1, 5)
    table.insert(results, "\\n=== STAGE 5 (LEVEL 5: GÖKDELEN %100 TAMAMLANDI) ===")

    local crane5 = plot.Folder:FindFirstChild("TowerCrane")
    local office5 = plot.Folder:FindFirstChild("SiteOffice")
    local plaque5 = plot.Folder:FindFirstChild("CorporatePlaque")
    local workers5 = plot.Folder:FindFirstChild("SiteWorkers")
    local cargo5 = plot.Folder:FindFirstChild("CargoUnloadPad")
    local hammer5 = plot.Folder:FindFirstChild("HammerTarget")
    local landscape5 = plot.Folder:FindFirstChild("ParcelLandscape")
    local promenade5 = plot.Folder:FindFirstChild("CommercialPromenade")

    -- Check if any worker models exist anywhere in the plot folder
    local leftoverWorkers = {}
    for _, child in ipairs(plot.Folder:GetChildren()) do
        if child.Name:match("^Worker_") then
            table.insert(leftoverWorkers, child.Name)
        end
    end
    if workers5 then
        for _, child in ipairs(workers5:GetChildren()) do
            table.insert(leftoverWorkers, child.Name)
        end
    end

    table.insert(results, string.format("Crane removed: %s (Expected: true)", tostring(crane5 == nil)))
    table.insert(results, string.format("SiteOffice removed: %s (Expected: true)", tostring(office5 == nil)))
    table.insert(results, string.format("CorporatePlaque built: %s (Expected: true)", tostring(plaque5 ~= nil)))
    table.insert(results, string.format("SiteWorkers folder removed: %s (Expected: true)", tostring(workers5 == nil)))
    table.insert(results, string.format("Leftover worker NPCs: %d %s (Expected: 0)", #leftoverWorkers, tostring(leftoverWorkers)))
    table.insert(results, string.format("CargoPad disabled: Transparency=%d, Collide=%s (Expected: 1, false)", cargo5 and cargo5.Transparency or -1, tostring(cargo5 and cargo5.CanCollide)))

    local cd5 = hammer5 and hammer5:FindFirstChildOfClass("ClickDetector")
    table.insert(results, string.format("HammerTarget ClickDetector disabled: %s (Expected: true)", tostring(cd5 and cd5.MaxActivationDistance == 0)))

    local blvdCount5 = 0
    local gardenPlaza5 = landscape5 and landscape5:FindFirstChild("GardenPlazaLawn")
    if landscape5 then
        for _, child in ipairs(landscape5:GetChildren()) do
            if child.Name == "LandscapeBoulevardTree" then blvdCount5 += 1 end
        end
    end
    table.insert(results, string.format("Stage 5 Boulevard Trees: %d (Expected: >= 3)", blvdCount5))
    table.insert(results, string.format("Stage 5 Garden Plaza Lawn exists: %s (Expected: true)", tostring(gardenPlaza5 ~= nil)))
    table.insert(results, string.format("Commercial Promenade exists: %s (Expected: true)", tostring(promenade5 ~= nil)))

    return table.concat(results, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Server",
        "code": test_code
    })

    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
