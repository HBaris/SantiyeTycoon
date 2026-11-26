import time
import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    # 1. Wait a couple seconds for player and island to initialize
    check_code = """
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]
    if not player then return "NO_PLAYER" end
    
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return "NO_PLAYER_GUI" end
    
    local customizerHUD = pg:FindFirstChild("DevCustomizerHUD")
    local hudStatus = customizerHUD and "HUD_FOUND" or "HUD_NOT_FOUND"
    
    local plot1 = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local promenade = plot1 and plot1:FindFirstChild("CommercialPromenade")
    
    local shops = {}
    if promenade then
        for _, child in ipairs(promenade:GetChildren()) do
            if child:IsA("Model") then
                local cf, sz = child:GetBoundingBox()
                table.insert(shops, {
                    name = child.Name,
                    size = {math.round(sz.X), math.round(sz.Y), math.round(sz.Z)},
                    pos = {math.round(cf.Position.X), math.round(cf.Position.Y), math.round(cf.Position.Z)}
                })
            end
        end
    end
    
    local building = plot1 and plot1:FindFirstChild("BuildingModel")
    local bSize = nil
    if building then
        local cf, sz = building:GetBoundingBox()
        bSize = {math.round(sz.X), math.round(sz.Y), math.round(sz.Z)}
    end
    
    return game:GetService("HttpService"):JSONEncode({
        hud = hudStatus,
        shops = shops,
        buildingSize = bSize
    })
    """
    
    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": check_code
    })
    print("PlayClient Check:", res.get("content", [{}])[0].get("text", ""))

    client.close()

if __name__ == "__main__":
    main()
