import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()

scale_test = """
local rs = game:GetService("ReplicatedStorage")
local assets = rs:FindFirstChild("Assets")
if not assets then return "NO_ASSETS" end

local sky = assets.Buildings:FindFirstChild("Level_5")
if not sky then return "NO_SKY" end

local clone = sky:Clone()
local cf, size = clone:GetBoundingBox()
local maxHoriz = math.max(size.X, size.Z)
local targetMax = 32
local scaleFactor = targetMax / maxHoriz

clone:ScaleTo(scaleFactor)
local ncf, nsize = clone:GetBoundingBox()
clone:Destroy()

return string.format("Original: (%.1f, %.1f, %.1f) -> Scaled: (%.1f, %.1f, %.1f)", size.X, size.Y, size.Z, nsize.X, nsize.Y, nsize.Z)
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Edit",
    "code": scale_test
})
txt = res.get("content", [{}])[0].get("text", "")
print("ScaleTo Test:", txt)
