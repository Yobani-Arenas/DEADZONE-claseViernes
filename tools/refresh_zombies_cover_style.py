from PIL import Image, ImageDraw
import os, random
OUT=os.path.join(os.path.dirname(__file__),'..','assets')
INK=(20,20,25,255); EDGE=(42,38,43,255); SHADOW=(30,32,35,255)
SKIN=(135,145,126,255); LIGHT=(180,177,151,255); MID=(91,108,96,255); DARK=(55,67,65,255)
RED=(176,49,45,255); RED2=(235,79,63,255); CLOTH=(61,55,59,255); BLUE=(48,57,68,255)
GREEN=(91,181,59,255); GLOW=(154,241,79,255); TEETH=(229,215,179,255)
def sprite(kind):
 im=Image.new('RGBA',(36,40),(0,0,0,0)); d=ImageDraw.Draw(im)
 d.ellipse((5,35,31,39),fill=(0,0,0,105))
 def poly(p,c,o=INK): d.polygon(p,fill=c,outline=o)
 def rect(b,c,o=INK): d.rectangle(b,fill=c,outline=o)
 def line(p,c,w=1): d.line(p,fill=c,width=w)
 if kind=='walker':
  # crooked shoulders and ragged jacket
  poly([(10,14),(15,11),(24,12),(29,19),(27,31),(22,34),(10,31),(6,24)],CLOTH)
  rect((7,18,11,26),MID); rect((25,18,29,27),SKIN)
  poly([(10,28),(16,29),(15,37),(9,37)],BLUE); poly([(20,29),(26,28),(28,37),(21,37)],BLUE)
  rect((7,35,16,38),DARK); rect((21,35,30,38),DARK)
  poly([(9,4),(13,1),(22,2),(27,7),(26,18),(21,22),(11,19),(7,13)],SKIN)
  poly([(8,7),(10,2),(16,0),(19,4),(25,3),(28,9),(22,8),(18,11),(12,8)],DARK)
  rect((12,11,15,14),RED2); rect((21,10,24,13),RED2)
  rect((13,12,14,13),INK); rect((22,11,23,12),INK)
  line([(14,18),(17,20),(21,18)],INK,2); line([(15,18),(17,19),(19,18)],TEETH,1)
  line([(9,21),(13,23),(16,22)],RED,2); rect((23,24,26,27),RED)
  rect((10,16,12,18),LIGHT); rect((25,13,27,16),LIGHT)
 elif kind=='runner':
  # forward-leaning, exposed limbs
  poly([(12,13),(23,10),(29,17),(26,27),(18,31),(8,25),(7,18)],(88,57,54,255))
  line([(10,18),(4,23),(2,29)],SKIN,4); line([(25,16),(32,19),(34,25)],SKIN,4)
  line([(13,27),(8,32),(5,38)],BLUE,4); line([(22,27),(28,31),(32,37)],BLUE,4)
  poly([(11,3),(16,0),(24,2),(28,8),(25,17),(18,20),(10,15),(8,9)],SKIN)
  poly([(9,7),(12,2),(18,0),(23,3),(28,6),(23,8),(18,7),(13,11)],DARK)
  rect((13,9,16,12),RED2); rect((21,8,24,11),RED2)
  line([(13,15),(18,17),(23,14)],INK,2); line([(15,16),(19,17),(21,15)],TEETH,1)
  line([(10,20),(16,22),(20,20)],RED2,2); line([(26,26),(31,29),(33,31)],RED,2)
  rect((7,26,10,29),LIGHT); rect((27,17,29,19),LIGHT)
 elif kind=='shooter':
  # gaunt infected with glowing fungal growth
  poly([(10,17),(15,12),(24,14),(28,23),(25,32),(11,32),(7,24)],(57,65,58,255))
  line([(11,23),(5,28),(4,33)],SKIN,3); line([(26,22),(32,25),(33,30)],SKIN,3)
  rect((11,30,15,37),BLUE); rect((21,30,25,37),BLUE); rect((8,36,16,38),DARK); rect((21,36,29,38),DARK)
  poly([(9,4),(14,1),(23,3),(27,9),(24,19),(17,22),(9,17),(7,10)],SKIN)
  poly([(8,7),(11,2),(18,0),(24,4),(28,8),(23,9),(18,7),(12,11)],DARK)
  rect((12,11,16,14),RED2); rect((21,11,24,14),RED2)
  line([(14,18),(18,20),(22,17)],INK,2); line([(16,18),(18,19),(20,18)],TEETH,1)
  # luminous green lesions
  for b in [(25,4,29,9),(28,9,33,14),(4,15,8,19),(26,22,30,26),(14,2,17,5)]:
   d.ellipse(b,fill=GREEN,outline=INK)
  d.ellipse((27,3,30,6),fill=GLOW); d.ellipse((29,10,32,13),fill=GLOW)
  line([(9,24),(13,26),(16,25)],GREEN,2)
 elif kind=='tank':
  # broad bruiser with torn vest and huge arms
  poly([(4,14),(11,10),(25,10),(32,15),(33,29),(27,34),(8,34),(3,27)],(73,76,75,255))
  d.ellipse((1,16,12,30),fill=SKIN,outline=INK,width=2); d.ellipse((25,15,35,30),fill=SKIN,outline=INK,width=2)
  rect((8,30,15,38),BLUE); rect((22,30,29,38),BLUE); rect((5,36,16,39),DARK); rect((21,36,32,39),DARK)
  poly([(8,3),(13,0),(24,1),(29,7),(28,18),(22,22),(11,20),(6,12)],SKIN)
  poly([(7,7),(11,1),(16,4),(21,0),(28,5),(30,10),(23,9),(18,11),(12,9)],DARK)
  rect((12,11,16,14),RED2); rect((22,10,25,14),RED2)
  line([(13,17),(17,20),(22,17)],INK,3); line([(15,18),(18,19),(21,18)],TEETH,1)
  poly([(9,21),(14,17),(24,18),(28,28),(22,32),(11,30)],(83,65,60,255))
  line([(11,23),(15,25),(18,23),(21,26),(25,23)],(184,66,57,255),2)
  # swollen infected shoulder and torn flesh
  d.ellipse((26,16,32,23),fill=(133,115,103,255),outline=INK); rect((29,20,32,23),RED2)
  line([(7,18),(11,15),(13,18)],LIGHT,2); rect((6,25,9,28),RED)
 return im
for k in ('walker','runner','shooter','tank'):
 sprite(k).save(os.path.join(OUT,'z_'+k+'.png'))
print('Zombie sprites refreshed in cover-matching gritty pixel-art style.')
