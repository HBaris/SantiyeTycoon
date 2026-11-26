local RS = game:GetService("ReplicatedStorage")
local comm = RS.Assets.Commercial

-- 1. Replace Fountain with CleanFountain
local cleanFountain = RS:FindFirstChild("CleanFountain")
if cleanFountain then
    local oldF = comm:FindFirstChild("Fountain")
    if oldF then oldF:Destroy() end
    cleanFountain.Name = "Fountain"
    cleanFountain.Parent = comm
    print("Replaced Fountain with CleanFountain successfully!")
end

-- 2. Clean Restaurant
local rest = comm:FindFirstChild("Restaurant")
if rest then
    for _, d in ipairs(rest:GetDescendants()) do
        if d.Name == "realisticTree" or d.Name == "tree" then
            d:Destroy()
            print("Destroyed realisticTree in Restaurant")
        end
    end
end

-- 3. Sanitize all commercial models: Strip lights, particle emitters, beams, and blinding neons
local removedCounts = { lights = 0, emitters = 0, neonFixed = 0, scripts = 0 }
for _, shop in ipairs(comm:GetChildren()) do
    for _, desc in ipairs(shop:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
            desc:Destroy()
            removedCounts.scripts += 1
        elseif desc:IsA("Light") then
            desc:Destroy()
            removedCounts.lights += 1
        elseif desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Highlight") then
            desc:Destroy()
            removedCounts.emitters += 1
        elseif desc:IsA("BasePart") and desc.Material == Enum.Material.Neon then
            local c = desc.Color
            if (c.R + c.G + c.B) / 3 > 0.6 then
                desc.Material = Enum.Material.SmoothPlastic
                removedCounts.neonFixed += 1
            end
        end
    end
end

return string.format("Clean complete: %d lights stripped, %d emitters stripped, %d neons converted, %d scripts purged",
    removedCounts.lights, removedCounts.emitters, removedCounts.neonFixed, removedCounts.scripts)
