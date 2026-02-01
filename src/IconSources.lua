local _, SMSN = ...

local IconSources = {}
local cache = {}

-- Adds a texture id to a target table when valid.
local function addTexture(target, textureID)
    if textureID and textureID ~= 0 then
        target[#target + 1] = textureID
    end
end

-- Builds the spell icon list.
function IconSources.Spells()
    if cache.spells then
        return cache.spells
    end
    local icons = {}
    if GetMacroIcons then
        for _, texture in ipairs(GetMacroIcons() or {}) do
            addTexture(icons, texture)
        end
    end
    if #icons == 0 and GetNumMacroIcons and GetMacroIconInfo then
        for index = 1, (GetNumMacroIcons() or 0) do
            addTexture(icons, GetMacroIconInfo(index))
        end
    end
    cache.spells = icons
    return icons
end

-- Builds the item icon list.
function IconSources.Items()
    if cache.items then
        return cache.items
    end
    local icons = {}
    if GetMacroItemIcons then
        for _, texture in ipairs(GetMacroItemIcons() or {}) do
            addTexture(icons, texture)
        end
    end
    if #icons == 0 and GetNumMacroItemIcons and GetMacroItemIconInfo then
        for index = 1, (GetNumMacroItemIcons() or 0) do
            addTexture(icons, GetMacroItemIconInfo(index))
        end
    end
    cache.items = icons
    return icons
end

-- Builds the mount icon list.
function IconSources.Mounts()
    if cache.mounts then
        return cache.mounts
    end
    local icons = {}
    if C_MountJournal and C_MountJournal.GetMountIDs then
        for _, mountID in ipairs(C_MountJournal.GetMountIDs() or {}) do
            local _, _, icon = C_MountJournal.GetMountInfoByID(mountID)
            addTexture(icons, icon)
        end
    end
    cache.mounts = icons
    return icons
end

-- Builds the currency icon list.
function IconSources.Currencies()
    if cache.currencies then
        return cache.currencies
    end
    local icons = {}
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.GetCurrencyListInfo then
        for index = 1, (C_CurrencyInfo.GetCurrencyListSize() or 0) do
            local info = C_CurrencyInfo.GetCurrencyListInfo(index)
            if info then
                addTexture(icons, info.iconFileID)
            end
        end
    end
    cache.currencies = icons
    return icons
end

-- Builds the combined icon list.
function IconSources.All()
    if cache.all then
        return cache.all
    end
    local seen, icons = {}, {}
    local function push(list)
        for index = 1, #list do
            local texture = list[index]
            if texture and texture ~= 0 and not seen[texture] then
                seen[texture] = true
                icons[#icons + 1] = texture
            end
        end
    end
    push(IconSources.Spells())
    push(IconSources.Items())
    push(IconSources.Mounts())
    push(IconSources.Currencies())
    cache.all = icons
    return icons
end

-- Declares available icon categories.
IconSources.Categories = {
    { key = "spells", label = "Spells", provider = IconSources.Spells },
    { key = "items", label = "Items", provider = IconSources.Items },
    { key = "mounts", label = "Mounts", provider = IconSources.Mounts },
    { key = "currencies", label = "Currencies", provider = IconSources.Currencies },
    { key = "housing", label = "Housing", provider = IconSources.Items }, -- Pull from items for now
    { key = "all", label = "All", provider = IconSources.All },
}

-- Provides lookup access to category providers.
IconSources.ByKey = {}
for _, category in ipairs(IconSources.Categories) do
    IconSources.ByKey[category.key] = category
end

SMSN.IconSources = IconSources
