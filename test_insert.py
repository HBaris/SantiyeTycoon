import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()
print("Studio ID:", studio_id)

# 1. Stop play mode to return to Edit mode
print("Stopping play mode...")
res = client.call_tool("start_stop_play", {"studio_id": studio_id, "is_start": False})
print("Stop res:", res)

# 2. Ensure ReplicatedStorage.Assets exists in Edit mode
ensure_code = """
local rs = game:GetService("ReplicatedStorage")
local assets = rs:FindFirstChild("Assets")
if not assets then
    assets = Instance.new("Folder")
    assets.Name = "Assets"
    assets.Parent = rs
end
local testFolder = assets:FindFirstChild("Test")
if not testFolder then
    testFolder = Instance.new("Folder")
    testFolder.Name = "Test"
    testFolder.Parent = assets
end
return "ENSURED_ASSETS_FOLDER"
"""
res = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Edit", "code": ensure_code})
print("Ensure res:", res)

# 3. Test insert_asset
# Asset 405471712: "Modern Skyscraper" (Free Model by camcool12354)
print("Testing insert_asset...")
res = client.call_tool("insert_asset", {
    "studio_id": studio_id,
    "assetId": "405471712",
    "assetName": "SkyscraperModel",
    "assetType": "Model",
    "parentPath": "game.ReplicatedStorage.Assets.Test"
})
print("Insert res:", json.dumps(res, indent=2))
