local _, ns = ...
local L = ns.L
local panel, launcher
local rows, headers, pending, collapsed = {}, {}, {}, {}
local category = "enchants"
local refresh
local groupOrder = {
  enchants = { "Main-Hand", "Off-Hand", "Head", "Shoulders", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet", "Rings" },
  gems = { "epicGems", "gems" },
  consumables = { "Flask", "Food Buff", "Combat Potion", "Health Potion", "Weapon Buff" },
}

local function label(parent, font, x, y, width)
  local text = parent:CreateFontString(nil, "OVERLAY", font)
  text:SetPoint("TOPLEFT", x, y)
  text:SetWidth(width)
  text:SetJustifyH("LEFT")
  return text
end

local function surface(frame, r, g, b)
  frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  frame:SetBackdropColor(r, g, b, 1)
  frame:SetBackdropBorderColor(0.34, 0.29, 0.21, 1)
end

local function button(parent, text, width, x, y, callback)
  local b = _G.CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(width, 28)
  b:SetPoint("TOPLEFT", x, y)
  surface(b, 0.15, 0.14, 0.12)
  local textRegion = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  textRegion:SetPoint("CENTER", 0, 0)
  textRegion:SetWidth(width - 12)
  b:SetFontString(textRegion)
  b:SetNormalFontObject("GameFontNormal")
  b:SetHighlightFontObject("GameFontHighlight")
  b:SetDisabledFontObject("GameFontDisable")
  b:SetText(text)
  local highlight = b:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetPoint("TOPLEFT", 4, -4)
  highlight:SetPoint("BOTTOMRIGHT", -4, 4)
  highlight:SetColorTexture(0.85, 0.70, 0.40, 0.12)
  b:SetScript("OnClick", callback)
  return b
end

local function selectButton(b, selected)
  b:SetBackdropColor(selected and 0.27 or 0.15, selected and 0.22 or 0.14, selected and 0.14 or 0.12, 1)
  b:SetBackdropBorderColor(selected and 0.77 or 0.34, selected and 0.59 or 0.29, selected and 0.30 or 0.21, 1)
end

local function getData()
  local index = _G.C_SpecializationInfo.GetSpecialization()
  local id, name
  if index then id, name = _G.C_SpecializationInfo.GetSpecializationInfo(index) end
  panel.spec:SetText(name or L.spec)
  local data = id and ns.Data.specs[id]
  return data and data[_G.WhatToBuyDB.mode]
end

local function createRow(index)
  local row = _G.CreateFrame("Frame", nil, panel.content, "BackdropTemplate")
  row:SetSize(410, 64)
  surface(row, 0.115, 0.108, 0.095)
  row:SetBackdropBorderColor(0.22, 0.20, 0.16, 1)
  row:EnableMouse(true)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(36, 36)
  row.icon:SetPoint("LEFT", 10, 0)
  row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  row.title = label(row, "GameFontHighlight", 56, -9, 257)
  row.title:SetHeight(29)
  row.title:SetWordWrap(true)
  row.detail = label(row, "GameFontDisableSmall", 56, -43, 170)
  row.popularity = label(row, "GameFontDisableSmall", 232, -43, 78)
  row.popularity:SetJustifyH("RIGHT")
  row.search = button(row, L.search, 78, 321, -18, function()
    if row.item then panel.status:SetText(ns.Search(row.item.id) or "") end
  end)
  local function tooltip(owner)
    if not row.item then return end
    _G.GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    _G.GameTooltip:SetItemByID(row.item.id)
    _G.GameTooltip:AddLine(string.format(L.popularity, row.item.popularity or 0), 0.84, 0.75, 0.64)
    if not ns.IsAuctionOpen() then _G.GameTooltip:AddLine(L.open, 0.84, 0.75, 0.64) end
    _G.GameTooltip:Show()
  end
  row:SetScript("OnEnter", tooltip)
  row.search:SetScript("OnEnter", tooltip)
  row:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
  row.search:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
  rows[index] = row
  return row
end

local function populateRow(row, item, y)
  row.item = item
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", 0, -y)
  local name, _, quality, _, _, _, _, _, _, icon = _G.C_Item.GetItemInfo(item.id)
  row.title:SetText(name or item.name or L.loading)
  local color = quality and _G.ITEM_QUALITY_COLORS[quality]
  row.title:SetTextColor(color and color.r or 0.84, color and color.g or 0.75, color and color.b or 0.64)
  row.icon:SetTexture(icon or 134400)
  row.detail:SetText(string.format(L.bags, _G.C_Item.GetItemCount(item.id)))
  row.popularity:SetText(string.format("%s%%", item.popularity or 0))
  row.search:SetEnabled(name ~= nil and ns.IsAuctionOpen())
  if not name and not pending[item.id] then
    pending[item.id] = true
    _G.C_Item.RequestLoadItemDataByID(item.id)
  end
  row:Show()
end

local function groupHeader(index, group, count, y)
  local header = headers[index]
  if not header then
    header = _G.CreateFrame("Button", nil, panel.content)
    header:SetSize(410, 30)
    header.title = label(header, "GameFontNormal", 20, -8, 330)
    header.count = label(header, "GameFontDisableSmall", 357, -9, 40)
    header.count:SetJustifyH("RIGHT")
    header.arrow = header:CreateTexture(nil, "ARTWORK")
    header.arrow:SetSize(14, 14)
    header.arrow:SetPoint("LEFT", 0, 0)
    local line = header:CreateTexture(nil, "BACKGROUND")
    line:SetColorTexture(0.55, 0.43, 0.25, 0.35)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    header:SetScript("OnClick", function()
      collapsed[header.key] = not collapsed[header.key]
      refresh()
    end)
    headers[index] = header
  end
  header.key = category .. ":" .. group
  header.title:SetText(L[group])
  header.count:SetText(count)
  header.arrow:SetTexture(collapsed[header.key] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
  header:ClearAllPoints()
  header:SetPoint("TOPLEFT", 0, -y)
  header:Show()
  return collapsed[header.key]
end

refresh = function()
  if not panel or not panel:IsShown() then return end
  local data = getData()
  local groups = category == "gems" and data or data and data[category]
  panel.provider:SetText(_G.WhatToBuyDB.provider == "native" and L.native or L.auto)
  for key, tab in pairs(panel.tabs) do selectButton(tab, key == category) end
  for key, tab in pairs(panel.modes) do selectButton(tab, key == _G.WhatToBuyDB.mode) end
  for _, row in ipairs(rows) do row.item = nil; row:Hide() end
  for _, header in ipairs(headers) do header:Hide() end
  local ordered, seen = {}, {}
  for _, group in ipairs(groupOrder[category]) do
    ordered[#ordered + 1], seen[group] = group, true
  end
  local extra = {}
  if category ~= "gems" then
    for group in pairs(groups or {}) do
      if not seen[group] then extra[#extra + 1] = group end
    end
  end
  table.sort(extra)
  for _, group in ipairs(extra) do ordered[#ordered + 1] = group end
  local y, rowIndex, headerIndex, total = 0, 0, 0, 0
  for _, group in ipairs(ordered) do
    local items = groups and groups[group]
    if items and items.id then items = { items } end
    if items and #items > 0 then
      headerIndex = headerIndex + 1
      total = total + #items
      local closed = groupHeader(headerIndex, group, #items, y)
      y = y + 36
      if not closed then
        for _, item in ipairs(items) do
          if item.id and item.id > 0 then
            rowIndex = rowIndex + 1
            populateRow(rows[rowIndex] or createRow(rowIndex), item, y)
            y = y + 68
          end
        end
      end
      y = y + 12
    end
  end
  panel.content:SetHeight(math.max(y, 1))
  panel.scroll:UpdateScrollChildRect()
  panel.scroll:SetVerticalScroll(math.min(panel.scroll:GetVerticalScroll(), math.max(0, y - panel.scroll:GetHeight())))
  panel.empty:SetText(total == 0 and L.empty or "")
  panel.status:SetText(ns.IsAuctionOpen() and "" or L.open)
end

local function createPanel()
  if panel then return end
  panel = _G.CreateFrame("Frame", "WhatToBuyFrame", _G.UIParent, "BackdropTemplate")
  panel:Hide()
  panel:SetSize(462, 630)
  panel:SetScale(math.min(1, _G.UIParent:GetHeight() / 650))
  if ns.IsAuctionOpen() then
    panel:SetPoint("TOPLEFT", _G.AuctionHouseFrame, "TOPRIGHT", 8, 0)
  else
    panel:SetPoint("CENTER", 0, 0)
  end
  panel:SetFrameStrata("DIALOG")
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  surface(panel, 0.065, 0.060, 0.052)
  panel:SetBackdropBorderColor(0.58, 0.46, 0.29, 1)
  local banner = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
  banner:SetPoint("TOPLEFT", 5, -5)
  banner:SetPoint("TOPRIGHT", -5, -5)
  banner:SetHeight(60)
  banner:SetColorTexture(0.14, 0.12, 0.085, 1)
  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(38, 38)
  icon:SetPoint("TOPLEFT", 17, -15)
  icon:SetTexture("Interface\\AddOns\\WhatToBuy\\Media\\Icon.tga")
  label(panel, "GameFontNormalLarge", 65, -17, 320):SetText("What To Buy")
  panel.spec = label(panel, "GameFontHighlightSmall", 65, -40, 320)
  local close = _G.CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -3, -3)
  close:SetScript("OnClick", function() panel:Hide() end)
  panel.modes = {}
  for i, mode in ipairs({ "mythicplus", "raid" }) do
    panel.modes[mode] = button(panel, L[mode], 94, 18 + (i - 1) * 99, -76, function()
      _G.WhatToBuyDB.mode = mode
      panel.scroll:SetVerticalScroll(0)
      refresh()
    end)
  end
  panel.provider = button(panel, "", 130, 311, -76, function()
    _G.WhatToBuyDB.provider = _G.WhatToBuyDB.provider == "native" and "auto" or "native"
    refresh()
  end)
  panel.tabs = {}
  for i, key in ipairs({ "enchants", "gems", "consumables" }) do
    panel.tabs[key] = button(panel, L[key], 137, 18 + (i - 1) * 143, -117, function()
      category = key
      panel.scroll:SetVerticalScroll(0)
      refresh()
    end)
  end
  panel.scroll = _G.CreateFrame("ScrollFrame", "WhatToBuyScrollFrame", panel, "UIPanelScrollFrameTemplate")
  panel.scroll:SetPoint("TOPLEFT", 18, -160)
  panel.scroll:SetPoint("BOTTOMRIGHT", -34, 62)
  panel.content = _G.CreateFrame("Frame", nil, panel.scroll)
  panel.content:SetSize(410, 1)
  panel.scroll:SetScrollChild(panel.content)
  panel.scroll:EnableMouseWheel(true)
  panel.scroll:SetScript("OnMouseWheel", function(self, delta)
    self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 44)))
  end)
  panel.empty = label(panel, "GameFontHighlight", 28, -180, 390)
  panel.status = label(panel, "GameFontHighlightSmall", 18, -584, 424)
  label(panel, "GameFontDisableSmall", 18, -608, 424):SetText(string.format(L.source, ns.Data.generatedAtUtc:sub(1, 10)))
  panel:SetScript("OnShow", refresh)
  panel:SetScript("OnHide", function() _G.GameTooltip:Hide() end)
  _G.UISpecialFrames[#_G.UISpecialFrames + 1] = "WhatToBuyFrame"
end

local function toggle()
  createPanel()
  panel:SetShown(not panel:IsShown())
end

local events = _G.CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED",
  "PLAYER_SPECIALIZATION_CHANGED", "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT", "BAG_UPDATE_DELAYED" }) do
  events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, arg)
  if event == "PLAYER_LOGIN" then
    if type(_G.WhatToBuyDB) ~= "table" then _G.WhatToBuyDB = {} end
    local db = _G.WhatToBuyDB
    db.mode = db.mode == "raid" and "raid" or "mythicplus"
    db.provider = db.provider == "native" and "native" or "auto"
    _G.SLASH_WHATTOBUY1 = "/wtb"
    _G.SlashCmdList.WHATTOBUY = toggle
    if _G.AddonCompartmentFrame then
      _G.AddonCompartmentFrame:RegisterAddon({ text = "What To Buy",
        icon = "Interface\\AddOns\\WhatToBuy\\Media\\Icon.tga", func = toggle })
    end
  elseif event == "AUCTION_HOUSE_SHOW" then
    if not launcher and _G.AuctionHouseFrame then
      launcher = button(_G.AuctionHouseFrame, "What To Buy", 130, 0, 32, toggle)
    end
    refresh()
  elseif event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
    if pending[arg] == true then pending[arg] = "received"; refresh() end
  elseif event ~= "PLAYER_SPECIALIZATION_CHANGED" or arg == "player" then
    refresh()
  end
end)
