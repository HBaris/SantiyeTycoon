import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local rs = game:GetService("ReplicatedStorage")
    local assets = rs:FindFirstChild("Assets")
    if not assets then return "NO_ASSETS_FOLDER" end

    local catalog = {}
    for _, category in ipairs(assets:GetChildren()) do
        local catName = category.Name
        catalog[catName] = {}
        for _, item in ipairs(category:GetChildren()) do
            local bbCFrame, bbSize = nil, nil
            if item:IsA("Model") then
                _, bbSize = item:GetBoundingBox()
            end
            table.insert(catalog[catName], {
                name = item.Name,
                className = item.ClassName,
                size = bbSize and string.format("%.1f x %.1f x %.1f", bbSize.X, bbSize.Y, bbSize.Z) or "N/A"
            })
        end
    end

    local HttpService = game:GetService("HttpService")
    return HttpService:JSONEncode(catalog)
    """

    for dm in ["Edit", "Server"]:
        try:
            res = client.call_tool("execute_luau", {
                "studio_id": sid,
                "datamodel_type": dm,
                "code": code
            })
            raw = res.get("content", [{}])[0].get("text", "{}")
            if "not available" not in raw and "NO_ASSETS" not in raw:
                data = json.loads(raw)
                print(f"--- DataModel: {dm} ---")
                print(json.dumps(data, indent=2))
                break
            else:
                print(f"{dm} returned: {raw}")
        except Exception as e:
            print(f"Error on {dm}: {e}")

    client.close()

if __name__ == "__main__":
    main()
