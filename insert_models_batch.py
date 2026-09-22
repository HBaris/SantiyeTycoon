import json
import time
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()
print("Connected Studio ID:", studio_id)

models_to_insert = [
    # Buildings
    {
        "name": "Level_1",
        "parentPath": "game.ReplicatedStorage.Assets.Buildings",
        "assetIds": ["92421233555395", "130614349716078", "98871355824652"],
        "label": "Cabin (Lv 1)"
    },
    {
        "name": "Level_2",
        "parentPath": "game.ReplicatedStorage.Assets.Buildings",
        "assetIds": ["1797685225", "78503599337602", "8389654775"],
        "label": "Manor (Lv 2)"
    },
    {
        "name": "Level_3",
        "parentPath": "game.ReplicatedStorage.Assets.Buildings",
        "assetIds": ["83674957516929", "71681948929345", "97116892859700"],
        "label": "Villa (Lv 3)"
    },
    {
        "name": "Level_4",
        "parentPath": "game.ReplicatedStorage.Assets.Buildings",
        "assetIds": ["18888365209", "96820416260580", "132637099551657"],
        "label": "Residence (Lv 4)"
    },
    {
        "name": "Level_5",
        "parentPath": "game.ReplicatedStorage.Assets.Buildings",
        "assetIds": ["405471712", "135190175623292", "116725035836233"],
        "label": "Skyscraper (Lv 5)"
    },
    # Commercial
    {
        "name": "Bakery",
        "parentPath": "game.ReplicatedStorage.Assets.Commercial",
        "assetIds": ["107766264572744", "5147878186", "429308166"],
        "label": "Bakery Shop"
    },
    {
        "name": "Market",
        "parentPath": "game.ReplicatedStorage.Assets.Commercial",
        "assetIds": ["103746864835015", "84806605225840", "96672096934960"],
        "label": "Supermarket"
    },
]

for item in models_to_insert:
    inserted = False
    for aid in item["assetIds"]:
        print(f"Trying to insert {item['label']} (ID: {aid})...")
        try:
            res = client.call_tool("insert_asset", {
                "studio_id": studio_id,
                "assetId": aid,
                "assetName": item["name"],
                "assetType": "Model",
                "parentPath": item["parentPath"]
            })
            txt = res.get("content", [{}])[0].get("text", "")
            data = json.loads(txt) if txt.startswith("{") else {}
            if data.get("status") == "success":
                print(f"  -> SUCCESS! Inserted {item['name']} (ID: {aid})")
                inserted = True
                break
            else:
                print(f"  -> Failed with ID {aid}: {data.get('error', 'unknown error')}")
        except Exception as e:
            print(f"  -> Exception with ID {aid}: {e}")
        time.sleep(0.5)

    if not inserted:
        print(f"WARNING: Could not insert ready model for {item['label']}. Procedural fallback will be used.")

# Post-processing in Studio: Sanitize, anchor, and set PrimaryParts for inserted models
sanitize_code = """
local rs = game:GetService("ReplicatedStorage")
local assets = rs:FindFirstChild("Assets")
if not assets then return "NO_ASSETS_FOLDER" end

local count = 0
for _, folder in ipairs(assets:GetChildren()) do
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            count += 1
            -- Remove any embedded scripts for safety
            for _, desc in ipairs(model:GetDescendants()) do
                if desc:IsA("Script") or desc:IsA("LocalScript") then
                    desc:Destroy()
                elseif desc:IsA("BasePart") then
                    desc.Anchored = true
                end
            end
            -- Ensure PrimaryPart
            if not model.PrimaryPart then
                local candidate = model:FindFirstChildWhichIsA("BasePart", true)
                if candidate then
                    model.PrimaryPart = candidate
                end
            end
        end
    end
end
return "SANITIZED_" .. count .. "_MODELS"
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Edit",
    "code": sanitize_code
})
print("\nSanitize result:", res.get("content", [{}])[0].get("text", ""))
