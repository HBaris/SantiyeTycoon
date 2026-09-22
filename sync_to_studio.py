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

    # Ensure Island folder exists under ServerScriptService.Server.Services
    ensure_folders_code = """
    local sss = game:GetService("ServerScriptService")
    local server = sss:WaitForChild("Server")
    local services = server:WaitForChild("Services")
    local islandFolder = services:FindFirstChild("Island")
    if not islandFolder then
        islandFolder = Instance.new("Folder")
        islandFolder.Name = "Island"
        islandFolder.Parent = services
    end
    return "ENSURED_ISLAND_FOLDER"
    """
    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Edit",
        "code": ensure_folders_code
    })
    print("Folder check:", res.get("content", [{}])[0].get("text", ""))

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
            "path": os.path.join(base_dir, "shared", "AssetNormalizer.luau"),
            "parent": 'game:GetService("ReplicatedStorage"):WaitForChild("Shared")',
            "name": "AssetNormalizer",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "shared", "ZoneConfig.luau"),
            "parent": 'game:GetService("ReplicatedStorage"):WaitForChild("Shared")',
            "name": "ZoneConfig",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "shared", "Network.luau"),
            "parent": 'game:GetService("ReplicatedStorage"):WaitForChild("Shared")',
            "name": "Network",
            "class": "ModuleScript"
        },
        # Server Services - Island Submodules
        {
            "path": os.path.join(base_dir, "server", "Services", "Island", "PlotDataTypes.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services"):WaitForChild("Island")',
            "name": "PlotDataTypes",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "Island", "IslandEnvironment.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services"):WaitForChild("Island")',
            "name": "IslandEnvironment",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "Island", "CommercialBuilder.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services"):WaitForChild("Island")',
            "name": "CommercialBuilder",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "Island", "BuildingBuilder.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services"):WaitForChild("Island")',
            "name": "BuildingBuilder",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "Island", "SiteEquipmentBuilder.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services"):WaitForChild("Island")',
            "name": "SiteEquipmentBuilder",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "Island", "CityLifeService.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services"):WaitForChild("Island")',
            "name": "CityLifeService",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "Island", "ParcelLandscape.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services"):WaitForChild("Island")',
            "name": "ParcelLandscape",
            "class": "ModuleScript"
        },
        # Server Services - Core
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
            "path": os.path.join(base_dir, "server", "Services", "ServiceBuildingManager.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")',
            "name": "ServiceBuildingManager",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "CityManager.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")',
            "name": "CityManager",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "Services", "ConstructionService.luau"),
            "parent": 'game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")',
            "name": "ConstructionService",
            "class": "ModuleScript"
        },
        {
            "path": os.path.join(base_dir, "server", "init.server.luau"),
            "parent": 'game:GetService("ServerScriptService")',
            "name": "Server",
            "class": "Script"
        },
        # Client Scripts
        {
            "path": os.path.join(base_dir, "client", "CityStatsUI.client.luau"),
            "parent": 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client")',
            "name": "CityStatsUI",
            "class": "LocalScript"
        },
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
        {
            "path": os.path.join(base_dir, "client", "GarageUI.client.luau"),
            "parent": 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client")',
            "name": "GarageUI",
            "class": "LocalScript"
        },
    ]

    synced_count = 0
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
        synced_count += 1

    client.close()
    print(f"\n>>> All {synced_count} scripts synchronized successfully to Roblox Studio! <<<")

if __name__ == "__main__":
    main()
