"""Explicit, reviewable corrections. No runtime inference from prose."""
import json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1]
P=R/'assets/data/guide_v33.json'
g=json.loads(P.read_text())
if 'ft-couper-le-feu' in g:
 raise SystemExit('Migration déjà appliquée ; ne pas réécrire les corrections ou les fiches locales.')
raw=json.loads((R/'assets/data/magnetisme_protocoles.json').read_text())['fiches']
book='Manuel formation Stéphane Langlade, PDF 128 pages, '
def action(id,kind,text,**kw):return dict(id=id,kind=kind,text=text,target='selection',source=book+kw.pop('page','page à rapprocher'),**kw)
def split(id,kind,needle,sep):
 a=next(x for x in g[id] if x['kind']==kind and needle in x['text']);idx=g[id].index(a);one,two=a['text'].split(sep,1)
 g[id][idx:idx+1]=[{**a,'text':one},{**a,'id':a['id']+'-priere','kind':'priere','text':two}]
split('ft-arthrose','intentions','Saint Thibault','\n6. ')
split('ft-arthrite','priere','Saint Thibault',').6. ')
# Restore the reference's closing punctuation stripped by the split.
g['ft-arthrite'][4]['text']+=').' 
for id in ['ft-arthrose','ft-arthrite']:
 a=next(x for x in g[id] if x['kind']=='communes');a['text']='14 conventions : insister sur les tensions et les blocages énergétiques.'
a=next(x for x in g['ft-insuffisance-veineuse'] if x['kind']=='communes');a['text']='14 conventions : insister sur le nettoyage des toxines.'
for a in g['ft-tabac-arret-du']:a['text']=a['text'].replace('geôles mentales','gestuels')
for a in g['ft-lombalgie']:a['text']=a['text'].replace('droit, fer comme','droit, fier comme')
for a in g['ft-hemorroides']:a['text']=a['text'].replace('circule dans par','circule dans ton corps [nom et prénom] par')
for a in g['ft-intervention-chirurgicale-apres']:
 if a['kind']=='autre' and ('Christ est né' in a['text'] or 'Amen' in a['text'] or 'prière' in a['text'].lower()):a['kind']='priere'
for a in g['ft-maladie-de-lyme']:
 if a['kind']=='autre' and 'Borrelia' in a['text']:a['kind']='intentions'
for a in g['ft-cervicalgie']:
 if a['kind']=='rapide':a['text']=a['text'].replace('sur le dos','sur le ventre')
# Pulmonary work is not a prayer and never a physical pass at distance.
aa=g['ft-asthme'];a=next(x for x in aa if x['kind']=='priere');i=aa.index(a)
pr=a['text'].split(').6.')[0]+').'
aa[i:i+1]=[
 {**a,'text':pr,'condition':'Uniquement si inflammation importante, selon la fiche p. 97.','repetitions':3},
 action('poumons-rapides','rapide','Passes rapides sur les poumons : chakra couronne au chakra plexus.',page='p. 97',route='Couronne → plexus',distanceText='Localiser les poumons sur le support anatomique ; trajet couronne → plexus, sans passes sur le patient.'),
 action('poumons-flux','flux','Contrôler le flux entre couronne et plexus ; reprendre les rapides si nécessaire.',page='p. 38 et techniques 08.02',route='Couronne → plexus'),
 action('poumons-lentes','lente','Passes lentes sur les poumons.',page='p. 97',route='Couronne → plexus'),
 action('poumons-imposition','imposition','Imposition sur les poumons, intention de stopper l’état inflammatoire.',page='p. 97',distanceText='Sur le support pulmonaire : intention de stopper l’état inflammatoire.')]
for a in aa:
 if a['id'].startswith('poumons'):a['target']='Poumons'
# Preserve detailed intentions in the support mode rather than generic substitutes.
for id in ['ft-acne','ft-troubles-du-sommeil','ft-maladie-de-verneuil','ft-sciatique','ft-cruralgie']:
 for a in g[id]:
  if a['kind'] in ['imposition','visualisation']:
   a['distanceText']=a['text'].replace('Imposition des mains','Intention sur support').replace('Imposez vos mains','Travaillez sur le support correspondant')
for a in g['ft-troubles-du-sommeil']:
 if a['kind']=='imposition' and a['target']=='selection':a['target']='Glande pinéale'
for a in g['ft-rhinopharyngite']:
 if a['kind'] in ['rapide','lente','flux','imposition']:a['target']='Sphère ORL'
for a in g['ft-douleurs-intestinales-pdf']:
 if a['kind'] in ['rapide','lente','flux','imposition']:a['target']='Abdomen'
# A complete action per timed intention: durations are not a sum guessed from a title.
for id,seconds in [('ft-zona',120),('ft-verrue',120),('ft-herpes',120),('ft-psoriasis',300)]:
 out=[]
 for a in g[id]:
  if a['kind']=='imposition' and a['text'].count('minutes')>=2:
   lines=a['text'].splitlines();timed=[x for x in lines if 'minutes' in x]
   for n,t in enumerate(timed):
    out.append({**a,'id':a['id']+f'-t{n+1}','text':lines[0]+'\n'+t,'distanceText':'Sur le support de la zone concernée : '+t,'seconds':seconds})
   tail=[x for x in lines[1:] if 'minutes' not in x and x.strip()]
   if tail:out[-1]['text']+='\n'+'\n'.join(tail)
  else:out.append(a)
 g[id]=out
for id in ['ft-acne','ft-eczema']:
 for a in g[id]:
  if a['kind'] in ['imposition','visualisation'] and '5 minutes' in a['text']:a['seconds']=300
for a in g['ft-constipation']:
 if '2 minutes' in a['text'] or '2 min ' in a['text']:a['seconds']=120
for a in g['ft-traitements-lourds-aide-aux']:
 if a['kind']=='priere':a['condition']='Si brûlure ou radiothérapie (PDF p. 123). Suivi radio : première séance complète et connexion/photo déjà établies.'
for a in g['ft-tendinite']:
 if a['kind']=='visualisation':a['seconds']=120;a['source']=book+'p. 40 et 81'
# Each existing action carries a provenance; source status is deliberately not inflated.
for id,aa in g.items():
 for a in aa:a['documented']=True
# Fire's autonomous source-backed core, not the old generic ten-step pathway.
g['ft-couper-le-feu']=[
 action('feu-priere','priere','Signe de croix sur la zone et prière contre le feu (voir la fiche « CONTRE LE FEU »). À répéter trois fois.',page='p. 69–70',standalone=True,repetitions=3),
 action('feu-imposition','imposition','Main au-dessus de la brûlure, sans contact ; visualiser une lumière bleue pendant une minute. Reprendre pour chaque zone concernée.',page='p. 69–70',seconds=60,distanceText='',standalone=True)]
# These eleven records stay explicitly unverified. Their original library content is unchanged.
for f in raw:
 if f.get('type')=='fiche_technique' and f['id'] not in g:
  g[f['id']]=[action('archive','personnel',f['contenu'],page='contenu historique V3.2 ; protocole complet non vérifié',standalone=True,documented=False)]
P.write_text(json.dumps(g,ensure_ascii=False,indent=2)+'\n')
status=[]
for f in raw:
 if f.get('type')!='fiche_technique':continue
 id=f['id'];unverified=any(not a.get('documented',True) for a in g[id])
 status.append({'id':id,'titre':f['titre'],'migration':'archive manuelle conservée' if unverified else 'actions structurées',
 'conformite':'non vérifiée : provenance du protocole complet manquante' if unverified else 'partielle : corrections sourcées, certification exhaustive non acquise',
 'limites':['Adaptation distance non documentée'] if unverified or id=='ft-couper-le-feu' else ['Validation documentaire continue de tous les gestes et variantes non acquise']})
(R/'assets/data/statut_v331.json').write_text(json.dumps(status,ensure_ascii=False,indent=2)+'\n')
print('57 guides ;',sum(x['migration']=='actions structurées' for x in status),'fiches structurées, archives non certifiées conservées')
