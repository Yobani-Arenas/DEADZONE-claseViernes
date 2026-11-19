from PIL import Image, ImageDraw
import os, random
OUT=os.path.join(os.path.dirname(__file__),'..','assets'); os.makedirs(OUT,exist_ok=True)
# palette
INK=(13,20,29,255); EDGE=(25,38,48,255); TEAL=(35,112,119,255); TEAL2=(62,166,157,255); MINT=(133,222,190,255); ORANGE=(222,104,49,255); GOLD=(244,190,87,255); STEEL=(105,132,148,255); DARK=(37,48,59,255); PALE=(191,211,201,255); RED=(220,66,62,255)
def canvas(w,h):
 im=Image.new('RGBA',(w,h),(0,0,0,0)); return im,ImageDraw.Draw(im)
def rect(d,xy,c,outline=INK): d.rectangle(xy,fill=c,outline=outline)
def line(d,pts,c,w=1): d.line(pts,fill=c,width=w)
def hero(direction='down',step=0):
 im,d=canvas(32,40)
 # ground shadow
 d.ellipse((5,34,27,38),fill=(0,0,0,105))
 # backpack silhouette
 rect(d,(21,13,28,27),(63,83,91,255)); rect(d,(23,15,27,19),(111,159,160,255)); rect(d,(23,22,27,25),ORANGE)
 # boots / legs with gait
 if step: rect(d,(8,29,14,36),(52,59,67,255)); rect(d,(17,29,24,35),(62,70,76,255))
 else: rect(d,(8,29,14,35),(52,59,67,255)); rect(d,(17,29,23,36),(62,70,76,255))
 rect(d,(7,34,15,37),DARK); rect(d,(16,34,25,37),DARK)
 # armored body, asymmetric shoulder pads
 d.polygon([(8,14),(12,11),(21,12),(25,17),(23,29),(8,29),(5,20)],fill=TEAL,outline=INK)
 rect(d,(10,16,21,26),TEAL2); rect(d,(13,18,18,25),DARK); rect(d,(14,19,17,23),GOLD)
 rect(d,(4,15,9,23),STEEL); rect(d,(23,16,27,24),ORANGE)
 # scarf / collar
 d.polygon([(8,12),(14,10),(22,12),(19,16),(12,16)],fill=ORANGE,outline=INK)
 # head hood and face
 d.polygon([(7,4),(11,1),(21,2),(25,7),(24,15),(19,18),(10,16),(6,11)],fill=(56,75,83,255),outline=INK)
 d.polygon([(9,5),(13,3),(20,4),(23,8),(21,13),(11,13),(8,10)],fill=PALE,outline=EDGE)
 # visor varies by direction
 if direction=='up':
  d.polygon([(8,6),(23,6),(22,12),(10,13)],fill=(42,62,69,255),outline=INK)
  line(d,[(11,8),(20,8)],(92,202,193,255),2)
 else:
  d.polygon([(9,7),(22,7),(21,12),(10,12)],fill=(28,67,76,255),outline=INK)
  line(d,[(11,9),(20,9)],(117,244,218,255),2)
 # side-facing profile detail
 if direction=='side':
  rect(d,(20,8,24,12),STEEL); rect(d,(21,9,23,10),MINT)
 # helmet crest / antenna
 rect(d,(13,0,19,2),ORANGE); line(d,[(19,2),(23,0)],GOLD,1)
 # utility belt and canister
 line(d,[(8,28),(23,28)],GOLD,2); rect(d,(19,26,23,30),(184,76,47,255))
 # arm bands
 rect(d,(4,21,8,24),MINT); rect(d,(24,21,27,24),MINT)
 return im
for name,direction,step in [('hero_down','down',0),('hero_up','up',0),('hero_side_a','side',0),('hero_side_b','side',1)]: hero(direction,step).save(os.path.join(OUT,name+'.png'))

def infected(kind,frame=0):
 im,d=canvas(36,40)
 d.ellipse((4,35,32,39),fill=(0,0,0,110))
 # class-specific silhouette and palette
 if kind=='walker':
  skin=(126,169,111,255); flesh=(80,119,83,255); cloth=(64,83,69,255)
  # dragging infected, ruptured shoulder
  d.polygon([(9,14),(15,10),(25,13),(29,28),(24,34),(9,31),(5,23)],fill=cloth,outline=INK)
  rect(d,(4,17,10,25),flesh); rect(d,(26,17,31,27),skin)
  d.ellipse((9,2,27,21),fill=skin,outline=INK,width=2); d.polygon([(10,5),(15,0),(25,3),(27,8),(21,7),(16,10)],fill=flesh,outline=INK)
  rect(d,(13,11,16,14),RED); rect(d,(21,11,24,14),RED); line(d,[(14,18),(22,17)],INK,2)
  rect(d,(9,30,15,37),DARK); rect(d,(21,30,27,37),DARK); rect(d,(7,36,16,38),STEEL); rect(d,(20,36,29,38),STEEL)
  # fungal growth
  d.ellipse((25,3,31,10),fill=(166,199,91,255),outline=INK); d.ellipse((28,1,33,5),fill=(201,222,123,255))
 elif kind=='runner':
  skin=(193,173,135,255); cloth=(133,53,48,255)
  # forward-leaning lean silhouette
  d.polygon([(12,12),(24,10),(29,23),(22,31),(10,27),(7,19)],fill=cloth,outline=INK)
  line(d,[(10,17),(2,23),(1,28)],skin,4); line(d,[(25,16),(33,20),(34,24)],skin,4)
  d.ellipse((10,1,27,18),fill=skin,outline=INK,width=2); d.polygon([(11,4),(17,0),(27,3),(28,8),(21,6)],fill=(92,66,54,255),outline=INK)
  rect(d,(13,9,17,12),(255,207,69,255)); rect(d,(21,8,25,11),(255,207,69,255)); line(d,[(15,16),(24,14)],INK,2)
  line(d,[(13,28),(6,34),(4,38)],DARK,4); line(d,[(22,28),(29,31),(32,37)],DARK,4)
  line(d,[(4,24),(8,22)],RED,2)
 elif kind=='shooter':
  skin=(124,89,161,255); cloth=(65,48,94,255)
  # floating spore sac with tendrils
  d.ellipse((6,5,30,29),fill=skin,outline=INK,width=2); d.ellipse((10,8,26,23),fill=(166,121,190,255),outline=(80,52,111,255))
  for x,y in [(7,3),(25,2),(29,13),(4,17)]: d.ellipse((x,y,x+5,y+5),fill=(195,130,206,255),outline=INK)
  rect(d,(12,13,16,17),(135,247,255,255)); rect(d,(21,13,25,17),(135,247,255,255)); line(d,[(14,23),(22,23)],INK,2)
  d.polygon([(12,28),(24,28),(28,35),(8,35)],fill=cloth,outline=INK)
  for x in (9,16,23): line(d,[(x,32),(x-2,38)],(151,103,174,255),2)
  d.ellipse((15,0,21,6),fill=(117,241,220,255),outline=INK)
 elif kind=='tank':
  skin=(91,125,132,255); armor=(75,92,104,255)
  # broad armored brute with glowing exposed core
  d.rounded_rectangle((3,12,33,34),radius=7,fill=armor,outline=INK,width=2)
  rect(d,(5,16,11,26),(119,144,145,255)); rect(d,(26,16,31,27),(119,144,145,255))
  d.ellipse((8,1,28,21),fill=skin,outline=INK,width=2); d.polygon([(7,7),(11,0),(16,5),(21,0),(28,7),(27,12)],fill=(61,84,94,255),outline=INK)
  rect(d,(11,10,15,14),RED); rect(d,(21,10,25,14),RED)
  d.ellipse((14,19,23,29),fill=(228,130,54,255),outline=INK); d.ellipse((17,22,20,26),fill=(255,220,116,255))
  rect(d,(8,32,15,38),DARK); rect(d,(22,32,29,38),DARK)
  # rivets
  for x,y in [(6,18),(29,19),(8,29),(27,29)]: d.point((x,y),MINT)
 # Detalles adicionales para que cada variante se lea mejor en pantalla.
 if kind=='walker':
  # Heridas, ropa rasgada y venas visibles.
  line(d,[(10,20),(14,23),(17,22)],(46,67,49,255),2)
  line(d,[(18,25),(22,27),(25,25)],(139,49,47,255),2)
  rect(d,(12,16,14,17),(255,213,111,255)); rect(d,(22,16,24,17),(255,213,111,255))
  line(d,[(8,26),(5,29)],(104,143,92,255),2)
  d.ellipse((27,10,31,14),fill=(184,66,57,255),outline=INK)
 elif kind=='runner':
  # Tendones expuestos, mandíbula abierta y marcas de velocidad.
  line(d,[(11,18),(16,21),(20,19),(25,20)],(90,48,42,255),2)
  line(d,[(15,22),(19,24),(23,22)],(231,105,85,255),1)
  line(d,[(8,29),(3,33)],(188,70,60,255),2)
  line(d,[(27,27),(33,31)],(188,70,60,255),2)
  rect(d,(16,14,18,16),(255,246,205,255)); rect(d,(23,13,25,15),(255,246,205,255))
 elif kind=='shooter':
  # Sacos de esporas, venas bioluminiscentes y boca vertical.
  line(d,[(9,15),(14,18),(12,22)],(91,63,130,255),2)
  line(d,[(26,14),(22,18),(25,22)],(91,63,130,255),2)
  d.ellipse((16,19,21,26),fill=(64,40,79,255),outline=(211,143,211,255))
  line(d,[(18,20),(18,24)],(242,183,223,255),1)
  for x,y in [(2,8),(30,20),(5,27)]:
   d.ellipse((x,y,x+4,y+4),fill=(111,238,211,255),outline=INK)
 elif kind=='tank':
  # Placas óseas, cicatrices y núcleo agrietado.
  line(d,[(5,13),(10,9),(14,12)],(151,176,174,255),2)
  line(d,[(25,12),(29,9),(32,14)],(151,176,174,255),2)
  line(d,[(13,23),(16,21),(18,24),(21,21),(24,24)],(255,183,93,255),2)
  line(d,[(14,27),(18,29),(23,27)],(79,45,44,255),2)
  rect(d,(6,22,8,25),(190,66,57,255)); rect(d,(28,23,30,26),(190,66,57,255))
 return im
for kind in ('walker','runner','shooter','tank'):
 infected(kind).save(os.path.join(OUT,'z_'+kind+'.png'))
print('Original survivor and four infected classes generated.')
