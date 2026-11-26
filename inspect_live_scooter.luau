local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local veh
for _, v in ipairs(workspace:GetChildren()) do
    if v.Name:find("Scooter") or v.Name:find("Vehicle") then
        veh = v
        break
    end
end
if not veh then return "No vehicle found in workspace" end

local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
if not seat then return "No VehicleSeat found" end

local root = veh.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover")
local stab = root:FindFirstChild("VehicleStabilizer")

local unanchoredParts = {}
local anchoredParts = {}
for _, d in ipairs(veh:GetDescendants()) do
    if d:IsA("BasePart") then
        if d.Anchored then
            table.insert(anchoredParts, d.Name)
        else
            table.insert(unanchoredParts, d.Name)
        end
    end
end

local info = {
    Name = veh.Name,
    PrimaryPart = root.Name,
    RootAnchored = root.Anchored,
    SeatOccupant = seat.Occupant and seat.Occupant.Parent.Name or "None",
    AnchoredCount = #anchoredParts,
    AnchoredList = table.concat(anchoredParts, ", "),
    UnanchoredCount = #unanchoredParts,
    MoverExists = tostring(mover ~= nil),
    MoverProps = mover and string.format("mode=%s, rel=%s, maxAxesForce=%s, vectorVel=%s",
        mover.VelocityConstraintMode.Name, mover.RelativeTo.Name, tostring(mover.MaxAxesForce), tostring(mover.VectorVelocity)) or "nil",
    StabExists = tostring(stab ~= nil),
    SeatAssemblyMass = seat.AssemblyMass,
    NetworkOwner = pcall(function() return root:GetNetworkOwner() and root:GetNetworkOwner().Name or "Server" end)
}

local lines = {}
for k, v in pairs(info) do
    table.insert(lines, k .. ": " .. tostring(v))
end
return table.concat(lines, "\n")
