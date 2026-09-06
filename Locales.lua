local _, ns = ...
local ru = _G.GetLocale() == "ruRU"
ns.L = ru and {
  enchants = "Чанты", gems = "Камни", consumables = "Расходники",
  search = "Найти", raid = "Рейд", mythicplus = "Mythic+",
  open = "Откройте аукцион для поиска", loading = "Загрузка предмета…",
  empty = "Нет данных для текущей специализации", busy = "Аукцион занят. Повторите поиск.",
  failed = "Поиск недоступен. Попробуйте стандартный аукцион.",
  bags = "В сумках: %d", popularity = "Популярность: %s%%", combat = "Поиск недоступен в бою",
  auto = "Авто", native = "WoW", source = "Данные: %s", spec = "Специализация не выбрана",
  ["Main-Hand"] = "Оружие", ["Off-Hand"] = "Левая рука", Head = "Голова",
  Shoulder = "Плечи", Back = "Плащ", Chest = "Грудь", Wrist = "Запястья",
  Hands = "Кисти рук", Waist = "Пояс", Legs = "Ноги", Feet = "Ступни",
  Ring = "Кольца", Rings = "Кольца", Shoulders = "Плечи", Neck = "Шея", Flask = "Настой", ["Food Buff"] = "Еда",
  ["Health Potion"] = "Зелье здоровья", ["Weapon Buff"] = "Масло / точило",
  ["Combat Potion"] = "Боевое зелье", epicGems = "Особые камни",
} or {
  enchants = "Enchants", gems = "Gems", consumables = "Consumables",
  search = "Search", raid = "Raid", mythicplus = "Mythic+",
  open = "Open the auction house to search", loading = "Loading item…",
  empty = "No data for your current specialization", busy = "Auction house busy. Try again.",
  failed = "Search unavailable. Try the default auction house.",
  bags = "In bags: %d", popularity = "Popularity: %s%%", combat = "Cannot search in combat",
  auto = "Auto", native = "WoW", source = "Data: %s", spec = "No specialization selected",
  epicGems = "Unique gems",
}
setmetatable(ns.L, { __index = function(_, key) return key end })
