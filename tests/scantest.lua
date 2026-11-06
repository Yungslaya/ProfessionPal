local P = ProfessionPal
C_TradeSkillUI.GetAllRecipeIDs = function() return { 1, 2 } end
C_TradeSkillUI.GetRecipeInfo = function(id) return id == 1 and { learned = true, name = "Fine Leather Tunic" } or { learned = false, name = "Hillman's Belt" } end
C_TradeSkillUI.GetRecipeSchematic = function(id) return { reagentSlotSchematics = {
  { reagents = { { itemID = 2319 } }, quantityRequired = 8, required = true },
  { reagents = { { itemID = 2321 } }, quantityRequired = 2 },
  { reagents = { { itemID = 5555 } }, quantityRequired = 1, required = false } } } end
FIRE("TRADE_SKILL_SHOW")
for name, m in pairs(P.db.recipeMats) do local t = {} for _, x in ipairs(m) do t[#t+1] = x[2] .. "x" .. x[1] end print(name, table.concat(t, ", ")) end
print("knows tunic:", P:KnowsCraft("Fine Leather Tunic"), " knows belt:", P:KnowsCraft("Hillman's Belt"))
