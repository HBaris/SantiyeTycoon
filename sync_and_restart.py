import time
from roblox_mcp_client import RobloxStudioMCPClient
import sync_to_studio

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Found Studio:", studio_id)

    # 1. Stop play if running
    print("Stopping play mode if active...")
    try:
        res = client.call_tool("start_stop_play", {
            "studio_id": studio_id,
            "is_start": False
        })
        print("Stop play response:", res)
    except Exception as e:
        print("Error stopping play:", e)

    time.sleep(1.5)
    client.close()

    # 2. Sync all scripts to Studio in Edit datamodel
    print("\n--- Synchronizing scripts to Studio ---")
    sync_to_studio.main()

    # 2.5 Ensure assets in Edit mode are clean
    print("\n--- Ensuring assets are clean in Edit datamodel ---")
    client_edit = RobloxStudioMCPClient()
    studio_id = client_edit.get_studio_id()
    clean_assets_luau = """
    local rs = game:GetService("ReplicatedStorage")
    local assets = rs:FindFirstChild("Assets")
    if not assets then return "NO_ASSETS" end

    -- Fix BoulevardTree in Trees folder
    local trees = assets:FindFirstChild("Trees")
    if trees then
        local garden = trees:FindFirstChild("GardenTree")
        local bTree = trees:FindFirstChild("BoulevardTree")
        if garden and bTree then
            -- Check if bTree contains rock cliff / trusses
            local hasRock = false
            for _, d in ipairs(bTree:GetDescendants()) do
                if d:IsA("TrussPart") or d.Name:find("Brick") then
                    hasRock = true
                    break
                end
            end
            if hasRock then
                bTree:Destroy()
                local newB = Instance.new("Model")
                newB.Name = "BoulevardTree"
                local clonedMesh = garden:Clone()
                clonedMesh.Name = "TreeMesh"
                clonedMesh.Parent = newB
                newB.Parent = trees
                print("Replaced ugly rock-cliff BoulevardTree with GardenTree mesh in Edit mode!")
            end
        end
    end

    -- Clean commercial models
    local comm = assets:FindFirstChild("Commercial")
    if comm then
        local rest = comm:FindFirstChild("Restaurant")
        if rest then
            for _, d in ipairs(rest:GetDescendants()) do
                if d.Name == "realisticTree" or d.Name == "tree" then
                    d:Destroy()
                end
            end
        end
    end
    return "ASSETS_CLEANED_EDIT"
    """
    try:
        c_res = client_edit.call_tool("execute_luau", {
            "studio_id": studio_id,
            "datamodel_type": "Edit",
            "code": clean_assets_luau
        })
        print("Edit asset cleanup:", c_res.get("content", [{}])[0].get("text", ""))
    except Exception as e:
        print("Edit asset cleanup error:", e)
    client_edit.close()
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("\nStarting play mode...")
    res = client.call_tool("start_stop_play", {
        "studio_id": studio_id,
        "is_start": True
    })
    print("Start play response:", res)
    client.close()

    print("\n--- Done! ---")

if __name__ == "__main__":
    main()
