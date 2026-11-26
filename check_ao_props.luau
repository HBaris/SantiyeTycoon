local ao = Instance.new("AlignOrientation")
local props = {
    Mode = ao.Mode.Name,
    AlignType = pcall(function() return ao.AlignType.Name end) and ao.AlignType.Name or "No AlignType",
    PrimaryAxisOnly = pcall(function() return ao.PrimaryAxisOnly end) and tostring(ao.PrimaryAxisOnly) or "No PrimaryAxisOnly",
}
return string.format("AlignType: %s, PrimaryAxisOnly: %s", props.AlignType, props.PrimaryAxisOnly)
