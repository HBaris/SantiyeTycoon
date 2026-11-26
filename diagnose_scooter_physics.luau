local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart
if not seat then return "No seat" end
local model = seat.Parent

local out = {}
table.insert(out, "Model: " .. model.Name)

for _, d in ipairs(model:GetDescendants()) do
    if d:IsA("BasePart") then
        table.insert(out, string.format("Part '%s': Anchored=%s, CanCollide=%s, Mass=%.1f, AssemblyRoot=%s",
            d.Name, tostring(d.Anchored), tostring(d.CanCollide), d.Mass,
            d.AssemblyRootPart and d.AssemblyRootPart.Name or "nil"))
    elseif d:IsA("WeldConstraint") then
        table.insert(out, string.format("Weld: Part0='%s', Part1='%s', Enabled=%s",
            d.Part0 and d.Part0.Name or "nil",
            d.Part1 and d.Part1.Name or "nil",
            tostring(d.Enabled)))
    elseif d:IsA("Constraint") then
        table.insert(out, string.format("Constraint '%s' (%s): Enabled=%s",
            d.Name, d.ClassName, tostring(d.Enabled)))
    end
end

-- Check character parts welded to anything
for _, d in ipairs(char:GetDescendants()) do
    if d:IsA("WeldConstraint") or d:IsA("Weld") or d:IsA("Motor6D") then
        local p0 = d.Part0 and d.Part0.Name or "nil"
        local p1 = d.Part1 and d.Part1.Name or "nil"
        if p0 == "Seat" or p1 == "Seat" then
            table.insert(out, string.format("Char Weld to Seat: %s (%s, Part0=%s, Part1=%s)", d.Name, d.ClassName, p0, p1))
        end
    end
end

return table.concat(out, "\n")
