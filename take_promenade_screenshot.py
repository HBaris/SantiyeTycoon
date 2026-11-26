import base64
import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
sid = client.get_studio_id()

# Position camera facing the Promenade and Residents from the road
res = client.call_tool("screen_capture", {
    "studio_id": sid,
    "capture_id": "promenade_after_fix",
    "camera_position": [-18.0, 15.0, 52.0],
    "look_at_position": [-22.0, 7.0, 15.0]
})

if res.get("isError"):
    print("Capture error:", res)
else:
    for item in res.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("promenade_verified.png", "wb") as f:
                f.write(img_bytes)
            print(f"Captured promenade_verified.png ({len(img_bytes)} bytes)")
            break

client.close()
