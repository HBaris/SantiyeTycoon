import time
import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()

    # 1. Check current sizes
    size_check = """
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]
    local plot = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local prom = plot and plot:FindFirstChild("CommercialPromenade")
    local bakery = prom and prom:FindFirstChild("Shop_Slot1_Bakery")
    local building = plot and plot:FindFirstChild("BuildingModel")
    
    local _, bSize = bakery:GetBoundingBox()
    local _, buildSize = building:GetBoundingBox()
    
    return game:GetService("HttpService"):JSONEncode({
        bakeryBefore = {math.round(bSize.X), math.round(bSize.Y), math.round(bSize.Z)},
        buildingBefore = {math.round(buildSize.X), math.round(buildSize.Y), math.round(buildSize.Z)}
    })
    """
    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": size_check
    })
    print("Before Scale:", res.get("content", [{}])[0].get("text", ""))

    # 2. Fire CustomizeModelEvent to scale bakery by 1.5x and building by 1.25x
    scale_call = """
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players:GetPlayers()[1]
    local Network = require(ReplicatedStorage.Shared.Network)
    
    Network.CustomizeModelEvent:FireServer(1, "Shop_Slot1_Bakery", "Scale", 1.5)
    Network.CustomizeModelEvent:FireServer(1, "BuildingModel", "Scale", 1.25)
    return "SCALE_FIRED"
    """
    res_scale = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": scale_call
    })
    print("Scale Fire:", res_scale.get("content", [{}])[0].get("text", ""))

    time.sleep(2)

    # 3. Check sizes after scale
    size_check_after = """
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]
    local plot = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local prom = plot and plot:FindFirstChild("CommercialPromenade")
    local bakery = prom and prom:FindFirstChild("Shop_Slot1_Bakery")
    local building = plot and plot:FindFirstChild("BuildingModel")
    
    local _, bSize = bakery:GetBoundingBox()
    local _, buildSize = building:GetBoundingBox()
    
    return game:GetService("HttpService"):JSONEncode({
        bakeryAfter = {math.round(bSize.X), math.round(bSize.Y), math.round(bSize.Z)},
        buildingAfter = {math.round(buildSize.X), math.round(buildSize.Y), math.round(buildSize.Z)}
    })
    """
    res_after = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": size_check_after
    })
    print("After Scale:", res_after.get("content", [{}])[0].get("text", ""))

    client.close()

if __name__ == "__main__":
    main()
