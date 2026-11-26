import json
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import anyio

async def main():
    server_params = StdioServerParameters(command="npx", args=["-y", "@roblox/assistant-cli@latest"])
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            res = await session.call_tool("list_open_studios", {})
            studios = json.loads(res.content[0].text)
            studio_id = studios[0]["studio_id"]
            code = """
            local Players = game:GetService("Players")
            local player = Players:GetPlayers()[1]
            local sss = game:GetService("ServerScriptService")
            local IslandManager = require(sss.Server.Services.IslandManager)
            local plot = IslandManager.GetPlot(player, 1)
            local wsPlot = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
            return game:GetService("HttpService"):JSONEncode({
                player = player.Name,
                hasPlot = plot ~= nil,
                hasWsPlot = wsPlot ~= nil,
                wsPlotChildren = wsPlot and #wsPlot:GetChildren() or 0,
                attributes = wsPlot and wsPlot:GetAttributes() or {}
            })
            """
            r = await session.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Server", "code": code})
            print(r.content[0].text)

anyio.run(main)
