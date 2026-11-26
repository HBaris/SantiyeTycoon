local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart
local isSeatVehicle = seat and seat:IsA("VehicleSeat")

local root = seat and seat.Parent and (seat.Parent.PrimaryPart or seat)
local mover = root and root:FindFirstChild("VehicleMover")
local stab = root and root:FindFirstChild("VehicleStabilizer")

return string.format("LocalPlayer: %s, Seated: %s, SeatPart: %s, IsVehicleSeat: %s, MoverFound: %s, StabFound: %s",
    lp.Name,
    tostring(hum and hum.Sit),
    seat and seat.Name or "nil",
    tostring(isSeatVehicle),
    tostring(mover ~= nil),
    tostring(stab ~= nil)
)
