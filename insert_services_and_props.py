import json
import time
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()
print("Connected to Studio ID:", studio_id)

# 1. Setup Services and Props folders in ReplicatedStorage.Assets
setup_folders_code = """
local RS = game:GetService("ReplicatedStorage")
local assets = RS:FindFirstChild("Assets")
if not assets then
    assets = Instance.new("Folder")
    assets.Name = "Assets"
    assets.Parent = RS
end

local function ensureFolder(parent, name)
    local f = parent:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f
end

ensureFolder(assets, "Props")
ensureFolder(assets, "Services")
return "FOLDERS_READY"
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Edit",
    "code": setup_folders_code
})
print("Setup folders result:", res.get("content", [{}])[0].get("text", ""))

# 2. Assets to download and their target paths
items = [
    # Props
    ("StreetLamp", 15472204631, "Props"),
    ("Bench", 393609716, "Props"),
    ("Planter", 127089648993053, "Props"),
    # Services
    ("FireStation", 5234408406, "Services"),
    ("Clinic", 71824035331091, "Services"),
    ("Park", 18420032855, "Services"),
]

for name, asset_id, target_subfolder in items:
    print(f"\n--- Inserting {name} (Asset ID: {asset_id}) into Assets.{target_subfolder} ---")
    insert_res = client.call_tool("insert_asset", {
        "studio_id": studio_id,
        "assetId": asset_id,
        "targetParent": "Workspace"
    })
    print("Insert response:", insert_res)
    time.sleep(1.0)

    # Sanitize and move to target folder
    organize_code = f"""
    local RS = game:GetService("ReplicatedStorage")
    local assets = RS:WaitForChild("Assets")
    local folder = assets:WaitForChild("{target_subfolder}")

    -- Remove any old copy
    local old = folder:FindFirstChild("{name}")
    if old then old:Destroy() end

    -- Find the newly inserted model in Workspace
    local candidate = nil
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart") then
            if child.Name ~= "Camera" and child.Name ~= "Terrain" and not child:FindFirstChild("Humanoid") and not child.Name:match("^Plot_") and child.Name ~= "Baseplate" and child.Name ~= "IslandProjects" then
                candidate = child
                break
            end
        end
    end

    if not candidate then
        -- Fallback: search for any new model inserted
        return "CANDIDATE_NOT_FOUND"
    end

    -- If candidate is a Folder or BasePart, wrap in Model
    local targetModel
    if candidate:IsA("Model") then
        targetModel = candidate
    else
        targetModel = Instance.new("Model")
        candidate.Parent = targetModel
    end
    targetModel.Name = "{name}"

    -- Strip scripts for security
    local removedScripts = 0
    for _, desc in ipairs(targetModel:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
            desc:Destroy()
            removedScripts = removedScripts + 1
        elseif desc:IsA("BasePart") then
            desc.Anchored = true
        end
    end

    -- Set PrimaryPart if missing
    if not targetModel.PrimaryPart then
        targetModel.PrimaryPart = targetModel:FindFirstChildWhichIsA("BasePart", true)
    end

    targetModel.Parent = folder
    local _, size = targetModel:GetBoundingBox()
    return string.format("ORGANIZED: %s -> Assets.%s (Parts: %d, Removed Scripts: %d, Size: %.1f, %.1f, %.1f)", targetModel.Name, "{target_subfolder}", #targetModel:GetDescendants(), removedScripts, size.X, size.Y, size.Z)
    """

    org_res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Edit",
        "code": organize_code
    })
    print(org_res.get("content", [{}])[0].get("text", ""))

client.close()
print("\nDone inserting and sanitizing Props and Services!")
