-- FreeMyBag Core
-- Addon lifecycle, delete mode logic, and auto-accept popup handling.
-- Loads LAST so FreeMyBagUI is already defined when events fire.
-- The FreeMyBag global is set here; UI.lua references it only inside
-- functions (never at file load time) to avoid nil issues.

local addon = CreateFrame("Frame", "FreeMyBagCore", UIParent)
FreeMyBag = addon

-- ============================================================
-- ---- Saved variables defaults ----
-- ============================================================

local DEFAULT_SAVED = {
    autoAccept          = true,   -- auto-confirm the Blizzard delete confirmation popup
    screenBorderEnabled = true,   -- pulsing red border around the screen while delete mode is on
    bagBorderEnabled    = true,   -- red outline on ContainerFrame1 while delete mode is on
    pulseEnabled        = true,   -- button alpha pulse while delete mode is on
}

addon.db         = {}
addon.deleteMode = false  -- runtime only, never persisted

-- ============================================================
-- ---- Auto-accept: auto-confirm delete popups ----
-- In delete mode Blizzard's DeleteCursorItem() shows its own
-- confirmation popup for quality items (Uncommon+). When
-- autoAccept is ON we dismiss those popups automatically.
-- ============================================================

local autoFrame = CreateFrame("Frame")

autoFrame:SetScript("OnUpdate", function()
    if not (FreeMyBag.deleteMode and FreeMyBag.db.autoAccept) then return end

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
-- ---- Delete Mode hook ----
-- ============================================================

local function OnItemButtonClick(self, button)
    if not FreeMyBag.deleteMode then return end
    if button ~= "RightButton" then return end

    -- RightButton doesn't put the item on the cursor (it equips/uses),
    -- so we pick it up manually then delete it.
    local parent   = self:GetParent()
    local frameNum = tonumber(parent:GetName():match("%d+"))
    if not frameNum then return end

    PickupContainerItem(frameNum - 1, self:GetID())
    if CursorHasItem() then
        -- Blizzard's DeleteCursorItem() handles quality thresholds:
        --   Poor/Common  → deleted immediately, no popup
        --   Uncommon+    → shows DELETE_GOOD_ITEM popup
        -- When autoAccept is ON the OnUpdate above auto-confirms it.
        DeleteCursorItem()
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

    hooksecurefunc("ContainerFrameItemButton_OnClick", OnItemButtonClick)

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
