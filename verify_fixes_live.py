import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    test_code = """
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
    local IslandManager = require(Server.Services.IslandManager)
    local BuildingBuilder = require(Server.Services.Island.BuildingBuilder)

    local player = Players:GetPlayers()[1]
    if not player then return "NO_PLAYER_FOUND" end

    local plot = IslandManager.GetPlot(player, 1)
    if not plot then
        plot = IslandManager.CreatePlot(player, 1, 1, 1)
    end

    local results = {}
    table.insert(results, "=== VERIFYING BUILDINGS (LEVEL 1-5 GROUND ALIGNMENT & SIZES) ===")

    for lvl = 1, 5 do
        IslandManager.UpdateBuildingVisuals(player, 1, lvl)
        local bModel = plot.Folder:FindFirstChild("BuildingModel")
        if bModel then
            local minY = math.huge
            local maxY = -math.huge
            local minX, maxX = math.huge, -math.huge
            local minZ, maxZ = math.huge, -math.huge
            local partCount = 0

            for _, d in ipairs(bModel:GetDescendants()) do
                if d:IsA("BasePart") then
                    partCount += 1
                    local cf = d.CFrame
                    local sz = d.Size
                    local pMinY = cf.Position.Y - (sz.Y / 2)
                    local pMaxY = cf.Position.Y + (sz.Y / 2)
                    if pMinY < minY then minY = pMinY end
                    if pMaxY > maxY then maxY = pMaxY end
                    if cf.Position.X < minX then minX = cf.Position.X end
                    if cf.Position.X > maxX then maxX = cf.Position.X end
                    if cf.Position.Z < minZ then minZ = cf.Position.Z end
                    if cf.Position.Z > maxZ then maxZ = cf.Position.Z end
                end
            end

            local height = maxY - minY
            local widthX = maxX - minX
            local depthZ = maxZ - minZ
            table.insert(results, string.format(
                "Level %d [%s]: Parts=%d, minY=%.2f (Expected ~6.20), Height=%.1f, Footprint=%.1fx%.1f",
                lvl, bModel.Name, partCount, minY, height, widthX, depthZ
            ))
        else
            table.insert(results, string.format("Level %d: NO BUILDING MODEL FOUND!", lvl))
        end
    end

    table.insert(results, "\\n=== VERIFYING LEVEL 5 SKYSCRAPER & PROMENADE COLLISION ===")
    local oldPlaza = plot.Folder:FindFirstChild("SkyscraperPlaza")
    table.insert(results, "Procedural SkyscraperPlaza exists: " .. tostring(oldPlaza ~= nil) .. " (Expected: false)")
    local promenade = plot.Folder:FindFirstChild("CommercialPromenade")
    table.insert(results, "CommercialPromenade exists: " .. tostring(promenade ~= nil) .. " (Expected: true)")

    table.insert(results, "\\n=== VERIFYING WORKER NPCS CLEARANCE ===")
    local office = plot.Folder:FindFirstChild("SiteOffice")
    local officeCF = office and office.CFrame
    local officeSz = office and office.Size
    table.insert(results, string.format("SiteOffice: Pos=%s, Size=%s", tostring(officeCF and officeCF.Position or "NIL"), tostring(officeSz or "NIL")))

    local usta = plot.Folder:FindFirstChild("Worker_Usta Ahmet")
    local burak = plot.Folder:FindFirstChild("Worker_Mühendis Burak")
    if usta and usta.PrimaryPart then
        table.insert(results, string.format("Usta Ahmet Pos: %s", tostring(usta.PrimaryPart.Position)))
    else
        table.insert(results, "Usta Ahmet: NOT FOUND")
    end
    if burak and burak.PrimaryPart then
        local bPos = burak.PrimaryPart.Position
        local insideOffice = office and (math.abs(bPos.X - officeCF.Position.X) < officeSz.X/2 and math.abs(bPos.Z - officeCF.Position.Z) < officeSz.Z/2)
        table.insert(results, string.format("Mühendis Burak Pos: %s, Inside Office: %s (Expected: false)", tostring(bPos), tostring(insideOffice)))
    else
        table.insert(results, "Mühendis Burak: NOT FOUND")
    end

    table.insert(results, "\\n=== VERIFYING CLIENT UI (HAMMER BUTTON SIZE) ===")
    local pGui = player:FindFirstChild("PlayerGui")
    local hud = pGui and pGui:FindFirstChild("BuilderHUD")
    local hammerBtn = hud and hud:FindFirstChild("HammerQuickButton")
    if hammerBtn then
        table.insert(results, string.format("HammerQuickButton Size: (%d, %d) (Expected: 135, 42), Pos: %s", hammerBtn.AbsoluteSize.X, hammerBtn.AbsoluteSize.Y, tostring(hammerBtn.Position)))
    else
        table.insert(results, "HammerQuickButton: NOT FOUND in BuilderHUD")
    end

    table.insert(results, "\\n=== VERIFYING UNLOCK PAD CONFIGURATION ===")
    local unlockPad = plot.Folder:FindFirstChild("UnlockNewPlotPad")
    if unlockPad then
        table.insert(results, string.format("UnlockNewPlotPad: Transparency=%d, CanCollide=%s", unlockPad.Transparency, tostring(unlockPad.CanCollide)))
    end

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
