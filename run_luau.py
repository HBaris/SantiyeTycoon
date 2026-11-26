import sys
from roblox_mcp_client import RobloxStudioMCPClient

def run(code, datamodel="Edit"):
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()
    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": datamodel,
        "code": code
    })
    client.close()
    if res.get("isError"):
        print("ERROR:", res)
    else:
        for item in res.get("content", []):
            print(item.get("text", ""))

if __name__ == "__main__":
    if len(sys.argv) > 1:
        with open(sys.argv[1], "r", encoding="utf-8") as f:
            code = f.read()
        dm = sys.argv[2] if len(sys.argv) > 2 else "Edit"
        run(code, dm)
