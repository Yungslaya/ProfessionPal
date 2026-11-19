--[[ ProfessionPal - when each guide recipe turns yellow, green and gray (WoW: Forever)
  SOURCE (read 2026-11-18): Wowhead Forever profession spell lists, "colors" of each recipe
    https://www.wowhead.com/forever/spells/professions/<profession>
    https://www.wowhead.com/forever/spells/secondary-skills/<first-aid|cooking>
  Row: [recipe spell ID] = { yellow at, green at, gray at }
  The chance uses the classic rule: always while orange, never once gray, and in between
  (gray - your skill) / (gray - yellow). Forever has not published its own rule, so the
  number is shown as "about".
]]
local _, PP = ...

PP.SkillColors = {
    [2660]={15,35,55}, [3320]={45,65,85}, [3323]={75,95,115}, [2666]={85,105,125}, [3326]={50,70,90}, [2668]={120,135,150},
    [2672]={125,140,155}, [9985]={155,170,185}, [3337]={100,112,125}, [3501]={165,177,190}, [7223]={185,197,210}, [9928]={200,210,220},
    [9931]={205,215,225}, [9959]={225,235,245}, [9961]={225,235,245}, [10001]={230,242,255}, [9968]={230,240,250}, [16640]={230,232,235},
    [19669]={250,255,260}, [10013]={255,267,280}, [1252365]={290,300,310}, [16969]={275,287,300}, [1245246]={10,12,15}, [2331]={65,85,105},
    [2334]={80,100,120}, [7183]={55,75,95}, [3171]={120,140,160}, [3173]={145,165,185}, [3452]={180,200,220}, [11449]={205,225,245},
    [11448]={220,240,260}, [11459]={240,260,280}, [11460]={245,265,285}, [17553]={275,295,315}, [1231583]={290,310,330}, [7421]={5,7,10},
    [7420]={70,90,110}, [7418]={20,22,25}, [7457]={100,120,140}, [7771]={110,130,150}, [7795]={130,150,170}, [13501]={155,175,195},
    [13628]={175,195,215}, [13637]={180,200,220}, [13661]={200,220,240}, [13702]={220,240,260}, [13746]={225,245,265}, [13815]={230,250,270},
    [13836]={235,255,275}, [13858]={240,260,280}, [25127]={260,270,280}, [20017]={285,305,325}, [20015]={305,325,345}, [20051]={310,330,350},
    [3918]={20,30,40}, [3922]={45,52,60}, [3923]={60,75,90}, [7430]={70,80,90}, [3929]={85,90,95}, [3931]={90,97,105},
    [3973]={110,125,140}, [3938]={105,130,155}, [3978]={135,147,160}, [3945]={125,135,145}, [3942]={125,150,175}, [3953]={145,170,195},
    [3955]={175,187,200}, [12585]={175,185,195}, [3962]={175,195,215}, [12589]={195,215,235}, [12591]={200,220,240}, [12599]={215,235,255},
    [12603]={215,235,255}, [12619]={235,255,275}, [19788]={250,255,260}, [19791]={280,290,300}, [19795]={295,305,315}, [2152]={30,45,60},
    [3816]={50,60,70}, [3756]={70,85,100}, [3763]={85,100,115}, [9068]={100,115,130}, [20648]={75,80,85}, [3817]={90,97,105},
    [3766]={125,137,150}, [20649]={125,130,135}, [3818]={135,140,145}, [3780]={145,155,165}, [7151]={170,180,190}, [7156]={185,195,205},
    [10487]={195,205,215}, [10507]={200,210,220}, [10548]={225,235,245}, [19047]={225,230,235}, [19049]={255,265,275}, [19048]={255,260,270},
    [19088]={290,300,310}, [8776]={50,67,85}, [2963]={25,37,50}, [2964]={70,77,85}, [2402]={80,97,115}, [3839]={110,115,120},
    [8760]={130,135,140}, [3871]={145,150,155}, [3865]={145,147,150}, [8791]={170,180,190}, [8799]={180,190,200}, [12053]={195,210,225},
    [12065]={205,220,235}, [18402]={225,240,255}, [18409]={240,255,270}, [18423]={250,265,280}, [1257487]={265,280,295}, [23662]={270,285,300},
    [1297120]={290,292,295}, [1297121]={295,297,300}, [1297122]={295,297,300}, [2657]={25,47,70}, [3304]={0,65,75}, [2659]={65,90,115},
    [2658]={100,112,125}, [3307]={130,135,140}, [3308]={170,177,185}, [3569]={165,165,165}, [10097]={175,175,175}, [10098]={230,230,230},
    [16153]={250,250,250}, [14891]={230,230,230}, [2540]={45,65,85}, [2541]={90,110,130}, [2546]={120,140,160}, [3376]={170,190,210},
    [15855]={215,235,255}, [22480]={265,285,305}, [3275]={30,45,60}, [3276]={50,75,100}, [3277]={80,115,150}, [3278]={115,150,185},
    [7928]={150,180,210}, [7929]={180,210,240}, [10840]={210,240,270}, [10841]={240,270,300}, [18629]={260,290,320}, [18630]={290,320,350},
}

-- Chance (0-100) that one craft of this step gives a skill point, and its color name.
-- nil when the recipe's numbers are not known.
function PP:SkillUpChance(def, st, skill)
    local rec = def and st and self.StepRecipe and self:StepRecipe(def, st)
    local c = rec and PP.SkillColors[rec.id]
    if not (c and type(skill) == "number") then return nil end
    local yellow, green, gray = c[1], c[2], c[3]
    if skill >= gray then return 0, "gray" end
    if skill < yellow then return 100, "orange" end
    local pct = math.floor((gray - skill) / (gray - yellow) * 100 + 0.5)
    return pct, skill < green and "yellow" or "green"
end

-- The edges of the skill bar for this step: { start, yellow, green, gray, end }, or nil.
-- It starts where the recipe is learned (or the step begins) and runs a little past gray.
function PP:SkillRange(def, st)
    local rec = def and st and self.StepRecipe and self:StepRecipe(def, st)
    local c = rec and PP.SkillColors[rec.id]
    if not c then return nil end
    local yellow, green, gray = c[1], c[2], c[3]
    local start = math.min(rec.at or yellow, st.from or yellow, yellow)
    local tail = math.max(5, math.floor((gray - start) * 0.15 + 0.5))
    if gray + tail <= start then return nil end
    return { start, yellow, green, gray, gray + tail }
end

local HEX = { orange = "ff8c26", yellow = "ffdb40", green = "40d95a", gray = "9a9a9a" }
-- Just the value, colored like the recipe is in the game: "always", "about 60%", "none (gray)".
function PP:SkillUpValue(def, st, skill)
    local pct, color = self:SkillUpChance(def, st, skill)
    if not pct then return nil end
    local words = pct >= 100 and "always" or pct <= 0 and "none (gray)" or ("about " .. pct .. "%")
    return "|cff" .. ({ orange = "ff8c26", yellow = "ffdb40", green = "40d95a", gray = "9a9a9a" })[color] .. words .. "|r"
end

-- "Skill-up: always" / "about 60%" / "none (gray)", colored like the recipe is in the game.
function PP:SkillUpText(def, st, skill)
    local pct, color = self:SkillUpChance(def, st, skill)
    if not pct then return nil end
    local words = pct >= 100 and "always" or pct <= 0 and "none (gray)" or ("about " .. pct .. "%")
    return "|cff" .. HEX[color] .. "Skill-up: " .. words .. "|r"
end
