local _, ns = ...
local L = ns.L
local panel, launcher
local rows, entries, pending = {}, {}, {}
local category = "enchants"
local offset = 0
local visibleRows = 8
local refresh

local function label(parent, font, x, y, width)
  local text = parent:CreateFontString(nil, "OVERLAY", font)
  text:SetPoint("TOPLEFT", x, y)
  text:SetWidth(width)
  text:SetJustifyH("LEFT")
  return text
end

local function button(parent, text, width, x, y, callback)
  local b = _G.CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 24)
  b:SetPoint("TOPLEFT", x, y)
  b:SetText(text)
  b:SetScript("OnClick", callback)
  return b
end

local function buildEntries()
  entries = {}
  local index = _G.C_SpecializationInfo.GetSpecialization()
  local id, name
  if index then id, name = _G.C_SpecializationInfo.GetSpecializationInfo(index) end
  panel.spec:SetText(name or L.spec)
  local data = id and ns.Data.specs[id]
  data = data and data[_G.WhatToBuyDB.mode]
  if not data then return end
  local function append(group, items)
    if not items then return end
    if items.id then items = { items } end
    for _, item in ipairs(items) do
      if item.id and item.id > 0 then
        entries[#entries + 1] = { item = item, group = L[group] }
      end
    end
  end
  if category == "gems" then
    append("epicGems", data.epicGems)
    append("gems", data.gems)
  else
    local groups = {}
    for group in pairs(data[category] or {}) do groups[#groups + 1] = group end
    table.sort(groups)
    for _, group in ipairs(groups) do append(group, data[category][group]) end
  end
end

refresh = function()
  if not panel or not panel:IsShown() then return end
  buildEntries()
  offset = math.max(0, math.min(offset, #entries - visibleRows))
  panel.mode:SetText(L[_G.WhatToBuyDB.mode])
  panel.provider:SetText(_G.WhatToBuyDB.provider == "native" and L.native or L.auto)
  for key, tab in pairs(panel.tabs) do
    if key == category then tab:LockHighlight() else tab:UnlockHighlight() end
  end
  panel.empty:SetText(#entries == 0 and L.empty or "")
  panel.status:SetText(ns.IsAuctionOpen() and "" or L.open)
  panel.page:SetText(#entries > 0 and string.format("%d–%d / %d", offset + 1, math.min(offset + visibleRows, #entries), #entries) or "")
  panel.previous:SetEnabled(offset > 0)
  panel.next:SetEnabled(offset + visibleRows < #entries)
  for i, row in ipairs(rows) do
    local entry = entries[offset + i]
    row.item = entry and entry.item or nil
    row:Hide()
    if entry then
      local item = entry.item
      local name, _, quality, _, _, _, _, _, _, icon = _G.C_Item.GetItemInfo(item.id)
      row.title:SetText(name or item.name or L.loading)
      local color = quality and _G.ITEM_QUALITY_COLORS[quality]
      row.title:SetTextColor(color and color.r or 0.84, color and color.g or 0.75, color and color.b or 0.64)
      row.icon:SetTexture(icon or 134400)
      row.detail:SetText(entry.group .. "  ·  " .. string.format(L.bags, _G.C_Item.GetItemCount(item.id)))
      row.search:SetEnabled(name ~= nil and ns.IsAuctionOpen())
      if not name and not pending[item.id] then
        pending[item.id] = true
        _G.C_Item.RequestLoadItemDataByID(item.id)
      end
      row:Show()
    end
  end
end

local function createPanel()
  if panel then return end
  panel = _G.CreateFrame("Frame", "WhatToBuyFrame", _G.UIParent, "BackdropTemplate")
  panel:Hide()
  panel:SetSize(420, 614)
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
  panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 32,
    edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  panel:SetBackdropColor(0.12, 0.11, 0.10, 1)
  panel:SetBackdropBorderColor(0.60, 0.49, 0.32, 1)
  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(32, 32)
  icon:SetPoint("TOPLEFT", 17, -16)
  icon:SetTexture("Interface\\AddOns\\WhatToBuy\\Media\\Icon.tga")
  label(panel, "GameFontNormalLarge", 59, -17, 290):SetText("What To Buy")
  panel.spec = label(panel, "GameFontHighlightSmall", 59, -38, 290)
  local close = _G.CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -3, -3)
  close:SetScript("OnClick", function() panel:Hide() end)
  panel.mode = button(panel, "", 118, 18, -65, function()
    _G.WhatToBuyDB.mode = _G.WhatToBuyDB.mode == "raid" and "mythicplus" or "raid"
    offset = 0
    refresh()
  end)
  panel.provider = button(panel, "", 90, 308, -65, function()
    _G.WhatToBuyDB.provider = _G.WhatToBuyDB.provider == "native" and "auto" or "native"
    refresh()
  end)
  panel.tabs = {}
  for i, key in ipairs({ "enchants", "gems", "consumables" }) do
    panel.tabs[key] = button(panel, L[key], 122, 18 + (i - 1) * 129, -101, function()
      category, offset = key, 0
      refresh()
    end)
  end
  for i = 1, visibleRows do
    local row = _G.CreateFrame("Frame", nil, panel)
    row:SetSize(380, 48)
    row:SetPoint("TOPLEFT", 18, -137 - (i - 1) * 49)
    row:EnableMouse(true)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.8, 0.7, 0.5, i % 2 == 0 and 0.055 or 0.025)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("LEFT", 5, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.title = label(row, "GameFontHighlight", 46, -6, 245)
    row.title:SetHeight(17)
    row.title:SetWordWrap(false)
    row.detail = label(row, "GameFontDisableSmall", 46, -27, 245)
    row.search = button(row, L.search, 76, 302, -12, function()
      if row.item then panel.status:SetText(ns.Search(row.item.id) or "") end
    end)
    local function tooltip(owner)
      if not row.item then return end
      _G.GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
      _G.GameTooltip:SetItemByID(row.item.id)
      _G.GameTooltip:AddLine(string.format(L.popularity, row.item.popularity or 0), 0.84, 0.75, 0.64)
      _G.GameTooltip:Show()
    end
    row:SetScript("OnEnter", tooltip)
    row.search:SetScript("OnEnter", tooltip)
    row:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
    row.search:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
    rows[i] = row
  end
  panel.empty = label(panel, "GameFontHighlight", 24, -170, 368)
  panel.previous = button(panel, "<", 32, 18, -535, function() offset = offset - visibleRows; refresh() end)
  panel.next = button(panel, ">", 32, 366, -535, function() offset = offset + visibleRows; refresh() end)
  panel.page = label(panel, "GameFontHighlightSmall", 145, -542, 130)
  panel.page:SetJustifyH("CENTER")
  panel.status = label(panel, "GameFontRedSmall", 18, -565, 380)
  label(panel, "GameFontDisableSmall", 18, -590, 380):SetText(string.format(L.source, ns.Data.generatedAtUtc:sub(1, 10)))
  panel:EnableMouseWheel(true)
  panel:SetScript("OnMouseWheel", function(_, delta) offset = offset - delta; refresh() end)
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
  elseif event == "AUCTION_HOUSE_SHOW" then
    if not launcher and _G.AuctionHouseFrame then
      launcher = button(_G.AuctionHouseFrame, "What To Buy", 130, 0, 28, toggle)
    end
    refresh()
  elseif event == "AUCTION_HOUSE_CLOSED" then
    if panel then panel:Hide() end
  elseif event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
    if pending[arg] == true then pending[arg] = "received"; refresh() end
  elseif event ~= "PLAYER_SPECIALIZATION_CHANGED" or arg == "player" then
    refresh()
  end
end)
