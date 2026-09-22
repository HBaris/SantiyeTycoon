import sys
import json
import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Studio ID:", studio_id)

    # Stop play mode if active
    try:
        client.call_tool("start_stop_play", {"studio_id": studio_id, "is_start": False})
    except Exception:
        pass
    time.sleep(1.0)

    # Ensure folders exist
    create_folders = """
    local rs = game:GetService("ReplicatedStorage")
    local assets = rs:WaitForChild("Assets")
    local function ensure(name)
        local f = assets:FindFirstChild(name)
        if not f then
            f = Instance.new("Folder")
            f.Name = name
            f.Parent = assets
        end
        return f
    end
    ensure("Trees")
    ensure("Equipment")
    return "FOLDERS_READY"
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Edit",
        "code": create_folders
    })
    print("Folders:", res.get("content", [{}])[0].get("text", ""))

    targets = [
        {
            "name": "TowerCrane",
            "parent": "game.ReplicatedStorage.Assets.Equipment",
            "ids": ["3299391292", "188265652", "78788407881132"]
        },
        {
            "name": "PineTree",
            "parent": "game.ReplicatedStorage.Assets.Trees",
            "ids": ["5392132809", "73454171742334", "14886003734"]
        },
        {
            "name": "GardenTree",
            "parent": "game.ReplicatedStorage.Assets.Trees",
            "ids": ["9912487907", "6044524598", "431934303"]
        },
        {
            "name": "CypressTree",
            "parent": "game.ReplicatedStorage.Assets.Trees",
            "ids": ["10202741330", "16017719557"]
        },
        {
            "name": "BoulevardTree",
            "parent": "game.ReplicatedStorage.Assets.Trees",
            "ids": ["210245082", "431934303", "9912487907"]
        }
    ]

    for t in targets:
        name = t["name"]
        print(f"\nInserting {name}...")
        inserted = False
        for aid in t["ids"]:
            try:
                ires = client.call_tool("insert_asset", {
                    "studio_id": studio_id,
                    "assetId": aid,
                    "assetName": name,
                    "assetType": "Model",
                    "parentPath": t["parent"]
                })
                txt = ires.get("content", [{}])[0].get("text", "")
                data = json.loads(txt) if txt.startswith("{") else {}
                if data.get("status") == "success":
                    print(f"  -> SUCCESS! Inserted {name} (ID: {aid})")
                    inserted = True
                    break
                else:
                    print(f"  Failed ID {aid}: {data.get('message', txt)}")
            except Exception as e:
                print(f"  Error ID {aid}: {e}")
            time.sleep(0.4)
        if not inserted:
            print(f"  WARNING: Could not insert {name}")

    # Sanitize new assets
    sanitize_code = """
    local rs = game:GetService("ReplicatedStorage")
    local assets = rs:FindFirstChild("Assets")
    if not assets then return "NO_ASSETS" end

    local count = 0
    for _, folderName in ipairs({"Trees", "Equipment"}) do
        local folder = assets:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") then
                    count += 1
                    for _, desc in ipairs(model:GetDescendants()) do
                        if desc:IsA("Script") or desc:IsA("LocalScript") then
                            desc:Destroy()
                        elseif desc:IsA("BasePart") then
                            desc.Anchored = true
                        end
                    end
                    if not model.PrimaryPart then
                        local candidate = model:FindFirstChildWhichIsA("BasePart", true)
                        if candidate then
                            model.PrimaryPart = candidate
                        end
                    end
                end
            end
        end
    end
    return "SANITIZED_NEW_ASSETS_" .. count
    """
    sres = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Edit",
        "code": sanitize_code
    })
    print("\nSanitize result:", sres.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
