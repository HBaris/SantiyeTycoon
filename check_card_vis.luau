local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pgui = lp:FindFirstChild("PlayerGui")
local card = pgui and pgui.VehicleHUD:FindFirstChild("SpeedometerCard")
return "SpeedometerCard.Visible: " .. tostring(card and card.Visible)
