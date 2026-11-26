local Players = game:GetService("Players")
local p = Players.LocalPlayer
local pg = p:FindFirstChild("PlayerGui")
if not pg then return "No pg" end
local ps = pg:FindFirstChild("ProjectSelectionUI")
if ps then
    local main = ps:FindFirstChild("MainFrame")
    if main then main.Visible = false end
    return "Closed project selection modal"
end
return "No ProjectSelectionUI"
