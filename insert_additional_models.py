import json
import time
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()

additional_models = [
    {
        "name": "Barber",
        "parentPath": "game.ReplicatedStorage.Assets.Commercial",
        "query": "barber shop building",
        "fallbackIds": ["115715918738367", "11652194389"]
    },
    {
        "name": "PetShop",
        "parentPath": "game.ReplicatedStorage.Assets.Commercial",
        "query": "pet shop store",
        "fallbackIds": ["7488349258", "13768725893"]
    },
    {
        "name": "Restaurant",
        "parentPath": "game.ReplicatedStorage.Assets.Commercial",
        "query": "outdoor cafe restaurant",
        "fallbackIds": ["3679516723", "9875150824"]
    },
    {
        "name": "Fountain",
        "parentPath": "game.ReplicatedStorage.Assets.Commercial",
        "query": "fountain park modern",
        "fallbackIds": ["70756050848972", "13182847753"]
    },
    {
        "name": "Scooter",
        "parentPath": "game.ReplicatedStorage.Assets.Vehicles",
        "query": "electric scooter vehicle",
        "fallbackIds": ["86935464252082", "74687562575022"]
    },
    {
        "name": "Pickup",
        "parentPath": "game.ReplicatedStorage.Assets.Vehicles",
        "query": "pickup truck vehicle drivable",
        "fallbackIds": ["110548350447464", "99074386"]
    }
]

for item in additional_models:
    print(f"\nSearching for {item['name']}...")
    res = client.call_tool("search_asset", {
        "studio_id": studio_id,
        "query": item["query"],
        "assetType": "Model",
        "scope": "creator_store",
        "priceFilter": "free",
        "maxResults": 3
    })
    txt = res.get("content", [{}])[0].get("text", "")
    data = json.loads(txt) if txt.startswith("{") else {}
    results = data.get("results", [])
    candidate_ids = [r["assetId"] for r in results] + item["fallbackIds"]

    inserted = False
    for aid in candidate_ids:
        print(f"  Attempting insert ID: {aid}...")
        try:
            ires = client.call_tool("insert_asset", {
                "studio_id": studio_id,
                "assetId": aid,
                "assetName": item["name"],
                "assetType": "Model",
                "parentPath": item["parentPath"]
            })
            itxt = ires.get("content", [{}])[0].get("text", "")
            idata = json.loads(itxt) if itxt.startswith("{") else {}
            if idata.get("status") == "success":
                print(f"  -> SUCCESS! Inserted {item['name']} (ID: {aid})")
                inserted = True
                break
        except Exception as e:
            pass
        time.sleep(0.4)

# Sanitize all assets
sanitize_code = """
local rs = game:GetService("ReplicatedStorage")
local assets = rs:FindFirstChild("Assets")
if not assets then return "NO_ASSETS" end

local count = 0
for _, folder in ipairs(assets:GetChildren()) do
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
return "TOTAL_SANITIZED_" .. count
"""
res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Edit",
    "code": sanitize_code
})
print("\nFinal sanitize:", res.get("content", [{}])[0].get("text", ""))
