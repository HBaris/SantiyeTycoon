import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local GarageService = require(game:GetService("ServerScriptService").Server.Services.GarageService)
    local cargoBefore = GarageService.GetCargo(p)

    -- Deliver cargo
    local delivered = GarageService.DeliverCargo(p, 1)
    local cargoAfter = GarageService.GetCargo(p)
    local isBoost = GarageService.IsCargoBoostActive(p, 1)

    return string.format("Deliver Cargo: Success=%s, Before=%d, After=%d, TurboActive=%s",
        tostring(delivered), cargoBefore, cargoAfter, tostring(isBoost))
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
