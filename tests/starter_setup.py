ADDON="ProfessionPal"
from pathlib import Path
from lupa import lua51
r=Path(__file__).resolve().parents[1]
def load(seed=""):
 L=lua51.LuaRuntime(unpack_returned_tuples=True)
 L.execute((r/'tests/harness.lua').read_text(encoding='utf-8-sig'))
 L.execute(seed)
 ns=L.table()
 for name in (r/ADDON/(ADDON+'.toc')).read_text().splitlines():
  if name.endswith('.lua'):
   L.eval('function(s,n) return assert(loadstring(s,n)) end')((r/ADDON/name).read_text(encoding='utf-8-sig'),name)(ADDON,ns)
 L.execute('FIRE("PLAYER_LOGIN")')
 return L
L=load()
L.execute("""local p=ProfessionPal
assert(p.db.tracker and p.db.trackerLocked and p.db.trackerHideCombat)
assert(not p.db.trackerButtons and not p.db.harvestAlert and not p.db.harvestGuide and not p.db.autoLearn)
assert(p.settings._h<=620,"settings exceed screen")
""")
L=load('ProfessionPalDB={harvestAlert=true,harvestGuide=true,trackerButtons=true,autoLearn=true,trackerLocked=false,guides={mining={title="Mine"}}}')
L.execute("""local p=ProfessionPal
assert(p.db.autoLearn and p.db.harvestAlert and p.db.trackerButtons,"update changed existing options")
assert(p:StarterSetup());assert(not p.db.autoLearn and not p.db.harvestAlert and p.db.trackerLocked)
assert(p.db.guides.mining.title=="Mine","preset lost imported guide")
assert(p:StarterSetup(true));assert(p.db.autoLearn and p.db.harvestAlert and p.db.trackerButtons)
""")
print('ProfessionPal fresh defaults, bounded options, saved preferences and reversible preset PASS')
