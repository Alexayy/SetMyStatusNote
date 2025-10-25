local _, SMSN = ...

-- Defines addon level constants.
SMSN.Constants = {
    MAX_TEXT = 120,
    MAX_ICONS = 4,
    ICON_SIZE = 30,
    LINE_SIZE = 12,
    PREFIX = "SMSN1",
    QUERY_COOLDOWN = 8,
    REPLY_COOLDOWN = 5,
    CACHE_TTL = 20,
}

-- Declares available text color options.
SMSN.ColorOptions = {
    { key = "WHITE",    label = "White",    hex = "FFFFFF", rgb = { 1.00, 1.00, 1.00 } },
    { key = "YELLOW",   label = "Yellow",   hex = "FFD200", rgb = { 1.00, 0.82, 0.00 } },
    { key = "GREEN",    label = "Green",    hex = "33FF66", rgb = { 0.20, 1.00, 0.40 } },
    { key = "TURQUOISE",label = "Turquoise",hex = "33FFE6", rgb = { 0.20, 1.00, 0.90 } },
    { key = "BLUE",     label = "Blue",     hex = "3399FF", rgb = { 0.20, 0.60, 1.00 } },
}

-- Builds a quick lookup for color settings.
SMSN.ColorByKey = {}
for _, option in ipairs(SMSN.ColorOptions) do
    SMSN.ColorByKey[option.key] = option
end
