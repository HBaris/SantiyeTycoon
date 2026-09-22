import os
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    if not studio_id:
        print("No studio connected.")
        return

    script_code = """
    local results = {}
    local function test(inst)
        if inst:IsA("LuaSourceContainer") then
            local fn, err = loadstring(inst.Source)
            if not fn then
                table.insert(results, "[ERROR] " .. inst.Name .. ": " .. tostring(err))
            else
                table.insert(results, "[OK] " .. inst.Name .. " (" .. inst.ClassName .. ")")
            end
        end
    end

    local sharedFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
    if sharedFolder then
        for _, s in ipairs(sharedFolder:GetChildren()) do test(s) end
    end

    local serverServices = game:GetService("ServerScriptService"):FindFirstChild("Server")
    if serverServices and serverServices:FindFirstChild("Services") then
        for _, s in ipairs(serverServices.Services:GetChildren()) do test(s) end
    end

    local clientFolder = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
    if clientFolder and clientFolder:FindFirstChild("Client") then
        for _, s in ipairs(clientFolder.Client:GetChildren()) do test(s) end
    end

    return table.concat(results, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Edit",
        "code": script_code
    })

    print(res.get("content", [{}])[0].get("text", ""))

if __name__ == "__main__":
    main()
