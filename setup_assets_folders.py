from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()
print("Studio ID:", studio_id)

# 1. Ensure Studio is in Edit mode
print("Stopping play mode to edit...")
client.call_tool("start_stop_play", {"studio_id": studio_id, "is_start": False})

# 2. Setup Assets folder structure under ReplicatedStorage
setup_code = """
local rs = game:GetService("ReplicatedStorage")

local assets = rs:FindFirstChild("Assets")
if not assets then
    assets = Instance.new("Folder")
    assets.Name = "Assets"
    assets.Parent = rs
end

local categories = {"Buildings", "Commercial", "Vehicles", "Props"}
for _, cat in ipairs(categories) do
    local f = assets:FindFirstChild(cat)
    if not f then
        f = Instance.new("Folder")
        f.Name = cat
        f.Parent = assets
    end
end

-- Also cleanup old Test folder if any
local test = assets:FindFirstChild("Test")
if test then test:Destroy() end

return "ASSET_FOLDERS_READY"
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Edit",
    "code": setup_code
})
print("Result:", res.get("content", [{}])[0].get("text", ""))
