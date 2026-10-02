import 'package:flutter/material.dart';
import '../services/magnetisme_library_service.dart';

class MagnetismeLibraryScreen extends StatefulWidget {
  const MagnetismeLibraryScreen({super.key});
  @override
  State<MagnetismeLibraryScreen> createState() => _MagnetismeLibraryScreenState();
}

class _MagnetismeLibraryScreenState extends State<MagnetismeLibraryScreen> {
  final _search = TextEditingController();
  List<Map<String,dynamic>> _items = [];
  String _category = 'Tout';
  bool _loading = true;

  @override
  void initState(){ super.initState(); _load(); }
  @override
  void dispose(){ _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    final all=await MagnetismeLibraryService.loadAll();
    if(!mounted)return;
    setState((){_items=all;_loading=false;});
  }

  List<Map<String,dynamic>> get _visible {
    final q=_search.text.trim().toLowerCase();
    return _items.where((e){
      final cat=(e['categorie']??'Références').toString();
      final title=(e['titre']??'').toString();
      final aliases=((e['aliases'] as List?)??const[]).join(' ');
      final content=(e['contenu']??'').toString();
      return (_category=='Tout'||cat==_category) &&
          (q.isEmpty || '$title $aliases $content'.toLowerCase().contains(q));
    }).toList()
      ..sort((a,b)=>(a['titre']??'').toString().toLowerCase()
          .compareTo((b['titre']??'').toString().toLowerCase()));
  }

  Future<void> _add() async {
    final title=TextEditingController(), explanation=TextEditingController(), content=TextEditingController(), aliases=TextEditingController();
    String type='fiche_technique';
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(
      builder:(ctx,setDialog)=>AlertDialog(
        title:const Text('Ajouter à la bibliothèque'),
        content:SizedBox(width:520,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          DropdownButtonFormField<String>(
            value:type, decoration:const InputDecoration(labelText:'Type'),
            items:const[
              DropdownMenuItem(value:'fiche_technique',child:Text('Fiche technique')),
              DropdownMenuItem(value:'technique',child:Text('Technique')),
              DropdownMenuItem(value:'priere',child:Text('Prière / formulation')),
              DropdownMenuItem(value:'reference',child:Text('Référence')),
            ],
            onChanged:(v){if(v!=null)setDialog(()=>type=v);}
          ),
          const SizedBox(height:10),
          TextField(controller:title,decoration:const InputDecoration(labelText:'Nom / titre')),
          const SizedBox(height:10),
          TextField(controller:explanation,minLines:2,maxLines:5,decoration:const InputDecoration(labelText:'Explication')),
          const SizedBox(height:10),
          TextField(controller:aliases,decoration:const InputDecoration(labelText:'Mots-clés / pathologies (séparés par des virgules)')),
          const SizedBox(height:10),
          TextField(controller:content,minLines:5,maxLines:14,decoration:const InputDecoration(labelText:'Contenu / prière')),
        ]))),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Annuler')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,title.text.trim().isNotEmpty&&content.text.trim().isNotEmpty),child:const Text('Enregistrer')),
        ],
      ),
    ));
    if(ok!=true){title.dispose();explanation.dispose();content.dispose();aliases.dispose();return;}
    final aliasList = aliases.text.split(',').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList();
    if(!aliasList.contains(title.text.trim())) aliasList.add(title.text.trim());
    await MagnetismeLibraryService.add({
      'id':'custom-${DateTime.now().microsecondsSinceEpoch}',
      'titre':title.text.trim(),'source':'Ajout manuel','type':type,
      'categorie':type=='priere'?'Prières / formulations':type=='fiche_technique'?'Fiches techniques':type=='technique'?'Techniques':'Références',
      'aliases':aliasList,'description':explanation.text.trim(),'contenu':content.text.trim(),
    });
    title.dispose();explanation.dispose();content.dispose();aliases.dispose();
    await _load();
  }

  @override
  Widget build(BuildContext context){
    if(_loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final cats=<String>{'Tout',..._items.map((e)=>(e['categorie']??'Références').toString())}.toList();
    return Scaffold(
      appBar:AppBar(title:const Text('Bibliothèque magnétisme'),actions:[IconButton(tooltip:'Ajouter',onPressed:_add,icon:const Icon(Icons.add))]),
      body:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(12,8,12,4),child:TextField(
          controller:_search,onChanged:(_)=>setState((){}),
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Rechercher une fiche, une prière, une formulation…'),
        )),
        SizedBox(height:48,child:ListView.separated(
          padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),scrollDirection:Axis.horizontal,
          itemCount:cats.length,
          itemBuilder:(_,i)=>ChoiceChip(label:Text(cats[i]),selected:_category==cats[i],onSelected:(_)=>setState(()=>_category=cats[i])),
          separatorBuilder:(_,__)=>const SizedBox(width:6),
        )),
        Expanded(child:ListView.builder(
          padding:const EdgeInsets.fromLTRB(12,4,12,24),itemCount:_visible.length,
          itemBuilder:(_,i){
            final e=_visible[i], type=(e['type']??'reference').toString();
            final icon=type=='priere'?Icons.volunteer_activism:type=='fiche_technique'?Icons.menu_book_outlined:type=='technique'?Icons.auto_awesome:Icons.book_outlined;
            return Card(child:ListTile(
              leading:CircleAvatar(child:Icon(icon,size:20)),
              title:Text((e['titre']??'').toString(),style:const TextStyle(fontWeight:FontWeight.w600)),
              subtitle:Text((e['description']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis),
              trailing:const Icon(Icons.chevron_right),
              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_LibraryReader(entry:e))),
            ));
          },
        )),
      ]),
    );
  }
}

class _LibraryReader extends StatelessWidget {
  final Map<String,dynamic> entry;
  const _LibraryReader({required this.entry});
  @override
  Widget build(BuildContext context){
    final type=(entry['type']??'reference').toString();
    final explanation=(entry['description']??'').toString().trim();
    final content=(entry['contenu']??'').toString().trim();
    final illustration=(entry['illustrationAsset']??'').toString().trim();
    return Scaffold(
      appBar:AppBar(title:Text((entry['titre']??'').toString())),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        if(illustration.isNotEmpty)Card(child:Padding(
          padding:const EdgeInsets.all(10),
          child:ClipRRect(
            borderRadius:BorderRadius.circular(8),
            child:Image.asset(illustration,fit:BoxFit.contain),
          ),
        )),
        if(illustration.isNotEmpty)const SizedBox(height:8),
        if(explanation.isNotEmpty)Card(color:Theme.of(context).colorScheme.primaryContainer,child:Padding(
          padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Explication',style:TextStyle(fontWeight:FontWeight.bold)),
            const SizedBox(height:6),Text(explanation,style:const TextStyle(height:1.45)),
          ]))),
        const SizedBox(height:8),
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(type=='priere'?'Prière / formulation':'Contenu',style:const TextStyle(fontWeight:FontWeight.bold)),
          const SizedBox(height:8),SelectableText(content,style:const TextStyle(fontSize:15,height:1.5)),
        ]))),
      ]),
    );
  }
}
