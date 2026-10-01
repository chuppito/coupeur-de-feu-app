import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';

class MagnetismeScreen extends StatefulWidget {
  final String? prefillNom, prefillNomFamille;
  const MagnetismeScreen({super.key,this.prefillNom,this.prefillNomFamille});
  @override State<MagnetismeScreen> createState()=>_MagnetismeScreenState();
}
class _MagnetismeScreenState extends State<MagnetismeScreen>{
  final _prenom=TextEditingController(),_nom=TextEditingController(),_notes=TextEditingController();
  List<_Fiche> _fiches=[]; String? _selection; String _mode='Présentiel'; bool _genere=false,_loading=true;
  final Set<int> _faites={}; final Map<String,bool> _scans={};
  @override void initState(){super.initState();_prenom.text=widget.prefillNom??'';_nom.text=widget.prefillNomFamille??'';_load();}
  @override void dispose(){_prenom.dispose();_nom.dispose();_notes.dispose();super.dispose();}
  Future<void> _load()async{try{final raw=await rootBundle.loadString('assets/data/magnetisme_protocoles.json');final d=jsonDecode(raw) as Map<String,dynamic>;final l=(d['fiches'] as List).map((e)=>_Fiche.fromJson(Map<String,dynamic>.from(e))).toList();if(mounted)setState((){_fiches=l;_loading=false;});}catch(_){if(mounted)setState(()=>_loading=false);}}
  List<_Fiche> get _fts=>_fiches.where((f)=>f.type=='fiche_technique').toList()..sort((a,b)=>a.titre.compareTo(b.titre));
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
      const SizedBox(height:16),const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('Trame V2 : déroulé commun présentiel ou à distance. Les détails propres à chaque FT restent liés à la fiche papier source.'))),
      ..._steps().asMap().entries.map((e)=>CheckboxListTile(value:_faites.contains(e.key),dense:true,controlAffinity:ListTileControlAffinity.leading,title:Text((e.key+1).toString()+'. '+e.value),onChanged:(v)=>setState(()=>v==true?_faites.add(e.key):_faites.remove(e.key)))),
      const Divider(),const Text('Bilan / contrôles au pendule',style:TextStyle(fontWeight:FontWeight.bold)),
      ...['Vitalité / taux vibratoire','Corps énergétiques','7 chakras','Entités','Énergies négatives','Organes / zones','Qualité énergétique du sang'].map((s)=>CheckboxListTile(value:_scans[s]??false,dense:true,title:Text(s),onChanged:(v)=>setState(()=>_scans[s]=v??false))),
      TextField(controller:_notes,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'Observations / débriefing',alignLabelWithHint:true)),const SizedBox(height:10),
      FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('Enregistrer la séance'))
    ]]);}
  Widget _library()=>ListView(padding:const EdgeInsets.all(12),children:[const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('Bibliothèque des fiches fournies. Les fiches papier restent la référence détaillée.'))),..._fiches.map((f)=>Card(child:ListTile(leading:Icon(f.type=='fiche_technique'?Icons.description_outlined:Icons.menu_book),title:Text(f.titre),subtitle:Text(f.source))))]);
}
class _Fiche{final String id,titre,source,type,contenu;const _Fiche({required this.id,required this.titre,required this.source,required this.type,required this.contenu});factory _Fiche.fromJson(Map<String,dynamic> j)=>_Fiche(id:(j['id']??'').toString(),titre:(j['titre']??'').toString(),source:(j['source']??'').toString(),type:(j['type']??'').toString(),contenu:(j['contenu']??'').toString());}
