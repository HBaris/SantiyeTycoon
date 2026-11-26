local Players = game:GetService("Players")
local p = Players.LocalPlayer
local char = p.Character
if not char then return "No Character" end
local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return "No HRP" end
return string.format("HRP pos: %s, parent: %s", tostring(hrp.Position), char.Parent and char.Parent.Name or "nil")
