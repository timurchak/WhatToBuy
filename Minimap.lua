local _, ns = ...
local icon = _G.LibStub("LibDBIcon-1.0")
local launcher = _G.LibStub("LibDataBroker-1.1"):NewDataObject("WhatToBuy", {
  type = "launcher",
  text = "What To Buy",
  icon = "Interface\\AddOns\\WhatToBuy\\Media\\Icon.tga",
  OnClick = function(_, mouseButton)
    if mouseButton == "LeftButton" then ns.Toggle() end
  end,
  OnTooltipShow = function(tooltip)
    tooltip:AddLine("What To Buy", 1, 0.82, 0)
    tooltip:AddLine(ns.L.minimapOpen, 0.84, 0.75, 0.64)
    tooltip:AddLine(ns.L.minimapDrag, 0.65, 0.65, 0.65)
  end,
})

local loader = _G.CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
  self:UnregisterAllEvents()
  if type(_G.WhatToBuyDB) ~= "table" then _G.WhatToBuyDB = {} end
  if type(_G.WhatToBuyDB.minimap) ~= "table" then
    _G.WhatToBuyDB.minimap = { hide = false, minimapPos = 225 }
  end
  if not icon:IsRegistered("WhatToBuy") then
    icon:Register("WhatToBuy", launcher, _G.WhatToBuyDB.minimap)
  end
end)
