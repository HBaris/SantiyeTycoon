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
                table.insert(results, "[OK] " .. inst.Name .. " (" .. inst.ClassName .. ", " .. #inst.Source .. " bytes)")
            end
        elseif inst:IsA("Folder") then
            for _, child in ipairs(inst:GetChildren()) do
                test(child)
            end
        end
    end

    local sharedFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
    if sharedFolder then
        test(sharedFolder)
    end

    local serverServices = game:GetService("ServerScriptService"):FindFirstChild("Server")
    if serverServices and serverServices:FindFirstChild("Services") then
        test(serverServices.Services)
    end

    local clientFolder = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
    if clientFolder and clientFolder:FindFirstChild("Client") then
        test(clientFolder.Client)
    end

    return table.concat(results, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Edit",
        "code": script_code
    })

    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
