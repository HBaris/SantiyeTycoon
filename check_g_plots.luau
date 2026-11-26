local res = {}
table.insert(res, "_G.PlayerPlots: " .. tostring(_G.PlayerPlots ~= nil))
if _G.PlayerPlots then
    for k, v in pairs(_G.PlayerPlots) do
        table.insert(res, string.format("  Key: %s (type: %s) -> plots count: %d", tostring(k), typeof(k), #v))
    end
end
return table.concat(res, "\n")
