local _, SMSN = ...

local Helpers = {}

-- Returns the current player region slug.
function Helpers.Region()
    local map = { "us", "kr", "eu", "tw", "cn" }
    return map[GetCurrentRegion()] or "us"
end

-- Normalizes a realm name into a slug.
function Helpers.SlugRealm(realm)
    realm = (realm or ""):gsub("%s+", "-"):gsub("'", ""):gsub("[^%w%-]", "-")
    realm = realm:gsub("-+", "-"):gsub("^%-", ""):gsub("%-$", "")
    return realm:lower()
end

-- Returns unit name and realm with fallbacks.
function Helpers.UnitNameRealm(unit)
    local name, realm = UnitName(unit)
    if not name then
        return
    end
    realm = (realm and realm ~= "") and realm or GetRealmName()
    return name, realm
end

-- Trims whitespace and clamps string length.
function Helpers.Trim(text, limit)
    text = (text or ""):gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
    if limit and #text > limit then
        text = text:sub(1, limit)
    end
    return text
end

-- Builds inline icon texture markup.
function Helpers.InlineIcons(paths)
    if not paths or #paths == 0 then
        return ""
    end
    local out = {}
    local limit = math.min(#paths, SMSN.Constants.MAX_ICONS)
    for index = 1, limit do
        out[#out + 1] = ("|T%s:%d:%d|t"):format(paths[index], SMSN.Constants.LINE_SIZE, SMSN.Constants.LINE_SIZE)
    end
    return table.concat(out, " ")
end

-- Produces a stable cache key for player data.
function Helpers.Key(region, realm, name)
    return ("%s:%s:%s"):format(region, Helpers.SlugRealm(realm), (name or ""):lower())
end

-- Formats a whisper target string.
function Helpers.WTarget(name, realm)
    realm = (realm and realm ~= "") and realm or GetRealmName()
    return name .. "-" .. realm:gsub("%s+", "")
end

-- Escapes special characters for transmission.
function Helpers.Esc(text)
    text = tostring(text or "")
    return text:gsub("|", "¦"):gsub(";", "·"):gsub(",", "‚")
end

-- Restores special characters after transmission.
function Helpers.Unesc(text)
    text = tostring(text or "")
    return text:gsub("¦", "|"):gsub("·", ";"):gsub("‚", ",")
end

SMSN.Helpers = Helpers
