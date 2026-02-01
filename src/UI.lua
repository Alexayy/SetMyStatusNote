local _, SMSN = ...

local Constants = SMSN.Constants
local Helpers = SMSN.Helpers
local IconSources = SMSN.IconSources
local ColorByKey = SMSN.ColorByKey

local UI = {}

local frame = CreateFrame("Frame", "SetMyStatusNoteFrame", UIParent, "BackdropTemplate")
frame:SetSize(560, 520)
frame:SetPoint("CENTER")
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:EnableKeyboard(true)
frame:SetScript("OnKeyDown", function(_, key)
    if key == "ESCAPE" then
        frame:Hide()
    end
end)
frame:Hide()
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("Set My Status / Note")

local textLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
textLabel:SetPoint("TOPLEFT", 20, -52)
textLabel:SetText("Text (max 120):")

local edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
edit:SetPoint("TOPLEFT", 20, -72)
edit:SetPoint("TOPRIGHT", -20, -72)
edit:SetHeight(32)
edit:SetAutoFocus(true)
edit:SetMaxLetters(Constants.MAX_TEXT)

local counter = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
counter:SetPoint("TOPRIGHT", -24, -52)
counter:SetText("0/" .. Constants.MAX_TEXT)

edit:SetScript("OnTextChanged", function(self)
    local value = self:GetText() or ""
    if #value > Constants.MAX_TEXT then
        self:SetText(value:sub(1, Constants.MAX_TEXT))
        self:SetCursorPosition(Constants.MAX_TEXT)
    end
    counter:SetText(('%d/%d'):format(#self:GetText(), Constants.MAX_TEXT))
end)

local colorLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colorLabel:SetPoint("TOPLEFT", 20, -104)
colorLabel:SetText("Text color:")

local colorPreview = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
colorPreview:SetPoint("LEFT", colorLabel, "RIGHT", 8, 0)
colorPreview:SetText("Sample")

local colorDropdown = CreateFrame("DropdownButton", "SMSN_Color_DropDown", frame, "WoWStyle1DropdownTemplate")
colorDropdown:SetPoint("LEFT", colorPreview, "RIGHT", 0, -4)
colorDropdown:SetWidth(140)

local selectedColorKey = SMSN.db.color or "WHITE"

-- Updates the color preview sample text.
function UI:RefreshColorPreview()
    local option = ColorByKey[selectedColorKey] or ColorByKey.WHITE
    if option then
        colorPreview:SetTextColor(option.rgb[1], option.rgb[2], option.rgb[3], 1)
        colorPreview:SetText(option.label)
        colorDropdown:SetText(option.label)
    end
end

colorDropdown:SetupMenu(function(_, rootDescription)
    for _, option in ipairs(SMSN.ColorOptions) do
        rootDescription:CreateRadio(option.label, function() return selectedColorKey == option.key end, function()
            selectedColorKey = option.key
            UI:RefreshColorPreview()
        end)
    end
end)

UI:RefreshColorPreview()

local selectedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
selectedLabel:SetPoint("TOPLEFT", 20, -138)
selectedLabel:SetText("Selected:")

local selectedBar = CreateFrame("Frame", nil, frame)
selectedBar:SetPoint("LEFT", selectedLabel, "RIGHT", 8, 0)
selectedBar:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
selectedBar:SetHeight(30)

local selectedSlots, selected, selectedOrder = {}, {}, {}

-- Determines whether the provided texture path is selected.
local function isSelected(path)
    return selected[path] and true or false
end

-- Adds a texture path to the selected list.
local function selectIcon(path)
    if selected[path] or #selectedOrder >= Constants.MAX_ICONS then
        return
    end
    selected[path] = true
    selectedOrder[#selectedOrder + 1] = path
end

-- Removes a texture path from the selected list.
local function unselectIcon(path)
    if not selected[path] then
        return
    end
    selected[path] = nil
    for index, value in ipairs(selectedOrder) do
        if value == path then
            table.remove(selectedOrder, index)
            break
        end
    end
end

-- Refreshes the selected icon bar display.
function UI:UpdateSelectedBar()
    local count = 0
    for index = 1, Constants.MAX_ICONS do
        local button = selectedSlots[index]
        local path = selectedOrder[index]
        if path then
            button.path = path
            button.tex:SetTexture(path)
            button.ring:Show()
            count = count + 1
        else
            button.path = nil
            button.tex:SetTexture(nil)
            button.ring:Hide()
        end
        button:Show()
    end
    frame.countLabel:SetText("(" .. count .. "/" .. Constants.MAX_ICONS .. ")")
end

for index = 1, Constants.MAX_ICONS do
    local button = CreateFrame("Button", nil, selectedBar)
    button:SetSize(30, 30)
    if index == 1 then
        button:SetPoint("LEFT")
    else
        button:SetPoint("LEFT", selectedSlots[index - 1], "RIGHT", 8, 0)
    end
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    button.tex = texture
    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ring:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    button.ring = ring
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnClick", function(self)
        if self.path then
            unselectIcon(self.path)
            UI:UpdateSelectedBar()
            UI:UpdateGrid()
        end
    end)
    selectedSlots[index] = button
end

local iconsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
iconsLabel:SetPoint("TOPLEFT", 20, -168)
iconsLabel:SetText("Pick up to 4 icons:")

local countLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
countLabel:SetPoint("LEFT", iconsLabel, "RIGHT", 8, 0)
countLabel:SetText("(0/" .. Constants.MAX_ICONS .. ")")
frame.countLabel = countLabel

local sourceDropdown = CreateFrame("DropdownButton", "SMSN_Source_DropDown", frame, "WoWStyle1DropdownTemplate")
sourceDropdown:SetPoint("TOPRIGHT", -28, -162)
sourceDropdown:SetWidth(170)
sourceDropdown:SetText("Source: Spells")

local currentCategory = "spells"

-- Changes the currently viewed icon category.
local function setCategory(key)
    currentCategory = key
    local category = IconSources.ByKey[key]
    if category then
        sourceDropdown:SetText("Source: " .. category.label)
    end
    frame.offsetRow = 0
    frame.scroll:SetValue(0)
    UI:UpdateGrid()
end

sourceDropdown:SetupMenu(function(_, rootDescription)
    for _, category in ipairs(IconSources.Categories) do
        rootDescription:CreateRadio(category.label, function() return currentCategory == category.key end, function()
            setCategory(category.key)
        end)
    end
end)

local grid = CreateFrame("Frame", nil, frame)
grid:SetPoint("TOPLEFT", 20, -196)
grid:SetPoint("BOTTOMRIGHT", -40, 60)

local scroll = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
scroll:SetPoint("TOPRIGHT", grid, "TOPRIGHT", 16, -4)
scroll:SetPoint("BOTTOMRIGHT", grid, "BOTTOMRIGHT", 16, 4)
scroll:SetMinMaxValues(0, 0)
scroll:SetValueStep(1)
frame.scroll = scroll

local viewport = CreateFrame("Frame", nil, grid)
viewport:SetAllPoints()

local buttons = {}
local columns, padding = 10, 6
frame.offsetRow, frame.visibleRows = 0, 1

-- Calculates the number of visible grid slots.
local function visibleCapacity()
    local height = viewport:GetHeight()
    local rows = math.max(1, math.floor((height + padding) / (Constants.ICON_SIZE + padding)))
    frame.visibleRows = rows
    return rows * columns
end

-- Ensures enough buttons exist for the visible grid.
local function ensureButtons()
    local needed = visibleCapacity()
    local existing = #buttons
    for index = existing + 1, needed do
        local button = CreateFrame("CheckButton", nil, viewport, "UICheckButtonTemplate")
        local normal = button:GetNormalTexture()
        if normal then
            normal:SetTexture("")
            normal:Hide()
        end
        local pushed = button:GetPushedTexture()
        if pushed then
            pushed:SetTexture("")
            pushed:Hide()
        end
        local highlight = button:GetHighlightTexture()
        if highlight then
            highlight:SetTexture("")
            highlight:Hide()
        end
        button:SetSize(Constants.ICON_SIZE + 6, Constants.ICON_SIZE + 6)
        local idx = index - 1
        local row, col = math.floor(idx / columns), idx % columns
        button:SetPoint("TOPLEFT", col * (Constants.ICON_SIZE + padding), -row * (Constants.ICON_SIZE + padding))
        local hover = button:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints()
        hover:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hover:SetBlendMode("ADD")
        local ring = button:CreateTexture(nil, "OVERLAY")
        ring:SetAllPoints()
        ring:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        button:SetCheckedTexture(ring)
        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        button.tex = texture
        button:SetScript("OnClick", function(self)
            if not self.path then
                return
            end
            if isSelected(self.path) then
                unselectIcon(self.path)
            else
                if #selectedOrder >= Constants.MAX_ICONS then
                    UIErrorsFrame:AddMessage("SetMyStatusNote: Max " .. Constants.MAX_ICONS .. " icons.", 1, 0.2, 0.2)
                    self:SetChecked(false)
                    return
                end
                selectIcon(self.path)
            end
            UI:UpdateSelectedBar()
            UI:UpdateGrid()
        end)
        buttons[index] = button
    end
end

-- Populates the icon grid for the current category.
function UI:UpdateGrid()
    ensureButtons()
    local category = IconSources.ByKey[currentCategory]
    local icons = (category and category.provider and category.provider()) or {}
    local totalRows = math.ceil(#icons / columns)
    local maxOffset = math.max(0, totalRows - frame.visibleRows)
    frame.offsetRow = math.min(frame.offsetRow, maxOffset)
    scroll:SetMinMaxValues(0, maxOffset)
    scroll:SetValue(frame.offsetRow)
    local startIndex = frame.offsetRow * columns + 1
    for index = 1, #buttons do
        local button = buttons[index]
        local iconIndex = startIndex + (index - 1)
        local path = icons[iconIndex]
        if path then
            button:Show()
            button.path = path
            button.tex:SetTexture(path)
            button:SetChecked(isSelected(path))
        else
            button:Hide()
            button.path = nil
        end
    end
end

scroll:SetScript("OnValueChanged", function(_, value)
    frame.offsetRow = math.floor(value or 0)
    UI:UpdateGrid()
end)

viewport:SetScript("OnSizeChanged", function()
    UI:UpdateGrid()
end)

frame:SetScript("OnShow", function()
    UI:UpdateSelectedBar()
    UI:UpdateGrid()
end)

local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
saveButton:SetSize(100, 24)
saveButton:SetPoint("BOTTOMRIGHT", -20, 20)
saveButton:SetText("Save")

local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
cancelButton:SetSize(100, 24)
cancelButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
cancelButton:SetText("Cancel")
cancelButton:SetScript("OnClick", function()
    frame:Hide()
end)

-- Persists the UI state into the saved variables.
function UI:Commit()
    local text = Helpers.Trim(edit:GetText() or "", Constants.MAX_TEXT)
    local icons = {}
    for index = 1, math.min(#selectedOrder, Constants.MAX_ICONS) do
        icons[index] = selectedOrder[index]
    end
    SMSN.db.text = text
    SMSN.db.icons = icons
    SMSN.db.color = selectedColorKey
    local region = Helpers.Region()
    local realm = Helpers.SlugRealm(GetRealmName())
    local name = UnitName("player")
    SMSN.live[Helpers.Key(region, realm, name)] = {
        t = text,
        i = icons,
        c = selectedColorKey,
        ts = GetTime(),
    }
    print(('|cff55ff55SetMyStatusNote:|r saved (%d chars, %d icon%s).'):format(#text, #icons, #icons == 1 and "" or "s"))
    frame:Hide()
end

saveButton:SetScript("OnClick", function()
    UI:Commit()
end)

-- Restores the UI from the saved variables.
function UI:Prefill()
    edit:SetText(SMSN.db.text or "")
    counter:SetText(('%d/%d'):format(#edit:GetText(), Constants.MAX_TEXT))
    wipe(selected)
    wipe(selectedOrder)
    for _, path in ipairs(SMSN.db.icons or {}) do
        selected[path] = true
        selectedOrder[#selectedOrder + 1] = path
    end
    selectedColorKey = SMSN.db.color or "WHITE"
    UI:RefreshColorPreview()
    UI:UpdateSelectedBar()
    UI:UpdateGrid()
end

-- Opens the configuration frame and preloads values.
function UI:Open()
    UI:Prefill()
    frame:Show()
end

SMSN.UI = UI
SMSN.UI.frame = frame
