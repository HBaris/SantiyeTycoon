local Players = game:GetService("Players")
local p = Players.LocalPlayer
local pg = p:FindFirstChild("PlayerGui")
if not pg then return "No PlayerGui" end

local guis = {}
for _, g in ipairs(pg:GetChildren()) do
    if g:IsA("ScreenGui") and g.Enabled then
        for _, f in ipairs(g:GetDescendants()) do
            if f:IsA("Frame") and f.Visible and f.BackgroundTransparency < 0.5 then
                local absSize = f.AbsoluteSize
                if absSize.X > 500 and absSize.Y > 400 then
                    table.insert(guis, string.format("BIG FRAME: %s in %s (size: %dx%d, color: %s, bgTrans: %.2f)",
                        f:GetFullName(), g.Name, absSize.X, absSize.Y, tostring(f.BackgroundColor3), f.BackgroundTransparency))
                end
            end
        end
    end
end
return table.concat(guis, "\n")
