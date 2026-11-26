from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local ramp = workspace.TycoonEnvironment:FindFirstChild("PlotEntranceRamp")
    if not ramp then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc.Name:find("Ramp") then
                return string.format("Found ramp: %s at %s, Size=%s", desc:GetFullName(), tostring(desc.Position), tostring(desc.Size))
            end
        end
        return "No ramp found"
    end
    return string.format("PlotEntranceRamp at %s, Size=%s, CFrame=%s", tostring(ramp.Position), tostring(ramp.Size), tostring(ramp.CFrame))
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": code
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
