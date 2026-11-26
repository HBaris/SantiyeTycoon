import sys
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
sid = client.get_studio_id()
res = client.call_tool("get_console_output", {"studio_id": sid})
txt = res.get("content", [{}])[0].get("text", "")
with open("console_output.txt", "w", encoding="utf-8") as f:
    f.write(txt)
client.close()

# Print last 20 lines cleanly
lines = txt.splitlines()
for line in lines[-25:]:
    try:
        print(line.encode("ascii", errors="replace").decode("ascii"))
    except Exception:
        pass
