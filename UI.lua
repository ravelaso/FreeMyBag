-- FreeMyBag UI
-- Delete Mode button anchored to the backpack (ContainerFrame1).
-- Visual feedback: screen border pulse, bag border, button pulse.
-- Config window opened via /fmb or /freemybag.
-- Compatible with WoW 3.3.5 (no SetColorTexture, no BackdropTemplate).

FreeMyBagUI = {}

-- ============================================================
-- ---- Shared texture helpers (3.3.5-safe) ----
-- ============================================================

local WHITE_TEX = "Interface\\Buttons\\WHITE8X8"

local function ColorTex(parent, layer, r, g, b, a)
    local tex = parent:CreateTexture(nil, layer)
    tex:SetTexture(WHITE_TEX)
    tex:SetVertexColor(r, g, b, a or 1)
    return tex
end

local function ApplyBorder(frame, r, g, b, a)
    a = a or 0.5
    local function edge(pt1, pt2, isH)
        local t = ColorTex(frame, "BORDER", r, g, b, a)
        t:SetPoint(pt1, frame, pt1, 0, 0)
        t:SetPoint(pt2, frame, pt2, 0, 0)
        if isH then t:SetHeight(1) else t:SetWidth(1) end
    end
    edge("TOPLEFT",    "TOPRIGHT",    true)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
    edge("TOPLEFT",    "BOTTOMLEFT",  false)
    edge("TOPRIGHT",   "BOTTOMRIGHT", false)
end

-- Horizontal separator
local function MakeSep(parent, yOff, pad)
    pad = pad or 8
    local sep = ColorTex(parent, "BORDER", 0.25, 0.25, 0.25, 0.45)
    sep:SetPoint("TOPLEFT",  parent, "TOPLEFT",   pad,  yOff)
    sep:SetPoint("TOPRIGHT", parent, "TOPRIGHT",  -pad, yOff)
    sep:SetHeight(1)
end

-- Toggle button (same visual style as Looty).
-- Returns: button frame with :SetState(on) method.
local function MakeToggle(parent, isOn, labelOn, labelOff, w, h, yOff, xOff, onClick)
    h    = h    or 22
    xOff = xOff or 8

    local nc = isOn and { 0.05, 0.20, 0.35 } or { 0.15, 0.15, 0.15 }
    local tc = isOn and { 0.4,  0.75, 1.0  } or { 0.7,  0.7,  0.7  }

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
    btn:EnableMouse(true)

    local bg = ColorTex(btn, "BACKGROUND", nc[1], nc[2], nc[3], 0.85)
    bg:SetAllPoints(btn)

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
    lbl:SetText(isOn and labelOn or labelOff)
    lbl:SetTextColor(tc[1], tc[2], tc[3])

    btn:SetScript("OnEnter", function()
        local n2 = isOn and { 0.10, 0.35, 0.55 } or { 0.25, 0.25, 0.25 }
        bg:SetVertexColor(n2[1], n2[2], n2[3], 0.85)
    end)
    btn:SetScript("OnLeave", function() bg:SetVertexColor(nc[1], nc[2], nc[3], 0.85) end)

    btn._bg  = bg
    btn._lbl = lbl

    btn:SetScript("OnClick", function() onClick(btn) end)

    function btn:SetState(on)
        local nc2 = on and { 0.05, 0.20, 0.35 } or { 0.15, 0.15, 0.15 }
        local tc2 = on and { 0.4,  0.75, 1.0  } or { 0.7,  0.7,  0.7  }
        self._bg:SetVertexColor(nc2[1], nc2[2], nc2[3], 0.85)
        self._lbl:SetText(on and labelOn or labelOff)
        self._lbl:SetTextColor(tc2[1], tc2[2], tc2[3])
    end

    return btn
end

-- ============================================================
-- ---- Delete Mode button (anchored to backpack) ----
-- ============================================================

local ICON_OFF = "Interface\\Icons\\INV_Misc_Bag_10"
local ICON_ON  = "Interface\\Icons\\INV_Misc_Bomb_07"

local BTN_OFF = { bg = { 0.15, 0.15, 0.15 }, hover = { 0.25, 0.25, 0.25 } }
local BTN_ON  = { bg = { 0.55, 0.08, 0.08 }, hover = { 0.75, 0.12, 0.12 } }

local deleteBtn
local deleteBtnBg
local deleteBtnIcon

-- OnUpdate state for button pulse
local pulseTime = 0

local function UpdateButtonPulse(self, elapsed)
    if not FreeMyBag.deleteMode or not FreeMyBag.db.pulseEnabled then
        self:SetScript("OnUpdate", nil)
        deleteBtnBg:SetVertexColor(BTN_ON.bg[1], BTN_ON.bg[2], BTN_ON.bg[3], 0.85)
        return
    end
    pulseTime = pulseTime + elapsed
    -- Sine wave between 0.5 and 1.0 alpha, period ~1.4s
    local a = 0.75 + 0.25 * math.sin(pulseTime * 4.5)
    deleteBtnBg:SetVertexColor(BTN_ON.bg[1], BTN_ON.bg[2], BTN_ON.bg[3], a)
end

function FreeMyBagUI:CreateDeleteButton()
    if deleteBtn then return end

    -- Anchor to the left of ContainerFrame1's close button so it sits
    -- at the same height and doesn't overlap Blizzard's X.
    deleteBtn = CreateFrame("Button", "FreeMyBagDeleteButton", ContainerFrame1)
    deleteBtn:SetSize(20, 20)
    deleteBtn:SetPoint("RIGHT", ContainerFrame1CloseButton, "LEFT", -2, 0)
    deleteBtn:EnableMouse(true)
    deleteBtn:SetFrameLevel(ContainerFrame1:GetFrameLevel() + 5)

    deleteBtnBg = ColorTex(deleteBtn, "BACKGROUND",
        BTN_OFF.bg[1], BTN_OFF.bg[2], BTN_OFF.bg[3], 0.85)
    deleteBtnBg:SetAllPoints(deleteBtn)

    deleteBtnIcon = deleteBtn:CreateTexture(nil, "ARTWORK")
    deleteBtnIcon:SetAllPoints(deleteBtn)
    deleteBtnIcon:SetTexture(ICON_OFF)

    ApplyBorder(deleteBtn, 0.30, 0.30, 0.30, 0.6)

    deleteBtn:SetScript("OnEnter", function()
        local s = FreeMyBag.deleteMode and BTN_ON or BTN_OFF
        deleteBtnBg:SetVertexColor(s.hover[1], s.hover[2], s.hover[3], 0.85)
        GameTooltip:SetOwner(deleteBtn, "ANCHOR_LEFT")
        if FreeMyBag.deleteMode then
            GameTooltip:SetText("|cffff4444Delete Mode ACTIVE|r\nAlt+LeftClick items to destroy them.\nClick again to disable.", nil, nil, nil, nil, true)
        else
            GameTooltip:SetText("|cffccccccDelete Mode|r\nActivate to destroy items\nby clicking them.", nil, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    deleteBtn:SetScript("OnLeave", function()
        local s = FreeMyBag.deleteMode and BTN_ON or BTN_OFF
        deleteBtnBg:SetVertexColor(s.bg[1], s.bg[2], s.bg[3], 0.85)
        GameTooltip:Hide()
    end)
    deleteBtn:SetScript("OnClick", function()
        FreeMyBag:ToggleDeleteMode()
    end)
end

-- Called from Core after deleteMode changes.
function FreeMyBagUI:RefreshDeleteButton()
    if not deleteBtn then return end

    if FreeMyBag.deleteMode then
        deleteBtnIcon:SetTexture(ICON_ON)
        deleteBtnBg:SetVertexColor(BTN_ON.bg[1], BTN_ON.bg[2], BTN_ON.bg[3], 0.85)
        if FreeMyBag.db.pulseEnabled then
            pulseTime = 0
            deleteBtn:SetScript("OnUpdate", UpdateButtonPulse)
        end
    else
        deleteBtnIcon:SetTexture(ICON_OFF)
        deleteBtnBg:SetVertexColor(BTN_OFF.bg[1], BTN_OFF.bg[2], BTN_OFF.bg[3], 0.85)
        deleteBtn:SetScript("OnUpdate", nil)
    end

    -- Refresh tooltip if cursor is still over the button
    if deleteBtn:IsMouseOver() then
        GameTooltip:SetOwner(deleteBtn, "ANCHOR_LEFT")
        if FreeMyBag.deleteMode then
            GameTooltip:SetText("|cffff4444Delete Mode ACTIVE|r\nAlt+LeftClick items to destroy them.\nClick again to disable.", nil, nil, nil, nil, true)
        else
            GameTooltip:SetText("|cffccccccDelete Mode|r\nActivate to destroy items\nby right-clicking them.", nil, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end
end

-- ============================================================
-- ---- Screen border pulse (UIParent-sized, FULLSCREEN) ----
-- Four 4px edge textures that pulse red while delete mode is ON.
-- ============================================================

local screenBorder = {}      -- holds the 4 edge textures
local screenBorderFrame      -- parent frame
local screenPulseTime = 0

local function UpdateScreenBorderPulse(self, elapsed)
    if not FreeMyBag.deleteMode or not FreeMyBag.db.screenBorderEnabled then
        self:SetScript("OnUpdate", nil)
        self:Hide()
        return
    end
    screenPulseTime = screenPulseTime + elapsed
    local a = 0.35 + 0.35 * math.sin(screenPulseTime * 3.0)
    for _, t in ipairs(screenBorder) do
        t:SetVertexColor(1, 0, 0, a)
    end
end

local function CreateScreenBorderFrame()
    if screenBorderFrame then return end

    screenBorderFrame = CreateFrame("Frame", "FreeMyBagScreenBorder", UIParent)
    screenBorderFrame:SetAllPoints(UIParent)
    screenBorderFrame:SetFrameStrata("FULLSCREEN")
    screenBorderFrame:SetFrameLevel(200)
    screenBorderFrame:Hide()

    local THICKNESS = 6

    -- Top edge
    local top = screenBorderFrame:CreateTexture(nil, "OVERLAY")
    top:SetTexture(WHITE_TEX)
    top:SetPoint("TOPLEFT",  screenBorderFrame, "TOPLEFT",  0,  0)
    top:SetPoint("TOPRIGHT", screenBorderFrame, "TOPRIGHT", 0,  0)
    top:SetHeight(THICKNESS)
    screenBorder[1] = top

    -- Bottom edge
    local bot = screenBorderFrame:CreateTexture(nil, "OVERLAY")
    bot:SetTexture(WHITE_TEX)
    bot:SetPoint("BOTTOMLEFT",  screenBorderFrame, "BOTTOMLEFT",  0, 0)
    bot:SetPoint("BOTTOMRIGHT", screenBorderFrame, "BOTTOMRIGHT", 0, 0)
    bot:SetHeight(THICKNESS)
    screenBorder[2] = bot

    -- Left edge
    local lft = screenBorderFrame:CreateTexture(nil, "OVERLAY")
    lft:SetTexture(WHITE_TEX)
    lft:SetPoint("TOPLEFT",    screenBorderFrame, "TOPLEFT",    0, 0)
    lft:SetPoint("BOTTOMLEFT", screenBorderFrame, "BOTTOMLEFT", 0, 0)
    lft:SetWidth(THICKNESS)
    screenBorder[3] = lft

    -- Right edge
    local rgt = screenBorderFrame:CreateTexture(nil, "OVERLAY")
    rgt:SetTexture(WHITE_TEX)
    rgt:SetPoint("TOPRIGHT",    screenBorderFrame, "TOPRIGHT",    0, 0)
    rgt:SetPoint("BOTTOMRIGHT", screenBorderFrame, "BOTTOMRIGHT", 0, 0)
    rgt:SetWidth(THICKNESS)
    screenBorder[4] = rgt
end

function FreeMyBagUI:SetScreenBorderActive(on)
    CreateScreenBorderFrame()
    if on and FreeMyBag.db.screenBorderEnabled then
        screenPulseTime = 0
        screenBorderFrame:Show()
        screenBorderFrame:SetScript("OnUpdate", UpdateScreenBorderPulse)
    else
        screenBorderFrame:SetScript("OnUpdate", nil)
        screenBorderFrame:Hide()
    end
end

-- ============================================================
-- ---- Bag border (red outline on EVERY container frame) ----
-- ============================================================

local bagBorderFrames = {}
local BAG_BORDER_THICKNESS = 3

function FreeMyBagUI:CreateBagBorderForFrame(containerFrame)
    if bagBorderFrames[containerFrame] then return end

    local border = CreateFrame("Frame", nil, containerFrame)
    border:SetAllPoints(containerFrame)
    border:SetFrameLevel(containerFrame:GetFrameLevel() + 3)
    border:Hide()

    local function edge(pt1, pt2, isH)
        local t = border:CreateTexture(nil, "OVERLAY")
        t:SetTexture(WHITE_TEX)
        t:SetVertexColor(0.9, 0.10, 0.10, 0.85)
        t:SetPoint(pt1, border, pt1, 0, 0)
        t:SetPoint(pt2, border, pt2, 0, 0)
        if isH then t:SetHeight(BAG_BORDER_THICKNESS) else t:SetWidth(BAG_BORDER_THICKNESS) end
    end
    edge("TOPLEFT",    "TOPRIGHT",    true)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
    edge("TOPLEFT",    "BOTTOMLEFT",  false)
    edge("TOPRIGHT",   "BOTTOMRIGHT", false)

    bagBorderFrames[containerFrame] = border
end

function FreeMyBagUI:SetBagBorderActive(on)
    for i = 1, 7 do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            FreeMyBagUI:CreateBagBorderForFrame(frame)
            local border = bagBorderFrames[frame]
            if on and FreeMyBag.db.bagBorderEnabled then
                border:Show()
            else
                border:Hide()
            end
        end
    end
end

-- ============================================================
-- ---- Central ON/OFF dispatcher called from Core ----
-- ============================================================

function FreeMyBagUI:OnDeleteModeActivated()
    FreeMyBagUI:RefreshDeleteButton()
    FreeMyBagUI:SetScreenBorderActive(true)
    FreeMyBagUI:SetBagBorderActive(true)
    if configFrame and configFrame:IsShown() then
        configFrame.dmToggle:SetState(true)
    end
end

function FreeMyBagUI:OnDeleteModeDeactivated()
    FreeMyBagUI:RefreshDeleteButton()
    FreeMyBagUI:SetScreenBorderActive(false)
    FreeMyBagUI:SetBagBorderActive(false)
    if configFrame and configFrame:IsShown() then
        configFrame.dmToggle:SetState(false)
    end
end

-- Legacy alias kept so nothing else breaks.
function FreeMyBagUI:RefreshDeleteModeToggle()
    if FreeMyBag.deleteMode then
        FreeMyBagUI:OnDeleteModeActivated()
    else
        FreeMyBagUI:OnDeleteModeDeactivated()
    end
end

-- ============================================================
-- ---- Config window ----
-- ============================================================

local configFrame

function FreeMyBagUI:CreateConfigWindow()
    if configFrame then return end

    local W, H = 290, 300

    configFrame = CreateFrame("Frame", "FreeMyBagConfigFrame", UIParent)
    configFrame:SetSize(W, H)
    configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop",  configFrame.StopMovingOrSizing)
    configFrame:Hide()

    local bg = ColorTex(configFrame, "BACKGROUND", 0.10, 0.10, 0.10, 0.95)
    bg:SetAllPoints(configFrame)
    ApplyBorder(configFrame, 0.28, 0.28, 0.28, 0.8)

    -- Title bar
    local titleBar = ColorTex(configFrame, "BORDER", 0.14, 0.14, 0.14, 1.0)
    titleBar:SetPoint("TOPLEFT",  configFrame, "TOPLEFT",  0, 0)
    titleBar:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(22)

    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 8, -5)
    title:SetText("|cffcc3333Free|r|cffccccccMyBag|r  —  Settings")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, configFrame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -3)
    local closeBg = ColorTex(closeBtn, "BACKGROUND", 0.35, 0.10, 0.10, 0.85)
    closeBg:SetAllPoints(closeBtn)
    local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeLbl:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeLbl:SetText("x")
    closeLbl:SetTextColor(0.80, 0.80, 0.80)
    closeBtn:SetScript("OnEnter", function() closeBg:SetVertexColor(0.60, 0.15, 0.15, 0.9) end)
    closeBtn:SetScript("OnLeave", function() closeBg:SetVertexColor(0.35, 0.10, 0.10, 0.85) end)
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)

    local PAD   = 8
    local INNER = W - PAD * 2
    local y     = -28

    -- ---- Section: Delete Mode ----
    local dmLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dmLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", PAD, y)
    dmLabel:SetText("Delete Mode")
    dmLabel:SetTextColor(0.75, 0.75, 0.75)
    y = y - 26

    local dmToggle = MakeToggle(
        configFrame, false,
        "Delete Mode: |cffff4444ON|r",
        "Delete Mode: |cff888888OFF|r",
        INNER, 22, y, PAD,
        function() FreeMyBag:ToggleDeleteMode() end
    )
    configFrame.dmToggle = dmToggle
    y = y - 28

    MakeSep(configFrame, y, PAD) ; y = y - 10

    -- ---- Section: Auto-Delete ----
    local adLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    adLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", PAD, y)
    adLabel:SetText("Auto-Delete")
    adLabel:SetTextColor(0.75, 0.75, 0.75)
    y = y - 22

    local adDesc = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    adDesc:SetPoint("TOPLEFT",  configFrame, "TOPLEFT",  PAD,  y)
    adDesc:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -PAD, y)
    adDesc:SetWordWrap(true)
    adDesc:SetNonSpaceWrap(true)
    adDesc:SetText("Auto-confirms ALL delete popups (both typing DELETE for Uncommon+ and yes/no for Poor/Common). OFF by default.")
    adDesc:SetTextColor(0.50, 0.50, 0.50)
    y = y - 26

    local adToggle = MakeToggle(
        configFrame, false,
        "Auto-Delete: |cff40c040ON|r",
        "Auto-Delete: |cff888888OFF|r",
        INNER, 22, y, PAD,
        function(btn)
            FreeMyBag.db.autoDelete = not FreeMyBag.db.autoDelete
            FreeMyBag_SavedVars = FreeMyBag.db
            btn:SetState(FreeMyBag.db.autoDelete)
        end
    )
    configFrame.adToggle = adToggle
    y = y - 28

    MakeSep(configFrame, y, PAD) ; y = y - 10

    -- ---- Section: Visual Feedback ----
    local vfLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    vfLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", PAD, y)
    vfLabel:SetText("Visual Feedback")
    vfLabel:SetTextColor(0.75, 0.75, 0.75)
    y = y - 26

    -- Screen border toggle
    local sbToggle = MakeToggle(
        configFrame, true,
        "Screen Border: |cff40c040ON|r",
        "Screen Border: |cff888888OFF|r",
        INNER, 22, y, PAD,
        function(btn)
            FreeMyBag.db.screenBorderEnabled = not FreeMyBag.db.screenBorderEnabled
            FreeMyBag_SavedVars = FreeMyBag.db
            btn:SetState(FreeMyBag.db.screenBorderEnabled)
            -- Apply immediately if delete mode is on
            FreeMyBagUI:SetScreenBorderActive(FreeMyBag.deleteMode)
        end
    )
    configFrame.sbToggle = sbToggle
    y = y - 26

    -- Bag border toggle
    local bbToggle = MakeToggle(
        configFrame, true,
        "Bag Border: |cff40c040ON|r",
        "Bag Border: |cff888888OFF|r",
        INNER, 22, y, PAD,
        function(btn)
            FreeMyBag.db.bagBorderEnabled = not FreeMyBag.db.bagBorderEnabled
            FreeMyBag_SavedVars = FreeMyBag.db
            btn:SetState(FreeMyBag.db.bagBorderEnabled)
            FreeMyBagUI:SetBagBorderActive(FreeMyBag.deleteMode)
        end
    )
    configFrame.bbToggle = bbToggle
    y = y - 26

    -- Button pulse toggle
    local bpToggle = MakeToggle(
        configFrame, true,
        "Button Pulse: |cff40c040ON|r",
        "Button Pulse: |cff888888OFF|r",
        INNER, 22, y, PAD,
        function(btn)
            FreeMyBag.db.pulseEnabled = not FreeMyBag.db.pulseEnabled
            FreeMyBag_SavedVars = FreeMyBag.db
            btn:SetState(FreeMyBag.db.pulseEnabled)
            -- Re-sync pulse state immediately
            FreeMyBagUI:RefreshDeleteButton()
        end
    )
    configFrame.bpToggle = bpToggle
end

function FreeMyBagUI:OpenConfig()
    if not configFrame then FreeMyBagUI:CreateConfigWindow() end

    local db = FreeMyBag.db
    configFrame.dmToggle:SetState(FreeMyBag.deleteMode)
    configFrame.adToggle:SetState(db.autoDelete)
    configFrame.sbToggle:SetState(db.screenBorderEnabled)
    configFrame.bbToggle:SetState(db.bagBorderEnabled)
    configFrame.bpToggle:SetState(db.pulseEnabled)

    configFrame:Show()
    configFrame:Raise()
end

function FreeMyBagUI:CloseConfig()
    if configFrame then configFrame:Hide() end
end

function FreeMyBagUI:ToggleConfig()
    if configFrame and configFrame:IsShown() then
        FreeMyBagUI:CloseConfig()
    else
        FreeMyBagUI:OpenConfig()
    end
end

-- ============================================================
-- ---- Delete confirm dialog (Rare+ safety, autoDelete=OFF) ----
-- ============================================================

local deleteConfirmFrame

function FreeMyBagUI:ShowDeleteConfirm(bag, slot, itemName)
    if not deleteConfirmFrame then
        local f = CreateFrame("Frame", "FreeMyBagDeleteConfirm", UIParent)
        f:SetSize(260, 125)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop",  f.StopMovingOrSizing)
        f:Hide()

        local bg = ColorTex(f, "BACKGROUND", 0.10, 0.10, 0.10, 0.95)
        bg:SetAllPoints(f)
        ApplyBorder(f, 0.28, 0.28, 0.28, 0.8)

        -- Title bar
        local titleBar = ColorTex(f, "BORDER", 0.14, 0.14, 0.14, 1.0)
        titleBar:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
        titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        titleBar:SetHeight(22)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -5)
        title:SetText("|cffcc3333Delete|r |cffccccccConfirm|r")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, f)
        closeBtn:SetSize(16, 16)
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -3)
        local closeBg = ColorTex(closeBtn, "BACKGROUND", 0.35, 0.10, 0.10, 0.85)
        closeBg:SetAllPoints(closeBtn)
        local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        closeLbl:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
        closeLbl:SetText("x")
        closeLbl:SetTextColor(0.80, 0.80, 0.80)
        closeBtn:SetScript("OnEnter", function() closeBg:SetVertexColor(0.60, 0.15, 0.15, 0.9) end)
        closeBtn:SetScript("OnLeave", function() closeBg:SetVertexColor(0.35, 0.10, 0.10, 0.85) end)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Item name
        local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, -30)
        nameText:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -30)
        nameText:SetJustifyH("CENTER")
        f._nameText = nameText

        -- Delete button
        local delBtn = CreateFrame("Button", nil, f)
        delBtn:SetSize(85, 22)
        delBtn:SetPoint("BOTTOMLEFT", f, "BOTTOM", -50, 8)
        local delBg = ColorTex(delBtn, "BACKGROUND", 0.55, 0.08, 0.08, 0.85)
        delBg:SetAllPoints(delBtn)
        local delLbl = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        delLbl:SetPoint("CENTER", delBtn, "CENTER", 0, 0)
        delLbl:SetText("Delete")
        delLbl:SetTextColor(0.85, 0.85, 0.85)
        delBtn:SetScript("OnEnter", function() delBg:SetVertexColor(0.75, 0.12, 0.12, 0.9) end)
        delBtn:SetScript("OnLeave", function() delBg:SetVertexColor(0.55, 0.08, 0.08, 0.85) end)
        delBtn:SetScript("OnClick", function()
            PickupContainerItem(f._bag, f._slot)
            if CursorHasItem() then
                DeleteCursorItem()
            end
            f:Hide()
        end)
        ApplyBorder(delBtn, 0.35, 0.05, 0.05, 0.5)

        -- Cancel button
        local canBtn = CreateFrame("Button", nil, f)
        canBtn:SetSize(85, 22)
        canBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOM", 50, 8)
        local canBg = ColorTex(canBtn, "BACKGROUND", 0.15, 0.15, 0.15, 0.85)
        canBg:SetAllPoints(canBtn)
        local canLbl = canBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        canLbl:SetPoint("CENTER", canBtn, "CENTER", 0, 0)
        canLbl:SetText("Cancel")
        canLbl:SetTextColor(0.70, 0.70, 0.70)
        canBtn:SetScript("OnEnter", function() canBg:SetVertexColor(0.25, 0.25, 0.25, 0.9) end)
        canBtn:SetScript("OnLeave", function() canBg:SetVertexColor(0.15, 0.15, 0.15, 0.85) end)
        canBtn:SetScript("OnClick", function() f:Hide() end)
        ApplyBorder(canBtn, 0.20, 0.20, 0.20, 0.5)

        deleteConfirmFrame = f
    end

    deleteConfirmFrame._bag  = bag
    deleteConfirmFrame._slot = slot
    deleteConfirmFrame._nameText:SetText("|cffff4444" .. itemName .. "|r\n\nDelete this item?")
    deleteConfirmFrame:Show()
    deleteConfirmFrame:Raise()
end

-- ============================================================
-- ---- Bootstrap ----
-- ============================================================

function FreeMyBagUI:Create()
    FreeMyBagUI:CreateDeleteButton()
    -- Screen border and bag border frames are created lazily on first activation.
end
