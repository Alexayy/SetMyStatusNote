local addonName, SMSN = ...

-- Initializes the addon namespace.
SMSN.name = addonName

-- Provides a simple table copy helper.
local function copyTable(source)
    local out = {}
    for key, value in pairs(source) do
        out[key] = value
    end
    return out
end

-- Declares saved variable defaults.
local defaults = {
    text = "",
    icons = {},
    showSelf = true,
    color = "WHITE",
}

-- Ensures saved variables exist before use.
local function ensureSavedTables()
    SetMyStatusNoteDB = SetMyStatusNoteDB or {}
    SMSN_Live = SMSN_Live or {}
end

-- Applies saved variable defaults when missing.
local function applyDefaults()
    ensureSavedTables()
    for key, value in pairs(defaults) do
        if SetMyStatusNoteDB[key] == nil then
            if type(value) == "table" then
                SetMyStatusNoteDB[key] = copyTable(value)
            else
                SetMyStatusNoteDB[key] = value
            end
        end
    end
end

applyDefaults()

-- Creates a proxy table that always resolves to the latest saved data.
local function createProxy(getTable)
    local proxy = {}
    local mt = {
        __index = function(_, key)
            local tbl = getTable()
            if tbl then
                return tbl[key]
            end
        end,
        __newindex = function(_, key, value)
            local tbl = getTable()
            if tbl then
                tbl[key] = value
            end
        end,
        __pairs = function()
            local tbl = getTable()
            return next, tbl, nil
        end,
        __len = function()
            local tbl = getTable()
            if tbl then
                return #tbl
            end
            return 0
        end,
    }
    return setmetatable(proxy, mt)
end

-- Stores references to saved data on the namespace table.
SMSN.db = createProxy(function()
    ensureSavedTables()
    return SetMyStatusNoteDB
end)

SMSN.live = createProxy(function()
    ensureSavedTables()
    return SMSN_Live
end)

-- Re-applies defaults after the saved variables file is fully loaded.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, name)
    if name == addonName then
        applyDefaults()
        eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Registers the main slash command handler.
SlashCmdList["SETMYSTATUSNOTE"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "key" then
        local key = SMSN.Helpers.Key(SMSN.Helpers.Region(), GetRealmName(), UnitName("player"))
        print("|cffffff00SMSN key:|r " .. key)
        return
    end
    if SMSN.UI then
        SMSN.UI:Open()
    end
end

-- Defines slash command aliases.
SLASH_SETMYSTATUSNOTE1 = "/status"
SLASH_SETMYSTATUSNOTE2 = "/smsn"
