WicksQuestKeyDB = WicksQuestKeyDB or {
    point = "CENTER", relativePoint = "CENTER", x = 0, y = -150,
}

local C_BG     = { 0.05, 0.04, 0.08, 0.97 }
local C_BORDER = { 0.22, 0.18, 0.36, 1 }
local C_GREEN  = { 0.31, 0.78, 0.47, 1 }
local C_HOVER  = { 0.31, 0.78, 0.47, 0.10 }
local C_MOVE   = { 0.64, 0.21, 0.93, 0.20 }

local function NewTexture(parent, layer, c)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(unpack(c))
    return t
end

local function AddBorder(frame, c)
    local t = NewTexture(frame, "BORDER", c); t:SetPoint("TOPLEFT");    t:SetPoint("TOPRIGHT");    t:SetHeight(1)
    local b = NewTexture(frame, "BORDER", c); b:SetPoint("BOTTOMLEFT"); b:SetPoint("BOTTOMRIGHT"); b:SetHeight(1)
    local l = NewTexture(frame, "BORDER", c); l:SetPoint("TOPLEFT");    l:SetPoint("BOTTOMLEFT");  l:SetWidth(1)
    local r = NewTexture(frame, "BORDER", c); r:SetPoint("TOPRIGHT");   r:SetPoint("BOTTOMRIGHT"); r:SetWidth(1)
end

local function AddCornerAccents(frame)
    local L, T = 10, 2
    for _, anchor in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
        local h = NewTexture(frame, "OVERLAY", C_GREEN); h:SetPoint(anchor); h:SetSize(L, T)
        local v = NewTexture(frame, "OVERLAY", C_GREEN); v:SetPoint(anchor); v:SetSize(T, L)
    end
end

local items = {}
local nextIndex = 1

local btn = CreateFrame("Button", "WicksQuestKeyButton", UIParent, "SecureActionButtonTemplate")
btn:SetSize(52, 52)
btn:SetFrameStrata("MEDIUM")
btn:SetClampedToScreen(true)
btn:SetMovable(true)
btn:SetAttribute("type1", "item")
btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
btn:Hide()

local bg = NewTexture(btn, "BACKGROUND", C_BG); bg:SetAllPoints(btn)
AddBorder(btn, C_BORDER)
AddCornerAccents(btn)

local icon = btn:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", 4, -4)
icon:SetPoint("BOTTOMRIGHT", -4, 4)
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
btn.icon = icon

local count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
count:SetPoint("BOTTOMRIGHT", -3, 3)
btn.count = count

local bindLabel = btn:CreateFontString(nil, "OVERLAY")
bindLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
bindLabel:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -3)
bindLabel:SetTextColor(1, 1, 1, 1)
btn.bindLabel = bindLabel

local hover = NewTexture(btn, "HIGHLIGHT", C_HOVER); hover:SetAllPoints(btn)

local moveTint = NewTexture(btn, "OVERLAY", C_MOVE)
moveTint:SetAllPoints(btn)
moveTint:Hide()

btn:SetScript("OnEnter", function(self)
    if #items == 0 then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local cur = items[nextIndex]
    if cur then GameTooltip:SetHyperlink("item:" .. cur.itemId) end
    if #items > 1 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(("Quest item %d of %d"):format(nextIndex, #items), 0.31, 0.78, 0.47)
        GameTooltip:AddLine("Right-click to cycle without using.", 0.42, 0.35, 0.54)
    end
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function ApplyPosition()
    local db = WicksQuestKeyDB
    btn:ClearAllPoints()
    btn:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
end

local function SavePosition()
    local point, _, relativePoint, x, y = btn:GetPoint(1)
    WicksQuestKeyDB.point = point
    WicksQuestKeyDB.relativePoint = relativePoint
    WicksQuestKeyDB.x = x
    WicksQuestKeyDB.y = y
end

local locked = true
local function SetLocked(state)
    if InCombatLockdown() then
        print("|cff8a5cf6Wick's Quest Key|r: cannot change lock during combat.")
        return
    end
    locked = state
    if locked then
        btn:RegisterForDrag()
        moveTint:Hide()
    else
        btn:RegisterForDrag("LeftButton")
        moveTint:Show()
        if #items == 0 then btn:Show() end
    end
end

btn:SetScript("OnDragStart", function(self) if not locked then self:StartMoving() end end)
btn:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing(); SavePosition() end)

local function Arm()
    local cur = items[nextIndex]
    if cur then
        if not InCombatLockdown() then
            btn:SetAttribute("item", "item:" .. cur.itemId)
        end
        btn.icon:SetTexture(cur.icon)
        btn.icon:Show()
        if not InCombatLockdown() then btn:Show() end
    else
        if not InCombatLockdown() then
            btn:SetAttribute("item", nil)
            if locked then btn:Hide() end
        end
        btn.icon:Hide()
    end
end

local function UpdateCount()
    local cur = items[nextIndex]
    if cur then
        local n = GetItemCount(cur.itemId) or 0
        btn.count:SetText(n > 1 and tostring(n) or "")
    else
        btn.count:SetText("")
    end
end

local function ShortBind(key)
    if not key or key == "" then return "" end
    return (key:upper()
        :gsub("ALT%-", "a")
        :gsub("CTRL%-", "c")
        :gsub("SHIFT%-", "s")
        :gsub("NUMPAD", "n")
        :gsub("BUTTON1", "M1")
        :gsub("BUTTON2", "M2")
        :gsub("BUTTON3", "M3")
        :gsub("MOUSEWHEELUP", "MwU")
        :gsub("MOUSEWHEELDOWN", "MwD"))
end

local function UpdateBindLabel()
    local key = GetBindingKey("WICKSQUESTKEY_FIRE")
    btn.bindLabel:SetText(ShortBind(key))
end

local function Scan()
    if InCombatLockdown() then return end
    wipe(items)
    local seen = {}
    for i = 1, GetNumQuestLogEntries() do
        local _, _, _, _, isHeader = GetQuestLogTitle(i)
        if not isHeader then
            local link, iconTex = GetQuestLogSpecialItemInfo(i)
            local itemId = link and tonumber(link:match("item:(%d+)"))
            if itemId and not seen[itemId] then
                seen[itemId] = true
                local cachedName, _, _, _, _, _, _, _, _, cachedIcon = GetItemInfo(itemId)
                items[#items + 1] = {
                    itemId = itemId,
                    name   = cachedName or link:match("%[(.-)%]") or ("item:" .. itemId),
                    icon   = iconTex or cachedIcon or 134400,
                }
            end
        end
    end
    if nextIndex > #items or nextIndex < 1 then nextIndex = 1 end
    Arm()
    UpdateCount()
end

btn:SetScript("OnClick", function(self, button)
    if button == "RightButton" and not InCombatLockdown() and #items > 1 then
        nextIndex = (nextIndex % #items) + 1
        Arm()
        UpdateCount()
    end
end)

btn:SetScript("PostClick", function(self, button)
    if button == "LeftButton" and not InCombatLockdown() and #items > 0 then
        nextIndex = (nextIndex % #items) + 1
        Arm()
        UpdateCount()
    end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("QUEST_LOG_UPDATE")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
f:RegisterEvent("UPDATE_BINDINGS")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then ApplyPosition(); UpdateBindLabel() end
    if event == "UPDATE_BINDINGS" then UpdateBindLabel(); return end
    if event == "BAG_UPDATE_DELAYED" then UpdateCount(); return end
    Scan()
end)

BINDING_HEADER_WICKSQUESTKEY = "Wick's Quest Key"
BINDING_NAME_WICKSQUESTKEY_FIRE = "Use current quest item"

SLASH_WICKSQUESTKEY1 = "/wqk"
SLASH_WICKSQUESTKEY2 = "/questkey"
SlashCmdList.WICKSQUESTKEY = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "unlock" or msg == "move" then
        SetLocked(false)
        print("|cff8a5cf6Wick's Quest Key|r: unlocked. Left-drag the button to move it.")
        return
    elseif msg == "lock" then
        SetLocked(true)
        print("|cff8a5cf6Wick's Quest Key|r: locked.")
        return
    elseif msg == "reset" then
        WicksQuestKeyDB.point, WicksQuestKeyDB.relativePoint = "CENTER", "CENTER"
        WicksQuestKeyDB.x, WicksQuestKeyDB.y = 0, -150
        ApplyPosition()
        print("|cff8a5cf6Wick's Quest Key|r: position reset.")
        return
    end
    if #items == 0 then
        print("|cff8a5cf6Wick's Quest Key|r: no usable quest items right now.")
    else
        print(("|cff8a5cf6Wick's Quest Key|r: %d quest item(s) loaded"):format(#items))
        for i, it in ipairs(items) do
            local marker = (i == nextIndex) and "  |cff4fc77b<-- next press|r" or ""
            print(("  %d. %s%s"):format(i, it.name, marker))
        end
    end
    print("Commands: /wqk unlock | lock | reset")
end
