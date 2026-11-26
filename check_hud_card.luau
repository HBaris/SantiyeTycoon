local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pgui = lp:FindFirstChild("PlayerGui")
local vHud = pgui and pgui:FindFirstChild("VehicleHUD")
local hudCard = vHud and vHud:FindFirstChild("Card")

local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seatPart = hum and hum.SeatPart

return string.format("hum.Sit: %s, SeatPart: %s, HUD Card Visible: %s, HUD Card Pos: %s",
    tostring(hum and hum.Sit),
    seatPart and seatPart.Name or "nil",
    tostring(hudCard and hudCard.Visible),
    hudCard and tostring(hudCard.Position) or "nil"
)
