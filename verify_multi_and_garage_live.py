import json
import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connecting to Studio ID:", studio_id)

    verify_code = """
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local ServerScriptService = game:GetService("ServerScriptService")

    local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
    local ProjectTypeConfig = require(ReplicatedStorage.Shared.ProjectTypeConfig)
    local Network = require(ReplicatedStorage.Shared.Network)

    local server = ServerScriptService.Server
    local services = server.Services
    local DataService = require(services.DataService)
    local GarageService = require(services.GarageService)
    local ConstructionService = require(services.ConstructionService)
    local IslandManager = require(services.IslandManager)
    local BuildingBuilder = require(services.Island.BuildingBuilder)

    local results = {}

    -- 1. ProjectTypeConfig Verification
    results.HasSingleBuilding = (ProjectTypeConfig.TYPES["SingleBuilding"] ~= nil)
    results.HasMultiBuilding = (ProjectTypeConfig.TYPES["MultiBuilding"] ~= nil)
    results.HasIslandProject = (ProjectTypeConfig.TYPES["IslandProject"] ~= nil)
    results.MultiBuildingCostMultiplier = ProjectTypeConfig.TYPES["MultiBuilding"].CostMultiplier
    results.MultiBuildingRewardMultiplier = ProjectTypeConfig.TYPES["MultiBuilding"].RewardMultiplier

    -- 2. GameConfig Upgrade Costs Verification
    results.BuildingLv2Cost = GameConfig.BUILDINGS[2].Cost
    results.BuildingLv3Cost = GameConfig.BUILDINGS[3].Cost
    results.BuildingLv4Cost = GameConfig.BUILDINGS[4].Cost
    results.BuildingLv5Cost = GameConfig.BUILDINGS[5].Cost

    -- 3. Network Events Verification
    results.HasSyncGarageEvent = (Network.SyncGarageEvent ~= nil)

    -- 4. MultiBuilding Geometry Spawning Verification (Levels 1 to 5)
    local testFolder = Instance.new("Folder")
    testFolder.Name = "TestMultiBuilding"
    testFolder.Parent = workspace

    local counts = {}
    for lvl = 1, 5 do
        local mModel = BuildingBuilder.buildBuildingModel(testFolder, Vector3.new(0, 0, lvl * 100), lvl, "MultiBuilding")
        local subBuildingCount = 0
        for _, child in ipairs(mModel:GetChildren()) do
            if child:IsA("Model") and child.Name:match("^Block_") then
                subBuildingCount += 1
            end
        end
        counts[tostring(lvl)] = subBuildingCount
        mModel:Destroy()
    end
    results.MultiBuildingSubCounts = counts

    -- SingleBuilding check
    local sModel = BuildingBuilder.buildBuildingModel(testFolder, Vector3.new(0, 0, 0), 1, "SingleBuilding")
    results.SingleBuildingChildren = #sModel:GetChildren()
    sModel:Destroy()
    testFolder:Destroy()

    -- 5. Live Player & Garage Test
    local player = Players:GetPlayers()[1]
    if player then
        local profile = DataService.GetProfile(player) or DataService.LoadPlayer(player)
        results.PlayerName = player.Name
        results.OwnsScooter = DataService.OwnsVehicle(player, "Scooter")
        results.InitialCash = profile and profile.Cash or 0

        -- Test vehicle purchase
        DataService.AddCash(player, 1000)
        local initialMotorcycle = DataService.OwnsVehicle(player, "Motorcycle")
        results.InitialMotorcycle = initialMotorcycle

        DataService.AddVehicle(player, "Motorcycle")
        results.AfterBuyMotorcycle = DataService.OwnsVehicle(player, "Motorcycle")

        -- Test DeliveredMaterials and upgrade discount
        if profile and profile.Plots and profile.Plots[1] then
            profile.Plots[1].DeliveredMaterials = 15 -- 15 units delivered
            local plot = IslandManager.GetPlot(player, 1)
            IslandManager.UpdateUpgradePadText(player, 1)
            results.UpgradePadText = plot and plot.UpgradePadLabel and plot.UpgradePadLabel.Text or "N/A"
            results.DeliveredMaterialsBefore = profile.Plots[1].DeliveredMaterials
        end
    else
        results.PlayerFound = false
    end

    local HttpService = game:GetService("HttpService")
    return HttpService:JSONEncode(results)
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Server",
        "code": verify_code
    })

    output_text = res.get("content", [{}])[0].get("text", "")
    print("\n--- Live Verification Result ---")
    try:
        data = json.loads(output_text)
        print(json.dumps(data, indent=2, ensure_ascii=False))
    except Exception:
        print(output_text)

    client.close()

if __name__ == "__main__":
    main()
