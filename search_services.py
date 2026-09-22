import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()

searches = [
    ("StreetLamp", "street lamp"),
    ("Bench", "park bench"),
    ("Planter", "flower planter"),
    ("FireStation", "fire station"),
    ("Clinic", "clinic"),
    ("Park", "gazebo park")
]

for cat, q in searches:
    res = client.call_tool("search_asset", {
        "studio_id": studio_id,
        "query": q,
        "assetType": "Model",
        "scope": "creator_store",
        "priceFilter": "free",
        "maxResults": 4
    })
    txt = res.get("content", [{}])[0].get("text", "")
    try:
        data = json.loads(txt)
        print(f"\n=== {cat} ===")
        for r in data.get("results", []):
            name = r["name"].encode("ascii", "replace").decode("ascii")
            creator = r.get("creatorName", "").encode("ascii", "replace").decode("ascii")
            print(f"  ID: {r['assetId']} | {name} (by {creator})")
    except Exception as e:
        print(f"Error {cat}: {e}")

client.close()
