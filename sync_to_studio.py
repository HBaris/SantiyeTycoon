import json
import os
import sys
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    base_dir = os.path.join(os.path.dirname(__file__), "ilk", "src")
    if not os.path.exists(base_dir):
        base_dir = os.path.join(os.path.dirname(__file__), "src")

    files_to_sync = [
        # Shared Modules
        {
            "path": os.path.join(base_dir, "shared", "NumberFormat.luau"),
            "parent": 'game:GetService("ReplicatedStorage"):WaitForChild("Shared")',
            "name": "NumberFormat",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "shared", "UpgradeConfig.luau"),
            "parent": 'game:GetService("ReplicatedStorage"):WaitForChild("Shared")',
            "name": "UpgradeConfig",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "shared", "ProjectTypeConfig.luau"),
            "parent": 'game:GetService("ReplicatedStorage"):WaitForChild("Shared")',
            "name": "ProjectTypeConfig",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "shared", "GameConfig.luau"),
            "parent": 'game:GetService("ReplicatedStorage"):WaitForChild("Shared")',
            "name": "GameConfig",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "shared", "Network.luau"),
            "parent": 'game:GetService("ReplicatedStorage"):WaitForChild("Shared")',
            "name": "Network",
            "class": "ModuleScript"
        },
        # Server Services
        {
            "path": os.path.join(base_dir, "server", "Services", "DataService.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")',
            "name": "DataService",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "UpgradeService.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")',
            "name": "UpgradeService",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "GarageService.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")',
            "name": "GarageService",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "IslandManager.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")',
            "name": "IslandManager",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "ConstructionService.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")',
            "name": "ConstructionService",
            "class": "ModuleScript"
        },
        # Client Scripts
        {
            "path": os.path.join(base_dir, "client", "BuilderToolController.client.luau"),
            "parent": 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client")',
            "name": "BuilderToolController",
            "class": "LocalScript"
        },
        {
            "path": os.path.join(base_dir, "client", "UpgradeUI.client.luau"),
            "parent": 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client")',
            "name": "UpgradeUI",
            "class": "LocalScript"
        },
        {
            "path": os.path.join(base_dir, "client", "ProjectSelectionUI.client.luau"),
            "parent": 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client")',
            "name": "ProjectSelectionUI",
            "class": "LocalScript"
        },
        {
            "path": os.path.join(base_dir, "client", "VehicleController.client.luau"),
            "parent": 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client")',
            "name": "VehicleController",
            "class": "LocalScript"
        },
        {
            "path": os.path.join(base_dir, "client", "WelcomeBackUI.client.luau"),
            "parent": 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client")',
            "name": "WelcomeBackUI",
            "class": "LocalScript"
        },
        {
            "path": os.path.join(base_dir, "client", "CraneRotator.client.luau"),
            "parent": 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client")',
            "name": "CraneRotator",
            "class": "LocalScript"
        },
    ]

    for item in files_to_sync:
        if not os.path.exists(item["path"]):
            print(f"ERROR: File not found: {item['path']}")
            continue

        with open(item["path"], "r", encoding="utf-8") as f:
            code_content = f.read()

        payload = json.dumps({"source": code_content})

        script_code = f"""
        local HttpService = game:GetService("HttpService")
        local raw = [====[{payload}]====]
        local data = HttpService:JSONDecode(raw)

        local parent = {item["parent"]}
        local target = parent:FindFirstChild("{item["name"]}")
        if not target then
            target = Instance.new("{item["class"]}")
            target.Name = "{item["name"]}"
            target.Parent = parent
        end

        target.Source = data.source
        return "SYNCED " .. target.Name .. " (" .. target.ClassName .. ", " .. #target.Source .. " bytes)"
        """

        res = client.call_tool("execute_luau", {
            "studio_id": studio_id,
            "datamodel_type": "Edit",
            "code": script_code
        })

        content = res.get("content", [{}])[0].get("text", "")
        print(f"[{item['name']}]: {content}")

    client.close()
    print("\n>>> All 16 scripts synchronized successfully to Roblox Studio! <<<")

if __name__ == "__main__":
    main()
