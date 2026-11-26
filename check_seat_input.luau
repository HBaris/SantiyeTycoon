local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart :: VehicleSeat?
if not seat then return "No seat" end

local UIS = game:GetService("UserInputService")
local isWDown = UIS:IsKeyDown(Enum.KeyCode.W)
local isADown = UIS:IsKeyDown(Enum.KeyCode.A)
local isSDown = UIS:IsKeyDown(Enum.KeyCode.S)
local isDDown = UIS:IsKeyDown(Enum.KeyCode.D)

return string.format("Seat Occupant: %s, ThrottleFloat: %s, SteerFloat: %s, Keys: W=%s, A=%s, S=%s, D=%s",
    seat.Occupant and seat.Occupant.Parent.Name or "nil",
    tostring(seat.ThrottleFloat),
    tostring(seat.SteerFloat),
    tostring(isWDown), tostring(isADown), tostring(isSDown), tostring(isDDown))
