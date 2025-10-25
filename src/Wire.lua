local _, SMSN = ...

local Helpers = SMSN.Helpers

local Wire = {}

-- Builds a query payload for requesting note data.
function Wire.BuildQuery(region, realmSlug, name)
    return table.concat({ "Q", region, realmSlug, (name or ""):lower() }, ";")
end

-- Builds a data payload for sending note details.
function Wire.BuildData(region, realmSlug, name, text, icons, colorKey)
    return table.concat({
        "D",
        region,
        realmSlug,
        (name or ""):lower(),
        Helpers.Esc(text or ""),
        colorKey or "",
        table.concat(icons or {}, ","),
    }, ";")
end

-- Parses an incoming addon message payload.
function Wire.Parse(message)
    local parts = { strsplit(";", message) }
    local kind = parts[1]
    if kind == "Q" then
        return kind, parts[2], parts[3], parts[4]
    elseif kind == "D" then
        local text = Helpers.Unesc(parts[5] or "")
        local colorKey, iconsField
        if #parts >= 7 then
            colorKey = parts[6]
            iconsField = parts[7]
        else
            iconsField = parts[6]
        end
        local icons = {}
        if iconsField and iconsField ~= "" then
            for iconPath in iconsField:gmatch("[^,]+") do
                icons[#icons + 1] = iconPath
            end
        end
        return kind, parts[2], parts[3], parts[4], text, icons, colorKey
    end
end

SMSN.Wire = Wire
