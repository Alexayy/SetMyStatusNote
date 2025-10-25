local _, SMSN = ...

local Constants = SMSN.Constants
local Helpers = SMSN.Helpers
local ColorByKey = SMSN.ColorByKey
local Wire = SMSN.Wire

local Tooltip = {}
local lastQueryAtByKey = {}

-- Attempts to query the target for updated status data.
function Tooltip:MaybeQueryTarget(name, realm)
    if not name then
        return
    end
    local region = Helpers.Region()
    realm = (realm and realm ~= "") and realm or GetRealmName()
    local key = Helpers.Key(region, realm, name)
    local now = GetTime()
    if (lastQueryAtByKey[key] or 0) + Constants.QUERY_COOLDOWN > now then
        return
    end
    lastQueryAtByKey[key] = now
    C_ChatInfo.SendAddonMessage(Constants.PREFIX, Wire.BuildQuery(region, Helpers.SlugRealm(realm), name), "WHISPER", Helpers.WTarget(name, realm))
end

-- Adds saved note information to the tooltip.
function Tooltip:AddToTooltip(tt)
    local unit = select(2, tt:GetUnit())
    if not unit or not UnitIsPlayer(unit) then
        return
    end
    local name, realm = Helpers.UnitNameRealm(unit)
    if not name then
        return
    end
    local region = Helpers.Region()
    local key = Helpers.Key(region, realm, name)
    local text, icons, colorKey
    local live = SMSN.live[key]
    if live then
        text, icons, colorKey = live.t, live.i, live.c
        if (GetTime() - (live.ts or 0)) > Constants.CACHE_TTL and not UnitIsUnit(unit, "player") then
            Tooltip:MaybeQueryTarget(name, realm)
        end
    else
        if not UnitIsUnit(unit, "player") then
            Tooltip:MaybeQueryTarget(name, realm)
        else
            text = Helpers.Trim(SMSN.db.text or "", Constants.MAX_TEXT)
            icons = SMSN.db.icons
            colorKey = SMSN.db.color
        end
    end
    if icons and #icons > 0 then
        tt:AddLine(Helpers.InlineIcons(icons), 1, 1, 1, false)
    end
    if text and text ~= "" then
        local color = ColorByKey[colorKey or "WHITE"] or ColorByKey.WHITE
        tt:AddLine(text, color.rgb[1], color.rgb[2], color.rgb[3], true)
        local fontString = _G[tt:GetName() .. "TextLeft" .. tt:NumLines()]
        if fontString and fontString.SetWordWrap then
            fontString:SetWordWrap(true)
        end
        if fontString and fontString.SetNonSpaceWrap then
            fontString:SetNonSpaceWrap(true)
        end
    end
    tt:Show()
end

-- Hooks tooltip events for displaying status data.
function Tooltip:Hook()
    if Tooltip.hooked then
        return
    end
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt)
            Tooltip:AddToTooltip(tt)
        end)
    else
        GameTooltip:HookScript("OnTooltipSetUnit", function(tt)
            Tooltip:AddToTooltip(tt)
        end)
    end
    Tooltip.hooked = true
end

SMSN.Tooltip = Tooltip
