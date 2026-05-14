-- FreeMyBag Core
-- Addon lifecycle, delete mode logic, and auto-delete popup handling.
-- Loads LAST so FreeMyBagUI is already defined when events fire.

local addon = CreateFrame("Frame", "FreeMyBagCore", UIParent)
FreeMyBag = addon

-- ============================================================
-- ---- Saved variables defaults ----
-- ============================================================

local DEFAULT_SAVED = {
    autoDelete          = false,
    screenBorderEnabled = false,
    bagBorderEnabled    = true,

    exclusionList       = { [6948] = true },  -- Hearthstone protected by default
}

addon.db         = {}
addon.deleteMode = false
addon.addExclusionMode = false

-- ============================================================
-- ---- Alt key tracking + pending actions ----
-- ============================================================
-- IsAltKeyDown() returns nil from hooksecurefunc and HookScript
-- (both run in a restored secure context). But it DOES work
-- from OnUpdate — so we track the Alt state every frame in
-- `altDown` for the OnMouseDown hook to read.
--
-- OnMouseDown fires for EVERY mouse button press, including
-- Alt+LeftClick which never reaches Blizzard's OnClick handler.

local autoFrame = CreateFrame("Frame")
local altDown = false
local pendingAction = false

autoFrame:SetScript("OnUpdate", function()
    -- Only check Alt when bags are open (no need when user can't click items)
    local bagsOpen = ContainerFrame1:IsShown() or ContainerFrame2:IsShown()
        or ContainerFrame3:IsShown() or ContainerFrame4:IsShown()
        or ContainerFrame5:IsShown()
    if bagsOpen then
        altDown = IsAltKeyDown()
    end

    -- Pending action from the confirm case (Rare+ with autoDelete OFF)
    -- Item was picked up by Blizzard's OnClick; put back and show dialog.
    if pendingAction then
        -- Cancel pending action if exclusion add mode is active
        if FreeMyBag.addExclusionMode then
            pendingAction = false
            return
        end
        local pa = pendingAction
        pendingAction = false
        PickupContainerItem(pa.bag, pa.slot)
        FreeMyBagUI:ShowDeleteConfirm(pa.bag, pa.slot, pa.name)
        return
    end

    -- Auto-confirm Blizzard popups (autoDelete = ON)
    if not (FreeMyBag.deleteMode and FreeMyBag.db.autoDelete) then return end

    for i = 1, STATICPOPUP_NUMDIALOGS do
        local dialog = _G["StaticPopup" .. i]
        if dialog and dialog:IsShown() then
            local which = dialog.which
            if which == "DELETE_ITEM" or which == "DELETE_GOOD_ITEM"
                or which == "DELETE_QUEST_ITEM" or which == "DELETE_GOOD_QUEST_ITEM" then

                local editBox = _G["StaticPopup" .. i .. "EditBox"]
                if editBox and editBox:IsShown() then
                    editBox:SetText("DELETE")
                end

                local btn1 = _G["StaticPopup" .. i .. "Button1"]
                if btn1 and btn1:IsShown() and btn1:IsEnabled() then
                    local data = StaticPopupDialogs[which]
                    if data and data.OnAccept then
                        data.OnAccept(dialog)
                    end
                    dialog:Hide()
                end
            end
        end
    end
end)

-- ============================================================
-- ---- Item type ID helper (must be before OnMouseDown hook) ----
-- ============================================================

-- Get item type ID from an item link (e.g. "69435" from "|Hitem:69435:...")
local function GetItemTypeID(itemLink)
    if not itemLink then return nil end
    return tonumber(string.match(itemLink, ":(%d+):"))
end

-- ============================================================
-- ---- OnMouseDown hook (Alt+LeftClick in delete mode) ----
-- ============================================================
-- OnMouseDown fires BEFORE the secure system processes the click,
-- so it catches ALL button presses including Alt+LeftClick (which
-- never reaches ContainerFrameItemButton_OnClick).
--
-- We read `altDown` (tracked by OnUpdate) since IsAltKeyDown()
-- would return nil from inside the hook itself.
--
-- Delete case:   pickup → DeleteCursorItem()
-- Confirm case:  pickup → put back → pendingAction → OnUpdate shows dialog
-- Blizzard OnClick after us: slot is empty (delete) → no-op;
--                            slot has item (confirm) → picks up again → OnUpdate puts back

local function OnContainerItemMouseDown(self, buttonName)
    -- Exclusion add mode: Alt+LeftClick adds item type to exclusion list
    -- Does NOT exit add mode — stays active for multiple items
    if FreeMyBag.addExclusionMode and buttonName == "LeftButton" and altDown then
        local parent   = self:GetParent()
        local frameNum = tonumber(parent:GetName():match("%d+"))
        if frameNum then
            local bag  = frameNum - 1
            local slot = self:GetID()
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local typeID = GetItemTypeID(itemLink)
                if typeID then
                    addon.db.exclusionList[typeID] = true
                    FreeMyBagUI:RefreshExclusionList()
                end
            end
        end
        return
    end

    -- Exclusion guard: skip items whose type is in the exclusion list
    if FreeMyBag.deleteMode then
        local parent   = self:GetParent()
        local frameNum = tonumber(parent:GetName():match("%d+"))
        if frameNum then
            local bag  = frameNum - 1
            local slot = self:GetID()
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local typeID = GetItemTypeID(itemLink)
                if typeID and addon.db.exclusionList[typeID] then
                    return  -- protected item, skip delete logic
                end
            end
        end
    end

    if not FreeMyBag.deleteMode then return end
    if buttonName ~= "LeftButton" then return end
    if not altDown then return end

    local parent   = self:GetParent()
    local frameNum = tonumber(parent:GetName():match("%d+"))
    if not frameNum then return end
    local bag  = frameNum - 1
    local slot = self:GetID()

    local itemLink = GetContainerItemLink(bag, slot)
    if not itemLink then return end
    local _, _, quality = GetItemInfo(itemLink)
    local name = GetItemInfo(itemLink)

    -- Pick up the item (Blizzard's OnClick fires after us)
    PickupContainerItem(bag, slot)
    if not CursorHasItem() then return end

    if not FreeMyBag.db.autoDelete and quality and quality >= 3 then
        -- Rare+ with autoDelete OFF: put it back, schedule confirm
        PickupContainerItem(bag, slot)
        pendingAction = { type = "confirm", bag = bag, slot = slot, name = name or "Unknown" }
    else
        -- autoDelete = ON or Poor/Common/Uncommon: destroy immediately
        DeleteCursorItem()
    end
end

-- ============================================================
-- ---- Hook all container buttons ----
-- ============================================================

local function HookContainerButtons()
    for i = 1, 10 do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            for j = 1, 32 do
                local button = _G["ContainerFrame" .. i .. "Item" .. j]
                if button and not button.fmbHooked then
                    button:HookScript("OnMouseDown", OnContainerItemMouseDown)
                    button.fmbHooked = true
                end
            end
        end
    end
end

-- ============================================================
-- ---- Toggle Delete Mode ----
-- ============================================================

function addon:ToggleDeleteMode()
    self.deleteMode = not self.deleteMode

    if self.deleteMode then
        FreeMyBagUI:OnDeleteModeActivated()
    else
        if CursorHasItem() then ClearCursor() end
        FreeMyBagUI:OnDeleteModeDeactivated()
    end
end

-- ============================================================
-- ---- Exclusion List ----
-- ============================================================

function addon:ToggleExclusionAddMode()
    if self.addExclusionMode then
        self:ExitExclusionAddMode()
    else
        if self.deleteMode then
            self:ToggleDeleteMode()
        end
        self.addExclusionMode = true
        addon:Print("|cff40c040Add Exclusion Mode ON|r — Alt+LeftClick items to protect them. /fmb to cancel.")
        if FreeMyBagUI then
            FreeMyBagUI:OnExclusionAddModeActivated()
        end
    end
end

function addon:ExitExclusionAddMode()
    self.addExclusionMode = false
    if CursorHasItem() then ClearCursor() end
    if FreeMyBagUI then
        FreeMyBagUI:OnExclusionAddModeDeactivated()
    end
end

-- ============================================================
-- ---- Event dispatch ----
-- ============================================================

function addon:OnEvent(event, ...)
    if self[event] then self[event](self, event, ...) end
end
addon:SetScript("OnEvent", addon.OnEvent)

-- ============================================================
-- ---- Lifecycle ----
-- ============================================================

function addon:PLAYER_LOGIN()
    self.db = FreeMyBag_SavedVars or {}
    for k, v in pairs(DEFAULT_SAVED) do
        if self.db[k] == nil then self.db[k] = v end
    end

    HookContainerButtons()
    FreeMyBagUI:Create()

    addon:Print("Loaded. Type |cffffd200/fmb|r to open settings.")
end

function addon:PLAYER_LOGOUT()
    if self.deleteMode then
        self.deleteMode = false
    end
    FreeMyBag_SavedVars = self.db
end

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_LOGOUT")

-- ============================================================
-- ---- Slash commands ----
-- ============================================================

SLASH_FREEMYBAG1 = "/fmb"
SLASH_FREEMYBAG2 = "/freemybag"

SlashCmdList["FREEMYBAG"] = function(msg)
    msg = msg:lower():trim()

    if msg == "" then
        FreeMyBagUI:ToggleConfig()

    elseif msg == "on" then
        if not FreeMyBag.deleteMode then FreeMyBag:ToggleDeleteMode() end

    elseif msg == "off" then
        if FreeMyBag.deleteMode then FreeMyBag:ToggleDeleteMode() end

    else
        addon:Print("Commands:")
        addon:Print("  /fmb         — Toggle settings window")
        addon:Print("  /fmb on      — Enable Delete Mode")
        addon:Print("  /fmb off     — Disable Delete Mode")
    end
end

-- ============================================================
-- ---- Utility ----
-- ============================================================

function addon:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffcc3333[FreeMyBag]|r " .. tostring(msg))
end
