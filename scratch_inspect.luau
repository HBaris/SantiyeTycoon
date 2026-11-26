local names = {}
for _, c in ipairs(workspace:GetChildren()) do
    table.insert(names, string.format("%s (%s)", c.Name, c.ClassName))
end
return table.concat(names, ", ")
