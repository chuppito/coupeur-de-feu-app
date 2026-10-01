import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/magnetisme_session_service.dart';

class MagnetismeSessionScreen extends StatefulWidget {
  final String? prefillNom;
  final String? prefillNomFamille;
  const MagnetismeSessionScreen({super.key,this.prefillNom,this.prefillNomFamille});
  @override State<MagnetismeSessionScreen> createState()=>_MagnetismeSessionScreenState();
}

class _MagnetismeSessionScreenState extends State<MagnetismeSessionScreen>{
  final _prenom=TextEditingController(),_nom=TextEditingController(),_notes=TextEditingController(),_debrief=TextEditingController();
  final _vitalite=TextEditingController(),_vibratoire=TextEditingController(),_corps=TextEditingController(),_entites=TextEditingController(),_negatives=TextEditingController(),_organes=TextEditingController(),_sang=TextEditingController(),_bilanNotes=TextEditingController(),_degagementNotes=TextEditingController();
  List<_Doc> _docs=[]; String? _ftId; String _mode='Présentiel'; int _step=0; bool _loading=true,_saving=false,_degagement=false;
  final Set<int> _done={},_conventions={}; final Map<String,String?> _chakras={for(final c in _chakraNames)c:null};
  static const _chakraNames=['Chakra racine','Chakra sacré','Chakra plexus solaire','Chakra cœur','Chakra gorge','Chakra 3ᵉ œil','Chakra couronne'];
  static const _chakraChoices=['Déficience — G (grave)','Déficience — I (importante)','Déficience — F (faible)','Équilibre','Excès — G (grave)','Excès — I (important)','Excès — F (faible)'];

  @override void initState(){super.initState();_prenom.text=widget.prefillNom??'';_nom.text=widget.prefillNomFamille??'';_load();}
  @override void dispose(){for(final c in [_prenom,_nom,_notes,_debrief,_vitalite,_vibratoire,_corps,_entites,_negatives,_organes,_sang,_bilanNotes,_degagementNotes])c.dispose();super.dispose();}

  Future<void> _load()async{try{
    final raw=await rootBundle.loadString('assets/data/magnetisme_protocoles.json'); final data=jsonDecode(raw) as Map<String,dynamic>;
    final docs=(data['fiches'] as List).map((e)=>_Doc.fromJson(Map<String,dynamic>.from(e))).toList();
    if(mounted)setState((){_docs=docs;_loading=false;});
  }catch(_){if(mounted)setState(()=>_loading=false);}}

  String get _patient{final p=_prenom.text.trim(),n=_nom.text.trim();return n.isEmpty?p:p+' '+n;}
  _Doc? get _ft{for(final d in _docs){if(d.id==_ftId)return d;}return null;}
  _Doc? _doc(String title){final q=title.toLowerCase();for(final d in _docs){if(d.titre.toLowerCase()==q||d.source.toLowerCase()==q||d.id.toLowerCase()==q)return d;}return null;}
  List<_Doc> get _fts=>_docs.where((d)=>d.type=='fiche_technique').toList()..sort((a,b)=>a.titre.compareTo(b.titre));
  List<String> get _steps=>['Prise de contact','Bilan énergétique','Dégagement si nécessaire','14 conventions','Conventions spécifiques','Prières / formulations',_mode=='Présentiel'?'Techniques propres au présentiel':'Techniques propres à distance','Débrief'];

  Future<void> _save()async{
    if(_saving||_patient.isEmpty||_ft==null)return;setState(()=>_saving=true);
    await MagnetismeSessionService.save({
      'date':DateTime.now().toIso8601String(),'nomPatient':_prenom.text.trim(),'nomFamille':_nom.text.trim(),'mode':_mode,'ftId':_ft!.id,'ftTitre':_ft!.titre,
      'etapes':_steps,'etapesFaites':_done.toList(),'conventionsFaites':_conventions.toList(),'degagementNecessaire':_degagement,'degagementNotes':_degagementNotes.text.trim(),
      'bilan':{'vitalite':_vitalite.text.trim(),'vibratoire':_vibratoire.text.trim(),'corpsEnergetiques':_corps.text.trim(),'chakras':Map<String,String?>.from(_chakras),'entites':_entites.text.trim(),'energiesNegatives':_negatives.text.trim(),'organesZones':_organes.text.trim(),'sang':_sang.text.trim(),'notes':_bilanNotes.text.trim()},
      'observations':_notes.text.trim(),'debrief':_debrief.text.trim(),
    });
    if(!mounted)return;setState(()=>_saving=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Séance de magnétisme enregistrée.')));
  }

  @override Widget build(BuildContext context){
    if(_loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Scaffold(appBar:AppBar(title:const Text('Nouveau soin magnétisme')),body:SafeArea(child:Stepper(
      currentStep:_step,onStepTapped:(i)=>setState(()=>_step=i),onStepContinue:(){if(_step<_steps.length-1)setState(()=>_step++);},onStepCancel:(){if(_step>0)setState(()=>_step--);},
      controlsBuilder:(context,details){final last=_step==_steps.length-1;return Padding(padding:const EdgeInsets.only(top:10),child:Row(children:[
        FilledButton(onPressed:_ft==null?null:(last?_save:details.onStepContinue),child:Text(last?(_saving?'Enregistrement…':'Enregistrer la séance'):'Étape suivante')),
        if(_step>0)...[const SizedBox(width:8),TextButton(onPressed:details.onStepCancel,child:const Text('Précédente'))]
      ]));},
      steps:List.generate(_steps.length,(i)=>Step(title:Text(_steps[i]),isActive:i<=_step,state:_done.contains(i)?StepState.complete:StepState.indexed,content:_content(i))),
    )));
  }

  Widget _content(int i){switch(i){case 0:return _contact();case 1:return _bilan();case 2:return _degagementWidget();case 3:return _conventionsWidget();case 4:return _specificWidget();case 5:return _prieresWidget();case 6:return _techniquesWidget();default:return _debriefWidget();}}

  Widget _contact()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    TextField(controller:_prenom,decoration:const InputDecoration(labelText:'Prénom du patient')),const SizedBox(height:8),TextField(controller:_nom,decoration:const InputDecoration(labelText:'Nom (optionnel)')),
    const SizedBox(height:12),const Text('Type de séance',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),
    SegmentedButton<String>(segments:const[ButtonSegment(value:'Présentiel',label:Text('Présentiel'),icon:Icon(Icons.person)),ButtonSegment(value:'À distance',label:Text('À distance'),icon:Icon(Icons.phone_in_talk))],selected:{_mode},onSelectionChanged:(v)=>setState(()=>_mode=v.first)),
    const SizedBox(height:12),DropdownButtonFormField<String>(value:_ftId,isExpanded:true,decoration:const InputDecoration(labelText:'Choisir une fiche technique (FT)'),items:_fts.map((d)=>DropdownMenuItem(value:d.id,child:Text(d.titre))).toList(),onChanged:(v)=>setState(()=>_ftId=v)),
    const SizedBox(height:10),if(_ft!=null)_sourceCard(_ft!),const SizedBox(height:8),_doneBox(0,'Prise de contact réalisée')
  ]);

  Widget _bilan()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _info('Les cadrans restent ceux sur papier. L’application sert de guide et de mémoire pour noter les résultats relevés.'),
    _number('Vitalité / taux de vitalité',_vitalite),_number('Taux vibratoire',_vibratoire),_text('Corps énergétiques',_corps),
    const SizedBox(height:8),const Text('7 chakras',style:TextStyle(fontWeight:FontWeight.bold)),
    Card(
      child: Column(
        children: _chakraNames.map((name) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
            child: DropdownButtonFormField<String>(
              value: _chakras[name],
              isExpanded: true,
              decoration: InputDecoration(labelText: name),
              items: _chakraChoices.map((choice) {
                return DropdownMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _chakras[name] = value;
                });
              },
            ),
          );
        }).toList(),
      ),
    ),
    _text('Entités',_entites),_text('Énergies négatives',_negatives),_text('Organes / zones',_organes),_text('Qualité énergétique du sang',_sang),_text('Notes du bilan',_bilanNotes,minLines:3),_doneBox(1,'Bilan énergétique réalisé')
  ]);

  Widget _degagementWidget()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    CheckboxListTile(value:_degagement,title:const Text('Dégagement nécessaire'),subtitle:const Text('Décision prise à partir du bilan et de tes documents.'),onChanged:(v)=>setState(()=>_degagement=v??false),contentPadding:EdgeInsets.zero),
    if(_degagement)_text('Observations / formulation utilisée',_degagementNotes,minLines:3),_doneBox(2,'Étape contrôlée / réalisée')
  ]);

  Widget _conventionsWidget()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(_doc('14 conventions')!=null)_sourceCard(_doc('14 conventions')!),const SizedBox(height:8),
    ...List.generate(14,(i)=>CheckboxListTile(value:_conventions.contains(i),title:Text('Convention '+(i+1).toString()),subtitle:const Text('Utiliser exactement la convention du document de référence.'),onChanged:(v)=>setState(()=>v==true?_conventions.add(i):_conventions.remove(i)),contentPadding:EdgeInsets.zero)),
    _doneBox(3,'Les 14 conventions sont réalisées')
  ]);

  Widget _specificWidget()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _info('Cette étape ne crée aucune technique nouvelle : consulte la FT sélectionnée et applique uniquement ce qui y est indiqué.'),if(_ft!=null)_sourceCard(_ft!),_doneBox(4,'Conventions spécifiques réalisées selon la FT')
  ]);

  Widget _prieresWidget()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(_doc('prières')!=null)_sourceCard(_doc('prières')!),if(_ft!=null)_sourceCard(_ft!),_doneBox(5,'Prières / formulations réalisées selon les documents')
  ]);

  Widget _techniquesWidget(){
    final title=_mode=='Présentiel'?'récap séance présentiel':'récap séance à distance';
    final recap=_docs.where((d)=>d.titre.toLowerCase()==title).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      _info('Les techniques sont celles de la FT et du récapitulatif correspondant au mode choisi. Aucun protocole supplémentaire n’est inventé par l’application.'),
      if(_ft!=null)_sourceCard(_ft!),...recap.map(_sourceCard),_doneBox(6,'Techniques réalisées selon la FT')
    ]);
  }

  Widget _debriefWidget()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_text('Observations générales',_notes,minLines:4),_text('Débrief',_debrief,minLines:4),_doneBox(7,'Débrief réalisé')]);

  Widget _doneBox(int i,String title)=>CheckboxListTile(value:_done.contains(i),title:Text(title),onChanged:(v)=>setState(()=>v==true?_done.add(i):_done.remove(i)),contentPadding:EdgeInsets.zero);
  Widget _sourceCard(_Doc d)=>Card(child:ExpansionTile(leading:Icon(d.type=='fiche_technique'?Icons.description_outlined:Icons.menu_book_outlined,color:Colors.indigo),title:Text(d.titre,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text('Document source : '+d.source),children:[Container(constraints:const BoxConstraints(maxHeight:420),padding:const EdgeInsets.fromLTRB(16,0,16,16),child:SingleChildScrollView(child:SelectableText(d.contenu)))]));
  Widget _info(String text)=>Card(color:Colors.indigo.withValues(alpha:0.07),child:Padding(padding:const EdgeInsets.all(12),child:Text(text)));
  Widget _number(String label,TextEditingController c)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:TextField(controller:c,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:label)));
  Widget _text(String label,TextEditingController c,{int minLines=2})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:TextField(controller:c,minLines:minLines,maxLines:minLines+4,decoration:InputDecoration(labelText:label,alignLabelWithHint:true)));
}

class _Doc{
  final String id,titre,source,type,contenu;
  const _Doc({required this.id,required this.titre,required this.source,required this.type,required this.contenu});
  factory _Doc.fromJson(Map<String,dynamic> j)=>_Doc(id:(j['id']??'').toString(),titre:(j['titre']??'').toString(),source:(j['source']??'').toString(),type:(j['type']??'').toString(),contenu:(j['contenu']??'').toString());
}