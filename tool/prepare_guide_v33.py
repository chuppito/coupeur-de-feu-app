"""Transformation documentaire hors moteur, relue par les tests de séquence.
Le texte des prières n'est pas réécrit. Les données produites sont versionnées.
"""
import json,re
from pathlib import Path
path=Path('assets/data/magnetisme_protocoles.json')
data=json.loads(path.read_text())
fixed={
'ft-angine':'Sphère ORL','ft-bronchite':'Bronches','ft-cervicalgie':'Cervicales, face postérieure',
'ft-constipation':'Système intestinal','ft-cystite':'Appareil urinaire','ft-endometriose':'Endomètre',
'ft-gastro-enterite':'Système intestinal','ft-hemorroides':'Zone hémorroïdaire',
'ft-lombalgie':'Lombaires','ft-nevralgie-d-arnold':'Cou et arrière du crâne',
'ft-otite':'Oreille(s) concernée(s)','ft-papillomavirus':'Utérus',
}
abdomen={'ft-acne':6,'ft-deprime':7,'ft-eczema':6,'ft-asthme':5,'ft-maladie-de-crohn':6,
'ft-maladie-de-verneuil':6,'ft-migraine':6,'ft-psoriasis':6,'ft-tabac-arret-du':6,
'ft-intervention-chirurgicale-avant':6,'ft-troubles-du-sommeil':6,'ft-douleurs-intestinales-pdf':6}
links={'ft-eczema':'3962908','ft-zona':'3962918','ft-verrue':'3962883','ft-sciatique':'4213494','ft-cruralgie':'4213494','ft-entorse':'3962662','ft-fibromyalgie':'4231902','ft-traitements-lourds-aide-aux':'3962979','ft-intervention-chirurgicale-avant':'4251258','ft-intervention-chirurgicale-apres':'4251258'}
for d in data['fiches']:
 if not d.get('etapesGuideSource'):continue
 # Correction confirmée par la vidéo 18.03 ; texte historique dans texteSource conservé.
 if d['id']=='ft-cruralgie':
  d['contenu']=d['contenu'].replace('jambe douloureuse (sur le ventre)','jambe douloureuse (sur le dos)')
  for s in d['etapesGuideSource']:s['texte']=s['texte'].replace('jambe douloureuse (sur le ventre)','jambe douloureuse (sur le dos)')
 out=[]; route=''; target='selection'; local_title=''; last_rapid=False
 for i,s in enumerate(d['etapesGuideSource']):
  kind=s['type']; txt=s['texte']
  source='https://enligne.formationmagnetisme.fr/school/course/praticien/lecture/'+links[d['id']] if d['id'] in links else d.get('source','')
  def add(k,t,**kwargs):
   out.append(dict(id=f's{i}-{len(out)}',kind=k,text=t,target=target,route=route,source=source,**kwargs))
  if kind in ['circulation','balayage']:
   add(kind,kind);continue
  if kind in ['accueil','bilan','degagement','communes','intentions','priere','autre']:
   add(kind,txt);continue
  if kind=='travail':
   # Les blocs successifs rapides/lents gardent leur cible et leur trajet.
   is_continuation=not re.search(r'travaillez|travail en',txt,re.I)
   if not is_continuation:
    target=fixed.get(d['id'],'selection');local_title=txt.split('\n')[0]
    if i==abdomen.get(d['id']):target='Abdomen et système intestinal'
    if d['id'] in ['ft-sciatique','ft-cruralgie']:
     target='Bas du dos' if i==5 else ('Jambe douloureuse, face postérieure' if d['id']=='ft-sciatique' else 'Jambe douloureuse, face antérieure ; patient sur le dos')
    if d['id']=='ft-tabac-arret-du' and i==5:target='Poumons et trachée'
   txt=re.split(r'\n9\.\s*&',txt)[0]
   lines=[x.strip() for x in txt.splitlines() if x.strip()]
   # Des données explicites sont produites ici ; aucun classement par texte dans le moteur.
   for line in lines:
    if re.search(r'travaillez en passes',line,re.I): continue
    if re.search(r'passes? rapides?',line,re.I):
     route=line
     add('rapide',local_title+'\n'+line)
     add('flux','Contrôler le passage du flux sur chacun des trajets ci-dessus, pour chaque côté concerné. En cas de blocage, reprendre les passes rapides puis contrôler de nouveau.')
     last_rapid=True
    elif re.search(r'passes? lentes?',line,re.I):add('lente',line);last_rapid=False
    elif re.search(r'imposition',line,re.I):add('imposition',line)
    elif re.search(r'visualis',line,re.I):add('visualisation',line)
    else:add('local',line)
  else:
   # Une imposition indépendante (plaques puis abdomen, notamment) garde sa place.
   if d['id'] in ['ft-eczema','ft-acne','ft-deprime'] and i<abdomen.get(d['id'],0):target='selection';route=''
   add(kind,txt)
 d['guideV33']=out
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
