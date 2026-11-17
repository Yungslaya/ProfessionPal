--[[ ProfessionPal - minimap button
  Left-click opens the guide (same as /prof), right-click opens Settings.
  Drag it around the edge of the minimap. Hide it in Settings or with /prof minimap.
  It hides itself while the gathering HUD is up, so it never floats in the middle of the screen.
]]
local _, PP = ...

local button
local RADIUS_PAD = 10   -- how far outside the minimap's edge the button sits

local function place()
    if not button or not Minimap then return end
    local angle = math.rad(PP.db and PP.db.minimapAngle or 200)
    local radius = (Minimap:GetWidth() or 140) / 2 + RADIUS_PAD
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function onDragUpdate()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    PP.db.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
    place()
end

local function build()
    if button or not Minimap then return end
    button = CreateFrame("Button", "ProfessionPalMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\Trade_Mining")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then
            if PP.ToggleSettings and PP.settings then PP:ToggleSettings() end
        elseif PP.Toggle then
            PP:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onDragUpdate) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ProfessionPal")
        GameTooltip:AddLine("Left-click: open the guide", 1, 1, 1)
        GameTooltip:AddLine("Right-click: settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: move this button", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Shows or hides the button from the saved setting and the HUD state.
function PP:MinimapButtonUpdate()
    if not self.db then return end
    build()
    if not button then return end
    local hud = self.GatherHUDOn and self:GatherHUDOn()
    if self.db.minimapButton and not hud then
        place()
        button:Show()
    else
        button:Hide()
    end
end

-- /prof minimap: turn the button on or off.
function PP:MinimapButtonCommand()
    if not self.db then return end
    self.db.minimapButton = not self.db.minimapButton
    self:MinimapButtonUpdate()
    -- keep the Settings checkbox in step if Settings is open
    for _, check in ipairs(self.settings and self.settings.checks or {}) do
        if check.refresh then check:refresh() end
    end
    self:Print(self.db.minimapButton and "Minimap button shown." or "Minimap button hidden. Type /prof minimap to bring it back.")
end

-- Follow the gathering HUD on and off.
if PP.SetGatherHUD then
    hooksecurefunc(PP, "SetGatherHUD", function() PP:MinimapButtonUpdate() end)
end

-- First login after install or update: say once how to open the guide.
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    C_Timer.After(0, function()
        if not PP.db then return end
        PP:MinimapButtonUpdate()
        if not PP.db.toldHowToOpen then
            PP.db.toldHowToOpen = true
            PP:Print("Type /prof or click the minimap button to open the guide.")
        end
    end)
end)
