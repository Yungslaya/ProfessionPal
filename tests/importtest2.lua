local P = ProfessionPal
local names = {}
for n in pairs(GUIDES) do names[#names + 1] = n end
table.sort(names)
local function sig(g)
  local t = {}
  for _, s in ipairs(g.steps) do
    local m = {}
    for _, x in ipairs(s.mats or {}) do m[#m+1] = x[2] .. " " .. x[3] .. (type(x[1]) == "number" and "" or "(?)") end
    t[#t+1] = s.from .. "-" .. s.to .. " " .. s.text .. (s.crafts and (" x" .. s.crafts) or " x?") .. " [" .. table.concat(m, ", ") .. "]"
  end
  return t
end
local ref = {}
for _, n in ipairs(names) do
  local g, why = P.ParseGuide(GUIDES[n])
  if not g then print(n .. ": FAILED " .. why) else
    local s = sig(g)
    local base = n:gsub("_wow%d$", "")
    if n == base then ref[base] = table.concat(s, "\n") end
    local same = (ref[base] == table.concat(s, "\n")) and "SAME as browser copy" or "DIFFERENT"
    print(string.format("%-26s %-14s %2d steps  title=%s  %s", n, tostring(g.prof), #g.steps, g.title, n == base and "" or same))
    if n ~= base and same == "DIFFERENT" then for i = 1, math.min(4, #s) do print("      " .. s[i]) end end
    if n == "wh_tailoring_wow4" then for i = 1, 3 do print("      " .. s[i]) end end
  end
end
