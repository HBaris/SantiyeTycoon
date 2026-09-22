from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()

for dm in ["Server", "Client"]:
    code = """
    local LogService = game:GetService("LogService")
    local logs = LogService:GetLogHistory()
    local out = {}
    for i = math.max(1, #logs - 50), #logs do
        local entry = logs[i]
        table.insert(out, "[" .. entry.messageType.Name .. "] " .. entry.message)
    end
    return table.concat(out, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": dm,
        "code": code
    })

    text = res.get("content", [{}])[0].get("text", "")
    print(f"=== {dm} LOGS ===")
    print(text.encode("ascii", "replace").decode("ascii"))
