local _, SMSN = ...

local Constants = SMSN.Constants
local Helpers = SMSN.Helpers
local Wire = SMSN.Wire

local lastReplyAtBySender = {}

-- Handles sending note data back to a requesting player.
local function handleQuery(sender)
    local now = GetTime()
    local last = lastReplyAtBySender[sender] or 0
    if now - last < Constants.REPLY_COOLDOWN then
        return
    end
    lastReplyAtBySender[sender] = now
    local payload = Wire.BuildData(
        Helpers.Region(),
        Helpers.SlugRealm(GetRealmName()),
        UnitName("player"),
        Helpers.Trim(SMSN.db.text or "", Constants.MAX_TEXT),
        SMSN.db.icons or {},
        SMSN.db.color or "WHITE"
    )
    C_ChatInfo.SendAddonMessage(Constants.PREFIX, payload, "WHISPER", sender)
end

-- Stores note data received from another player.
local function handleData(region, realmSlug, name, text, icons, colorKey)
    if not (region and realmSlug and name) then
        return
    end
    local key = ("%s:%s:%s"):format(region, realmSlug, name:lower())
    SMSN.live[key] = {
        t = text or "",
        i = icons or {},
        c = colorKey,
        ts = GetTime(),
    }
    if UnitExists("mouseover") then
        local hoverName, hoverRealm = Helpers.UnitNameRealm("mouseover")
        if hoverName and hoverRealm and hoverName:lower() == name:lower() and Helpers.SlugRealm(hoverRealm) == realmSlug then
            GameTooltip:SetUnit("mouseover")
        end
    end
end

-- Handles player login initialization.
local function onLogin()
    SMSN.Tooltip:Hook()
    C_ChatInfo.RegisterAddonMessagePrefix(Constants.PREFIX)
    local text = Helpers.Trim(SMSN.db.text or "", Constants.MAX_TEXT)
    local icons = SMSN.db.icons or {}
    print(('|cff55ff55SetMyStatusNote:|r current status: %s%s'):format(
        #text > 0 and ('"' .. text .. '"') or '<empty>',
        #icons > 0 and ('  (' .. #icons .. ' icon' .. (#icons == 1 and '' or 's') .. ')') or ''
    ))
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        onLogin()
        return
    end
    local prefix, message, _, sender = ...
    if prefix ~= Constants.PREFIX or not message then
        return
    end
    local kind, region, realmSlug, name, text, icons, colorKey = Wire.Parse(message)
    if kind == "Q" then
        handleQuery(sender)
    elseif kind == "D" then
        handleData(region, realmSlug, name, text, icons, colorKey)
    end
end)
