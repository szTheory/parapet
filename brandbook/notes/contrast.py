def lin(c):
    c = c/255.0
    return c/12.92 if c <= 0.03928 else ((c+0.055)/1.055)**2.4
def L(hexs):
    h = hexs.lstrip('#')
    r,g,b = int(h[0:2],16),int(h[2:4],16),int(h[4:6],16)
    return 0.2126*lin(r)+0.7152*lin(g)+0.0722*lin(b)
def ratio(fg,bg):
    a,b = L(fg)+0.05, L(bg)+0.05
    return round((max(a,b)/min(a,b)),2)

pairs = [
 ("Parapet Black on Limestone","#101820","#F8F4EC","body text / main"),
 ("Parapet Black on Mortar","#101820","#EAE2D4","text on cards"),
 ("Parapet Black on Stone","#101820","#D8D0C3","text on stone fills"),
 ("Parapet Black on white","#101820","#FFFFFF","docs text"),
 ("Limestone on Parapet Black","#F8F4EC","#101820","inverse / hero"),
 ("Limestone on Deep Slate","#F8F4EC","#18232B","admin shell text"),
 ("Mortar on Deep Slate","#EAE2D4","#18232B","code-block text"),
 ("Stone on Deep Slate","#D8D0C3","#18232B","muted text on dark"),
 ("Watch Blue on Limestone","#256C82","#F8F4EC","links"),
 ("Watch Blue on white","#256C82","#FFFFFF","links on white"),
 ("Watch Blue on Mortar","#256C82","#EAE2D4","links on cards"),
 ("Beacon Amber on Limestone","#B45309","#F8F4EC","warning on light"),
 ("Beacon Amber on white","#B45309","#FFFFFF","warning on white"),
 ("Beacon Amber Light on Deep Slate","#D97706","#18232B","warning on dark"),
 ("Budget Moss on Limestone","#567236","#F8F4EC","success"),
 ("Budget Moss on white","#567236","#FFFFFF","success on white"),
 ("Incident Red on Limestone","#B13A32","#F8F4EC","burn"),
 ("Incident Red on white","#B13A32","#FFFFFF","burn on white"),
 ("Trace Violet on Limestone","#6D5BD0","#F8F4EC","AI accent"),
 ("Trace Violet on white","#6D5BD0","#FFFFFF","AI accent on white"),
 # status sets (text on bg)
 ("Healthy text on Healthy bg","#3F5E28","#EFF6E8","status: healthy"),
 ("Watch text on Watch bg","#92400E","#F8EFD7","status: watch"),
 ("Burning text on Burning bg","#9F2D2D","#FCE8E2","status: burning"),
 ("Exhausted text on Exhausted bg","#7F1D1D","#F8D7D4","status: exhausted"),
 ("Unknown text on Unknown bg","#2E3A42","#ECEFF1","status: unknown"),
 ("AI Assist text on AI bg","#4F46A5","#ECEBFF","status: ai-assist"),
]
# non-text / UI component contrast (3:1)
ui = [
 ("Focus ring Watch Blue vs Limestone","#256C82","#F8F4EC"),
 ("Focus ring Watch Blue vs white","#256C82","#FFFFFF"),
 ("Focus ring Watch Blue vs Deep Slate","#256C82","#18232B"),
 ("Light border vs Limestone (approx #DCD6CB)","#C9C2B4","#F8F4EC"),
]
print("=== TEXT PAIRS (AA: 4.5 normal / 3.0 large) ===")
for name,fg,bg,role in pairs:
    r = ratio(fg,bg)
    aa = "AA" if r>=4.5 else ("AA-large" if r>=3 else "FAIL")
    print(f"{r:>5}  {aa:<9} {name}  [{role}]")
print("\n=== UI / NON-TEXT (need 3.0) ===")
for name,fg,bg in ui:
    r = ratio(fg,bg)
    ok = "PASS" if r>=3 else "FAIL"
    print(f"{r:>5}  {ok:<5} {name}")
