import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()

searches = [
    ("Cabin (Lv1)", "wooden cabin house"),
    ("Manor (Lv2)", "brick house modern"),
    ("Villa (Lv3)", "modern luxury villa"),
    ("Residence (Lv4)", "modern apartment building"),
    ("Skyscraper (Lv5)", "modern skyscraper building"),
    ("Scooter", "electric scooter vehicle"),
    ("Pickup", "pickup truck drivable"),
    ("Bakery", "bakery shop building"),
    ("Supermarket", "grocery store supermarket"),
    ("Fountain", "modern park fountain"),
]

for cat, q in searches:
    res = client.call_tool("search_asset", {
        "studio_id": studio_id,
        "query": q,
        "assetType": "Model",
        "scope": "creator_store",
        "priceFilter": "free",
        "maxResults": 3
    })
    txt = res.get("content", [{}])[0].get("text", "")
    try:
        data = json.loads(txt)
        results = data.get("results", [])
        print(f"\n=== {cat} ===")
        for r in results:
            name = r['name'].encode('ascii', 'replace').decode('ascii')
            creator = r.get('creatorName', '').encode('ascii', 'replace').decode('ascii')
            print(f"  ID: {r['assetId']} | {name} (by {creator})")
    except Exception as e:
        print(f"Error {cat}: {e}")
