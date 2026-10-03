import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import '../services/magnetisme_library_service.dart';

class MagnetismeScreen extends StatefulWidget {
  final String? prefillNom, prefillNomFamille;
  const MagnetismeScreen({super.key,this.prefillNom,this.prefillNomFamille});
  @override State<MagnetismeScreen> createState()=>_MagnetismeScreenState();
}
class _MagnetismeScreenState extends State<MagnetismeScreen>{
  final _prenom=TextEditingController(),_nom=TextEditingController(),_notes=TextEditingController();
  List<_Fiche> _fiches=[]; List<Map<String,dynamic>> _bibliotheque=[]; String? _selection; String _mode='Présentiel'; bool _genere=false,_loading=true;
  final Set<int> _faites={}; final Map<String,bool> _scans={};
  @override void initState(){super.initState();_prenom.text=widget.prefillNom??'';_nom.text=widget.prefillNomFamille??'';_load();}
  @override void dispose(){_prenom.dispose();_nom.dispose();_notes.dispose();super.dispose();}
  Future<void> _load()async{try{final raw=await rootBundle.loadString('assets/data/magnetisme_protocoles.json');final d=jsonDecode(raw) as Map<String,dynamic>;final l=(d['fiches'] as List).map((e)=>_Fiche.fromJson(Map<String,dynamic>.from(e))).toList();final all=await MagnetismeLibraryService.loadAll();if(mounted)setState((){_fiches=l;_bibliotheque=all;_loading=false;});}catch(_){if(mounted)setState(()=>_loading=false);}}
  List<_Fiche> get _fts=>_fiches.where((f)=>f.type=='fiche_technique').toList()..sort((a,b)=>a.titre.compareTo(b.titre));

  List<Map<String,dynamic>> _ressourcesLiees(_Fiche fiche){
    final texte=fiche.contenu.toLowerCase();
    final result=<Map<String,dynamic>>[];
    final seen=<String>{fiche.id};
    for(final e in _bibliotheque){
      final id=(e['id']??'').toString();
      if(id.isEmpty||seen.contains(id)) continue;
      final titre=(e['titre']??'').toString();
      final aliases=((e['aliases'] as List?)??const []).map((x)=>x.toString());
      final termes=<String>[titre,...aliases]
        .map((x)=>x.trim().toLowerCase())
        .where((x)=>x.length>=5)
        .toSet();
      if(termes.any((t)=>texte.contains(t))){
        result.add(e);
        seen.add(id);
      }
    }
    result.sort((a,b)=>(a['titre']??'').toString().compareTo((b['titre']??'').toString()));
    return result;
  }

  String _personnalise(String texte){
    return MagnetismeLibraryService.personalized(
      texte,
      prenom:_prenom.text,
      nom:_nom.text,
      pathologie:_selection,
    );
  }
  List<String> _steps(){final s=['Prise de contact','Bilan énergétique','Dégagement des entités / énergies négatives si nécessaire','14 conventions mentales','Conventions mentales supplémentaires de la fiche technique','Prières / formulations prévues par le protocole'];if(_mode=='Présentiel'){s.addAll(['Passes et impositions selon la fiche','Circulation énergétique entre les chakras','Balayage','Débriefing / observation']);}else{s.addAll(['Travail sur photo / planches anatomiques selon la fiche','Renforcement de l’intention, notamment lors de la convention n°10','Débriefing / observation']);}return s;}
  Future<void> _save()async{final b=await Hive.openBox('soins_magnetisme');await b.add({'date':DateTime.now().toIso8601String(),'nom':_prenom.text.trim(),'nomFamille':_nom.text.trim(),'pathologie':_selection??'','mode':_mode,'etapesFaites':_faites.toList(),'scans':Map<String,bool>.from(_scans),'notes':_notes.text.trim()});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Séance enregistrée.')));}
  @override Widget build(BuildContext context){if(_loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));return DefaultTabController(length:2,child:Scaffold(appBar:AppBar(title:const Text('Soins magnétisme'),bottom:const TabBar(tabs:[Tab(text:'Nouveau soin'),Tab(text:'Fiches techniques')])),body:TabBarView(children:[_newCare(),_library()])));}
  Widget _newCare(){return ListView(padding:const EdgeInsets.all(12),children:[
    TextField(controller:_prenom,decoration:const InputDecoration(labelText:'Prénom du patient')),const SizedBox(height:8),
    TextField(controller:_nom,decoration:const InputDecoration(labelText:'Nom (optionnel)')),const SizedBox(height:14),
    const Text('Type de séance',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),
    SegmentedButton<String>(segments:const[ButtonSegment(value:'Présentiel',label:Text('Présentiel'),icon:Icon(Icons.person)),ButtonSegment(value:'Distance',label:Text('À distance'),icon:Icon(Icons.phone_in_talk))],selected:{_mode},onSelectionChanged:(v)=>setState(()=>_mode=v.first)),
    const SizedBox(height:14),const Text('Fiche technique',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),
    DropdownButtonFormField<String>(value:_selection,isExpanded:true,decoration:const InputDecoration(labelText:'Choisir l’affection / la FT'),items:_fts.map((f)=>DropdownMenuItem(value:f.titre,child:Text(f.titre))).toList(),onChanged:(v)=>setState(()=>_selection=v)),
    const SizedBox(height:12),FilledButton.icon(onPressed:_selection==null?null:()=>setState((){_genere=true;_faites.clear();_scans.clear();}),icon:const Icon(Icons.auto_awesome),label:const Text('Générer la séance complète')),
    if(_genere)...[
      const SizedBox(height:16),
      if (_selection != null) ...[
        Card(child:ExpansionTile(
          initiallyExpanded:true,
          leading:const Icon(Icons.medical_information_outlined,color:Colors.indigo),
          title:Text(_selection!,style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:const Text('Contenu complet de la fiche technique'),
          children:[
            Padding(
              padding:const EdgeInsets.fromLTRB(16,0,16,16),
              child:SingleChildScrollView(
                child:SelectableText(
                  _personnalise(_fiches.firstWhere((f)=>f.titre==_selection).contenu),
                ),
              ),
            ),
          ],
        )),
        const SizedBox(height:10),
      ],
      Builder(
        builder:(context){
          final fiche=_fiches.firstWhere((f)=>f.titre==_selection);
          final ressources=_ressourcesLiees(fiche);
          if(ressources.isEmpty) return const SizedBox.shrink();
          return Card(
            child:ExpansionTile(
              initiallyExpanded:true,
              leading:const Icon(Icons.link_outlined),
              title:const Text('Éléments liés à cette fiche'),
              subtitle:Text('${ressources.length} ressource(s) détectée(s) dans le protocole'),
              children:ressources.map((e){
                final type=(e['type']??'reference').toString();
                final titre=(e['titre']??'').toString();
                final contenu=_personnalise((e['contenu']??'').toString());
                return ListTile(
                  leading:Icon(type=='priere'?Icons.volunteer_activism:Icons.menu_book_outlined),
                  title:Text(titre),
                  subtitle:Text(
                    contenu,
                    maxLines:5,
                    overflow:TextOverflow.ellipsis,
                  ),
                  onTap:()=>showDialog<void>(
                    context:context,
                    builder:(_)=>AlertDialog(
                      title:Text(titre),
                      content:SizedBox(
                        width:600,
                        child:SingleChildScrollView(child:SelectableText(contenu)),
                      ),
                      actions:[
                        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Fermer')),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('Trame V2 : déroulé commun présentiel ou à distance, issue des fiches de séance fournies.'))),
      ..._steps().asMap().entries.map((e)=>CheckboxListTile(value:_faites.contains(e.key),dense:true,controlAffinity:ListTileControlAffinity.leading,title:Text((e.key+1).toString()+'. '+e.value),onChanged:(v)=>setState(()=>v==true?_faites.add(e.key):_faites.remove(e.key)))),
      const Divider(),const Text('Bilan / contrôles au pendule',style:TextStyle(fontWeight:FontWeight.bold)),
      ...['Vitalité / taux vibratoire','Corps énergétiques','7 chakras','Entités','Énergies négatives','Organes / zones','Qualité énergétique du sang'].map((s)=>CheckboxListTile(value:_scans[s]??false,dense:true,title:Text(s),onChanged:(v)=>setState(()=>_scans[s]=v??false))),
      TextField(controller:_notes,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'Observations / débriefing',alignLabelWithHint:true)),const SizedBox(height:10),
      FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('Enregistrer la séance'))
    ]]);}
  String? _referenceImage(_Fiche f){
    if(f.id=='chakras') return 'assets/images/chakras.jpg';
    if(f.id=='mesure chakras') return 'assets/images/mesurer_chakras.jpg';
    return null;
  }

  Widget _referenceImageWidget(_Fiche f){
    final path=_referenceImage(f);
    if(path==null) return const SizedBox.shrink();
    return Padding(
      padding:const EdgeInsets.fromLTRB(0,0,0,16),
      child:ClipRRect(
        borderRadius:BorderRadius.circular(8),
        child:Container(
          width:double.infinity,
          color:Theme.of(context).colorScheme.surfaceContainerHighest,
          padding:const EdgeInsets.all(4),
          child:InteractiveViewer(
            minScale:0.8,
            maxScale:4.0,
            child:Image.asset(
              path,
              width:double.infinity,
              fit:BoxFit.contain,
              cacheWidth:1200,
              filterQuality:FilterQuality.medium,
              errorBuilder:(context,error,stack)=>Padding(
                padding:const EdgeInsets.all(16),
                child:Column(
                  mainAxisSize:MainAxisSize.min,
                  children:[
                    const Icon(Icons.broken_image_outlined,size:40),
                    const SizedBox(height:8),
                    Text('Impossible de charger le schéma.\\n$path',textAlign:TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _library()=>ListView(padding:const EdgeInsets.all(12),children:[
    const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('Bibliothèque complète des fiches fournies. Ouvre une fiche pour consulter son contenu et, pour une FT, l’utiliser pour un soin.'))),
    ..._fiches.map((f)=>Card(child:ExpansionTile(
      leading:Icon(f.type=='fiche_technique'?Icons.description_outlined:Icons.menu_book),
      title:Text(f.titre),
      subtitle:Text(f.source),
      children:[
        Padding(
          padding:const EdgeInsets.fromLTRB(16,0,16,16),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _referenceImageWidget(f),
            SelectableText(f.contenu),
            if(f.type=='fiche_technique') ...[
              const SizedBox(height:12),
              FilledButton.icon(
                onPressed:(){
                  setState((){_selection=f.titre;_genere=false;});
                  DefaultTabController.of(context).animateTo(0);
                },
                icon:const Icon(Icons.playlist_add_check),
                label:const Text('Utiliser cette FT pour un soin'),
              ),
            ],
          ]),
        ),
      ],
    ))),
  ]);
}
class _Fiche{final String id,titre,source,type,contenu;const _Fiche({required this.id,required this.titre,required this.source,required this.type,required this.contenu});factory _Fiche.fromJson(Map<String,dynamic> j)=>_Fiche(id:(j['id']??'').toString(),titre:(j['titre']??'').toString(),source:(j['source']??'').toString(),type:(j['type']??'').toString(),contenu:(j['contenu']??'').toString());}
