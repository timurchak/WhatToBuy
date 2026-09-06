local _, ns = ...
local L = ns.L

function ns.IsAuctionOpen()
  return _G.AuctionHouseFrame and _G.AuctionHouseFrame:IsShown()
end

function ns.Search(itemID)
  if not ns.IsAuctionOpen() then return L.open end
  if _G.InCombatLockdown() then return L.combat end
  local name = _G.C_Item.GetItemInfo(itemID)
  if not name then
    _G.C_Item.RequestLoadItemDataByID(itemID)
    return L.loading
  end
  if not _G.C_AuctionHouse.IsThrottledMessageSystemReady() then return L.busy end
  local api = _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1
  if _G.WhatToBuyDB.provider ~= "native" and api and api.MultiSearchExact then
    local ok = pcall(api.MultiSearchExact, "WhatToBuy", { name })
    if ok then return end
  end
  local frame = _G.AuctionHouseFrame
  if not frame.SearchBar or not frame.SendBrowseQuery then return L.failed end
  local ok = pcall(function()
    frame:GetCategoriesList():SetSelectedCategory(nil)
    frame:SetDisplayMode(_G.AuctionHouseFrameDisplayMode.Buy)
    frame.SearchBar.FilterButton:Reset()
    frame.SearchBar:SetSearchText(name)
    frame.SearchBar:StartSearch()
  end)
  if not ok then return L.failed end
end
