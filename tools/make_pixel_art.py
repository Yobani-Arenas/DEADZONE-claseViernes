"""Genera el arte 16x16 estilo NES (Zelda 1986) en assets/. Uso: python3 tools/make_pixel_art.py"""
from PIL import Image, ImageDraw
import random, os
OUT = os.path.join(os.path.dirname(__file__), "..", "assets")

def new(w=16, h=16):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); return im, ImageDraw.Draw(im)
def R(d, x0, y0, x1, y1, c): d.rectangle([x0, y0, x1, y1], fill=c)
def save(im, name): im.save(os.path.join(OUT, name + ".png"))
def flip(im): return im.transpose(Image.FLIP_LEFT_RIGHT)

K=(0,0,0); W=(255,255,255); GRN=(0,168,0); DGRN=(0,100,0); SKIN=(252,188,148); HAIR=(160,90,20); BRN=(120,64,0); RED=(216,40,0)

# ---------------- Héroe
def hero(kind, leg=0):
    im, d = new()
    if kind in ("down", "up"):
        R(d,4,1,11,3,GRN); R(d,3,3,12,3,DGRN)
        if kind == "down":
            R(d,4,4,11,7,SKIN); R(d,3,4,3,6,HAIR); R(d,12,4,12,6,HAIR)
            d.point((6,5),K); d.point((9,5),K)
        else:
            R(d,3,4,12,7,HAIR)
        R(d,3,8,12,12,GRN); R(d,3,10,12,10,BRN); R(d,7,10,8,10,(252,216,0))
        R(d,1,9,2,11,SKIN); R(d,13,9,14,11,SKIN)
        R(d,4,13,6,15,BRN); R(d,9,13,11,15,BRN)
        if leg: R(d,4,13,6,14,BRN); R(d,9,13,11,15,BRN)
    else:
        R(d,5,1,11,3,GRN); R(d,4,3,5,3,DGRN)
        R(d,6,4,11,7,SKIN); R(d,4,4,5,7,HAIR); d.point((10,5),K)
        R(d,5,8,10,12,GRN); R(d,5,10,10,10,BRN)
        R(d,9,9,12,10,SKIN)
        if leg == 0: R(d,5,13,7,15,BRN); R(d,8,13,10,14,BRN)
        else: R(d,4,13,6,14,BRN); R(d,8,13,10,15,BRN)
    return im
save(hero("down"),"hero_down"); save(hero("up"),"hero_up")
save(hero("side",0),"hero_side_a"); save(hero("side",1),"hero_side_b")

# ---------------- Zombis
def zombie(skin, shirt, eye, lean=0, name=""):
    im, d = new()
    R(d,5,2,10,6,skin); R(d,5,2,10,2,tuple(max(0,c-40) for c in skin))
    R(d,6,4,6,4,eye); R(d,9,4,9,4,eye); R(d,7,6,8,6,K)
    R(d,4,7,11,11,shirt); R(d,6,8,6,9,K); R(d,9,9,10,10,tuple(max(0,c-50) for c in shirt))
    R(d,2,7,3,9,skin); R(d,12,7,13,9,skin)       # brazos extendidos
    R(d,5,12,6,14,(40,40,60)); R(d,9,12,10,14,(40,40,60))
    return im
save(zombie((60,160,70),(70,70,120),(255,40,40)),"z_walker")
save(zombie((200,190,160),(180,40,30),(255,230,0)),"z_runner")
def tank():
    im, d = new()
    R(d,2,1,13,14,(60,80,150)); R(d,2,1,13,2,(40,50,110))
    R(d,4,4,6,6,(255,60,60)); R(d,9,4,11,6,(255,60,60)); R(d,5,9,10,11,K); R(d,6,9,6,10,W); R(d,9,9,9,10,W)
    R(d,0,5,1,10,(90,150,90)); R(d,14,5,15,10,(90,150,90)); R(d,4,14,6,15,K); R(d,9,14,11,15,K)
    return im
save(tank(),"z_tank")
def shooter():
    im, d = new()
    d.ellipse([1,1,14,9],fill=(150,60,170)); d.ellipse([3,2,6,4],fill=(230,200,255)); d.ellipse([9,3,12,6],fill=(230,200,255))
    R(d,5,9,10,14,(220,210,170)); R(d,6,10,6,11,K); R(d,9,10,9,11,K); R(d,7,12,8,12,K)
    return im
save(shooter(),"z_shooter")

# ---------------- Jefes 32x32
def boss0():
    im, d = new(32,32)
    d.ellipse([3,5,28,30],fill=(70,140,60)); d.ellipse([3,5,28,12],fill=(50,110,45))
    R(d,0,12,4,22,(70,140,60)); R(d,27,12,31,22,(70,140,60))
    for x in (7,13,19,24): R(d,x,2,x+2,6,(210,200,170))
    R(d,9,12,13,16,(255,220,0)); R(d,18,12,22,16,(255,220,0)); R(d,11,13,12,15,RED); R(d,19,13,20,15,RED)
    R(d,9,21,22,26,K)
    for x in (10,13,16,19): R(d,x,21,x+1,23,W)
    return im
def boss1():
    im, d = new(32,32)
    d.ellipse([5,9,26,30],fill=(130,60,160)); d.ellipse([9,12,22,22],fill=(160,90,190))
    R(d,6,3,25,7,(252,216,0))
    for x in (6,11,16,21,25): R(d,x,0,x+1,3,(252,216,0))
    R(d,10,12,13,15,RED); R(d,18,12,21,15,RED); R(d,10,12,11,13,W); R(d,18,12,19,13,W)
    R(d,11,20,20,24,K); R(d,12,20,13,23,W); R(d,18,20,19,23,W)
    for x in (0,2): R(d,x,14+x,x+5,15+x,(100,40,120)); R(d,27-x,14+x,31-x,15+x,(100,40,120))
    return im
def boss2():
    im, d = new(32,32)
    R(d,8,20,23,30,(230,235,240)); R(d,12,22,19,30,(190,200,210))
    d.ellipse([3,2,28,24],fill=(95,205,215)); d.arc([6,5,25,20],200,340,fill=(40,120,140)); d.arc([9,9,22,22],20,160,fill=(40,120,140))
    R(d,8,11,13,16,K); R(d,18,11,23,16,K); R(d,10,12,11,13,(120,255,120)); R(d,20,12,21,13,(120,255,120))
    R(d,12,19,19,20,(40,120,140))
    return im
for i,f in enumerate((boss0,boss1,boss2)): save(f(), f"boss_{i}")

# ---------------- Objetos
def heart(c, hl=True):
    im, d = new(8,8)
    rows=[".rr.rr..","rrrrrrr.","rrrrrrr.",".rrrrr..","..rrr...","...r...."]
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            if ch=="r": d.point((x,y),c)
    if hl: d.point((1,1),W)
    return im
save(heart(RED),"heart"); save(heart((70,70,70),False),"heart_empty")
im,d=new(); 
for y,row in enumerate([".rr.rr..",".rrrrrr.","rrrrrrrr","rrrrrrrr",".rrrrrr.","..rrrr..","...rr..."]):
    for x,ch in enumerate(row):
        if ch=="r": d.rectangle([x*2,y*2,x*2+1,y*2+1],fill=RED if y>0 else (255,120,100))
R(d,3,2,4,3,W); save(im,"container")
im,d=new(); d.ellipse([4,0,11,7],outline=(252,216,0),width=2); R(d,7,7,8,14,(252,216,0)); R(d,9,11,11,11,(252,216,0)); R(d,9,14,11,14,(252,216,0)); save(im,"key")
im,d=new(); R(d,7,0,8,9,(200,220,230)); R(d,7,0,7,9,W); d.point((7,0),(200,220,230)); R(d,4,10,11,11,(230,170,30)); R(d,7,12,8,15,BRN); save(im,"sword")
im,d=new(); R(d,6,1,9,14,(80,200,255)); R(d,7,0,8,15,W); save(im,"beam")
im,d=new(8,8); d.ellipse([1,1,6,6],fill=(190,80,230)); d.point((3,3),W); save(im,"spore")
for i,c in enumerate(((255,80,80),(80,255,120),(90,220,255))):
    im,d=new(); d.polygon([(7,0),(13,6),(7,15),(2,6)],fill=c); d.polygon([(7,1),(10,6),(7,10),(5,6)],fill=W); save(im,f"fragment_{i}")
im,d=new(); R(d,5,5,10,10,W); R(d,3,7,12,8,(255,220,100)); R(d,7,3,8,12,(255,220,100)); save(im,"poof")
im,d=new(); R(d,3,3,12,12,(255,255,255,180)); save(im,"flash")

# ---------------- Mosaicos por mundo
rnd = random.Random(7)
PAL = [
 dict(g=(44,44,54), g2=(60,60,72), wall=(120,120,140), wall2=(70,70,90), obs=(150,96,48), obs2=(96,60,30), liq=(40,90,110), liq2=(80,150,170)),
 dict(g=(32,84,32), g2=(46,112,46), wall=(14,64,20), wall2=(6,36,12), obs=(20,110,30), obs2=(88,52,16), liq=(30,70,200), liq2=(150,200,255)),
 dict(g=(28,48,64), g2=(40,72,92), wall=(70,110,130), wall2=(30,60,80), obs=(70,150,170), obs2=(30,60,80), liq=(50,200,70), liq2=(170,255,150)),
]
for w,p in enumerate(PAL):
    for v in (0,1):
        im,d=new(); R(d,0,0,15,15,p["g"])
        for _ in range(7): d.point((rnd.randint(0,15),rnd.randint(0,15)),p["g2"])
        if w==0: R(d,0,15,15,15,p["g2"]) if v else None
        if w==2: d.rectangle([0,0,15,15],outline=p["g2"])
        save(im,f"tile_ground_{w}_{v}")
    im,d=new(); R(d,0,0,15,15,p["wall"])
    if w==1:
        for _ in range(5): d.ellipse([rnd.randint(0,9),rnd.randint(0,9),0,0][:2]+[rnd.randint(8,15),rnd.randint(8,15)],fill=p["wall2"]) if False else None
        for cx,cy in ((3,3),(11,4),(5,11),(12,12)): d.ellipse([cx-4,cy-4,cx+3,cy+3],fill=p["wall2"])
    else:
        for y in (0,5,10): R(d,0,y,15,y,p["wall2"])
        for y,off in ((0,4),(5,10),(10,4)): R(d,off,y,off,y+4,p["wall2"])
        R(d,0,15,15,15,p["wall2"])
    save(im,f"tile_wall_{w}")
    im,d=new(); R(d,0,0,15,15,p["g"])
    if w==1:
        R(d,7,10,8,15,p["obs2"]); d.ellipse([1,0,14,12],fill=p["obs"]); d.ellipse([4,2,8,5],fill=(40,150,50))
    elif w==0:
        R(d,1,1,14,14,p["obs"]); R(d,1,5,14,5,p["obs2"]); R(d,1,10,14,10,p["obs2"]); R(d,7,1,7,14,p["obs2"]); d.rectangle([1,1,14,14],outline=p["obs2"])
    else:
        R(d,1,1,14,14,p["obs"]); R(d,3,3,12,8,(20,40,50)); R(d,4,4,6,5,(120,255,160)); R(d,3,11,12,12,p["obs2"]); d.rectangle([1,1,14,14],outline=p["obs2"])
    save(im,f"tile_obs_{w}")
    im,d=new(); R(d,0,0,15,15,p["liq"])
    for y in (3,8,13): R(d,2,y,6,y,p["liq2"]); R(d,9,y+1,13,y+1,p["liq2"])
    save(im,f"tile_liq_{w}")
im,d=new(); R(d,0,0,15,15,(90,60,20)); d.rectangle([0,0,15,15],outline=K); R(d,6,4,9,8,(252,216,0)); R(d,7,8,8,12,(252,216,0)); save(im,"tile_lock")
im,d=new(); R(d,0,0,15,15,(20,20,30)); d.rectangle([0,0,15,15],outline=(120,120,140)); R(d,2,7,13,8,(120,120,140)); save(im,"tile_shut")

# Mejora visual: sprites de mayor resolución, con más volumen y rasgos propios.
def detailed_hero(direction="down", frame=0):
    im,d=new(24,28)
    d.ellipse([3,22,20,26],fill=(12,18,20,150))
    R(d,5,19,9,26,(75,43,28)); R(d,14,19,18,26,(75,43,28))
    R(d,4,10,19,21,(24,112,76)); R(d,6,12,17,19,(35,156,100))
    R(d,10,12,13,20,(210,165,55)); R(d,1,11,4,18,(190,145,105)); R(d,19,11,22,18,(190,145,105))
    R(d,6,2,17,11,(226,174,132)); R(d,5,1,18,5,(105,58,28)); R(d,4,4,7,10,(105,58,28)); R(d,16,4,19,10,(105,58,28))
    if direction == "up": R(d,5,2,18,12,(90,52,30)); R(d,7,5,16,10,(125,75,38))
    else:
        d.point((9,7),fill=(20,25,28)); d.point((14,7),fill=(20,25,28)); R(d,9,9,14,9,(135,55,45))
    R(d,4,0,19,3,(30,145,83)); R(d,7,0,16,1,(70,205,125))
    if frame: R(d,5,22,9,25,(100,65,40)); R(d,14,21,18,24,(100,65,40))
    return im
save(detailed_hero("down"),"hero_down"); save(detailed_hero("up"),"hero_up")
save(detailed_hero("side",0),"hero_side_a"); save(detailed_hero("side",1),"hero_side_b")

def detailed_zombie(kind):
    im,d=new(32,32)
    d.ellipse([3,25,28,30],fill=(0,0,0,115))
    skin={"walker":(92,174,91),"runner":(204,190,151),"shooter":(151,91,180),"tank":(91,116,153)}[kind]
    dark=tuple(max(0,c-48) for c in skin)
    shirt={"walker":(59,91,67),"runner":(150,44,40),"shooter":(85,47,119),"tank":(64,75,105)}[kind]
    if kind == "runner": R(d,1,12,7,16,skin); R(d,23,7,30,11,skin)
    else: R(d,1,13,8,20,skin); R(d,24,13,30,20,skin)
    R(d,3,18,8,21,dark); R(d,24,18,29,21,dark)
    if kind == "tank":
        d.rounded_rectangle([5,9,27,27],radius=5,fill=shirt,outline=(25,32,48),width=2)
        R(d,8,17,24,21,(113,126,145)); R(d,9,18,23,19,(174,187,192))
    else:
        d.polygon([(9,10),(22,9),(27,24),(21,28),(8,26),(5,17)],fill=shirt)
        for yy in (17,20,23): R(d,11,yy,20,yy,dark)
    d.ellipse([7,1,25,17],fill=skin,outline=dark,width=2)
    R(d,9,12,23,18,dark); R(d,11,13,21,15,(34,24,28))
    R(d,8,2,12,5,dark); R(d,19,1,24,4,dark)
    eye=(255,48,45) if kind != "runner" else (255,224,58)
    R(d,11,7,14,10,eye); R(d,19,7,22,10,eye); R(d,12,8,13,9,(255,245,220)); R(d,20,8,21,9,(255,245,220))
    if kind == "walker": R(d,14,15,18,17,(230,225,190)); R(d,6,21,10,24,(80,125,62))
    elif kind == "runner":
        R(d,14,13,20,15,(35,22,20)); R(d,3,6,7,9,(190,40,35)); d.line((5,27,12,24),fill=(220,110,80),width=2)
    elif kind == "shooter":
        d.ellipse([10,0,22,6],fill=(204,130,230),outline=(70,35,100),width=1); R(d,14,18,18,24,(65,35,95)); d.point((16,20),fill=(130,235,255))
    else:
        d.polygon([(5,8),(9,0),(13,7),(18,0),(22,7),(27,4),(26,11)],fill=(75,90,120)); R(d,7,22,25,25,(42,50,68)); R(d,13,18,18,21,(255,180,40))
    R(d,9,25,13,30,(48,48,58)); R(d,19,25,23,30,(48,48,58))
    return im
for _kind in ("walker","runner","shooter","tank"): save(detailed_zombie(_kind),"z_"+_kind)

# Hoja de contacto de vista previa
names=sorted(f[:-4] for f in os.listdir(OUT) if f.endswith(".png") and f not in ("title.png","menu_bg.png","icon.png"))
sheet=Image.new("RGBA",(16*14*4,((len(names)+13)//14)*20*4),(90,90,90,255))
for i,n in enumerate(names):
    t=Image.open(os.path.join(OUT,n+".png")).convert("RGBA")
    if t.size[0]>16: t=t.resize((16,16),Image.NEAREST)
    t=t.resize((t.size[0]*4,t.size[1]*4),Image.NEAREST); sheet.paste(t,((i%14)*64,(i//14)*80),t)
sheet.save(os.path.join(OUT, "preview.png"))
print(len(names),"imágenes")
