from roblox_mcp_client import RobloxStudioMCPClient
import json

c = RobloxStudioMCPClient()
c.msg_id += 1
c._send({'jsonrpc': '2.0', 'id': c.msg_id, 'method': 'tools/list'})
tools = c._read().get('result', {}).get('tools', [])
target_tools = [t for t in tools if t['name'] in ['search_asset', 'insert_asset']]
with open("asset_tools.json", "w", encoding="utf-8") as f:
    json.dump(target_tools, f, indent=2, ensure_ascii=False)
print("Saved asset_tools.json")
c.close()
