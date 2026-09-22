import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()
print("Studio ID:", studio_id)

test_code = """
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
if not player then return "NO_PLAYER_FOUND" end

local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local IslandManager = require(Server.Services.IslandManager)

local plot = IslandManager.GetPlot(player, 1)
if not plot then
    plot = IslandManager.CreatePlot(player, 1, 1, 1)
end

local results = {}
table.insert(results, "=== TESTING READY MODELS & DECLUTTERED LAYOUT ===")

-- Test Level 1 (Ready Cabin Model)
IslandManager.UpdateBuildingVisuals(player, 1, 1)
local b1 = plot.Folder:FindFirstChild("BuildingModel")
local count1 = 0
if b1 then
    for _, d in ipairs(b1:GetDescendants()) do if d:IsA("BasePart") then count1 += 1 end end
end
table.insert(results, string.format("Level 1 Building: %s (Part count: %d, Ready Model: %s)", b1 and b1.Name or "NIL", count1, tostring(count1 > 50)))

-- Test Level 3 (Ready Villa Model)
IslandManager.UpdateBuildingVisuals(player, 1, 3)
local b3 = plot.Folder:FindFirstChild("BuildingModel")
local count3 = 0
if b3 then
    for _, d in ipairs(b3:GetDescendants()) do if d:IsA("BasePart") then count3 += 1 end end
end
table.insert(results, string.format("Level 3 Building: %s (Part count: %d, Ready Model: %s)", b3 and b3.Name or "NIL", count3, tostring(count3 > 100)))

-- Test Level 5 (Ready Skyscraper & Commercial Promenade)
IslandManager.UpdateBuildingVisuals(player, 1, 5)
local b5 = plot.Folder:FindFirstChild("BuildingModel")
local count5 = 0
if b5 then
    for _, d in ipairs(b5:GetDescendants()) do if d:IsA("BasePart") then count5 += 1 end end
end
table.insert(results, string.format("Level 5 Building: %s (Part count: %d, Ready Model: %s)", b5 and b5.Name or "NIL", count5, tostring(count5 > 500)))

-- Check Commercial Promenade Ready Models
local prom = plot.Folder:FindFirstChild("CommercialPromenade")
table.insert(results, "\\n=== COMMERCIAL READY MODELS ===")
table.insert(results, "Promenade exists: " .. tostring(prom ~= nil))
if prom then
    for _, shopName in ipairs({"Shop_Bakery", "Shop_Market", "Shop_Barber", "Shop_PetShop", "Shop_Restaurant", "FountainPool"}) do
        local m = prom:FindFirstChild(shopName)
        local pCount = 0
        if m then
            for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then pCount += 1 end end
        end
        table.insert(results, string.format("  [%s]: exists=%s, parts=%d", shopName, tostring(m ~= nil), pCount))
    end
end

-- Check Distances / Overlap Verification
table.insert(results, "\\n=== SPATIAL CLEARANCE & OVERLAP VERIFICATION ===")
local bPos = plot.BuildingOrigin
local upPad = plot.UpgradePad
local cgPad = plot.CargoPad
local unPad = plot.UnlockPad

local distBuildingToUpgrade = (bPos - upPad.Position).Magnitude
local distUpgradeToCargo = (upPad.Position - cgPad.Position).Magnitude
local distUpgradeToUnlock = (upPad.Position - unPad.Position).Magnitude
local distCargoToUnlock = (cgPad.Position - unPad.Position).Magnitude

table.insert(results, string.format("Building to Upgrade Pad Distance: %.1f studs (Clearance OK: %s)", distBuildingToUpgrade, tostring(distBuildingToUpgrade >= 15)))
table.insert(results, string.format("Upgrade Pad to Cargo Pad Distance: %.1f studs (Clearance OK: %s)", distUpgradeToCargo, tostring(distUpgradeToCargo >= 20)))
table.insert(results, string.format("Upgrade Pad to Unlock Pad Distance: %.1f studs (Clearance OK: %s)", distUpgradeToUnlock, tostring(distUpgradeToUnlock >= 20)))
table.insert(results, string.format("Cargo Pad to Unlock Pad Distance: %.1f studs (Clearance OK: %s)", distCargoToUnlock, tostring(distCargoToUnlock >= 12)))

-- Check BillboardGui Properties
local upGui = upPad:FindFirstChildOfClass("BillboardGui")
if upGui then
    table.insert(results, string.format("Upgrade Billboard AlwaysOnTop: %s, MaxDistance: %.0f", tostring(upGui.AlwaysOnTop), upGui.MaxDistance))
end

local cgGui = cgPad:FindFirstChildOfClass("BillboardGui")
if cgGui then
    table.insert(results, string.format("Cargo Billboard AlwaysOnTop: %s, MaxDistance: %.0f", tostring(cgGui.AlwaysOnTop), cgGui.MaxDistance))
end

return table.concat(results, "\\n")
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Server",
    "code": test_code
})
txt = res.get("content", [{}])[0].get("text", "")
print(txt)
