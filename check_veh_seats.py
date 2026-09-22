import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()

code = """
local rs = game:GetService("ReplicatedStorage")
local assets = rs:FindFirstChild("Assets")
if not assets then return "NO_ASSETS" end
local veh = assets:FindFirstChild("Vehicles")
if not veh then return "NO_VEHICLES" end

local results = {}
for _, v in ipairs(veh:GetChildren()) do
    local seat = v:FindFirstChildWhichIsA("VehicleSeat", true) or v:FindFirstChildWhichIsA("Seat", true)
    table.insert(results, v.Name .. " seat: " .. tostring(seat and seat.ClassName or "none"))
end
return table.concat(results, "\\n")
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Edit",
    "code": code
})
print(res.get("content", [{}])[0].get("text", ""))
